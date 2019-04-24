-----------------------------------------------------------------[Rev.20110803]
-- Pentagon 256K
-------------------------------------------------------------------------------
-- By MVV
-- Version	: V0.01
-- Devboard	: U10EP3C

-- Карта SRAM 512K
-- 00000-3FFFF	RAM 256K (Pentagon)
-- * 40000-5FFFF	RAM 128K (GS)
-- 60000-63FFF	ROM 16K "TR-DOS"
-- 64000-67FFF	ROM 16K "OS`82"
-- 68000-6BFFF	ROM 16K "OS`86"
-- 6C000-6FFFF	ROM 16K "HEGluk"
-- * 70000-77FFF	ROM 32K "GS"
-- * 78000-7FFFF	RAM 32K CASHE

-- Карта FLASH 512K
-- 00000-5FFFF	Конфигурация (Cyclone EP3C10)
-- 60000-63FFF	ROM 16K "TR-DOS"
-- 64000-67FFF	ROM 16K "OS`82"
-- 68000-6BFFF	ROM 16K "OS`86"
-- 6C000-6FFFF	ROM 16K "HEGluk"
-- 70000-77FFF	ROM 32K "GS"
-- 78000-7FFFF	32K Свободно

-- Карта M9K 46K
-- 0000-B7FF

library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;  

entity pentagon is                    
port (
	-- Clock
	CLK_50MHz	: in std_logic;
	-- SRAM (CY7C1049DV33-10)
	SRAM_A		: out std_logic_vector(18 downto 0);
	SRAM_D		: inout std_logic_vector(7 downto 0);
	SRAM_OE_n	: out std_logic;
	SRAM_WE_n	: out std_logic;
	SRAM_CE_n	: out std_logic;
	-- RTC (PCF8583)
	RTC_INT_n	: in std_logic;
	RTC_SCL		: inout std_logic;
	RTC_SDA		: inout std_logic;
	-- FLASH (M25P40)
	DATA0		: in std_logic;
	NCSO		: out std_logic;
	DCLK		: out std_logic;
	ASDO		: out std_logic;
	-- FLASH (AT45DB161D)
	FLASH_SI	: out std_logic;
	FLASH_SO	: in std_logic;
	FLASH_SCK	: out std_logic;
	FLASH_CS_n	: out std_logic;
	-- Audio Codec (VS1053B)
	VS_SO		: in std_logic;
	VS_SI		: out std_logic;
	VS_SCLK		: out std_logic;
	VS_CS_n		: out std_logic;
	VS_DCS_n	: out std_logic;
	VS_DREQ		: in std_logic;
	VS_GPIO		: inout std_logic_vector(7 downto 0);
	-- VGA
	VGA_R		: out std_logic_vector(2 downto 0);
	VGA_G		: out std_logic_vector(2 downto 0);
	VGA_B		: out std_logic_vector(2 downto 0);
	VGA_VSYNC	: out std_logic;
	VGA_HSYNC	: out std_logic;
	-- External I/O
	RST_n		: in std_logic;
	-- PS/2
	PS2_KBCLK	: inout std_logic;
	PS2_KBDAT	: inout std_logic;		
	PS2_MSCLK	: inout std_logic;
	PS2_MSDAT	: inout std_logic;		
	-- USB1
	USB1_DN		: in std_logic;
	USB1_DP		: in std_logic;
	-- USB2
	USB2_DN		: in std_logic;
	USB2_DP		: in std_logic;
	-- UART (MAX3232)
	UART_TXD	: in std_logic;
	UART_RXD	: out std_logic;
	UART_CTS	: out std_logic;
	UART_RTS	: in std_logic;
	-- SD Card
	SD_CLK		: out std_logic;
	SD_DAT0		: in std_logic;
	SD_DAT1		: in std_logic;
	SD_DAT2		: in std_logic;
	SD_DAT3		: out std_logic;
	SD_CMD		: out std_logic;
	SD_PROT		: in std_logic
);		
end pentagon;

-------------------------------------------------------------------------------
architecture pentagon_arch of pentagon is

