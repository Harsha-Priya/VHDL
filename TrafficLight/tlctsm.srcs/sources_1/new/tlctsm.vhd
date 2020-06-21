----------------------------------------------------------------------------------
-- Create Date: 05/15/2019 11:50:57 AM
-- Module Name: tlctsm - Behavioral
-- Description: Traffic light controller as timed state machine
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tlctsm is
    Port ( treset : in STD_LOGIC;
           tstart : in STD_LOGIC;
           tclk : in STD_LOGIC;
           red3 : out STD_LOGIC;
           red2 : out STD_LOGIC;
           red1 : out STD_LOGIC;
           green3 : out STD_LOGIC;
           green2 : out STD_LOGIC;
           green1 : out STD_LOGIC);
end tlctsm;

architecture Behavioral of tlctsm is

CONSTANT MAX_TIMERV : integer := 7;
SUBTYPE Counter_type IS integer RANGE 0 to MAX_TIMERV;
TYPE State_type IS (idle, st_red, st_ry, st_green, st_yel);
SIGNAL state, next_state : State_type;
SIGNAL timerval : Counter_type;
SIGNAL red, yellow, green: STD_LOGIC;

--For simulator
CONSTANT MAXCOUNT : integer := 3;
--For hardware test
--CONSTANT MAXCOUNT : integer := 24999999;
SIGNAL pulse_250ms : std_logic;

begin

    clk_dev : PROCESS(tclk)
    VARIABLE k : integer RANGE 0 to MAXCOUNT := MAXCOUNT;
    BEGIN
        IF rising_edge(tclk) THEN
            pulse_250ms <= '0';
            IF k=0 THEN
                pulse_250ms <= '1';
                k := MAXCOUNT;                
            ELSE
                k := k-1;
            END IF;
        END IF;
    END PROCESS clk_dev;
    
    red3   <= red;
    green3 <= '0';
    red2   <= yellow;
    green2 <= yellow;
    red1   <= '0';
    green1 <= green;
    
    seq_tsm : PROCESS(treset, tclk, timerval, next_state, pulse_250ms)
    VARIABLE cnt : Counter_type; 
    BEGIN
        IF rising_edge(tclk) THEN
            IF treset='1' THEN
                state <= idle;
                cnt := 0;
            ELSIF pulse_250ms = '1' THEN
                IF cnt = timerval THEN
                    state <= next_state;
                cnt := 0;
                ELSE
                    cnt := cnt+1;
                END IF;
            ELSE
            END IF;
        END IF;
    END PROCESS seq_tsm;
    
    comb_tsm : PROCESS(state, tstart)
    BEGIN
        next_state <= state;
        red <= '0'; yellow <= '0'; green <= '0';
        timerval <= 1;
        CASE state IS
            WHEN idle =>
                timerval <= 0;
                IF tstart = '1' THEN
                    next_state <= st_red;
                END IF;
            WHEN st_red=> 
                timerval <= 4;
                red <= '1';
                next_state <= st_ry;
            WHEN st_ry=>
                red <= '1';
                yellow <= '1';
                next_state <= st_green;
            WHEN st_green=>
                timerval <= 5;
                green <= '1';
                next_state <= st_yel;
            WHEN st_yel=>
                yellow <= '1';
                IF tstart = '1'THEN
                    next_state <= st_red;
                ELSE
                    next_state <= idle;
                END IF;
         END CASE;   
    END PROCESS comb_tsm;
    


end Behavioral;
