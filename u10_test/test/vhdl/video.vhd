library IEEE; 
use  IEEE.STD_LOGIC_1164.all; 
use  IEEE.STD_LOGIC_ARITH.all;
use  IEEE.STD_LOGIC_UNSIGNED.all;
 
ENTITY video is
	PORT(	CLOCK_25		: IN STD_LOGIC;
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
END video;

ARCHITECTURE A OF video IS

    use work.z80soc_pack.all;
	
	-- Added for VDU support
	signal Clock_video			: std_logic;
	signal VGA_R_sig			: std_logic_vector(2 downto 0);
	signal VGA_G_sig			: std_logic_vector(2 downto 0);
	signal VGA_B_sig			: std_logic_vector(2 downto 0);
	signal pixel_row_sig		: std_logic_vector(9 downto 0);
	signal pixel_column_sig		: std_logic_vector(9 downto 0);
	signal pixel_clock_sig		: std_logic;
	signal char_addr_sig		: std_logic_vector(7 downto 0);
	signal font_row_sig			: std_logic_vector(2 downto 0);
	signal font_col_sig			: std_logic_vector(2 downto 0);
	signal pixel_sig			: std_logic;
	signal video_on_sig			: std_logic;
	
	constant sv1				: integer := 3 + pixelsxchar - 1;
	constant sv2				: integer := 9 + pixelsxchar - 1;
	constant cv1				: integer := 0 + pixelsxchar - 1;
	constant cv2				: integer := 2 + pixelsxchar - 1;
	signal fix					: integer;
		
COMPONENT VGA_SYNC
	PORT(	clock_25Mhz		: IN 	STD_LOGIC;
			red				: IN	STD_LOGIC_VECTOR(2 DOWNTO 0);
			green			: IN	STD_LOGIC_VECTOR(2 DOWNTO 0);				
			blue			: IN	STD_LOGIC_VECTOR(2 DOWNTO 0);
			red_out			: OUT	STD_LOGIC_VECTOR(2 DOWNTO 0);
			green_out		: OUT	STD_LOGIC_VECTOR(2 DOWNTO 0);
			blue_out		: OUT	STD_LOGIC_VECTOR(2 DOWNTO 0);
			horiz_sync_out,
			vert_sync_out, 
			video_on,
			pixel_clock		: OUT	STD_LOGIC;
			pixel_row,
			pixel_column	: OUT 	STD_LOGIC_VECTOR(9 DOWNTO 0));
END COMPONENT;
	
BEGIN
	
	VGA_R_sig <= pixel_sig & pixel_sig & '0';
	VGA_G_sig <= pixel_sig & pixel_sig & pixel_sig;
	VGA_B_sig <= pixel_sig & pixel_sig & '0'; --- "000";
	
	-- Fonts ROM read
	VRAM_WREN  <= '1';
	VRAM_CLOCK <= pixel_clock_sig;
	VRAM_ADDR  <= pixel_row_sig(sv2 - 1 downto sv1) * conv_std_logic_vector(vid_cols,7) + pixel_column_sig(sv2 downto sv1);

	-- Fonts RAM read
	CRAM_WEB  <= '1';
	CRAM_ADDR <= VRAM_DATA & pixel_row_sig(cv2 downto cv1);
	fix 	  <= 1 when pixelsxchar = 2 else 2;
	pixel_sig <= CRAM_DATA (CONV_INTEGER(NOT (pixel_column_sig(cv2 downto cv1) - fix)))  when 
	             ( (pixel_row_sig < (8 * 25)) and (pixel_column_sig < (8 * 40)) ) else 
                 '0';
	              	
	vga_sync_inst: VGA_SYNC 
		port map (
			clock_25Mhz			=> CLOCK_25,
			red					=> VGA_R_sig,
			green				=> VGA_G_sig,
			blue				=> VGA_B_sig,
			red_out				=> VGA_R,
			green_out			=> VGA_G,
			blue_out			=> VGA_B,
			horiz_sync_out		=> VGA_HS,
			vert_sync_out		=> VGA_VS,
			video_on			=> video_on_sig,
			pixel_clock			=> pixel_clock_sig,
			pixel_row			=> pixel_row_sig,
			pixel_column		=> pixel_column_sig
	);
		
END A;
