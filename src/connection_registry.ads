with Ada.Strings.Unbounded;
with OCPP.Models;

package Connection_Registry is
   use Ada.Strings.Unbounded;
   use OCPP.Models;

   type Charger_State_View is record
      Charge_Point_Id : Unbounded_String;
      Version         : OCPP_Version;
      State           : Charger_State_Kind;
      Last_Message    : Unbounded_String;
   end record;

   type Charger_State_Array is array (Positive range <>) of Charger_State_View;

   procedure Upsert
     (Charge_Point_Id : String;
      Version         : OCPP_Version;
      State           : Charger_State_Kind;
      Last_Message    : String := "");

   function Snapshot return Charger_State_Array;

end Connection_Registry;
