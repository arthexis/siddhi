package OCPP16_Dispatcher is

   procedure Handle_Action
     (Charge_Point_Id : String;
      Action          : String;
      Frame_JSON      : String);

end OCPP16_Dispatcher;
