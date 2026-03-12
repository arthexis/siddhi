with Ada.Strings.Unbounded;

package OCPP16_Call_Parser is
   use Ada.Strings.Unbounded;

   type Parse_Result is record
      Is_Valid : Boolean := False;
      Action   : Unbounded_String := To_Unbounded_String ("");
      Error    : Unbounded_String := To_Unbounded_String ("");
   end record;

   function Parse_Action (Frame_JSON : String) return Parse_Result;

end OCPP16_Call_Parser;
