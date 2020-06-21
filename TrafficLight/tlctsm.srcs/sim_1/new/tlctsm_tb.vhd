----------------------------------------------------------------------------------
-- Create Date: 05/15/2019 12:14:57 PM
-- Module Name: tlctsm_tb - Behavioral
-- Description: Traffic light controller test bench
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tlctsm_tb is
end tlctsm_tb;

architecture Behavioral of tlctsm_tb is
COMPONENT tlctsm is
    Port ( treset : in STD_LOGIC;
           tstart : in STD_LOGIC;
           tclk : in STD_LOGIC;
           red3 : out STD_LOGIC;
           red2 : out STD_LOGIC;
           red1 : out STD_LOGIC;
           green3 : out STD_LOGIC;
           green2 : out STD_LOGIC;
           green1 : out STD_LOGIC);
end component;

SIGNAL treset :  STD_LOGIC := '0';
SIGNAL tstart :  STD_LOGIC:= '0';
SIGNAL tclk :  STD_LOGIC:= '0';
SIGNAL red3 :  STD_LOGIC:= '0';
SIGNAL red2 :  STD_LOGIC:= '0';
SIGNAL red1 :  STD_LOGIC:= '0';
SIGNAL green3 :  STD_LOGIC:= '0';
SIGNAL green2 :  STD_LOGIC:= '0';
SIGNAL green1 :  STD_LOGIC:= '0';
  
  CONSTANT clk_period : time := 10 ns;
  
begin

    uut : tlctsm
    Port map( treset =>treset,
               tstart =>tstart,
               tclk =>tclk,
               red3 =>red3,
               red2 =>red2,
               red1 =>red1,
               green3 =>green3,
               green2 =>green2,
               green1 =>green1);
               
               clk_p : PROCESS
               BEGIN
                tclk <= '0';
                wait for clk_period/2;
                tclk <= '1';
                wait for clk_period/2;
               END PROCESS clk_p;
               
               stim_p : PROCESS
               BEGIN
                wait for clk_period;
                treset <= '1';
                wait for clk_period;
                treset <= '0';
                wait for clk_period;
                tstart <= '1';
                wait for clk_period*8;
                tstart <= '0';
                wait;
              END PROCESS stim_p;


end Behavioral;
