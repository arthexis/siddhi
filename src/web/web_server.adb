with Ada.Calendar;
with Ada.Characters.Latin_1;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;

with AWS.Config;
with AWS.Config.Set;
with AWS.Messages;
with AWS.MIME;
with AWS.Response;
with AWS.Server;
with AWS.Status;

with OCPP.Models;
with Connection_Registry;
with OCPP_Router;

package body Web_Server is
   use Ada.Characters.Latin_1;
   use Ada.Strings.Fixed;
   use OCPP.Models;

   function Escape_JSON (Text : String) return String is
      Output : Unbounded_String;
   begin
      for Ch of Text loop
         case Ch is
            when '"' =>
               Append (Output, "\\\"");
            when '\\' =>
               Append (Output, "\\\\");
            when LF =>
               Append (Output, "\\n");
            when CR =>
               Append (Output, "\\r");
            when HT =>
               Append (Output, "\\t");
            when others =>
               Append (Output, Ch);
         end case;
      end loop;

      return To_String (Output);
   end Escape_JSON;

   function Version_Image (Version : OCPP_Version) return String is
   begin
      case Version is
         when V16J =>
            return "1.6J";
         when V20x =>
            return "2.x";
         when Unknown =>
            return "unknown";
      end case;
   end Version_Image;

   function State_Image (State : Charger_State_Kind) return String is
   begin
      case State is
         when Disconnected =>
            return "Disconnected";
         when Connecting =>
            return "Connecting";
         when Connected =>
            return "Connected";
         when Faulted =>
            return "Faulted";
      end case;
   end State_Image;

   function Build_State_JSON return String is
      Snapshot : constant Connection_Registry.Charger_State_Array := Connection_Registry.Snapshot;
      Body     : Unbounded_String := To_Unbounded_String ("{\"updatedAt\":\"");
      Now      : constant Ada.Calendar.Time := Ada.Calendar.Clock;
      Year     : Ada.Calendar.Year_Number;
      Month    : Ada.Calendar.Month_Number;
      Day      : Ada.Calendar.Day_Number;
      Seconds  : Ada.Calendar.Day_Duration;
      Hour     : Natural;
      Minute   : Natural;
      Second   : Natural;
   begin
      Ada.Calendar.Split (Now, Year, Month, Day, Seconds);
      Hour   := Natural (Seconds / 3600.0);
      Minute := Natural ((Seconds - Ada.Calendar.Day_Duration (Hour) * 3600.0) / 60.0);
      Second := Natural (Seconds) mod 60;

      Append (Body, Trim (Year'Image, Both) & "-");
      if Month < 10 then
         Append (Body, "0");
      end if;
      Append (Body, Trim (Month'Image, Both) & "-");
      if Day < 10 then
         Append (Body, "0");
      end if;
      Append (Body, Trim (Day'Image, Both) & "T");
      if Hour < 10 then
         Append (Body, "0");
      end if;
      Append (Body, Trim (Hour'Image, Both) & ":");
      if Minute < 10 then
         Append (Body, "0");
      end if;
      Append (Body, Trim (Minute'Image, Both) & ":");
      if Second < 10 then
         Append (Body, "0");
      end if;
      Append (Body, Trim (Second'Image, Both) & "Z\",\"chargers\":[");

      for I in Snapshot'Range loop
         if I > Snapshot'First then
            Append (Body, ",");
         end if;

         Append
           (Body,
            "{\"id\":\"" & Escape_JSON (To_String (Snapshot (I).Charge_Point_Id)) &
            "\",\"version\":\"" & Escape_JSON (Version_Image (Snapshot (I).Version)) &
            "\",\"state\":\"" & Escape_JSON (State_Image (Snapshot (I).State)) &
            "\",\"lastMessage\":\"" & Escape_JSON (To_String (Snapshot (I).Last_Message)) & "\"}");
      end loop;

      Append (Body, "]}");
      return To_String (Body);
   end Build_State_JSON;

   function Read_File (Path : String) return String is
      File : Ada.Text_IO.File_Type;
      Data : Unbounded_String;
   begin
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Append (Data, Ada.Text_IO.Get_Line (File));
         if not Ada.Text_IO.End_Of_File (File) then
            Append (Data, LF);
         end if;
      end loop;
      Ada.Text_IO.Close (File);
      return To_String (Data);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return "";
   end Read_File;

   function URL_Decode (Encoded : String) return String is
      Decoded : Unbounded_String;

      function Hex_Value (Ch : Character) return Natural is
      begin
         case Ch is
            when '0' .. '9' =>
               return Character'Pos (Ch) - Character'Pos ('0');
            when 'A' .. 'F' =>
               return 10 + Character'Pos (Ch) - Character'Pos ('A');
            when 'a' .. 'f' =>
               return 10 + Character'Pos (Ch) - Character'Pos ('a');
            when others =>
               return 0;
         end case;
      end Hex_Value;

      I : Positive := Encoded'First;
   begin
      while I <= Encoded'Last loop
         if Encoded (I) = '+' then
            Append (Decoded, ' ');
            I := I + 1;
         elsif Encoded (I) = '%' and then I + 2 <= Encoded'Last then
            Append
              (Decoded,
               Character'Val
                 (Hex_Value (Encoded (I + 1)) * 16 + Hex_Value (Encoded (I + 2))));
            I := I + 3;
         else
            Append (Decoded, Encoded (I));
            I := I + 1;
         end if;
      end loop;

      return To_String (Decoded);
   end URL_Decode;

   function Query_Value (URI : String; Key : String) return String is
      Query_Start : constant Natural := Index (URI, "?");
   begin
      if Query_Start = 0 or else Query_Start = URI'Last then
         return "";
      end if;

      declare
         Query       : constant String := URI (Query_Start + 1 .. URI'Last);
         Search_From : Positive := Query'First;
         Pair_End    : Natural;
         Key_Value   : Natural;
      begin
         while Search_From <= Query'Last loop
            Pair_End := Index (Query, "&", Search_From);
            if Pair_End = 0 then
               Pair_End := Query'Last + 1;
            end if;

            Key_Value := Index (Query, "=", Search_From);
            if Key_Value > 0 and then Key_Value < Pair_End then
               declare
                  Current_Key : constant String := URL_Decode (Query (Search_From .. Key_Value - 1));
               begin
                  if Current_Key = Key then
                     return URL_Decode (Query (Key_Value + 1 .. Pair_End - 1));
                  end if;
               end if;
               end;
            end if;

            Search_From := Pair_End + 1;
         end loop;
      end;

      return "";
   end Query_Value;

   function Path_Only (URI : String) return String is
      Query_Start : constant Natural := Index (URI, "?");
   begin
      if Query_Start = 0 then
         return URI;
      elsif Query_Start = URI'First then
         return "/";
      else
         return URI (URI'First .. Query_Start - 1);
      end if;
   end Path_Only;

   function Callback (Request : AWS.Status.Data) return AWS.Response.Data is
      URI  : constant String := AWS.Status.URI (Request);
      Path : constant String := Path_Only (URI);
   begin
      if Path = "/api/state" then
         return AWS.Response.Build
           (Content_Type  => AWS.MIME.Application_JSON,
            Message_Body  => Build_State_JSON,
            Status_Code   => AWS.Messages.S200);
      elsif Path = "/api/inbound" then
         declare
            Charge_Point_Id : constant String := Query_Value (URI, "chargePointId");
            OCPP_Path       : constant String := Query_Value (URI, "path");
            Frame_JSON      : constant String := Query_Value (URI, "frame");
         begin
            if Charge_Point_Id = "" or else OCPP_Path = "" or else Frame_JSON = "" then
               return AWS.Response.Build
                 (Content_Type => AWS.MIME.Application_JSON,
                  Message_Body => "{""ok"":false,""error"":""Missing required query params: chargePointId, path, frame""}",
                  Status_Code  => AWS.Messages.S400);
            end if;

            OCPP_Router.Handle_Inbound_Frame
              (Charge_Point_Id => Charge_Point_Id,
               Path            => OCPP_Path,
               Frame_JSON      => Frame_JSON);

            return AWS.Response.Build
              (Content_Type => AWS.MIME.Application_JSON,
               Message_Body => "{""ok"":true}",
               Status_Code  => AWS.Messages.S200);
         end;
      elsif Path = "/" or else Path = "/index.html" then
         return AWS.Response.Build
           (Content_Type => AWS.MIME.Text_HTML,
            Message_Body => Read_File ("web/index.html"),
            Status_Code  => AWS.Messages.S200);
      elsif Path = "/admin" or else Path = "/admin/" or else Path = "/admin/index.html" then
         return AWS.Response.Build
           (Content_Type => AWS.MIME.Text_HTML,
            Message_Body => Read_File ("web/admin/index.html"),
            Status_Code  => AWS.Messages.S200);
      elsif Path = "/state.json" then
         return AWS.Response.Build
           (Content_Type => AWS.MIME.Application_JSON,
            Message_Body => Build_State_JSON,
            Status_Code  => AWS.Messages.S200);
      else
         return AWS.Response.Build
           (Content_Type => AWS.MIME.Text_Plain,
            Message_Body => "Not Found",
            Status_Code  => AWS.Messages.S404);
      end if;
   end Callback;

   procedure Run is
      HTTP_Server : AWS.Server.HTTP;
      Config      : AWS.Config.Object;
   begin
      AWS.Config.Set.Server_Host (Config, "0.0.0.0");
      AWS.Config.Set.Server_Port (Config, 8443);
      AWS.Config.Set.Security (Config, True);
      AWS.Config.Set.Certificate (Config, "certs/server.crt");
      AWS.Config.Set.Key_File (Config, "certs/server.key");

      AWS.Server.Start
        (Web_Server => HTTP_Server,
         Name       => "ocpp-csms-https",
         Callback   => Callback'Unrestricted_Access,
         Config     => Config);

      Ada.Text_IO.Put_Line ("HTTPS dashboard server listening on https://localhost:8443");
      AWS.Server.Wait (AWS.Server.Forever);
   end Run;

end Web_Server;
