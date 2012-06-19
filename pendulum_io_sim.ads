-- Pendulum_IO_Sim
-- Simulator of the X3 Pendulum
--
--
-- Jorge Real. December 2005

with Low_Level_Types; use Low_Level_Types;
with Ada.Real_Time;   use Ada.Real_Time;

package Pendulum_Io_Sim is

   -- This constant defines the simulated pendulum period.
   -- The actual XP3 period is 114 ms
   -- Keep this constant above 2 seconds
   Oscillation_Period : constant Time_Span := Milliseconds(3000);

   function Get_Sync return Boolean;    -- Returns True if Sync=1; False otherwise
   function Get_Barrier return Boolean; -- Returns True if Barrier=1; False otherwise

   procedure Set_Leds (B : in Byte);    -- Lights LEDs whose position is 1 in B
   procedure Reset_Leds;                -- Blanks LEDs column. Equivalent to Set_Leds(0)

end Pendulum_Io_Sim;