-- Master Reset
signal reset			: std_logic;
signal locked			: std_logic;
-- CPU0
signal cpu0_clk			: std_logic;
signal cpu0_a_bus		: std_logic_vector(15 downto 0);
signal cpu0_do_bus		: std_logic_vector(7 downto 0);
signal cpu0_di_bus		: std_logic_vector(7 downto 0);
signal cpu0_mreq_n		: std_logic;
signal cpu0_iorq_n		: std_logic;
signal cpu0_wr_n		: std_logic;
signal cpu0_rd_n		: std_logic;
signal cpu0_int_n		: std_logic;
signal cpu0_m1_n		: std_logic;
-- Memory
signal rom_do_bus		: std_logic_vector(7 downto 0);
signal ram_a_bus		: std_logic_vector(4 downto 0);
signal loader			: std_logic;
signal dos				: std_logic;
-- Port
signal port_xxfe		: std_logic;
signal port_7ffd		: std_logic;
signal port_xx00		: std_logic;
signal port_xx0A		: std_logic;
signal port_xxfe_reg	: std_logic_vector(7 downto 0);
signal port_7ffd_reg	: std_logic_vector(7 downto 0);
signal port_xx00_reg	: std_logic_vector(7 downto 0);
signal port_xx0A_reg	: std_logic_vector(7 downto 0);
-- Sound
signal beep				: std_logic;
signal tape				: std_logic;
-- PS/2 Keyboard
signal kb_a_bus			: std_logic_vector(7 downto 0);
signal kb_do_bus		: std_logic_vector(4 downto 0);
-- Video
signal vid_a_bus		: std_logic_vector(12 downto 0);
signal vid_di_bus		: std_logic_vector(7 downto 0);
signal vid_wr			: std_logic;
signal vid_clk			: std_logic;
signal vid_scr			: std_logic;
signal vid_r			: std_logic_vector(2 downto 1);
signal vid_g			: std_logic_vector(2 downto 1);
signal vid_b			: std_logic_vector(2 downto 1);
signal vid_hs			: std_logic;
signal vid_vs			: std_logic;
-- Txt
signal txt_clk			: std_logic;
signal txt_hs			: std_logic;
signal txt_vs			: std_logic;
signal txt_wr			: std_logic;
signal txt_r			: std_logic_vector(1 downto 0);
signal txt_g			: std_logic_vector(1 downto 0);
signal txt_b			: std_logic_vector(1 downto 0);
signal txt_a_bus		: std_logic_vector(13 downto 0);
signal txt_di_bus		: std_logic_vector(7 downto 0);
-- ZC
signal zc_a				: std_logic;
signal zc_do_bus		: std_logic_vector(7 downto 0);
signal zc_rd			: std_logic;
signal zc_wr			: std_logic;
-- SPI
signal spi_cs			: std_logic;
signal spi_wr			: std_logic;
signal spi_a			: std_logic;
signal spi_do_bus		: std_logic_vector(7 downto 0);

