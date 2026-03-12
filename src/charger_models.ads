with Ada.Strings.Unbounded;

package Charger_Models is
   use Ada.Strings.Unbounded;

   type OCPP_Version is (V16J, V20x, Unknown);

   type Charger_State_Kind is (Disconnected, Connecting, Connected, Faulted);

   type Charger_Session is record
      Charge_Point_Id : Unbounded_String;
      Version         : OCPP_Version := Unknown;
      State           : Charger_State_Kind := Disconnected;
      Last_Message    : Unbounded_String;
   end record;
end Charger_Models;
