--  SOC u10 v0.03 By MVV 18.09.2010
--	PCB u10ep3c rev.A 

--  16 KB Internal ROM		Read		(0x0000h - 0x3FFFh)
--  03 KB Internal VRAM		Write		(0x4000h - 0x5FFFh)
--  16 KB Internal RAM		Read/Write	(0x8000h - 0xBFFFh)
--  16 KB External SRAM		Read/Write	(0xC000h - 0xFFFFh)

--	01 PS/2 keyboard        In			(Port 0x80h)
--	01 Video write port     In/Out		(Port 0x90h)
--  01 Cursor_X             In/Out		(Port 0x91h)
--  01 Cursor_Y				In/Out		(Port 0x92h)
--  01 Memory Page			In/Out		(Port 0x70h)
--	01 Port Test			In			(Port 0x71h)

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity TOP_DE1 is
	port(
    -- Clocks
    CLOCK_50 : in std_logic;	-- 50 MHz
    -- Buttons and switches
    KEY : in std_logic;         -- Push buttons
    -- PS/2
    PS2_MSDAT,
    PS2_MSCLK,
    PS2_KBDAT,
    PS2_KBCLK : inout std_logic;
    -- SRAM
    SRAM_DQ		: inout std_logic_vector(7 downto 0);   -- Data bus 8 Bits
    SRAM_ADDR	: out std_logic_vector(18 downto 0);    -- Address bus 18 Bits
    SRAM_nOE	: out std_logic;						-- Output Enable
    SRAM_nWE	: out std_logic;						-- Write Enable
    SRAM_nCE0	: out std_logic;                        -- Chip 0 Enable
    SRAM_nCE1	: out std_logic;                        -- Chip 1 Enable
    -- VGA
    VGA_R,										-- Red  [2:0]
    VGA_G,										-- Green[2:0]
    VGA_B  : out std_logic_vector(2 downto 0);  -- Blue [2:0]
    VGA_HS,										-- H_SYNC
    VGA_VS : out std_logic						-- SYNC
    
    -- SD card interface
--    SD_DAT 	: in std_logic;     -- SD Card Data      SD pin 7 "DAT 0/DataOut"
--    SD_DAT3 : out std_logic;		-- SD Card Data 3    SD pin 1 "DAT 3/nCS"
--    SD_CMD 	: out std_logic;    -- SD Card Command   SD pin 2 "CMD/DataIn"
--    SD_CLK 	: out std_logic;    -- SD Card Clock     SD pin 5 "CLK"

    -- I2C bus
--    I2C_SDAT : inout std_logic;	-- I2C Data
--    I2C_SCLK : out std_logic;		-- I2C Clock

    -- USB JTAG link
--    TDI,							-- CPLD -> FPGA (data in)
--    TCK,							-- CPLD -> FPGA (clk)
--    TCS : in std_logic;			-- CPLD -> FPGA (CS)
--    TDO : out std_logic;			-- FPGA -> CPLD (data out)

    -- RS-232 interface
--    UART_TXD : out std_logic;		-- UART transmitter   
--    UART_RXD : in std_logic;		-- UART receiver

    -- Audio CODEC
--    AUD_ADCLRCK : inout std_logic;                      -- ADC LR Clock
--    AUD_ADCDAT : in std_logic;                          -- ADC Data
--    AUD_DACLRCK : inout std_logic;                      -- DAC LR Clock
--    AUD_DACDAT : out std_logic;                         -- DAC Data
--    AUD_BCLK : inout std_logic;                         -- Bit-Stream Clock
--    AUD_XCK : out std_logic;                            -- Chip Clock

);
end TOP_DE1;