begin
-------------------------------------------------------------------------------
-- PLL
-------------------------------------------------------------------------------
U0: entity work.altpll0
port map (
	inclk0	=> CLK_50MHz,
	locked	=> locked,
	c0		=> vid_clk,
	c1		=> cpu0_clk,
	c2		=> txt_clk
);
-------------------------------------------------------------------------------
-- CPU0
-------------------------------------------------------------------------------
U1: entity work.T80se
generic map (
	Mode		=> 0,	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
	T2Write		=> 1,	-- 0 => WR_n active in T3, 1 => WR_n active in T2
	IOWait		=> 0	-- 0 => Single cycle I/O, 1 => Std I/O cycle
)
port map(
	RESET_n		=> not reset,
	CLK_n		=> cpu0_clk,
	CLKEN		=> '1',
	WAIT_n		=> '1',
	INT_n		=> cpu0_int_n,
	NMI_n		=> '1',
	BUSRQ_n		=> '1',
	M1_n		=> cpu0_m1_n,
	MREQ_n		=> cpu0_mreq_n,
	IORQ_n		=> cpu0_iorq_n,
	RD_n		=> cpu0_rd_n,
	WR_n		=> cpu0_wr_n,
	RFSH_n		=> open,
	HALT_n		=> open,
	BUSAK_n		=> open,
	A			=> cpu0_a_bus,
	DI			=> cpu0_di_bus,
	DO			=> cpu0_do_bus
);
-------------------------------------------------------------------------------
-- VIDEO
-------------------------------------------------------------------------------
U2: entity work.zxscr
port map (
	CLK			=> vid_clk,
	INT			=> cpu0_int_n,
	BORDER		=> port_xxfe_reg(2 downto 0),	-- Биты D0..D2 порта xxFE определяют цвет бордюра
	A			=> vid_a_bus,
	DI			=> vid_di_bus,
	R			=> vid_r(2 downto 1),
	G			=> vid_g(2 downto 1),
	B			=> vid_b(2 downto 1),
	HS			=> vid_hs,
	VS			=> vid_vs
);
-------------------------------------------------------------------------------
-- KEYBOARD
-------------------------------------------------------------------------------
U3: entity work.keyboard
generic map (
	ledStatusSupport=> true,	-- Include code for LED status updates
	clockFilter		=> 15,		-- Number of system-cycles used for PS/2 clock filtering
	ticksPerUsec	=> 14		-- Timer calibration 14Mhz
)
port map(
	CLK			=>	vid_clk,
	RESET		=>	not locked,
	A			=>	kb_a_bus,
	KEYB		=>	kb_do_bus,
	KEYF		=>	open,
	KEYJOY		=>	open,
	KEYNUMLOCK	=>	open,
	KEYRESET	=>	reset,
	KEYLED		=>  "111",
	PS2_KBCLK	=>	PS2_KBCLK,
	PS2_KBDAT	=>	PS2_KBDAT
);
-------------------------------------------------------------------------------
-- ROM 1K
-------------------------------------------------------------------------------
U4: entity work.altram0
port map (
	clock_a		=> cpu0_clk,
	clock_b		=> cpu0_clk,
	address_a	=> cpu0_a_bus(9 downto 0),
	address_b	=> "0000000000",
	data_a	 	=> cpu0_do_bus,
	data_b	 	=> "00000000",
	q_a	 		=> rom_do_bus,
	q_b	 		=> open,
	wren_a	 	=> '0',
	wren_b	 	=> '0'
);
-------------------------------------------------------------------------------
-- Video memory
-------------------------------------------------------------------------------
U5: entity work.altram1
port map (
	clock_a		=> cpu0_clk,
	clock_b		=> vid_clk,
	address_a	=> vid_scr & cpu0_a_bus(12 downto 0),
	address_b	=> port_7ffd_reg(3) & vid_a_bus,
	data_a		=> cpu0_do_bus,
	data_b		=> "11111111",
	q_a			=> open,
	q_b			=> vid_di_bus,
	wren_a		=> vid_wr,
	wren_b		=> '0'
);
-------------------------------------------------------------------------------
-- ZC SD Card Controller
-------------------------------------------------------------------------------
U6: entity work.zc
port map (
	RESET		=> reset,
	CLK			=> vid_clk,
	A			=> zc_a,
	DI			=> cpu0_do_bus,
	DO			=> zc_do_bus,
	RD			=> zc_rd,
	WR			=> zc_wr,
	SDCS_n		=> SD_DAT3,
	SCK			=> SD_CLK,
	MOSI		=> SD_CMD,
	MISO		=> SD_DAT0
);
-------------------------------------------------------------------------------
-- SPI Controller
-------------------------------------------------------------------------------
U7: entity work.spi
port map (
	RESET		=> reset,
	CLK			=> vid_clk,
	WR			=> spi_wr,
	ADDR		=> cpu0_a_bus(0),
	DATA_IN		=> cpu0_do_bus,
	DATA_OUT	=> spi_do_bus,
	IRQ			=> open,
	SPI_MISO	=> DATA0,
	SPI_MOSI	=> ASDO,
	SPI_CLK		=> DCLK,
	SPI_CS_n	=> NCSO
);
spi_wr <= '1' when (cpu0_iorq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(7 downto 1) = "0000001") else '0';

