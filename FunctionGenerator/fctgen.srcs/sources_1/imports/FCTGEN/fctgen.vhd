----------------------------------------------------------------------------------
-- Create Date: 05/17/2019 12:19:48 AM
-- Module Name: fctgen - Behavioral
-- Description: function generator (triangular, sine) 10 KHz
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fctgen is
    Port ( reset : in STD_LOGIC;
           clk : in STD_LOGIC;
           start : in STD_LOGIC;
           spi_csq : out STD_LOGIC;
           spi_sclk : out STD_LOGIC;
           spi_sd0_0 : out STD_LOGIC;
           spi_sd0_1 : out STD_LOGIC;
           aLED : out STD_LOGIC_VECTOR (3 downto 0));
end fctgen;

architecture Behavioral of fctgen is

-- for simulator
CONSTANT CLK_160KHz : integer := 100;
-- for hardware
--CONSTANT CLK_160KHz : integer := 624;

-- for simulator
CONSTANT SPI_10MHz : integer := 1;
-- for hardware
--CONSTANT SPI_10MHz : integer := 4;
CONSTANT ACNT_MAX : integer := 8;
CONSTANT AMIN : integer := 16;
CONSTANT ADELTA : integer := 508;
SUBTYPE Count_type IS integer RANGE 0 to ACNT_MAX;
SIGNAL cnt : Count_type := 0;
SUBTYPE int_f16 IS integer RANGE -32768 to 32767;
SUBTYPE  int_f32 IS integer RANGE -2147483648 to 2147483647;
SIGNAL sig_u_i : int_f16;
SIGNAL down_dir : std_logic := '0';
CONSTANT FIR_ORDER : integer := 9;
CONSTANT FRACTS : integer := 16;
TYPE  c_array IS ARRAY (0 to FIR_ORDER) of int_f16;
CONSTANT fcoef : c_array := (786, 2136, 5820, 10422,
                 13604, 13604, 10422, 5820, 2136, 786);
TYPE  p_array IS ARRAY (1 to FIR_ORDER) of int_f32;
SIGNAL f_sum : int_f32;
SIGNAL prd : p_array;
SIGNAL y_32 : std_logic_vector(31 downto 0);

TYPE State_type IS (idle, st_1, st_2, st_3);
SIGNAL state : State_type := idle;

CONSTANT SPIDAC_NBITS : integer := 16;

COMPONENT spidacms IS
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
END COMPONENT spidacms;

SIGNAL reset_lo : std_logic;
SIGNAL dstart : std_logic;
SIGNAL ddone : std_logic;
SIGNAL spi_clkp : std_logic;
SIGNAL sig_u : std_logic_vector(15 downto 0);
SIGNAL SndData0_i, SndData1_i : std_logic_vector(SPIDAC_NBITS-1 downto 0);

SIGNAL T_Sample : std_logic;

begin

    aLED <= reset_lo & start & start & ddone;
    reset_lo <= NOT reset;

    --Sample time period for 160kHz
    stp_p : PROCESS(clk)
    variable cnt : integer RANGE 0 to CLK_160KHz := CLK_160KHz;
    BEGIN
        IF rising_edge(clk) THEN
             T_Sample<='0';
             IF cnt=0 THEN
                T_Sample<='1';
                cnt:=CLK_160KHz;
             ELSE
                cnt := cnt -1;
             END IF;
        END IF;
    END PROCESS stp_p;
    
    -- 10 MBit/s spi transmission speed
    clkp_gen : PROCESS(clk)
    VARIABLE cnt : integer RANGE 0 to SPI_10MHz := SPI_10MHz;
    BEGIN
        IF rising_edge(clk) THEN
            spi_clkp <= '0';
            IF cnt=0 THEN
                spi_clkp <= '1';
                cnt := SPI_10MHz;
            ELSE
                cnt := cnt - 1;
            END IF;
        END IF;
    END PROCESS clkp_gen;
    
    SndData0_i <= std_logic_vector(to_signed(sig_u_i, SndData0_i'length));
    y_32 <= std_logic_vector(to_signed(f_sum, y_32'length));
    SndData1_i <= y_32(31 downto 16);
    
    sgen_p : PROCESS(clk)
    begin
        IF rising_edge(clk) THEN
            dstart <= '0';
            IF reset = '1' THEN
                state<=idle;
                sig_u_i <= AMIN;
                f_sum <= 0;
                FOR k IN 1 to FIR_ORDER LOOP
                    prd(k) <= 0;
                END LOOP;
            ELSE
                CASE state IS
                    WHEN idle =>
                        IF start='1' THEN
                            state <= st_1;
                        END IF;
                    WHEN st_1 =>
                        --Function Generator
                        IF down_dir = '0' THEN
                            IF cnt = ACNT_MAX - 1 THEN
                                down_dir <= '1';
                            END IF;
                            cnt <= cnt+1;
                        ELSE
                            cnt <= cnt-1;
                            IF cnt = 1 THEN
                                down_dir <= '0';
                            END IF;
                        END IF;
                        sig_u_i <= AMIN + cnt*ADELTA ;
                        --FIR
                        f_sum <= fcoef(0) * sig_u_i + prd(1);
                        FOR n IN 1 to FIR_ORDER -1 LOOP
                            prd(n) <= sig_u_i*fcoef(n) + prd(n+1);
                        END LOOP;
                        prd(FIR_ORDER) <= fcoef(FIR_ORDER) * sig_u_i;
                        state<= st_2;
                    WHEN st_2 =>
                        --Sending to DACs
                        dstart <= '1';
                        IF ddone ='0' THEN
                            state <= st_3;
                        END IF;
                    WHEN st_3 =>
                        --Wait for sample time period
                        IF start='0' THEN
                            state <= idle;
                        ELSIF T_Sample = '1' THEN
                            state <= st_1;
                        END IF;
                END CASE;
            END IF;
        END IF;
    END PROCESS sgen_p;

    reset_lo <= NOT reset;
    
    pmoddac : spidacms
    GENERIC MAP( USPI_SIZE => SPIDAC_NBITS)
    PORT MAP( resetn => reset_lo,
                bclk => clk,
            spi_clkp => spi_clkp,
              dstart => dstart,
               ddone => ddone,
                scsq => spi_csq,
                sclk => spi_sclk,
               sdo_0 => spi_sd0_0,
               sdo_1 => spi_sd0_1,
           sndData_0 => sndData0_i,
           sndData_1 => sndData1_i);
end Behavioral;








