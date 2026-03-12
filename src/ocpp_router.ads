with Charger_Models;

package OCPP_Router is
   use Charger_Models;

   function Detect_Version (Path : String) return OCPP_Version;

   --  Parse and route an inbound OCPP frame.
   --  Currently implemented for OCPP 1.6 CALL frames:
   --    [2, messageId, action, payload]
   procedure Handle_Inbound_Frame
     (Charge_Point_Id : String;
      Path            : String;
      Frame_JSON      : String);

end OCPP_Router;
