with Ada.Text_IO; use Ada.Text_IO;
with OCPP_Router;
with Web_Server;

procedure Main is
begin
   Put_Line ("OCPP CSMS Ada starter");
   Put_Line ("Starting Ada HTTPS server for dashboard and state API...");

   --  Seed demo state for initial dashboard preview.
   OCPP_Router.Handle_Inbound_Frame
     (Charge_Point_Id => "demo-cp-001",
      Path            => "/ocpp/1.6/demo-cp-001",
      Frame_JSON      => "BootNotification accepted");

   Web_Server.Run;
end Main;
