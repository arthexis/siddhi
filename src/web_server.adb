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

with Charger_Models;
with Connection_Registry;

package body Web_Server is
   use Ada.Characters.Latin_1;
   use Ada.Strings.Fixed;
   use Charger_Models;

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

   function Callback (Request : AWS.Status.Data) return AWS.Response.Data is
      URI : constant String := AWS.Status.URI (Request);
   begin
      if URI = "/api/state" then
         return AWS.Response.Build
           (Content_Type  => AWS.MIME.Application_JSON,
            Message_Body  => Build_State_JSON,
            Status_Code   => AWS.Messages.S200);
      elsif URI = "/" or else URI = "/index.html" then
         return AWS.Response.Build
           (Content_Type => AWS.MIME.Text_HTML,
            Message_Body => Read_File ("web/index.html"),
            Status_Code  => AWS.Messages.S200);
      elsif URI = "/admin" or else URI = "/admin/" or else URI = "/admin/index.html" then
         return AWS.Response.Build
           (Content_Type => AWS.MIME.Text_HTML,
            Message_Body => Read_File ("web/admin/index.html"),
            Status_Code  => AWS.Messages.S200);
      elsif URI = "/state.json" then
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
