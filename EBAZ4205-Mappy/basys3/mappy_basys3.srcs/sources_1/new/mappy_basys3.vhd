---------------------------------------------------------------------------------
-- Basys 3 top level for Mappy
-- Source: EBAZ4205-Druaga.vhd by pinballwiz.org
--   (https://github.com/pinballwizz/EBAZ4205-Mappy). See that file for its
--   history.
-- Core: MiSTer-X, MC6809 by Greg Miller
---------------------------------------------------------------------------------
--
-- 11/05/2026: initial Basys 3 release by Red~Bote
--
---------------------------------------------------------------------------------
-- License:
--  - Basys 3 changes: MIT (see LICENSE)
--  - Code from EBAZ4205-Druaga.vhd: no license stated
--  - Core (rtl/*.v): (c) 2007 MiSTer-X, (c) 2016 Greg Miller, terms as stated in the
--    file headers
---------------------------------------------------------------------------------
--
-- Main features:
--  Connections:
--   VGA monitor, 31 kHz (scandoubler). 15 kHz RGB with sw13 up (not tested)
--   USB keyboard on the USB-HID host connector (MAME default keys)
--   Atari-type joystick on Pmod JA, pins 1/2/3/4/7 = right/left/down/up/fire
--   PmodAMP2 with speaker on Pmod JXADC, pins 1/2/4
--  Controls       keyboard       stick          button
--   move          arrows         stick
--   door          Left Ctrl      fire
--   coin          5                             btnU, btnD
--   start1/2      1, 2                          btnL, btnR
--   reset                                       btnC
--  Switches:
--   sw15      audio off
--   sw14      scanlines
--   sw13      15 kHz RGB
--   sw12      test mode
--   sw0-sw9   DIP switches, down = default:
--    sw0       bonus life bit 0
--    sw1       coin B bit 1
--    sw2       demo sounds
--    sw3       rack test
--    sw4       freeze
--    sw5-sw6   bonus life bits 1-2
--    sw7       lives (3/5)
--    sw8       difficulty bit 1
--    sw9       difficulty bit 2, also cocktail cabinet
--   Coin A fixed at 1 coin 1 credit
--  Clock: 1 MMCM, 49.152 MHz from 100 MHz
--
-- Other details: see basys3/README.md
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;

---------------------------------------------------------------------------------
entity mappy_basys3 is
port(
    clk         : in  std_logic;
    btnC        : in  std_logic;
    btnU        : in  std_logic;
    btnD        : in  std_logic;
    btnL        : in  std_logic;
    btnR        : in  std_logic;
    sw          : in  std_logic_vector(15 downto 0);
    vga_r       : out std_logic_vector(3 downto 0);
    vga_g       : out std_logic_vector(3 downto 0);
    vga_b       : out std_logic_vector(3 downto 0);
    hsync       : out std_logic;
    vsync       : out std_logic;
    ps2_clk     : in  std_logic;
    ps2_dat     : inout std_logic;
    JA          : in  std_logic_vector(4 downto 0);
    JXADC       : out std_logic_vector(3 downto 0);
    led         : out std_logic_vector(15 downto 0)
);
end mappy_basys3;

------------------------------------------------------------------------------
architecture struct of mappy_basys3 is

    signal clock_48        : std_logic;
    signal clock_24        : std_logic;
    signal clock_12        : std_logic;
    signal clock_6         : std_logic;
    signal pll_lock        : std_logic;
    signal mmcm_reset      : std_logic := '0';
    --
    signal PCLK            : std_logic;
    signal HPOS            : std_logic_vector(8 downto 0);
    signal VPOS            : std_logic_vector(8 downto 0);
    signal oPIX            : std_logic_vector(7 downto 0);
    --
    signal video_r         : std_logic_vector(5 downto 0);
    signal video_g         : std_logic_vector(5 downto 0);
    signal video_b         : std_logic_vector(5 downto 0);
    signal M_HSYNC         : std_logic;
    signal M_VSYNC         : std_logic;
    signal h_blank         : std_logic;
    signal v_blank         : std_logic;
    --
    signal video_r_x2      : std_logic_vector(5 downto 0);
    signal video_g_x2      : std_logic_vector(5 downto 0);
    signal video_b_x2      : std_logic_vector(5 downto 0);
    signal hsync_x2        : std_logic;
    signal vsync_x2        : std_logic;
    signal scanlines       : std_logic_vector(1 downto 0);
    --
    signal oSND            : std_logic_vector(7 downto 0);
    signal audio_pwm       : std_logic;
    --
    signal INP0            : std_logic_vector(5 downto 0);
    signal INP1            : std_logic_vector(5 downto 0);
    signal INP2            : std_logic_vector(2 downto 0);
    signal dsw0            : std_logic_vector(7 downto 0);
    signal dsw1            : std_logic_vector(7 downto 0);
    signal dsw2            : std_logic_vector(7 downto 0);
    --
    signal reset           : std_logic;
    signal cpu_reset       : std_logic;
    signal reset_counter   : std_logic_vector(7 downto 0);
    --
    signal kbd_intr        : std_logic;
    signal kbd_scancode    : std_logic_vector(7 downto 0);
    signal kbd_joy         : std_logic_vector(9 downto 0);
    signal joy_BBBBFRLDU   : std_logic_vector(9 downto 0);
    signal ps2_clk_meta    : std_logic;
    signal ps2_clk_s       : std_logic;
    signal ps2_dat_meta    : std_logic;
    signal ps2_dat_s       : std_logic;
    signal btn_meta        : std_logic_vector(3 downto 0);
    signal btn_s           : std_logic_vector(3 downto 0);
    signal stick_meta      : std_logic_vector(4 downto 0);
    signal stick_s         : std_logic_vector(4 downto 0);
    attribute ASYNC_REG    : string;
    attribute ASYNC_REG of btn_meta, btn_s, stick_meta, stick_s : signal is "TRUE";
    attribute ASYNC_REG of ps2_clk_meta, ps2_clk_s, ps2_dat_meta, ps2_dat_s : signal is "TRUE";
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
    constant CLOCK_FREQ    : integer := 24E6;
    signal counter_clk     : std_logic_vector(25 downto 0);
    signal AD              : std_logic_vector(15 downto 0);

---------------------------------------------------------------------------
begin

    -- btnC reset
    reset <= btnC;

---------------------------------------------------------------------------
    -- Clock: MMCM 49.152 MHz from the 100 MHz board clock (core master clock MCLK)
    clk_wiz_0 : entity work.clk_wiz_0
    port map (
        reset    => mmcm_reset,
        clk_in1  => clk,
        clk_out1 => clock_48,
        locked   => pll_lock
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

    SW_UP      <= joy_BBBBFRLDU(0);
    SW_DOWN    <= joy_BBBBFRLDU(1);
    SW_LEFT    <= joy_BBBBFRLDU(2);
    SW_RIGHT   <= joy_BBBBFRLDU(3);
    SW_FIRE    <= joy_BBBBFRLDU(4);
    P1_START   <= joy_BBBBFRLDU(5);
    P2_START   <= joy_BBBBFRLDU(6);
    SW_COIN    <= joy_BBBBFRLDU(7);
    SW_BOMB    <= joy_BBBBFRLDU(8);

    -- DIP switches (switch list in the header). The core orders the DIP nibbles for
    -- Druaga, so the Mappy settings differ from the bit names. dsw0(7) is the test
    -- mode bit (sw12).
    dsw0 <= sw(12) & sw(9) & sw(8) & "00" & sw(7 downto 5);
    dsw1 <= sw(4 downto 3) & sw(2 downto 0) & "000";
    dsw2 <= (others => '0');

    -- sw14 up: scanlines, alternate lines at 50 % brightness (31 kHz output only)
    scanlines <= "10" when sw(14) = '1' else "00";

---------------------------------------------------------------------------
    -- Main

    druaga : entity work.fpga_druaga
    port map (
        MCLK      => clock_48,
        CLKCPUx2  => clock_6,
        CLK12M    => clock_12,
        CLK24M    => clock_24,
        RESET     => reset,
        LOCK      => pll_lock,
        CPU_RESET => cpu_reset, -- snd cpu delayed reset
        INP0      => INP0,
        INP1      => INP1,
        INP2      => INP2,
        DSW0      => dsw0,
        DSW1      => dsw1,
        DSW2      => dsw2,
        PH        => HPOS,
        PV        => VPOS,
        PCLK      => PCLK,
        POUT      => oPIX,
        SOUT      => oSND,
        AD        => AD
    );

-----------------------------------------------------------------------------
    -- Video Gen

    hvgen : entity work.HVGEN
    port map (
        HPOS => HPOS,
        VPOS => VPOS,
        PCLK => PCLK,
        HBLK => h_blank,
        VBLK => v_blank,
        HSYN => M_HSYNC,
        VSYN => M_VSYNC
    );

    video_r <= oPIX(2 downto 0) & oPIX(2 downto 0) when h_blank = '0' and v_blank = '0' else "000000";
    video_g <= oPIX(5 downto 3) & oPIX(5 downto 3) when h_blank = '0' and v_blank = '0' else "000000";
    video_b <= oPIX(7 downto 6) & oPIX(7 downto 6) & oPIX(7 downto 6) when h_blank = '0' and v_blank = '0' else "000000";

------------------------------------------------------------------------------
    -- scan doubler

    dblscan : entity work.scandoubler
    port map (
        clk_sys   => clock_24,
        scanlines => scanlines,
        r_in      => video_r,
        g_in      => video_g,
        b_in      => video_b,
        hs_in     => M_HSYNC,
        vs_in     => M_VSYNC,
        r_out     => video_r_x2,
        g_out     => video_g_x2,
        b_out     => video_b_x2,
        hs_out    => hsync_x2,
        vs_out    => vsync_x2
    );

-------------------------------------------------------------------------
    -- vga outputs

    -- sw13 down: 31 kHz VGA (scandoubler), up: 15 kHz TV with composite sync on HS
    process(clock_24)
    begin
        if rising_edge(clock_24) then
            if sw(13) = '0' then
                vga_r <= video_r_x2(5 downto 2);
                vga_g <= video_g_x2(5 downto 2);
                vga_b <= video_b_x2(5 downto 2);
                hsync <= hsync_x2;
                vsync <= vsync_x2;
            else
                vga_r <= video_r(5 downto 2);
                vga_g <= video_g(5 downto 2);
                vga_b <= video_b(5 downto 2);
                hsync <= M_HSYNC and M_VSYNC; -- composite sync, active low
                vsync <= '1';
            end if;
        end if;
    end process;

------------------------------------------------------------------------------
    -- get scancode from keyboard

    process(clock_12)
    begin
        if rising_edge(clock_12) then
            ps2_clk_meta <= ps2_clk;
            ps2_clk_s    <= ps2_clk_meta;
            ps2_dat_meta <= ps2_dat;
            ps2_dat_s    <= ps2_dat_meta;
        end if;
    end process;

    keyboard : entity work.io_ps2_keyboard
    port map (
        clk       => clock_12,
        kbd_clk   => ps2_clk_s,
        kbd_dat   => ps2_dat_s,
        interrupt => kbd_intr,
        scancode  => kbd_scancode
    );

------------------------------------------------------------------------------
    -- translate scancode to joystick

    joystick : entity work.kbd_joystick
    port map (
        clk           => clock_12,
        kbdint        => kbd_intr,
        kbdscancode   => std_logic_vector(kbd_scancode),
        joy_BBBBFRLDU => kbd_joy
    );

------------------------------------------------------------------------------
    -- buttons and JA joystick (active low, pins 1/2/3/4/7 = R/L/D/U/fire):
    -- 2-FF synchronizers, ORed with the keyboard
    process(clock_12)
    begin
        if rising_edge(clock_12) then
            btn_meta   <= btnU & btnD & btnL & btnR;
            btn_s      <= btn_meta;
            stick_meta <= JA;
            stick_s    <= stick_meta;
        end if;
    end process;

    joy_BBBBFRLDU(0) <= kbd_joy(0) or not stick_s(3); -- up
    joy_BBBBFRLDU(1) <= kbd_joy(1) or not stick_s(2); -- down
    joy_BBBBFRLDU(2) <= kbd_joy(2) or not stick_s(1); -- left
    joy_BBBBFRLDU(3) <= kbd_joy(3) or not stick_s(0); -- right
    joy_BBBBFRLDU(4) <= kbd_joy(4) or not stick_s(4); -- fire
    joy_BBBBFRLDU(5) <= kbd_joy(5) or btn_s(1); -- start 1: btnL
    joy_BBBBFRLDU(6) <= kbd_joy(6) or btn_s(0); -- start 2: btnR
    joy_BBBBFRLDU(7) <= kbd_joy(7) or btn_s(3) or btn_s(2); -- coin: btnU, btnD
    joy_BBBBFRLDU(8) <= kbd_joy(8);
    joy_BBBBFRLDU(9) <= kbd_joy(9);

------------------------------------------------------------------------------
    -- Audio DAC: 1-bit output to the PmodAMP2

    u_dac : entity work.dac
    generic map (
        msbi_g => 7
    )
    port map (
        clk_i   => clock_12,
        res_n_i => not reset,
        dac_i   => oSND,
        dac_o   => audio_pwm
    );

    JXADC(0) <= audio_pwm;
    JXADC(1) <= '1';        -- PmodAMP2 GAIN (JXADC2), active low: fixed low gain
    JXADC(2) <= '0';
    JXADC(3) <= not sw(15); -- PmodAMP2 SHUTD (JXADC4), active low: sw15 up = audio off

------------------------------------------------------------------------------
    -- debug

    led(15 downto 8) <= (others => '0');

    process(reset, clock_24)
    begin
        if reset = '1' then
            counter_clk <= (others => '0');
        else
            if rising_edge(clock_24) then
                if counter_clk = CLOCK_FREQ/8 then
                    counter_clk <= (others => '0');
                    led(7 downto 0) <= not AD(14 downto 7);
                else
                    counter_clk <= counter_clk + 1;
                end if;
            end if;
        end if;
    end process;

------------------------------------------------------------------------------
end struct;
