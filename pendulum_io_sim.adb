-- Pendulum_IO_Sim
-- Simulator of the X3 Pendulum
--
--
-- Jorge Real. November 2009
--    The simulator now uses a Win_IO Graphics_Windows canvas
-- Jorge Real. December 2005
--    Initial text-based version

pragma Task_Dispatching_Policy (Fifo_Within_Priorities);
pragma Locking_Policy (Ceiling_Locking);

with System;           use System;
with Graphics_Windows; use Graphics_Windows;


package body Pendulum_Io_Sim is

   protected type Boolean_Signal (Ceiling : Priority) is
      pragma Priority(Ceiling);
      procedure Set;
      procedure Reset;
      function Value return Boolean;
   private
      The_Value : Boolean := True;
   end Boolean_Signal;

   protected body Boolean_Signal is
      procedure Set is
      begin
         The_Value := True;
      end Set;
      procedure Reset is
      begin
         The_Value := False;
      end Reset;
      function Value return Boolean is
      begin
         return The_Value;
      end Value;
   end Boolean_Signal;

   Barrier, Sync : Boolean_Signal(Priority'Last); -- To model the corresponding signals

   Text_Lines  : constant Integer := 72;
   Blank_Lines : constant Integer := 10;
   Lines       : constant Integer := Text_Lines + (2 * Blank_Lines);
   type Position_Type is mod Lines;              -- Position of the pendulum
   type Period_Position_Type is mod (2 * Lines); -- Position of pendulum in the whole period

   protected Position is             -- To track the pendulum's current position
      pragma Priority (Priority'Last);
      procedure Set (P : in Position_Type);  -- To set a particular position
      procedure Advance;                     -- To advance the position by one line
      entry Wait_Next_Change (P : out Position_Type);  -- To wait for a position change
      function Get_Period_Position return Period_Position_Type; -- Position in a full period (2*Lines)
   private
      Pos : Position_Type := 0;
      Period_Pos : Period_Position_Type := 0;
      New_Pos : Boolean := False;
   end Position;

   protected body Position is
      procedure Set (P : in Position_Type) is
      begin
         Pos := P;
      end Set;
      procedure Advance is
      begin
         Period_Pos := Period_Pos + 1;
         if Integer(Period_Pos) < Lines then
            Pos := Position_Type(Period_Pos);
         else
            Pos := Position_Type((2 * Lines) - 1 - Integer(Period_Pos));
         end if;
         New_Pos := True;
      end Advance;
      entry Wait_Next_Change (P : out Position_Type) when New_Pos is
      begin
         P := Pos;
         New_Pos := False;
      end Wait_Next_Change;
      function Get_Period_Position return Period_Position_Type is
      begin
         return Period_Pos;
      end Get_Period_Position;
   end Position;

   task Signals_And_Position_Simulator is
      pragma Priority(Priority'Last);
      entry Start;
   end Signals_And_Position_Simulator;

   task body Signals_And_Position_Simulator is
      --   Simulation of signals Barrier and Sync
      --   and simulation of the pendulum's position
      --
      -- Barrier   _                      _
      --          | |                    | |
      --         _| |____________________| |_   a @  5 % of cycle
      --   Sync    _                            b @ 10 %
      --          | |                           c @ 90 %
      --         _| |_________________________  d @ 95 %
      --          ^ ^                    ^ ^
      --          a b                    c d

      Delta_Time : Time_Span := Oscillation_Period / (2 * Lines);
      Next       : Time;

   begin
      accept Start;
      Barrier.Reset;
      Sync.Reset;
      Position.Set(0);
      Next := Clock;
      loop
         Position.Advance;
         case Position.Get_Period_Position is
            when Period_Position_Type((2*Lines*5)/100)  => Barrier.Set;   Sync.Set;
            when Period_Position_Type((2*Lines*10)/100) => Barrier.Reset; Sync.Reset;
            when Period_Position_Type((2*Lines*90)/100) => Barrier.Set;
            when Period_Position_Type((2*Lines*95)/100) => Barrier.Reset;
            when others => null;
         end case;
         Next := Next + Delta_Time;
         delay until Next;
      end loop;
   end Signals_And_Position_Simulator;

   --------------
   -- Get_Sync --
   --------------
   function Get_Sync return Boolean is
   begin
      return Sync.Value;
   end Get_Sync;

   -----------------
   -- Get_Barrier --
   -----------------
   function Get_Barrier return Boolean is
   begin
      return Barrier.Value;
   end Get_Barrier;


   --------------------------------------------
   -- Draw functions and needed declarations --
   --------------------------------------------

   Pendulum_Canvas : Canvas_Type;
   LED_Radius      : constant Integer := 3;
   Line_Separation : constant Integer := 1;
   LED_Separation  : constant Integer := 2;
   -- Coordinates for drawing the left and right limits on the canvas
   Left_From  : Point_Type := (X => Line_Separation + Blank_Lines*(2*LED_Radius + Line_Separation),
                               Y => 0);
   Left_To    : Point_Type := (X => Line_Separation + Blank_Lines*(2*LED_Radius + Line_Separation),
                               Y => LED_Separation + 8*(2*LED_Radius + LED_Separation));
   Right_From : Point_Type := (X => (Blank_Lines + Text_Lines)*(2*LED_Radius + Line_Separation),
                               Y => 0);
   Right_To   : Point_Type := (X => (Blank_Lines + Text_Lines)*(2*LED_Radius + Line_Separation),
                               Y => LED_Separation + 8*(2 * LED_Radius + LED_Separation));

   ------------------
   -- Clear_Canvas --
   ------------------
   procedure Clear_Canvas is
   begin
      Set_Colour (Pendulum_Canvas,White);
      Set_Fill (Pendulum_Canvas,White);
      Erase (Pendulum_Canvas);
      Set_Pen(Pendulum_Canvas,Black);
      Draw_Line(Pendulum_Canvas,Right_From,Right_To);
      Draw_Line(Pendulum_Canvas,Left_From,Left_To);
      Draw (Pendulum_Canvas);
      Set_Pen (Pendulum_Canvas,Red);
      Set_Fill (Pendulum_Canvas,Red);
      Set_Fill (Pendulum_Canvas,True);
   end Clear_Canvas;

   ----------
   -- Draw --
   ----------
   procedure Draw (B : in Byte; P : in Position_Type) is
      Center : Point_Type;
   begin
      for I in 0..7 loop
         if ((B and (2**I)) /= 0) then -- If LED I is set draw a red circle
            Center.X := (Line_Separation + LED_Radius) + (Integer(P) * (Line_Separation + 2*LED_Radius));
            Center.Y := LED_Separation + LED_Radius + (I * (LED_Separation + 2*LED_Radius));
            Draw_Circle (Pendulum_Canvas, Center, LED_Radius);
         end if;
      end loop;
      -- Clear canvas at both ends of the pendulum run
      if (P = Position_Type'First) or (P = Position_Type'Last) then
         Clear_Canvas;
      end if;
      Draw (Pendulum_Canvas);
   end Draw;


  protected Leds is
     pragma Priority (Priority'Last);
     procedure Set (B : in Byte);
     procedure Reset;
     function Get return Byte;
  private
     The_Leds : Byte := 0;
  end Leds;

  protected body Leds is
     procedure Set (B: in Byte) is
     begin
        The_Leds := B;
     end Set;
     procedure Reset is
     begin
        The_Leds := 0;
     end Reset;
     function Get return Byte is
     begin
        return The_Leds;
     end Get;
  end Leds;


   task Leds_Simulator is
      pragma Priority(Priority'Last);
      entry Start;
   end Leds_Simulator;


   -- Draws the LEDs when there is a position change
   task body Leds_Simulator is
      Current_Position : Position_Type;
   begin
      accept Start;
      loop
         Position.Wait_Next_Change(Current_Position);
         Draw(Leds.Get,Current_Position);
      end loop;
   end Leds_Simulator;


   ----------------
   -- Reset_Leds --
   ----------------
   procedure Reset_Leds is
   begin
      Leds.Reset;
   end Reset_Leds;

   --------------
   -- Set_Leds --
   --------------
   procedure Set_Leds (B : in Byte) is
   begin
      Leds.Set(B);
   end Set_Leds;


   -- Initialisation: draw canvas and start simulator tasks
begin
   Pendulum_Canvas := Canvas (Width => Lines * (2*LED_Radius + Line_Separation) + 2*Line_Separation,
                              Height => 8 * (2*LED_Radius + LED_Separation) + LED_Separation,
                              Title => "Pendulum simulation");
   Clear_Canvas;
   Signals_And_Position_Simulator.Start;
   Leds_Simulator.Start;
end Pendulum_Io_Sim;

