----------------------------------------------------------------------------------
-- Create Date: 05/29/2019 11:58:42 AM
-- Module Name: fctgen_tb - Behavioral
-- Description: fctgen testbench
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fctgen_tb is
end fctgen_tb;

architecture Behavioral of fctgen_tb is

COMPONENT fctgen is
    Port ( reset : in STD_LOGIC;
           clk : in STD_LOGIC;
           start : in STD_LOGIC;
           spi_csq : out STD_LOGIC;
           spi_sclk : out STD_LOGIC;
           spi_sd0_0 : out STD_LOGIC;
           spi_sd0_1 : out STD_LOGIC;
           aLED : out STD_LOGIC_VECTOR (3 downto 0));
END COMPONENT fctgen;

SIGNAL reset :  STD_LOGIC := '0';
SIGNAL clk :  STD_LOGIC:= '0';
SIGNAL start :  STD_LOGIC:= '0';
SIGNAL spi_csq :  STD_LOGIC:= '0';
SIGNAL spi_sclk :  STD_LOGIC:= '0';
SIGNAL spi_sd0_0 :  STD_LOGIC:= '0';
SIGNAL  spi_sd0_1 :  STD_LOGIC:= '0';
SIGNAL  aLED : STD_LOGIC_VECTOR(3 DOWNTO 0) := x"0";

CONSTANT clk_period :time := 10ns;

begin

    uut : fctgen
    PORT MAP ( reset =>reset,
           clk  =>clk,
           start  => start,
           spi_csq => spi_csq,
           spi_sclk  => spi_sclk,
           spi_sd0_0  => spi_sd0_0,
           spi_sd0_1  =>spi_sd0_1,
           aLED  =>aLED);


    clk_p : PROCESS
    BEGIN
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    END PROCESS clk_p;
    
    stim_p : PROCESS
    BEGIN
        wait for clk_period;
        reset <= '1';
        wait for clk_period;
        reset <= '0';
        wait for clk_period;
        start <= '1';
        wait;
    END PROCESS stim_p;
end Behavioral;
