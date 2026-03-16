with Ada.Text_IO; use Ada.Text_IO;
with OCPP_Router;
with Web_Server;

procedure CSMS_Web_Server is
begin
   Put_Line ("OCPP CSMS Ada starter");
   Put_Line ("Starting Ada HTTPS server for dashboard and state API...");

   --  Seed demo state for initial dashboard preview.
   OCPP_Router.Handle_Inbound_Frame
     (Charge_Point_Id => "demo-cp-001",
      Path            => "/ocpp/1.6/demo-cp-001",
      Frame_JSON      => "[2,""startup-001"",""BootNotification"",{""chargePointVendor"":""Demo"",""chargePointModel"":""Starter""}]");

   Web_Server.Run;
end CSMS_Web_Server;
