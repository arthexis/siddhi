with Ada.Characters.Latin_1;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body OCPP16_Call_Parser is
   use Ada.Strings.Fixed;

   function Skip_Spaces (Source : String; From : Positive) return Positive is
      I : Positive := From;
   begin
      while I <= Source'Last and then
        (Source (I) = ' ' or else Source (I) = Ada.Characters.Latin_1.HT)
      loop
         I := I + 1;
      end loop;
      return I;
   end Skip_Spaces;

   function Find_Comma_Or_End (Source : String; From : Positive) return Natural is
      I             : Positive := From;
      In_String     : Boolean := False;
      Escape_Next   : Boolean := False;
      Brace_Depth   : Natural := 0;
      Bracket_Depth : Natural := 0;
   begin
      while I <= Source'Last loop
         if In_String then
            if Escape_Next then
               Escape_Next := False;
            elsif Source (I) = '\\' then
               Escape_Next := True;
            elsif Source (I) = '"' then
               In_String := False;
            end if;
         else
            case Source (I) is
               when '"' =>
                  In_String := True;
               when '{' =>
                  Brace_Depth := Brace_Depth + 1;
               when '}' =>
                  if Brace_Depth > 0 then
                     Brace_Depth := Brace_Depth - 1;
                  end if;
               when '[' =>
                  Bracket_Depth := Bracket_Depth + 1;
               when ']' =>
                  if Bracket_Depth = 0 and then Brace_Depth = 0 then
                     return I;
                  elsif Bracket_Depth > 0 then
                     Bracket_Depth := Bracket_Depth - 1;
                  end if;
               when ',' =>
                  if Brace_Depth = 0 and then Bracket_Depth = 0 then
                     return I;
                  end if;
               when others =>
                  null;
            end case;
         end if;

         I := I + 1;
      end loop;

      return 0;
   end Find_Comma_Or_End;

   function Parse_Action (Frame_JSON : String) return Parse_Result is
      I      : Positive := Frame_JSON'First;
      Stop_1 : Natural;
      Stop_2 : Natural;
      Stop_3 : Natural;
   begin
      if Frame_JSON'Length < 3 then
         return (Is_Valid => False,
                 Action   => To_Unbounded_String (""),
                 Error    => To_Unbounded_String ("Frame too short"));
      end if;

      I := Skip_Spaces (Frame_JSON, I);
      if Frame_JSON (I) /= '[' then
         return (Is_Valid => False,
                 Action   => To_Unbounded_String (""),
                 Error    => To_Unbounded_String ("Frame is not a JSON array"));
      end if;

      I := Skip_Spaces (Frame_JSON, I + 1);
      if I > Frame_JSON'Last or else Frame_JSON (I) /= '2' then
         return (Is_Valid => False,
                 Action   => To_Unbounded_String (""),
                 Error    => To_Unbounded_String ("Message type is not CALL (2)"));
      end if;

      I := Skip_Spaces (Frame_JSON, I + 1);
      if I > Frame_JSON'Last or else Frame_JSON (I) /= ',' then
         return (Is_Valid => False,
                 Action   => To_Unbounded_String (""),
                 Error    => To_Unbounded_String ("Missing delimiter after message type"));
      end if;

      I := Skip_Spaces (Frame_JSON, I + 1);
      Stop_1 := Find_Comma_Or_End (Frame_JSON, I);
      if Stop_1 = 0 or else Stop_1 >= Frame_JSON'Last then
         return (Is_Valid => False,
                 Action   => To_Unbounded_String (""),
                 Error    => To_Unbounded_String ("Missing message id element"));
      end if;

      I := Skip_Spaces (Frame_JSON, Stop_1 + 1);
      Stop_2 := Find_Comma_Or_End (Frame_JSON, I);
      if Stop_2 = 0 then
         return (Is_Valid => False,
                 Action   => To_Unbounded_String (""),
                 Error    => To_Unbounded_String ("Missing action element"));
      end if;

      declare
         Raw_Action : constant String :=
           Trim (Frame_JSON (I .. Stop_2 - 1), Ada.Strings.Both);
      begin
         if Raw_Action'Length < 2
           or else Raw_Action (Raw_Action'First) /= '"'
           or else Raw_Action (Raw_Action'Last) /= '"'
         then
            return (Is_Valid => False,
                    Action   => To_Unbounded_String (""),
                    Error    => To_Unbounded_String ("Action must be a JSON string"));
         end if;

         I := Skip_Spaces (Frame_JSON, Stop_2 + 1);
         Stop_3 := Find_Comma_Or_End (Frame_JSON, I);
         if Stop_3 = 0 then
            return (Is_Valid => False,
                    Action   => To_Unbounded_String (""),
                    Error    => To_Unbounded_String ("Missing payload element"));
         end if;

         return
           (Is_Valid => True,
            Action   => To_Unbounded_String
              (Raw_Action (Raw_Action'First + 1 .. Raw_Action'Last - 1)),
            Error    => To_Unbounded_String (""));
      end;
   exception
      when others =>
         return (Is_Valid => False,
                 Action   => To_Unbounded_String (""),
                 Error    => To_Unbounded_String ("Unexpected parse failure"));
   end Parse_Action;

end OCPP16_Call_Parser;
