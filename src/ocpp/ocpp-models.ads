with Ada.Calendar;
with Ada.Strings.Unbounded;

package OCPP.Models is
   use Ada.Strings.Unbounded;

   type OCPP_Version is (V16J, V20x, Unknown);

   type Charger_State_Kind is (Disconnected, Connecting, Connected, Faulted);

   type Charger_Session is record
      Charge_Point_Id : Unbounded_String;
      Version         : OCPP_Version := Unknown;
      State           : Charger_State_Kind := Disconnected;
      Last_Message    : Unbounded_String;
   end record;

   --  DB model/instance definition for charger session persistence.
   subtype Charger_Session_Id is Natural;

   type Session_Status is (Offline, Online, Faulted);

   type Charger_Session_Model is record
      Id                : Charger_Session_Id := 0;
      Charge_Point_Id   : Unbounded_String;
      Ocpp_Version      : Unbounded_String;
      Status            : Session_Status := Offline;
      Last_Action       : Unbounded_String;
      Last_Heartbeat_At : Ada.Calendar.Time := Ada.Calendar.Clock;
      Created_At        : Ada.Calendar.Time := Ada.Calendar.Clock;
      Updated_At        : Ada.Calendar.Time := Ada.Calendar.Clock;
   end record;

   type Charger_Session_Model_Array is array (Positive range <>) of Charger_Session_Model;

   --  Canonical table/column names used by persistence/repository code.
   Table_Name               : constant String := "charger_sessions";
   Column_Id                : constant String := "id";
   Column_Charge_Point_Id   : constant String := "charge_point_id";
   Column_Ocpp_Version      : constant String := "ocpp_version";
   Column_Status            : constant String := "status";
   Column_Last_Action       : constant String := "last_action";
   Column_Last_Heartbeat_At : constant String := "last_heartbeat_at";
   Column_Created_At        : constant String := "created_at";
   Column_Updated_At        : constant String := "updated_at";
end OCPP.Models;