architecture rtl of TOP_DE1 is
	component T80se
	generic(
		Mode : integer := 0;	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write : integer := 1;	-- 0 => CPU_nWR active in T3, /=0 => CPU_nWR active in T2
		IOWait : integer := 1	-- 0 => Single cycle I/O, 1 => Std I/O cycle
	);
	port(
		RESET_n		: in std_logic;
		CLK_n		: in std_logic;
		CLKEN		: in std_logic;
		WAIT_n		: in std_logic;
		INT_n		: in std_logic;
		NMI_n		: in std_logic;
		BUSRQ_n		: in std_logic;
		M1_n		: out std_logic;
		MREQ_n		: out std_logic;
		IORQ_n		: out std_logic;
		RD_n		: out std_logic;
		WR_n		: out std_logic;
		RFSH_n		: out std_logic;
		HALT_n		: out std_logic;
		BUSAK_n		: out std_logic;
		A			: out std_logic_vector(15 downto 0);
		DI			: in std_logic_vector(7 downto 0);
		DO			: out std_logic_vector(7 downto 0)
	);
	end component;
	
	component sram
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
	end component;
	
	component rom
	port (
		clock		: in std_logic;
		address		: in std_logic_vector(9 downto 0);
		q			: out std_logic_vector(7 downto 0));
	end component;

	component Clock_357Mhz
	PORT (
		clock_50Mhz				: IN	STD_LOGIC;
		clock_357Mhz			: OUT	STD_LOGIC);
	end component;
	
	component clk_div
	PORT
	(
		clock_25Mhz				: IN	STD_LOGIC;
		clock_1MHz				: OUT	STD_LOGIC;
		clock_100KHz			: OUT	STD_LOGIC;
		clock_10KHz				: OUT	STD_LOGIC;
		clock_1KHz				: OUT	STD_LOGIC;
		clock_100Hz				: OUT	STD_LOGIC;
		clock_10Hz				: OUT	STD_LOGIC;
		clock_1Hz				: OUT	STD_LOGIC);
	end component;

	component ps2kbd
	port (	
		keyboard_clk	: inout std_logic;
		keyboard_data	: inout std_logic;
		clock			: in std_logic;
		clkdelay		: in std_logic;
		reset			: in std_logic;
		read			: in std_logic;
		scan_ready		: out std_logic;
		ps2_ascii_code	: out std_logic_vector(7 downto 0));
	end component;
	
	component vram3200x8
	port
	(
		rdaddress		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		wraddress		: IN STD_LOGIC_VECTOR (12 DOWNTO 0);
		rdclock			: IN STD_LOGIC;
		wrclock			: IN STD_LOGIC;
		data			: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren			: IN STD_LOGIC;
		q				: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
	end component;

	component charram2k
	port (
		data			: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdaddress		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		rdclock			: IN STD_LOGIC ;
		wraddress		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
		wrclock			: IN STD_LOGIC;
		wren			: IN STD_LOGIC;
		q				: OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
	end component;
	
	COMPONENT video
	PORT (		
		CLOCK_25		: IN STD_LOGIC;
		VRAM_DATA		: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		VRAM_ADDR		: OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
		VRAM_CLOCK		: OUT STD_LOGIC;
		VRAM_WREN		: OUT STD_LOGIC;
		CRAM_DATA		: IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		CRAM_ADDR		: OUT STD_LOGIC_VECTOR(10 DOWNTO 0);
		CRAM_WEB		: OUT STD_LOGIC;
		VGA_R			: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		VGA_G			: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		VGA_B			: OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
		VGA_HS,
		VGA_VS			: OUT STD_LOGIC);
	END COMPONENT;
	
	COMPONENT video_PLL
	PORT
	(
		inclk0				: IN STD_LOGIC  := '0';
		c0					: OUT STD_LOGIC; 
		c1					: OUT STD_LOGIC
	);
	END COMPONENT;

	-- CPU signals
	signal CPU_nMREQ		: std_logic;
	signal CPU_nIORQ		: std_logic;
	signal CPU_nRFSH		: std_logic;
	signal CPU_nRD			: std_logic;
	signal CPU_nWR			: std_logic;
	signal MCPU_nWR			: std_logic;
	signal CPU_nRESET		: std_logic;
	signal CPU_CLK			: std_logic;
	signal CPU_DI			: std_logic_vector(7 downto 0);
	signal CPU_DO			: std_logic_vector(7 downto 0);
	signal CPU_A			: std_logic_vector(15 downto 0);
	signal One				: std_logic;
	
	signal D_ROM			: std_logic_vector(7 downto 0);

	-- ram signals
	signal ram_addr			: std_logic_vector(13 downto 0);
	signal ram_din			: std_logic_vector(7 downto 0);
	signal ram_dout			: std_logic_vector(7 downto 0);
	signal ram_wea			: std_logic;
	
	signal clk25mhz			: std_logic;
	signal clk100hz			: std_logic;
	signal clk10hz			: std_logic;
	signal clk1hz			: std_logic;
	signal clk_x_mhz		: std_logic;
	
	signal vram_address		: std_logic_vector(15 downto 0);
	signal vram_addrb		: std_logic_vector(12 downto 0);
	signal vram_dina		: std_logic_vector(7 downto 0);
	signal vram_dinb		: std_logic_vector(7 downto 0);
	signal vram_douta		: std_logic_vector(7 downto 0);
	signal vram_doutb		: std_logic_vector(7 downto 0);
	signal vram_wea			: std_logic;
	signal vram_web			: std_logic;
	signal vram_clka		: std_logic;
	signal vram_clkb		: std_logic;
	
	signal vram_douta_reg	: std_logic_vector(7 downto 0);	
	signal VID_CURSOR		: std_logic_vector(15 downto 0);
	signal CURSOR_X		    : std_logic_vector(6 downto 0);
	signal CURSOR_Y		    : std_logic_vector(5 downto 0);

	signal cram_address		: std_logic_vector(15 downto 0);
	signal cram_addrb		: std_logic_vector(15 downto 0);
	signal cram_dina		: std_logic_vector(7 downto 0);
	signal cram_dinb		: std_logic_vector(7 downto 0);
	signal cram_douta		: std_logic_vector(7 downto 0);
	signal cram_doutb		: std_logic_vector(7 downto 0);
	signal cram_wea			: std_logic;
	signal cram_web			: std_logic;
	signal cram_clka		: std_logic;
	signal cram_clkb		: std_logic;
	
	-- PS/2 Keyboard
	signal ps2_read			: std_logic;
	signal ps2_scan_ready	: std_logic;
	signal ps2_ascii_sig	: std_logic_vector(7 downto 0);
	signal ps2_ascii_reg1	: std_logic_vector(7 downto 0);
	signal ps2_ascii_reg	: std_logic_vector(7 downto 0);
 	
 	-- Port
 	signal page_reg	: std_logic_vector (7 downto 0);
 	signal port_reg : std_logic_vector (7 downto 0);
 	
begin
	
	CPU_nRESET <= KEY;
		
	--	Write into VRAM
	vram_address <= VID_CURSOR when (CPU_nIORQ = '0' and CPU_nMREQ = '1' and CPU_A(7 downto 0) = x"90")  else
					CPU_A - x"4000" when (CPU_A >= x"4000" and CPU_A < x"4C80");
	vram_wea <= '0' when ((CPU_A >= x"4000" and CPU_A < x"4C80" and CPU_nWR = '0' and CPU_nMREQ = '0') or (CPU_nWR = '0' and CPU_nIORQ = '0' and CPU_A(7 downto 0) = x"90")) else 
					'1';
	vram_dina <= CPU_DO;
	
	-- Write into char ram
--	cram_address <= CPU_A - x"4C80";
--	cram_dina <= CPU_DO;
--	cram_wea <= '0' when (CPU_A >= x"4C80" and CPU_A < x"5480" and CPU_nWR = '0' and CPU_nMREQ = '0') else '1';
	
	-- Write into RAM
	ram_addr 	<= CPU_A(13 downto 0);
	ram_din 	<= CPU_DO;
	ram_wea 	<= CPU_nWR or CPU_nMREQ when CPU_A(15) = '1' and CPU_A(14) = '0';
		
	-- SRAM control signals
	SRAM_ADDR	<= page_reg(4 downto 0) & CPU_A(13 downto 0);
	SRAM_DQ  	<= CPU_DO when CPU_nWR = '0' and CPU_nMREQ = '0' and CPU_A(15 downto 14) = "11" else (others => 'Z');
	SRAM_nWE 	<= CPU_nWR or CPU_nMREQ when CPU_A(15 downto 14) = "11";
	SRAM_nOE	<= CPU_nRD or CPU_nMREQ when CPU_A(15 downto 14) = "11";
	SRAM_nCE0	<= '0';
	SRAM_nCE1	<= '1';

	port_reg <= PS2_KBDAT & PS2_KBCLK & PS2_MSDAT & PS2_MSCLK & clk1hz & "000"; 
	
	-- Input to Z80
	CPU_DI <= D_ROM when (CPU_nRD = '0' and CPU_nMREQ = '0' and CPU_nIORQ = '1' and CPU_A(15 downto 14) = "00") else
			--vram_douta when (CPU_nMREQ = '0' and CPU_nIORQ = '1' and CPU_nRD = '0' and CPU_A < x"4C80") else
			--cram_douta when (CPU_nMREQ = '0' and CPU_nIORQ = '1' and CPU_nRD = '0' and CPU_A < x"5480") else
			ram_dout when (CPU_nRD = '0' and CPU_nMREQ = '0' and CPU_nIORQ = '1' and CPU_A(15 downto 14) = "10") else
			page_reg when (CPU_nIORQ = '0' and CPU_nMREQ = '1' and CPU_nRD = '0' and CPU_A(7 downto 0) = x"70") else			
			port_reg when (CPU_nIORQ = '0' and CPU_nMREQ = '1' and CPU_nRD = '0' and CPU_A(7 downto 0) = x"71") else			
			ps2_ascii_reg when (CPU_nIORQ = '0' and CPU_nMREQ = '1' and CPU_nRD = '0' and CPU_A(7 downto 0) = x"80") else
			("0" & CURSOR_X) when (CPU_nIORQ = '0' and CPU_nMREQ = '1' and CPU_nRD = '0' and CPU_A(7 downto 0) = x"91") else
			("00" & CURSOR_Y) when (CPU_nIORQ = '0' and CPU_nMREQ = '1' and CPU_nRD = '0' and CPU_A(7 downto 0) = x"92") else
			SRAM_DQ when (CPU_nRD = '0' and CPU_nMREQ = '0' and CPU_nIORQ = '1' and CPU_A(15 downto 14) = "11") else
			"ZZZZZZZZ";
		
	-- the following three processes deals with different clock domain signals
	ps2_process1: process(CLOCK_50)
	begin
		if CLOCK_50'event and CLOCK_50 = '1' then
			if ps2_read = '1' then
				if ps2_ascii_sig /= x"FF" then
					ps2_read <= '0';
					ps2_ascii_reg1 <= "00000000";
				end if;
			elsif ps2_scan_ready = '1' then
				if ps2_ascii_sig = x"FF" then
					ps2_read <= '1';
				else
					ps2_ascii_reg1 <= ps2_ascii_sig;
				end if;
			end if;
		end if;
	end process;
	
	ps2_process2: process(CPU_CLK)
	begin
		if CPU_CLK'event and CPU_CLK = '1' then
			ps2_ascii_reg <= ps2_ascii_reg1;
		end if;
	end process;
	
	port_process: process(CPU_CLK)
	begin
		if CPU_CLK'event and CPU_CLK = '1' then
		  if CPU_nIORQ = '0' and CPU_nMREQ = '1' and CPU_nWr = '0' then
			-- reg pages
			if CPU_A(7 downto 0) = x"70" then
				page_reg <= CPU_DO;	
			elsif CPU_A(7 downto 0) = x"72" then
				page_reg <= CPU_DO;	
			end if;
		  end if;
		end if;	
	end process;
			
	cursorxy: process (CPU_CLK)
	variable VID_X	: std_logic_vector(6 downto 0);
	variable VID_Y	: std_logic_vector(5 downto 0);
	begin
		if CPU_CLK'event and CPU_CLK = '1' then
			if (CPU_nIORQ = '0' and CPU_nMREQ = '1' and CPU_nWR = '0' and CPU_A(7 downto 0) = x"91") then
				VID_X := CPU_DO(6 downto 0);
			elsif (CPU_nIORQ = '0' and CPU_nMREQ = '1' and CPU_nWR = '0' and CPU_A(7 downto 0) = x"92") then
				VID_Y := CPU_DO(5 downto 0);
			elsif (CPU_nIORQ = '0' and CPU_nMREQ = '1' and CPU_nWR = '0' and CPU_A(7 downto 0) = x"90") then
				if VID_X = 40 - 1 then
					VID_X := "0000000";
					if VID_Y = 30 - 1 then
						VID_Y := "000000";
					else
						VID_Y := VID_Y + 1;
					end if;
				else
					VID_X := VID_X + 1;
				end if;
			end if;
		end if;
		VID_CURSOR <= x"4000" + ( VID_X + ( VID_Y * conv_std_logic_vector(40,7)));
		CURSOR_X <= VID_X;
		CURSOR_Y <= VID_Y;
	end process;
		
	One <= '1';
	z80_inst: T80se
		port map (
			M1_n 	=> open,
			MREQ_n 	=> CPU_nMREQ,
			IORQ_n 	=> CPU_nIORQ,
			RD_n 	=> CPU_nRD,
			WR_n 	=> CPU_nWR,
			RFSH_n 	=> CPU_nRFSH,
			HALT_n 	=> open,
			WAIT_n 	=> One,
			INT_n 	=> One,
			NMI_n 	=> One,
			RESET_n => CPU_nRESET,
			BUSRQ_n => One,
			BUSAK_n => open,
			CLK_n 	=> CPU_CLK,
			CLKEN 	=> One,
			A		=> CPU_A,
			DI 		=> CPU_DI,
			DO 		=> CPU_DO
		);

	video_inst: video port map (
			CLOCK_25		=> clk25mhz,
			VRAM_DATA		=> vram_doutb,
			VRAM_ADDR		=> vram_addrb(12 downto 0),
			VRAM_CLOCK		=> vram_clkb,
			VRAM_WREN		=> vram_web,
			CRAM_DATA		=> cram_doutb,
			CRAM_ADDR		=> cram_addrb(10 downto 0),
			CRAM_WEB		=> cram_web,
			VGA_R			=> VGA_R,
			VGA_G			=> VGA_G,
			VGA_B			=> VGA_B,
			VGA_HS			=> VGA_HS,
			VGA_VS			=> VGA_VS
	);

	vram : vram3200x8
		port map (
		rdclock	 	=> vram_clkb,
		wrclock 	=> CPU_CLK,	
		wren	 	=> not vram_wea,
		wraddress	=> vram_address(12 downto 0),
		rdaddress	=> vram_addrb(12 downto 0),
		data	 	=> vram_dina,
		q	 		=> vram_doutb
	);

	cram: charram2k
		port map (	
		rdaddress	=> cram_addrb(10 downto 0),
		wraddress	=> cram_address(10 downto 0),
		wrclock		=> CPU_CLK,
		rdclock		=> vram_clkb,
		data		=> cram_dina,
		q			=> cram_doutb,
		wren		=> NOT cram_wea		
	);
	
	ram : sram
		port map (
			clock 		=> CPU_CLK,
			data 		=> ram_din,
			address 	=> ram_addr(13 downto 0),
			wren 		=> NOT ram_wea,
			q 			=> ram_dout);
			
	rom_inst: rom
		port map (
			clock	=> CPU_CLK,
			address	=> CPU_A(9 downto 0),
			q	 	=> D_ROM
		);

	-- PLL below is used to generate the pixel clock frequency
	-- Uses 50Mhz clock for PLL's input clock
	video_PLL_inst: video_PLL 
	port map (
		inclk0	=> CLOCK_50,
		c0		=> clk25mhz,
		c1		=> CPU_CLK
	);

	clkdiv_inst: clk_div
	port map (
		clock_25Mhz				=> clk25mhz,
		clock_1MHz				=> open,
		clock_100KHz			=> open,
		clock_10KHz				=> open,
		clock_1KHz				=> open,
		clock_100Hz				=> clk100hz,
		clock_10Hz				=> clk10hz,
		clock_1Hz				=> clk1hz
	);
		
	clock_z80_inst : Clock_357Mhz
		port map (
			clock_50Mhz		=> CLOCK_50,
			clock_357Mhz	=> clk_x_mhz --CPU_CLK
	);

	ps2_kbd_inst : ps2kbd PORT MAP (
		keyboard_clk	=> PS2_KBCLK,
		keyboard_data	=> PS2_KBDAT,
		clock			=> CLOCK_50,
		clkdelay		=> clk100hz,
		reset			=> CPU_nRESET,
		read			=> ps2_read,
		scan_ready		=> ps2_scan_ready,
		ps2_ascii_code	=> ps2_ascii_sig
	);

end;