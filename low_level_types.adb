--with Interfaces;  use Interfaces;

package body Low_Level_Types is

   function High_Byte (Value : in Word) return Byte is
   begin
      return Byte(Shift_Right(Value,8));
   end High_Byte;

   function Low_Byte (Value : in Word) return Byte is
   begin
      return High_Byte(Rotate_Left(Value,8));
   end Low_Byte;

   function Make_Word (High_Byte : in Byte;
                       Low_Byte  : in Byte) return Word is
      Low,
      High : Word;

   begin
      Low:=Word(Low_Byte);
      High:=Shift_Left(Word(High_Byte),8);
      return(Low+High);
   end Make_Word;

end Low_Level_Types;
