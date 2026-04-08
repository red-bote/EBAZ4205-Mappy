---------------------------------------------------------------------------------
--                          Mappy - EBAZ4205
--                          Code from Mister-X
--
--                         Modified for EBAZ4205 
--                            by pinballwiz.org 
--                               03/03/2026
---------------------------------------------------------------------------------
-- Keyboard inputs :
--   5 : Add coin
--   2 : Start 2 players
--   1 : Start 1 player
--   LEFT Ctrl   : Pump
--   X           : Drill
--   RIGHT arrow : Move Right
--   LEFT arrow  : Move Left
--   UP arrow    : Move Up
--   DOWN arrow  : Move Down
--
-- Joystick Enable :
--  dip1 = off
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
---------------------------------------------------------------------------------
entity druaga_ebaz4205 is
port(
	clock_50    : in std_logic;
   	I_RESET     : in std_logic;
	O_VIDEO_R	: out std_logic_vector(2 downto 0); 
	O_VIDEO_G	: out std_logic_vector(2 downto 0);
	O_VIDEO_B	: out std_logic_vector(1 downto 0);
	O_HSYNC		: out std_logic;
	O_VSYNC		: out std_logic;
	O_AUDIO_L 	: out std_logic;
	O_AUDIO_R 	: out std_logic;
	greenLED 	: out std_logic;
	redLED 	    : out std_logic;
   	ps2_clk     : in std_logic;
	ps2_dat     : inout std_logic;
	joy         : in std_logic_vector(8 downto 0);
	dipsw       : in std_logic_vector(4 downto 0);
	led         : out std_logic_vector(7 downto 0)
);
end druaga_ebaz4205;
------------------------------------------------------------------------------
architecture struct of druaga_ebaz4205 is
 
 signal clock_12 : std_logic;
 signal clock_24 : std_logic;
 signal clock_48 : std_logic;
 signal clock_9  : std_logic;
 signal clock_6  : std_logic;
 signal	pll_lock : std_logic;
 --
 signal PCLK     : std_logic;
 signal HPOS     : std_logic_vector(8 downto 0);
 signal VPOS     : std_logic_vector(8 downto 0);
 signal oPIX     : std_logic_vector(7 downto 0);
 --
 signal video_r  : std_logic_vector(5 downto 0);
 signal video_g  : std_logic_vector(5 downto 0);
 signal video_b  : std_logic_vector(5 downto 0);
 --
 signal oRGB     : std_logic_vector(11 downto 0);
 --
 signal M_HSYNC  : std_logic;
 signal M_VSYNC	 : std_logic;
 --
 signal h_blank  : std_logic;
 signal v_blank	 : std_logic;
 --
 signal video_r_x2  : std_logic_vector(5 downto 0);
 signal video_g_x2  : std_logic_vector(5 downto 0);
 signal video_b_x2  : std_logic_vector(5 downto 0);
 signal hsync_x2    : std_logic;
 signal vsync_x2    : std_logic;
 --
 signal oSND        : std_logic_vector(7 downto 0);
 signal audio_pwm   : std_logic;
 --
 signal INP0        : std_logic_vector(5 downto 0);
 signal INP1        : std_logic_vector(5 downto 0);
 signal INP2        : std_logic_vector(2 downto 0);
 --
 signal reset           : std_logic;
 signal cpu_reset       : std_logic;
 signal reset_counter   : std_logic_vector(7 downto 0);
 --
 signal kbd_intr        : std_logic;
 signal kbd_scancode    : std_logic_vector(7 downto 0);
 signal joy_BBBBFRLDU   : std_logic_vector(9 downto 0);
-- signal buttons         : std_logic_vector(8 downto 0);
-- signal buttons_b       : std_logic_vector(8 downto 0);
 --
 signal SW_LEFT         : std_logic;
 signal SW_RIGHT        : std_logic;
 signal SW_UP           : std_logic;
 signal SW_DOWN         : std_logic;
 signal SW_FIRE         : std_logic;
 signal SW_BOMB         : std_logic;
 signal SW_COIN         : std_logic;
 signal P1_START        : std_logic;
 signal P2_START        : std_logic;
 --
 constant CLOCK_FREQ    : integer := 27E6;
 signal counter_clk     : std_logic_vector(25 downto 0);
 signal clock_4hz       : std_logic;
 signal AD              : std_logic_vector(15 downto 0);
