with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Connection_Registry;
with OCPP16_Call_Parser;
with OCPP16_Dispatcher;

package body OCPP_Router is
   use Ada.Strings.Fixed;

   function Detect_Version (Path : String) return OCPP_Version is
   begin
      if Index (Path, "/1.6") > 0 then
         return V16J;
      elsif Index (Path, "/2.0") > 0 or else Index (Path, "/2.1") > 0 then
         return V20x;
      else
         return Unknown;
      end if;
   end Detect_Version;

   procedure Handle_Inbound_Frame
     (Charge_Point_Id : String;
      Path            : String;
      Frame_JSON      : String) is
      Version      : constant OCPP_Version := Detect_Version (Path);
      Parse_Outcome : OCPP16_Call_Parser.Parse_Result;
   begin
      if Version /= V16J then
         Connection_Registry.Upsert
           (Charge_Point_Id => Charge_Point_Id,
            Version         => Version,
            State           => Connected,
            Last_Message    => "Unsupported for now: " & Frame_JSON);
         return;
      end if;

      Parse_Outcome := OCPP16_Call_Parser.Parse_Action (Frame_JSON);
      if not Parse_Outcome.Is_Valid then
         Connection_Registry.Upsert
           (Charge_Point_Id => Charge_Point_Id,
            Version         => V16J,
            State           => Faulted,
            Last_Message    => "Invalid OCPP 1.6 CALL frame: " & To_String (Parse_Outcome.Error));
         return;
      end if;

      OCPP16_Dispatcher.Handle_Action
        (Charge_Point_Id => Charge_Point_Id,
         Action          => To_String (Parse_Outcome.Action),
         Frame_JSON      => Frame_JSON);
   end Handle_Inbound_Frame;

end OCPP_Router;
