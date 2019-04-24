-----------------------------------------------------------------[Rev.20110803]
-- Text Mode
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity vgatxt is
port (
	RESET		: in std_logic;							-- reset
	CLOCK		: in std_logic; 						-- VGA dot clock
	A			: out std_logic_vector(13 downto 0); 	-- address to video RAM 16K
	DI			: in std_logic_vector(7 downto 0); 		-- data from video RAM
	R			: out std_logic_vector(1 downto 0); 	-- red color
	G			: out std_logic_vector(1 downto 0); 	-- green color
	B			: out std_logic_vector(1 downto 0); 	-- blue color
	HSYNC		: out std_logic;						-- horizontal (line) sync
	VSYNC		: out std_logic 						-- vertical (frame) sync
	);
end vgatxt;

architecture rtl of vgatxt is
signal hcnt		: std_logic_vector(10 downto 0); 	-- horizontal pixel counter
signal vcnt		: std_logic_vector(9 downto 0); 	-- vertical line counter
signal text_reg	: std_logic_vector(7 downto 0); 	-- byte register
signal color_reg: std_logic_vector(7 downto 0); 	-- byte register
signal font_reg	: std_logic_vector(7 downto 0); 	-- byte register
signal c_reg	: std_logic_vector(7 downto 0); 	-- byte register
signal f_reg	: std_logic_vector(7 downto 0); 	-- byte register
signal blank	: std_logic; 						-- video blanking signal
signal pblank	: std_logic; 						-- pipelined video blanking signal
signal dot		: std_logic;
signal hs		: std_logic;

begin
process(CLOCK, RESET)
begin
	-- reset asynchronously clears pixel counter
	if (RESET = '1') then
		hcnt <= "00000000000";
	-- horiz. pixel counter increments on rising edge of dot clock
	elsif (CLOCK'event and CLOCK = '0') then
		-- horiz. pixel counter rolls-over after pixels
		if (hcnt = 1344) then
			hcnt <= "00000000000";
		else
			hcnt <= hcnt + 1;
		end if;
	end if;
end process;

process(hs, RESET)
begin
	-- reset asynchronously clears line counter
	if (RESET = '1') then
		vcnt <= "0000000000";
	-- vert. line counter increments after every horiz. line
	elsif (hs'event and hs = '0') then
		-- vert. line counter rolls-over after lines
		if (vcnt = 806) then
			vcnt <= "0000000000";
		else
			vcnt <= vcnt + 1;
		end if;
	end if;
end process;

process(CLOCK, RESET, hcnt)
begin
	-- reset asynchronously sets horizontal sync to inactive
	if (RESET = '1') then
		hs <= '1';
	-- horizontal sync is recomputed on the rising edge of every dot clock
	elsif (CLOCK'event and CLOCK = '1') then
		-- horiz. sync low in this interval to signal start of new line
		if (hcnt = 1056) then hs <= '0';
		elsif (hcnt = 1192) then hs <= '1';
		end if;
	end if;
end process;

process(hs, RESET, vcnt)
begin
	-- reset asynchronously sets vertical sync to inactive
	if (RESET = '1') then
		VSYNC <= '1';
	-- vertical sync is recomputed at the end of every line of pixels
	elsif (hs'event and hs = '1') then
		-- vert. sync low in this interval to signal start of a new frame
		if (vcnt = 771) then VSYNC <= '0';
		elsif (vcnt = 777) then	VSYNC <= '1';
		end if;
	end if;
end process;

-- blank video outside of visible region
blank <= '1' when (hcnt > 1031 or hcnt < 8 or vcnt > 767) else '0';

-- store the blanking signal for use in the next pipeline stage
F: process(CLOCK, RESET)
begin
	if (RESET = '1') then
		pblank <= '0';
	elsif (CLOCK'event and CLOCK = '1') then
		pblank <= blank;
	end if;
end process;

-- video RAM control signals
process (vcnt, hcnt, text_reg)
begin
	if hcnt(0) = '1' then
		A <= vcnt(9 downto 4) & hcnt(9 downto 2);	-- Char address
	else
		A <= "11" & text_reg & vcnt(3 downto 0);	-- Font address
	end if;	
end process;

process(CLOCK, hcnt)
begin
	if hcnt(2 downto 0) = "000" then
		if (CLOCK'event and CLOCK = '0') then
			c_reg <= color_reg;
			f_reg <= font_reg;
		end if;
 end if;
end process;

process(CLOCK, hcnt)
begin
	if (hcnt(2 downto 0) = "101") then
		if (CLOCK'event and CLOCK = '1') then
			color_reg <= "01001111";
		end if;
	end if;
end process;

process(CLOCK, hcnt)
begin
	if (hcnt(2 downto 0) = "011") then
		if (CLOCK'event and CLOCK = '1') then
			text_reg <= "00110000";
		end if;
	end if;
end process;

process(CLOCK, hcnt)
begin
	if (hcnt(2 downto 0) = "110") then
		if (CLOCK'event and CLOCK = '1') then
			font_reg <= DI;
		end if;
	end if;
end process;

process (hcnt, f_reg)	
begin
	case hcnt(2 downto 0) is
		when "000" => dot <= f_reg(0); 
		when "001" => dot <= f_reg(7);
		when "010" => dot <= f_reg(6);
		when "011" => dot <= f_reg(5);
		when "100" => dot <= f_reg(4);
		when "101" => dot <= f_reg(3);
		when "110" => dot <= f_reg(2);
		when "111" => dot <= f_reg(1);
	end case;
end process;

process(CLOCK, RESET)
begin
	-- blank the video on reset
	if (RESET = '1') then
		R <= "00";
		G <= "00";
		B <= "00";
	-- update the color outputs on every dot clock
	elsif (CLOCK'event and CLOCK = '1') then
		-- map the pixel to a color if the video is not blanked
		if (pblank = '0') then
			if dot = '0' then
				B <= c_reg(3) & (c_reg(3) and c_reg(6));
				R <= c_reg(4) & (c_reg(4) and c_reg(6));
				G <= c_reg(5) & (c_reg(5) and c_reg(6));
			else
				B <= c_reg(0) & (c_reg(0) and c_reg(6));
				R <= c_reg(1) & (c_reg(1) and c_reg(6));
				G <= c_reg(2) & (c_reg(2) and c_reg(6));
			end if;
		-- otherwise, output black if the video is blanked
		else
			R <= "00"; -- black
			G <= "00"; -- black
			B <= "00"; -- black
		end if;
	end if;
end process;

HSYNC <= hs;
end rtl;