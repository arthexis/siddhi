package OCPP16.Dispatcher is

   procedure Handle_Action
     (Charge_Point_Id : String;
      Action          : String;
      Frame_JSON      : String);

end OCPP16.Dispatcher;
