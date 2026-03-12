with Charger_Models;

package OCPP_Router is
   use Charger_Models;

   function Detect_Version (Path : String) return OCPP_Version;

   --  Stub for future JSON frame routing.
   procedure Handle_Inbound_Frame
     (Charge_Point_Id : String;
      Path            : String;
      Frame_JSON      : String);
end OCPP_Router;