---------------------------------------------------------------------------
component druaga_clocks
port(
  clk_out1          : out    std_logic;
  clk_out2          : out    std_logic;
  locked            : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;
---------------------------------------------------------------------------
begin

 reset <= not I_RESET;
 greenLED <= '1'; -- turn off leds
 redLED   <= '1';
---------------------------------------------------------------------------
Clocks: druaga_clocks
    port map (
        clk_in1   => clock_50,
        clk_out1  => clock_48,
        clk_out2  => clock_9,
        locked    => pll_lock
    );
---------------------------------------------------------------------------
-- Delayed Reset generator

	process
	begin
		wait until rising_edge(clock_12);
		if pll_lock = '0' or reset = '1' then
			reset_counter <= (others => '0');
			cpu_reset <= '1';
		else
			if reset_counter < x"80" then
				reset_counter <= reset_counter + 1;
			else
				cpu_reset <= '0';
			end if;
		end if;
	end process;
---------------------------------------------------------------------------
-- input map

INP0  <= SW_BOMB & SW_FIRE & SW_LEFT & SW_DOWN & SW_RIGHT & SW_UP;
INP1  <= SW_BOMB & SW_FIRE & SW_LEFT & SW_DOWN & SW_RIGHT & SW_UP;
INP2  <= SW_COIN & P2_START & P1_START; 

SW_LEFT    <= joy_BBBBFRLDU(2) when dipsw(0) = '0' else not joy(0);
SW_RIGHT   <= joy_BBBBFRLDU(3) when dipsw(0) = '0' else not joy(1);
SW_UP      <= joy_BBBBFRLDU(0) when dipsw(0) = '0' else not joy(2);
SW_DOWN    <= joy_BBBBFRLDU(1) when dipsw(0) = '0' else not joy(3);
SW_FIRE    <= joy_BBBBFRLDU(4) when dipsw(0) = '0' else not joy(4);
SW_BOMB    <= joy_BBBBFRLDU(8) when dipsw(0) = '0' else not joy(5);
SW_COIN    <= joy_BBBBFRLDU(7) when dipsw(0) = '0' else not joy(6);
P1_START   <= joy_BBBBFRLDU(5) when dipsw(0) = '0' else not joy(7);
P2_START   <= joy_BBBBFRLDU(6) when dipsw(0) = '0' else not joy(8);
---------------------------------------------------------------------------
-- Main

druaga : entity work.fpga_druaga
  port map (
 MCLK       => clock_48,
 CLKCPUx2   => clock_6,
 CLK12M     => clock_12,
 CLK24M     => clock_24,
 RESET      => reset,
 LOCK       => pll_lock,
 CPU_RESET  => cpu_reset, -- snd cpu delayed reset
 INP0       => INP0,
 INP1       => INP1,
 INP2       => INP2,
 DSW0       => "00000000",
 DSW1       => "00000000",
 DSW2       => "00000000",
 PH         => HPOS,
 PV         => VPOS,
 PCLK       => PCLK,
 POUT       => oPIX,
 SOUT       => oSND,
 AD         => AD
   );
-----------------------------------------------------------------------------
-- Video Gen

hvgen : entity work.HVGEN
  port map (
 HPOS    => HPOS,
 VPOS    => VPOS,
 PCLK    => PCLK,
 HBLK    => h_blank,
 VBLK    => v_blank,
 HSYN    => M_HSYNC,
 VSYN    => M_VSYNC
);
-- vga output
-----------------------------------------------------------------------------
video_r <= oPIX(2 downto 0) & oPIX(2 downto 0) when h_blank = '0' and v_blank = '0' else "000000";
video_g <= oPIX(5 downto 3) & oPIX(5 downto 3) when h_blank = '0' and v_blank = '0' else "000000";
video_b <= oPIX(7 downto 6) & oPIX(7 downto 6) & oPIX(7 downto 6) when h_blank = '0' and v_blank = '0' else "000000";
------------------------------------------------------------------------------
-- scan doubler

dblscan: entity work.scandoubler
	port map(
		clk_sys => clock_24,
		scanlines => "00",
		r_in   => video_r,
		g_in   => video_g,
		b_in   => video_b,
		hs_in  => M_HSYNC,
		vs_in  => M_VSYNC,
		r_out  => video_r_x2,
		g_out  => video_g_x2,
		b_out  => video_b_x2,
		hs_out => hsync_x2,
		vs_out => vsync_x2
	);
-------------------------------------------------------------------------
-- vga output

	O_VIDEO_R 	<= video_r_x2(5 downto 3);
	O_VIDEO_G 	<= video_g_x2(5 downto 3);
	O_VIDEO_B 	<= video_b_x2(5 downto 4);
	O_HSYNC     <= hsync_x2;
	O_VSYNC     <= vsync_x2;
------------------------------------------------------------------------------
-- get scancode from keyboard

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_9,
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);
------------------------------------------------------------------------------
-- translate scancode to joystick

joystick : entity work.kbd_joystick
port map (
  clk         => clock_9,
  kbdint      => kbd_intr,
  kbdscancode => std_logic_vector(kbd_scancode), 
  joy_BBBBFRLDU  => joy_BBBBFRLDU 
);
---------------------------------------------------------------
 -- Audio DAC
 
 u_dac : entity work.dac
  generic map(
    msbi_g => 7
  )
port  map(
    clk_i   => clock_12,
    res_n_i => I_RESET,
    dac_i   => oSND,
    dac_o   => audio_pwm
);

 O_AUDIO_L <= audio_pwm; 
 O_AUDIO_R <= audio_pwm;
------------------------------------------------------------------------------
-- debug

process(reset, clock_24)
begin
  if reset = '1' then
   clock_4hz <= '0';
   counter_clk <= (others => '0');
  else
    if rising_edge(clock_24) then
      if counter_clk = CLOCK_FREQ/8 then
        counter_clk <= (others => '0');
        clock_4hz <= not clock_4hz;
        led(7 downto 0) <= not AD(14 downto 7);
      else
        counter_clk <= counter_clk + 1;
      end if;
    end if;
  end if;
end process;
------------------------------------------------------------------------------
end struct;