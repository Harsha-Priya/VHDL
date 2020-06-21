----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- Create Date: 05/29/2019 02:40:50 PM
-- Design Name: 
-- Module Name: spidacms - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: spi master for dac(16 bit)
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


ENTITY spidacms IS
    GENERIC ( USPI_SIZE : INTEGER := 16 );
    PORT ( resetn : in STD_LOGIC;
           bclk : in STD_LOGIC;
           spi_clkp : in STD_LOGIC;
           dstart : in STD_LOGIC;
           ddone : out STD_LOGIC;
           scsq : out STD_LOGIC;
           sclk : out STD_LOGIC;
           sdo_0 : out STD_LOGIC;
           sdo_1 : out STD_LOGIC;
           sndData_0 : in STD_LOGIC_VECTOR (USPI_SIZE-1 downto 0);
           sndData_1 : in STD_LOGIC_VECTOR (USPI_SIZE-1 downto 0) );
END spidacms;



architecture Behavioral of spidacms is

TYPE State_type IS (sidle, sstartx, start_lo, sclk_hi, sclk_lo,
                    stop_hi, stop_lo );
SIGNAL state, next_state :  State_type;
SIGNAL scsq_i, sclk_i, sdo0_i, sdo1_i : std_logic;
SIGNAL wr_buf0, wr_buf1 : STD_LOGIC_VECTOR (USPI_SIZE-1 downto 0);

SUBTYPE Count_type IS integer RANGE 0 to USPI_SIZE-1;
SIGNAL count : Count_type;

begin
    
    seq_p :PROCESS(bclk, resetn, next_state, scsq_i, sclk_i, sdo0_i, sdo1_i, count)
    BEGIN
        IF rising_edge(bclk) THEN
            IF resetn = '0' THEN
                state <= sidle;
            elsif spi_clkp='1' then                                
                IF next_state = sstartx THEN
                    count  <= USPI_SIZE-1;
                    wr_buf0 <= sndData_0;
                    wr_buf1 <= sndData_1;
                ELSIF next_state = sclk_hi THEN
                    count <= count -1;
                ELSIF next_state = sclk_lo THEN
                    wr_buf0 <= wr_buf0(USPI_SIZE-2 downto 0) & '-';
                    wr_buf1 <= wr_buf1(USPI_SIZE-2 downto 0) & '-';
                ELSE                    
                END IF;
                
                state <= next_state;
                scsq <= scsq_i;
                sclk <= sclk_i;
                sdo_0 <= sdo0_i;
                sdo_1 <= sdo1_i;
            END IF;
        END IF;
    END PROCESS seq_p;
    
    cmb_p :PROCESS(state, dstart, wr_buf0, wr_buf1,count)
    BEGIN
        next_state <= state;
        scsq_i  <= '0';
        sclk_i  <= '0';
        sdo0_i   <= '0';
        sdo1_i   <= '0';
        ddone    <= '0';
        
        CASE state IS
            WHEN sidle =>
                ddone   <= '1';
                scsq_i <= '1';
                IF dstart = '1' THEN
                    next_state <= sstartx;
                END IF;
            WHEN sstartx =>
                next_state <= start_lo;
            WHEN start_lo =>
                next_state <= sclk_hi;
                sclk_i <= '1';
                sdo0_i <= wr_buf0(USPI_SIZE-1);
                sdo1_i <= wr_buf1(USPI_SIZE-1);
            WHEN sclk_hi =>
                next_state <= sclk_lo;
                sdo0_i <= wr_buf0(USPI_SIZE-1);
                sdo1_i <= wr_buf1(USPI_SIZE-1);
            WHEN sclk_lo =>
                IF count = 0 THEN
                    next_state <= stop_hi;
                ELSE
                    next_state <= sclk_hi;
                END IF;
                sclk_i <= '1';
                sdo0_i <= wr_buf0(USPI_SIZE-1);
                sdo1_i <= wr_buf1(USPI_SIZE-1);
            WHEN stop_hi =>
                next_state <= stop_lo;
                sdo0_i <= wr_buf0(USPI_SIZE-1);
                sdo1_i <= wr_buf1(USPI_SIZE-1);
            WHEN stop_lo =>
                next_state <= sidle;
                scsq_i <= '1';
        END CASE;
        
    END PROCESS cmb_p;

end Behavioral;