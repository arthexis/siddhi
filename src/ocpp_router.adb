with Ada.Strings.Fixed;
with Connection_Registry;

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
      Version : constant OCPP_Version := Detect_Version (Path);
   begin
      --  TODO: Replace with real parser/dispatcher once websocket endpoint is in place.
      Connection_Registry.Upsert
        (Charge_Point_Id => Charge_Point_Id,
         Version         => Version,
         State           => Connected,
         Last_Message    => Frame_JSON);
   end Handle_Inbound_Frame;

end OCPP_Router;