-------------------------------------------------------------------------------
-- Text Mode 128 x 48 (XGA Signal 1024 x 768 @ 60 Hz timing)
-------------------------------------------------------------------------------
U8: entity work.vgatxt
port map(
	RESET		=> '1',
	CLOCK		=> txt_clk,
	A			=> txt_a_bus,
	DI			=> txt_di_bus,
	R			=> txt_r,
	G			=> txt_g,
	B			=> txt_b,
	HSYNC		=> txt_hs,
	VSYNC		=> txt_vs
);
-------------------------------------------------------------------------------
-- Video memory
-------------------------------------------------------------------------------
U9: entity work.altram2
port map (
	clock_a		=> cpu0_clk,
	clock_b		=> txt_clk,
	address_a	=> cpu0_a_bus(13 downto 0),
	address_b	=> txt_a_bus,
	data_a		=> cpu0_do_bus,
	data_b		=> "11111111",
	q_a			=> open,
	q_b			=> txt_di_bus,
	wren_a		=> txt_wr,
	wren_b		=> '0'
);
txt_wr <= '1' when (cpu0_mreq_n = '0' and cpu0_wr_n = '0' and (ram_a_bus = "1111" and cpu0_a_bus(15 downto 14) = "11")) else '0';

-------------------------------------------------------------------------------
-- Порт xxFE
port_xxfe <= '1' when (cpu0_wr_n = '0' and cpu0_iorq_n = '0' and cpu0_a_bus(7 downto 0) = x"FE") else '0';
port_xxfe_reg <= cpu0_do_bus when (port_xxfe'event and port_xxfe = '1');
beep <= port_xxfe_reg(4) xor tape;	--бит D4 управляет звуковым каналом 
tape <= port_xxfe_reg(3);			--бит D3 управляет выходом на магнитофон

-- Порт 7FFD
port_7ffd <= '1' when (cpu0_wr_n = '0' and cpu0_iorq_n = '0' and cpu0_a_bus(15 downto 0) = x"7FFD") else '0';
process (reset, port_7ffd, cpu0_do_bus)
begin
	if (reset = '1') then
		port_7ffd_reg <= "00000000";
	else
		if (port_7ffd'event and port_7ffd = '1') then
			port_7ffd_reg <= cpu0_do_bus;
		end if;
	end if;
end process;

-- Порт xx00
port_xx00 <= '1' when (cpu0_wr_n = '0' and cpu0_iorq_n = '0' and cpu0_a_bus(7 downto 0) = x"00") else '0';
process (reset, port_xx00, cpu0_do_bus)
begin
	if (reset = '1') then
		port_xx00_reg <= "00000000";
	else
		if (port_xx00'event and port_xx00 = '1') then
			port_xx00_reg <= cpu0_do_bus;
		end if;
	end if;
end process;

-- Порт xx0A
port_xx0A <= '1' when (cpu0_wr_n = '0' and cpu0_iorq_n = '0' and cpu0_a_bus(7 downto 0) = x"0A") else '0';
process (reset, port_xx0A, cpu0_do_bus)
begin
	if (reset = '1') then
		port_xx0A_reg <= "00000000";
	else
		if (port_xx0A'event and port_xx0A = '1') then
			port_xx0A_reg <= cpu0_do_bus;
		end if;
	end if;
end process;
-------------------------------------------------------------------------------
-- Селектор
--
process (cpu0_a_bus, port_7ffd_reg, port_xx00_reg, dos)
begin
	case cpu0_a_bus(15 downto 14) is
		when "00" => ram_a_bus <= "1100" & dos;
		when "01" => ram_a_bus <= "00101";
		when "10" => ram_a_bus <= port_xx00_reg(4 downto 0);	-- окно используется для возможности загрузки ROM в страницы SRAM, после требуется установка в 00010 
		when "11" => ram_a_bus <= '0' & port_7ffd_reg(6) & port_7ffd_reg(2 downto 0);
		when others => null;
	end case;
end process;

process (reset, cpu0_clk, cpu0_a_bus, cpu0_m1_n, port_xx00_reg, cpu0_mreq_n)
begin
	if (reset = '1') then
		loader <= '1';
	elsif (cpu0_clk'event and cpu0_clk = '1') then
		if (cpu0_m1_n = '0' and cpu0_mreq_n = '0' and cpu0_a_bus = "0000000000000000" and port_xx00_reg(1) = '1') then 
			loader <= '0';
		end if;
	end if;
end process;

process (reset, cpu0_clk, cpu0_mreq_n, cpu0_m1_n, port_7ffd_reg, cpu0_a_bus)
begin
	if (reset = '1') then
		dos <= '0';
	elsif (cpu0_clk'event and cpu0_clk = '1') then 
		if (cpu0_m1_n = '0' and cpu0_mreq_n = '0' and cpu0_a_bus(15 downto 8) = "00111101") then
			dos <= '1';
		elsif (cpu0_m1_n = '0' and cpu0_mreq_n = '0' and cpu0_a_bus(15 downto 14) /= "00") then
			dos <= '0';
		end if;
	end if;
end process;

-------------------------------------------------------------------------------
-- Шина данных CPU0
--
cpu0_di_bus	<= 	rom_do_bus when (cpu0_mreq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(15 downto 14) = "00" and loader = '1') else
				SRAM_D when (cpu0_mreq_n = '0' and cpu0_rd_n = '0') else
				spi_do_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 1) = "0000001") else
				"111" & kb_do_bus when (cpu0_iorq_n = '0' and cpu0_rd_n = '0' and cpu0_a_bus(7 downto 0) = x"FE") else	-- Клавиатура, порт xxFE
				"11111111";
				
-------------------------------------------------------------------------------
-- SRAM
SRAM_A 		<= ram_a_bus & cpu0_a_bus(13 downto 0);
SRAM_D		<= cpu0_do_bus when (cpu0_mreq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(15 downto 14) /= "00") else "ZZZZZZZZ";
SRAM_OE_n	<= '0';
SRAM_WE_n	<= '0' when (cpu0_mreq_n = '0' and cpu0_wr_n = '0' and cpu0_a_bus(15 downto 14) /= "00") else '1';
SRAM_CE_n	<= '0';

-- VS1053
VS_CS_n		<= '1';
VS_DCS_n	<= '1';
VS_GPIO		<= "00000000";

-- Video
vid_wr 		<= '1' when (cpu0_mreq_n = '0' and cpu0_wr_n = '0' and ((ram_a_bus = "0101" and cpu0_a_bus(15 downto 13) = "010") or (ram_a_bus = "0111" and cpu0_a_bus(15 downto 13) = "110"))) else '0';
vid_scr		<= '1' when (ram_a_bus = "0111") else '0';

VGA_R(0) 	<= 'Z';
VGA_G(0) 	<= 'Z';
VGA_B(0) 	<= 'Z';

-- Keyboard
kb_a_bus	<= cpu0_a_bus(15 downto 8);
				
-- Video Mode
process (port_xx0A_reg, vid_r, vid_g, vid_b, vid_hs, vid_vs, txt_r, txt_g, txt_b, txt_hs, txt_vs)
begin
	if (port_xx0A_reg(0) = '0') then
		VGA_R(2 downto 1) <= vid_r;
		VGA_G(2 downto 1) <= vid_g;
		VGA_B(2 downto 1) <= vid_b;
		VGA_HSYNC <= vid_hs;
		VGA_VSYNC <= vid_vs;
	else
		VGA_R(2 downto 1) <= txt_r;
		VGA_G(2 downto 1) <= txt_g;
		VGA_B(2 downto 1) <= txt_b;
		VGA_HSYNC <= txt_hs;
		VGA_VSYNC <= txt_vs;
	end if;
end process;

end pentagon_arch;