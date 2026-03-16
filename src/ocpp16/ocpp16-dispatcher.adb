with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with OCPP.Models;
with Connection_Registry;

package body OCPP16.Dispatcher is
   use OCPP.Models;

   procedure Handle_Action
     (Charge_Point_Id : String;
      Action          : String;
      Frame_JSON      : String) is
      State : Charger_State_Kind := Connected;
      Note  : Unbounded_String := To_Unbounded_String ("OCPP 1.6 action=" & Action);
   begin
      if Action = "BootNotification" then
         State := Connected;
         Note := To_Unbounded_String ("BootNotification received");
      elsif Action = "Heartbeat" then
         State := Connected;
         Note := To_Unbounded_String ("Heartbeat received");
      elsif Action = "StatusNotification" then
         State := Connected;
         Note := To_Unbounded_String ("StatusNotification received");
      else
         State := Connected;
         Note := To_Unbounded_String ("OCPP 1.6 CALL received: " & Action);
      end if;

      Connection_Registry.Upsert
        (Charge_Point_Id => Charge_Point_Id,
         Version         => V16J,
         State           => State,
         Last_Message    => To_String (Note) & " | " & Frame_JSON);
   end Handle_Action;

end OCPP16.Dispatcher;
