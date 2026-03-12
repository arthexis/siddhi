with Ada.Text_IO;         use Ada.Text_IO;
with Connection_Registry;
with OCPP_Router;

procedure Main is
begin
   Put_Line ("OCPP CSMS Ada starter");
   Put_Line ("TODO: wire HTTP + WebSocket endpoints for /ocpp/1.6 and /ocpp/2.0.1");

   --  Seed demo state for initial dashboard preview.
   OCPP_Router.Handle_Inbound_Frame
     (Charge_Point_Id => "demo-cp-001",
      Path            => "/ocpp/1.6/demo-cp-001",
      Frame_JSON      => "BootNotification accepted");

   Put_Line ("Dashboard static assets available in ./web");
end Main;
