pragma Task_Dispatching_Policy (Fifo_Within_Priorities);
pragma Locking_Policy (Ceiling_Locking);


with Ada.Real_Time; use Ada.Real_Time;
with Gnat.IO;       use Gnat.IO;
with Low_Level_Types; use Low_Level_Types;
with System;           use System;
with pendulum_io_sim; use pendulum_io_sim;
with chars_8x5;	      use chars_8x5;
with Generic_Circular_Buffer;
procedure Pendulo is

   t_Barrier, t_Barrier_Ant : Ada.Real_Time.Time;
   type buffer_Byte is array (1 .. 72) of Byte;
   Cadena : buffer_Byte;
   Total, Periodo_Total, P1, P2, B1, B2 : Ada.Real_Time.Time_Span := Milliseconds(3000);
   Inicio    : Ada.Real_Time.Time;
   n, n1       : Integer := 0;
   cad : String := "HOLA MUNDO!";
   Char : Character;

   procedure Barrier (tiempo : out Ada.Real_Time.Time) is
      b : Boolean;
   begin
      -- obtnemos el valor booleano actual de la se–al Barrier 
      b := Get_Barrier;

      -- esperamos a que cambie de valor la se–al Barrier
      while Get_Barrier = b loop
         delay 0.001;
      end loop;
      -- devolvemos el tiempo cuando cambia la se–al 
      tiempo := Ada.Real_Time.Clock;

   end Barrier;

   procedure Sync is
   begin
       -- esperamos a que la se–al Sync este a nivel bajo
       while Get_Sync = true loop
         delay 0.001;
       end loop;
    
      -- esperamos a que la se–al Sync cambie a nivel alto
      while Get_Sync /= true loop
         delay 0.001;
      end loop;

   end Sync;



   procedure Esperar is
      Next : Ada.Real_Time.Time;
   begin

      Next := Ada.Real_Time.Clock;
      Next := Next + ((B2+B1+P2)/2) + Total;
      delay until Next;

   end Esperar;

   task calcular_tiempo is

      Ð- le asignamos la prioridad que debe ser menor a la utilizada                   
      Ð-  por el pendulo simulado 
      pragma Priority (System.Priority'Last-1);
   end calcular_tiempo;

   task body calcular_tiempo is
   begin

      loop

      -- Utilizamos el procedimiento Sync para empezar a calcular el       
      -- periodo siempre desde el mismo sitio, en este caso lo
      -- empezamos a calcular siempre en el subperiodo m‡s largo
         Sync;


      -- Primer Flanco Bajada
      -- Primer Flanco Bajada
      -- Como nos hemos esperado a que la se–al Sync este a nivel
      -- alto, tambiŽn los estar‡ la se–al Barrier. Esperamos a que
      -- la se–al Barrier este a nivel bajo y devolvemos el tiempo 
      -- en ese instante

      Barrier(t_Barrier_Ant);
      -- Como antes, volvemos a esperar que la se–al Barrier cambie
      -- de valor esta vez esperaremos que cambie de de nivel bajo a
      -- alto y nos devolver‡ el tiempo de ese instante.
      Barrier(t_Barrier);
      P1 := t_Barrier - t_Barrier_Ant;

      Put_Line("1 : " & Duration'Image(To_Duration(P1)));

         -- Segundo Flanco Subida
      -- DespuŽs de obtener el subperiodo largo, viene la primera 
      -- activaci—n de la se–al de Barrier y haremos como antes, con 
      -- el valor obtenido en t_Barrier y t_Barrier_Ant, obtenemos el 
      -- valor del escal—n
      Barrier(t_Barrier_Ant);
      B1 := t_Barrier_Ant - t_Barrier;
      Put_Line("2 : " & Duration'Image(To_Duration(B1)));

      -- Este instante, es cuando se ha obtenido el escal—n, el cual
      -- que coincide con el movimiento de vuelta del pŽndulo. Es 
      -- justamente el momento en que la se–al Sync esta a nivel bajo 
      -- y Barrier activa. 
      -- Lo que vamos ha hacer es guardar cuando ser‡ la pr—xima vez
      -- que suceda esto con la variable inicio y sum‡ndole el
      -- periodo total que es la suma de todos los tramos del
      -- periodo, inicialmente cuando todav’a no se han calculado los
      -- tramos vale 3 segundos

         Inicio := Ada.Real_Time.Clock;
         Inicio := Inicio + Periodo_Total;
         n := 1;
      -- Tercer Flanco Bajada
      -- DespuŽs de obtener el primer escal—n, viene el subperiodo
      -- corto y volvemos ha hacer como antes, con 
      -- el valor obtenido en t_Barrier y t_Barrier_Ant, obtenemos el 
      -- valor del subperiodo m‡s corto
      Barrier(t_Barrier);
      P2 := t_Barrier - t_Barrier_Ant;
      Put_Line("3 : " & Duration'Image(To_Duration(P2)));

      -- Cuarto Flanco Subida
      -- Finalmente obtenemos el segundo escal—n, que va despuŽs el
      -- subperiodo corto y as’ completamos el periodo.
      Barrier(t_Barrier_Ant);

      B2 := t_Barrier_Ant - t_Barrier;
      Put_Line("4 : " &  Duration'Image(To_Duration(B2)));

      -- Obtenemos el periodo total que es la suma de los 4 tramos
      Periodo_Total := P1 + P2 + B1 + B2;

-- Calculamos la fracci—n de tiempo necesaria, para saber en que
-- momento debemos encender los LEDs para formar las letras. 

-- Para ello, primero obtenemos las lineas necesarias en cada periodo.
-- Como el pŽndulo no va siempre a la misma velocidad, debemos dejar
-- 10 lineas a cada lado antes de encender los LEDs y como m‡ximo se
-- pueden visualizar hasta 12 letras y cada letra se representa con 5
-- lineas, teniendo en cuenta las 10 l’neas y que cada letra debe
-- tener una l’nea de separaci—n, sabemos que necesitamos solo para
-- la ida del pŽndulo 10+10+12*5+12 = 92. Como hace un movimiento de
-- ida y vuelta finalmente tenemos 92 * 2 = 184 lineas;
      Total := Periodo_Total/((10+10+72)*2);

      end loop;

   end calcular_tiempo;

   task pendul is
        -- le asignamos la prioridad que debe ser menor a la utilizada          	--  por el pendulo simulado 
      pragma Priority (System.Priority'Last-1);
   end pendul;

   task body pendul is
      Periodo, Sig : Ada.Real_Time.Time_Span;
      cont : Integer := 0;
      Ini, Siguiente, Mitad : Ada.Real_Time.Time;
   begin

      loop

         if n > 0 then
          -- La variable inicio la hemos calculado previamente en la  
          -- tarea calcular_tiempo, la cual nos indica que el pŽndulo 
          -- esta de  vuelta y el periodo se repite. 
          -- Sabemos que se empieza a escribir en el extremo de 
          -- la izquierda del r—tulo oscilante, por lo tanto una vez
          -- pasado el tiempo de la variable inicio debemos volver a
          -- esperar para que el pŽndulo este en la posici—n de
          -- inicio, cuya espera correspondo a la mitad del
          -- subperiodo corto. La cual se calcula con el
          -- procedimiento ÒEsperaÓ.
            Ini := Inicio;
            delay until Ini;
            Esperar;

            Periodo := Periodo_Total;
            Sig := Total;

            Mitad := Ada.Real_Time.Clock;
	    Mitad := (Mitad + (Periodo/2)) - 2*Sig;
           -- Una vez ya estamos en e inicio empezamos ha encender los LEDs
            for I in  0 .. 71 loop

               Siguiente := Ada.Real_Time.Clock;
               Siguiente := Siguiente + Sig;
               delay until Siguiente;
               Set_Leds(cadena(I+1));

            end loop;

            Reset_Leds;

-- Una vez terminamos de encender las 72 lineas de LEDs, debemos
-- esperar a para dibujar los LEDs a la vuelta, esto la hacemos con
-- la variable Mitad, que la hemos calculado anteeriormente.

            delay until Mitad;

            for I in  0 .. 71 loop

               Set_Leds(cadena(72-(I)));
               Siguiente := Ada.Real_Time.Clock;
               Siguiente := Siguiente +Sig;
               delay until Siguiente;

            end loop;

            Reset_Leds;

         end if;

      end loop;

   end pendul;

   k : Integer := 1;
begin
   Put_Line("Inicio.");
   cadena := (others => 0);
   for I in  0 .. cad'Length-1 loop
      Char := cad(I+1);
      for J in 0 .. 4 loop
         cadena(k) := Char_Map(Char, J);
         k := k +1;
      end loop;

         cadena(k) := 0;
         k := k +1;

   end loop;



end Pendulo;
