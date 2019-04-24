-----------------------------------------------------------------[Rev.20110720]
-- ZX Spectrum (Pentagon frame)
-------------------------------------------------------------------------------
 
library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;

entity zxscr is
	port (
		CLK		: in std_logic;
		INT		: out std_logic;
		BORDER	: in std_logic_vector(2 downto 0);
		A		: out std_logic_vector(12 downto 0);
		DI		: in std_logic_vector(7 downto 0);
		R		: out std_logic_vector(1 downto 0);
		G		: out std_logic_vector(1 downto 0);
		B		: out std_logic_vector(1 downto 0);
		HS		: out std_logic;
		VS		: out std_logic
	);
end entity;

architecture rtl of zxscr is
	signal hcnt					: std_logic_vector(8 downto 0);
	signal vcnt					: std_logic_vector(9 downto 0);
	signal hsync				: std_logic;
	signal vsync				: std_logic;
	signal screen				: std_logic;
	signal screen1				: std_logic;
	signal blank				: std_logic;
	signal flash				: std_logic_vector(4 downto 0);
	signal vid_0_reg			: std_logic_vector(7 downto 0);
	signal vid_1_reg			: std_logic_vector(7 downto 0);
	signal vid_b_reg			: std_logic_vector(7 downto 0);
	signal vid_c_reg			: std_logic_vector(7 downto 0);
	signal vid_dot				: std_logic;
	signal vid_int				: std_logic;
	signal vid_r, vid_rb		: std_logic;
	signal vid_g, vid_gb		: std_logic;
	signal vid_b, vid_bb		: std_logic;

begin

process (CLK, vcnt, hcnt)
begin
	if (CLK'event and CLK = '1') then
		if (vcnt(9 downto 1) = 239 and hcnt = 316) then 
			vid_int <= '1';
		else 
			vid_int <= '0'; 
		end if;
	end if;
end process;

process (vid_int, hcnt)
begin
	if (vid_int'event and vid_int = '1') then
		INT <= '0';
	end if;
	if hcnt = 388 then
		INT <='1';
	end if;
end process; 

process (CLK, hcnt)
begin
	if (CLK'event and CLK = '0') then
		if hcnt = 447 then
			hcnt <= "000000000";
		else
			hcnt <= hcnt + 1;
		end if;
	end if; 
end process; 

process (CLK, hcnt, vcnt)
begin
if (CLK'event and CLK = '0') then  
	if hcnt = 328 then 
		if vcnt(9 downto 1) = 311 then 
			vcnt(9 downto 1) <= "000000000";
		else
			vcnt <= vcnt + 1;
		end if;	
	end if;
end if;
end process;

process(CLK, hcnt)
begin
	if (CLK'event and CLK = '1') then
		if hcnt = 328 then hsync <= '0';
		elsif hcnt = 381 then hsync <= '1'; 
		end if;
	end if;
end process;

process (CLK, vcnt)
begin
	if (CLK'event and CLK = '1') then
		if vcnt(9 downto 1) = 256 then vsync <= '0';
		elsif vcnt(9 downto 1) = 260 then vsync <= '1'; 
		end if;
	end if;
end process;

process (CLK, hcnt, vcnt)	 
begin
	if (CLK'event and CLK = '1') then
		 if (hcnt > 301 and hcnt < 417) or (vcnt(9 downto 1) > 224 and vcnt(9 downto 1) < 285) then
			blank <= '1';
		else
			blank <= '0';
		end if;
	end if;
end process;

process (CLK, hcnt, vcnt)
begin
	if (CLK'event and CLK = '1') then
		if (hcnt < 256 and vcnt(9 downto 1) < 192) then
			screen <= '1';
		else 
			screen <= '0';
		end if;
	end if;
end process;

process (CLK, hcnt)
begin
	if hcnt(2 downto 0) = "100" then
		if (CLK'event and CLK = '1') then
			vid_0_reg <= DI;
		end if;
	end if;
end process;

process (CLK, hcnt)
begin
	if hcnt(2 downto 0) = "101" then
		if (CLK'event and CLK = '1') then
			vid_1_reg <= DI;
		end if;
	end if;
end process;

process (hcnt, CLK)	
begin
	if hcnt(2 downto 0) = "111" then
		if (CLK'event and CLK = '1') then
			vid_b_reg 	<= vid_0_reg;
			vid_c_reg 	<= vid_1_reg;
			screen1 	<= screen;
		end if;
 end if;
end process;

process (hcnt, vid_b_reg)	
begin
	case hcnt(2 downto 0) is
		when "000" => vid_dot <= vid_b_reg(7); 
		when "001" => vid_dot <= vid_b_reg(6);
		when "010" => vid_dot <= vid_b_reg(5);
		when "011" => vid_dot <= vid_b_reg(4);
		when "100" => vid_dot <= vid_b_reg(3);
		when "101" => vid_dot <= vid_b_reg(2);
		when "110" => vid_dot <= vid_b_reg(1);
		when "111" => vid_dot <= vid_b_reg(0);
	end case;
end process;

process (vcnt, hcnt)
begin
	if hcnt(0) = '0' then
		A <= vcnt(8 downto 7) & vcnt(3 downto 1) & vcnt(6 downto 4) & hcnt(7 downto 3);
	else
		A <= "110" & vcnt(8 downto 4) & hcnt(7 downto 3);
	end if;	
end process;

process(screen1, blank, hcnt, vid_dot, vid_c_reg, CLK, flash)
variable selector: std_logic_vector(2 downto 0);
begin
selector := vid_dot & flash(4) & vid_c_reg(7);
	if (CLK'event and CLK = '1') then
		if blank = '0' then
			if screen1 = '1' then
				case selector is
					when "000"!"010"!"011"!"101" => vid_b <= vid_c_reg(3);					
													vid_bb <= (vid_c_reg(3) and vid_c_reg(6));
													vid_r <= vid_c_reg(4);
													vid_rb <= (vid_c_reg(4) and vid_c_reg(6));
													vid_g <= vid_c_reg(5);
													vid_gb <= (vid_c_reg(5) and vid_c_reg(6));
					when "100"!"001"!"111"!"110" => vid_b <= vid_c_reg(0);
													vid_bb <= (vid_c_reg(0) and vid_c_reg(6));
													vid_r <= vid_c_reg(1);
													vid_rb <= (vid_c_reg(1) and vid_c_reg(6));
													vid_g <= vid_c_reg(2);
													vid_gb <= (vid_c_reg(2) and vid_c_reg(6));
				end case;                 
			else 
				vid_b <= BORDER(0);
				vid_r <= BORDER(1);
				vid_g <= BORDER(2);
				vid_rb <= '0';
				vid_gb <= '0';
				vid_bb <= '0'; 
			end if;
		else
			vid_b <= '0';
			vid_r <= '0';
			vid_g <= '0';
			vid_rb <= '0';
			vid_gb <= '0';
			vid_bb <= '0';
		end if;
	end if;  
end process; 

flash 	<= (flash + 1) when (vcnt(9)'event and vcnt(9) = '0');

R	<= vid_r & vid_rb;
G	<= vid_g & vid_gb;
B	<= vid_b & vid_bb;
HS	<= hsync;
VS	<= vsync;

end architecture;