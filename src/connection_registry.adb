with Ada.Strings.Unbounded;
with OCPP.Models;

package body Connection_Registry is
   use Ada.Strings.Unbounded;
   use OCPP.Models;

   Max_Chargers : constant Positive := 128;

   protected Store is
      procedure Upsert
        (Charge_Point_Id : String;
         Version         : OCPP_Version;
         State           : Charger_State_Kind;
         Last_Message    : String := "");
      function Snapshot return Charger_State_Array;
   private
      Count : Natural := 0;
      Data  : array (Positive range 1 .. Max_Chargers) of Charger_State_View :=
        (others =>
           (Charge_Point_Id => To_Unbounded_String (""),
            Version         => Unknown,
            State           => Disconnected,
            Last_Message    => To_Unbounded_String ("")));
   end Store;

   protected body Store is
      procedure Upsert
        (Charge_Point_Id : String;
         Version         : OCPP_Version;
         State           : Charger_State_Kind;
         Last_Message    : String := "") is
      begin
         for I in 1 .. Count loop
            if To_String (Data (I).Charge_Point_Id) = Charge_Point_Id then
               Data (I).Version      := Version;
               Data (I).State        := State;
               Data (I).Last_Message := To_Unbounded_String (Last_Message);
               return;
            end if;
         end loop;

         if Count < Max_Chargers then
            Count := Count + 1;
            Data (Count) :=
              (Charge_Point_Id => To_Unbounded_String (Charge_Point_Id),
               Version         => Version,
               State           => State,
               Last_Message    => To_Unbounded_String (Last_Message));
         end if;
      end Upsert;

      function Snapshot return Charger_State_Array is
      begin
         if Count = 0 then
            return (1 .. 0 =>
                      (Charge_Point_Id => To_Unbounded_String (""),
                       Version         => Unknown,
                       State           => Disconnected,
                       Last_Message    => To_Unbounded_String ("")));
         end if;

         return Data (1 .. Count);
      end Snapshot;
   end Store;

   procedure Upsert
     (Charge_Point_Id : String;
      Version         : OCPP_Version;
      State           : Charger_State_Kind;
      Last_Message    : String := "") is
   begin
      Store.Upsert (Charge_Point_Id, Version, State, Last_Message);
   end Upsert;

   function Snapshot return Charger_State_Array is
   begin
      return Store.Snapshot;
   end Snapshot;

end Connection_Registry;
