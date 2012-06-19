with Interfaces;  use Interfaces;

package Low_Level_Types is

   type Word is new Unsigned_16;
   type Byte is new Unsigned_8;

   function High_Byte (Value : in Word) return Byte;
   function Low_Byte  (Value : in Word) return Byte;

   function Make_Word (High_Byte : in Byte;
                       Low_Byte  : in Byte) return Word;

end Low_Level_Types;
