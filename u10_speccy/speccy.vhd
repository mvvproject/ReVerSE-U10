library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.ALL;  

entity speccy is                    
port(
clk:		in std_logic;
r,g,b:      out std_logic;
rb,gb,bb:   out std_logic;
vsyn,hsyn:  out std_logic;
a:			out std_logic_vector(18 downto 0);
d:			inout std_logic_vector(7 downto 0);
ram_oe:     out std_logic;
ram_we:     out std_logic;
ram_ce:     out std_logic;
ps2_clk:  	in std_logic;
ps2_data:	in std_logic;
ps2_ms_clk: inout std_logic;
ps2_ms_dat: inout std_logic;
ay_outA:	buffer std_logic;
ay_outB:	buffer std_logic;
tape_in:	in std_logic;
tape_out:	out std_logic;
sd_clk:		out std_logic;
sd_di:		in std_logic;
sd_do:		out std_logic;
sd_cs:		out std_logic
);
end speccy;

architecture speccy_arch of speccy is

component T80s is
	generic(
		Mode : integer := 0;	-- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
		T2Write : integer := 0;	-- 0 => WR_n active in T3, /=0 => WR_n active in T2
		IOWait : integer := 1	-- 0 => Single cycle I/O, 1 => Std I/O cycle
	);
	port(
		RESET_n		: in std_logic;
		CLK_n		: in std_logic;
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
		DO			: out std_logic_vector(7 downto 0);
		RestorePC_n : in std_logic
	);
end component;

component zxkbd is
 port(
   clk            :in std_logic;
   reset          :in std_logic;
   res_k          :out std_logic;
   f			  :out std_logic_vector(12 downto 1);   
   ps2_clk        :in std_logic;
   ps2_data       :in std_logic;
   zx_kb_scan     :in std_logic_vector(7 downto 0);
   zx_kb_out      :out std_logic_vector(4 downto 0);
   k_joy		  :out std_logic_vector(4 downto 0); 
   num_joy        :out std_logic  
);
end component;

component io_ps2_mouse is
	generic (
		clockFilter 	: integer := 15;
		ticksPerUsec 	: integer := 28   -- 33 Mhz clock
	);
	port (
		clk				: in std_logic;
		ps2_clk_in		: in std_logic;
		ps2_dat_in		: in std_logic;
		ps2_clk_out		: out std_logic;
		ps2_dat_out		: out std_logic;
		
		mousePresent 	: out std_logic;
		
		leftButton 		: out std_logic;
		middleButton 	: out std_logic;
		rightButton 	: out std_logic;
		X 				: out std_logic_vector(7 downto 0);
		Y 				: out std_logic_vector(7 downto 0)
	);
end component;

component YM2149 is
  port (
  -- data bus
  I_DA                : in  std_logic_vector(7 downto 0);
  O_DA                : out std_logic_vector(7 downto 0);
  O_DA_OE_L           : out std_logic;
  -- control
  I_A9_L              : in  std_logic;
  I_A8                : in  std_logic;
  I_BDIR              : in  std_logic;
  I_BC2               : in  std_logic;
  I_BC1               : in  std_logic;
  I_SEL_L             : in  std_logic;

  O_AUDIO             : out std_logic_vector(7 downto 0);
  
  O_AUDIO_A           : out std_logic_vector(7 downto 0);
  O_AUDIO_B           : out std_logic_vector(7 downto 0);
  O_AUDIO_C           : out std_logic_vector(7 downto 0);


  -- port a
  I_IOA               : in  std_logic_vector(7 downto 0);
  O_IOA               : out std_logic_vector(7 downto 0);
  O_IOA_OE_L          : out std_logic;
  -- port b
  I_IOB               : in  std_logic_vector(7 downto 0);
  O_IOB               : out std_logic_vector(7 downto 0);
  O_IOB_OE_L          : out std_logic;
  --
  ENA                 : in  std_logic; -- clock enable for higher speed operation
  RESET_L             : in  std_logic;
  CLK                 : in  std_logic  -- actually 1.75 Mhz
  );
end component;

component ZCSPI is
port(
--INPUTS
DIN		: in std_logic_vector(7 downto 0);
nRD     : in std_logic;
nWR     : in std_logic;
nIORQ   : in std_logic;
nRES    : in std_logic;
CLC     : in std_logic;
A       : in std_logic_vector(7 downto 0);
MISO    : in std_logic;
--OUTPUTS
DOUT	: out std_logic_vector(7 downto 0);
nSDCS   : out std_logic;
SCK     : out std_logic;
MOSI    : out std_logic;
ZC_PORTS_READ	: out std_logic
);
end component;

component altpll0 is
port
(
	inclk0		: IN STD_LOGIC;
	c0			: OUT STD_LOGIC;
	c1			: OUT STD_LOGIC;
	c2			: OUT STD_LOGIC 
);
end component;

component lpm_ram_dp0 is
port
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (5 DOWNTO 0);
		rdaddress	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wraddress	: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
		wren		: IN STD_LOGIC  := '1';
		q			: OUT STD_LOGIC_VECTOR (5 DOWNTO 0)
	);
end component;

component lpm_rom1 is
port
(
	address		: IN STD_LOGIC_VECTOR (11 DOWNTO 0);
	clock		: IN STD_LOGIC  := '1';
	q			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
);
end component;

signal clock:			std_logic;
signal hcnt:       		std_logic_vector(8 downto 0);
signal scan_cnt:		std_logic_vector(10 downto 0);
signal vcnt:       		std_logic_vector(8 downto 0);
signal hsync,vsync: 	std_logic;
signal blank,screen:	std_logic;
signal screen1:         std_logic;
signal sel,vid:			std_logic;
signal del:				std_logic_vector(1 downto 0);
signal vidb,vidc:		std_logic_vector(7 downto 0);
signal vid0,vid1:		std_logic_vector(7 downto 0);
signal mreq_n:			std_logic;
signal iorq_n:          std_logic;
signal m1_n:        	std_logic;
signal wr_n,rd_n:		std_logic;
signal a_buff:			std_logic_vector(15 downto 0);
signal dataI:			std_logic_vector(7 downto 0);
signal dataO:			std_logic_vector(7 downto 0);
signal rom_d:			std_logic_vector(7 downto 0);
signal romsel:			std_logic;
signal int_n:			std_logic;
signal pfe:				std_logic_vector(7 downto 0);
signal csfe:			std_logic;
signal cskb:			std_logic;
signal res_n,res_key:	std_logic;
signal ka:             	std_logic_vector(7 downto 0);
signal kb:             	std_logic_vector(4 downto 0);
signal flash:      		std_logic_vector(4 downto 0);
signal p7ffd:	    	std_logic_vector(7 downto 0);
signal cs7ffd:		  	std_logic;
signal p1ffd:	    	std_logic;
signal cs1ffd:		  	std_logic;
signal adr_m:			std_logic_vector(4 downto 0);
signal dac_regA:     	std_logic_vector(7 downto 0);
signal dac_regB:     	std_logic_vector(7 downto 0);
signal dac_regC:     	std_logic_vector(7 downto 0);
signal dac_cntA:     	std_logic_vector(7 downto 0);
signal dac_cntB:     	std_logic_vector(7 downto 0);
signal dac_cntC:     	std_logic_vector(7 downto 0);
signal dac_bufA:     	std_logic_vector(7 downto 0);
signal dac_bufB:     	std_logic_vector(7 downto 0);
signal dac_bufC:     	std_logic_vector(7 downto 0);
signal dac_regD:     	std_logic_vector(7 downto 0);
signal dac_regE:     	std_logic_vector(7 downto 0);
signal dac_regF:     	std_logic_vector(7 downto 0);
signal dac_cntD:     	std_logic_vector(7 downto 0);
signal dac_cntE:     	std_logic_vector(7 downto 0);
signal dac_cntF:     	std_logic_vector(7 downto 0);
signal dac_bufD:     	std_logic_vector(7 downto 0);
signal dac_bufE:     	std_logic_vector(7 downto 0);
signal dac_bufF:     	std_logic_vector(7 downto 0);
signal dac_regSa:     	std_logic_vector(7 downto 0);
signal dac_cntSa:     	std_logic_vector(7 downto 0);
signal dac_bufSa:     	std_logic_vector(7 downto 0);
signal dac_regSb:     	std_logic_vector(7 downto 0);
signal dac_cntSb:     	std_logic_vector(7 downto 0);
signal dac_bufSb:     	std_logic_vector(7 downto 0);
signal dac_regsound:   	std_logic_vector(7 downto 0);
signal dac_cntsound:    std_logic_vector(7 downto 0);
signal dac_bufsound:    std_logic_vector(7 downto 0);
signal ayBC1:       	std_logic;
signal ayBDIR:      	std_logic;
signal ayBC1a:       	std_logic;
signal ayBDIRa:      	std_logic;
signal ayBC1b:       	std_logic;
signal ayBDIRb:      	std_logic;
signal ay_clk:			std_logic;
signal sd_read:			std_logic;
signal z_data:			std_logic_vector(7 downto 0);
signal sd_dout,sd_din:	std_logic_vector(7 downto 0);
signal sd_boot:         std_logic;
signal dos:            	std_logic;
signal ramm1:          	std_logic;
signal dos_win:        	std_logic;
signal csfd:			std_logic;
signal ay_data:			std_logic_vector(7 downto 0);
signal ay_databuff:		std_logic_vector(7 downto 0);
signal ay_databuff1:	std_logic_vector(7 downto 0);
signal delmux:			std_logic_vector(2 downto 0);
signal interr:			std_logic;
signal turbo_reg:		std_logic;
signal cpu_clk:			std_logic;
signal button:			std_logic_vector(2 downto 0);
signal mouse_clk_out:   std_logic;
signal mouse_dat_out:	std_logic;
signal csms:			std_logic;
signal present:         std_logic;
signal cs_b,cs_x,cs_y: 	std_logic;
signal mouse_x,mouse_y:	std_logic_vector(7 downto 0);
signal kempston:		std_logic_vector(4 downto 0);
signal numlock,cs_joy:	std_logic;
signal left_hand:		std_logic;
signal left_joy:		std_logic;
signal to_scan:			std_logic_vector(5 downto 0);
signal from_scan:		std_logic_vector(5 downto 0);
signal scan_page:		std_logic;
signal ram_clk:			std_logic;
signal ay_ouA:		 	std_logic;
signal ay_ouB:		 	std_logic;
signal ay_ouC:			std_logic;
signal ay_ouD:		 	std_logic;
signal ay_ouE:		 	std_logic;
signal ay_ouF:			std_logic;
signal SOUNDRIVEa:		std_logic;
signal SOUNDRIVEb:		std_logic;
signal sound:		    std_logic;
signal trst:		    std_logic;
signal csts:		    std_logic;
signal csSOUNDRIVE:		std_logic;
signal sodr:			std_logic;
signal sodra:			std_logic;
signal sodrb:			std_logic;
signal cova:			std_logic;
signal covb:			std_logic;
signal mux:			std_logic;
signal video_mode:		std_logic;
signal vpix:			std_logic_vector(8 downto 0);
signal f:				std_logic_vector(12 downto 1);
signal sd_switch:		std_logic;

begin

process(clock,del)
begin
if (clock'event and clock='0') then
 del<=del+1;
end if;
end process;

process(ram_clk,del,delmux)
begin
if (ram_clk'event and ram_clk='0') then
 delmux<=delmux+1;
end if;
end process; 

process(clock,hcnt,scan_cnt)
begin
if (clock'event and clock='0') then
 if scan_cnt(8 downto 0)=447 then
  scan_cnt(8 downto 0)<="000000000";
 else
  scan_cnt<=scan_cnt+1;
 end if;
 if scan_cnt(8 downto 0)=328 then
  scan_cnt(10 downto 9)<=scan_cnt(10 downto 9)+1;
 end if; 
end if; 
end process;

process(del,hcnt)
begin
if (del(0)'event and del(0)='1') then
 if hcnt=447 then
  hcnt<="000000000";
 else
  hcnt<=hcnt+1;
 end if;
end if; 
end process;   

process(del,hcnt,vcnt,scan_page,vpix)
begin
if (del(0)'event and del(0)='0') then  
 if hcnt=328 then
 scan_page<=not(scan_page);
 if vcnt(8 downto 0)=vpix then   
  vcnt(8 downto 0)<="000000000";
 else
  vcnt<=vcnt+1;
 end if;
 end if;
end if;
end process;

vpix<="10011" & not(video_mode) & "111";

process(interr,hcnt,turbo_reg)
begin
if (interr'event and interr='1') then
 int_n<='0';
end if;
 if ((hcnt=388 and turbo_reg='0') or (hcnt=352 and turbo_reg='1')) then
 int_n<='1';
end if;
end process;  

process(clock,vcnt,hcnt,video_mode)
begin
if (clock'event and clock='1') then
 if (vcnt=("111" & video_mode & not(video_mode) & "111") and hcnt=316) then -- Pentagono - 239, 316
  interr<='1';
 else 
  interr<='0'; 
 end if;
end if;
end process;

process(f(9))
begin
 if (f(9)'event and f(9)='1') then
  turbo_reg<=not(turbo_reg);
 end if;
end process; 

process(clock,turbo_reg,del)
begin
if (clock'event and clock='0') then
 if turbo_reg='0' then
  cpu_clk<=(del(1));
 else 
  cpu_clk<=(del(0));
 end if;
end if; 
end process;  

---------------------------------DOS--------------------------------------------------------------------
ramm1<='1' when (m1_n='0' and romsel='0' and rd_n='0' and mreq_n='0') else '0';
dos_win<='1' when (a_buff(13 downto 8)="111101" and m1_n='0' and p7ffd(4)='1' and romsel='1') else '0';

process(clock,res_n,dos_win,ramm1)
begin
if (clock'event and clock='0') then
 if (res_n='0') then
  dos<='0';
 else 
  if (ramm1='1') then
   dos<='0';
  end if;
  if (dos_win='1') then
   dos<='1';
  end if;
 end if;
end if; 
end process;

------------------------------Video system section--------------------------------------------------------
process(clock,sel,d,hcnt)
begin
if sel='1' then
 if (clock'event and clock='0') then
  vid0<=d;
 end if;
end if;
end process;

process(clock,sel,d,hcnt)
begin
if sel='1' then
 if (clock'event and clock='1') then
  vid1<=d;
 end if;
end if;
end process;

process(hcnt,del,vid0,vid1)    --Prepare videodata for mux--
begin
 if hcnt(2 downto 0)="111" then
  if (del(0)'event and del(0)='1') then
   vidb<=vid0;
   vidc<=vid1;
   screen1<=screen;
  end if;
 end if;
end process;

process(hcnt,vidb)   --Video data shift registers--
begin
case hcnt(2 downto 0) is
 when "000"=>vid<=vidb(7); 
 when "001"=>vid<=vidb(6);
 when "010"=>vid<=vidb(5);
 when "011"=>vid<=vidb(4);
 when "100"=>vid<=vidb(3);
 when "101"=>vid<=vidb(2);
 when "110"=>vid<=vidb(1);
 when "111"=>vid<=vidb(0);
end case;
end process;

process(scan_cnt,clock)                   --Horizontal sync--
begin
if (clock'event and clock='1') then                          
 if (scan_cnt(8 downto 0)=328) then hsync<='0';
  elsif (scan_cnt(8 downto 0)=381) then hsync<='1'; 
 end if;
end if; 
end process;

process(del,vcnt)                     		--Vertical sync--
begin
if (del(0)'event and del(0)='1') then
 if vcnt(8 downto 0)=256 then vsync<='0';
  elsif vcnt(8 downto 0)=260 then vsync<='1';
 end if;
end if;
end process;

process(hcnt,vcnt,del)							--Blank-- 
begin
if (del(0)'event and del(0)='1') then
 if (hcnt<301 or hcnt>417) and (vcnt(8 downto 0)<224 or vcnt(8 downto 0)>285) then
  blank<='1';
 else
  blank<='0';
 end if;
end if;
end process;

process(hcnt,vcnt,del)
begin
if (del(0)'event and del(0)='1') then
 if (hcnt<256 and vcnt(8 downto 0)<192) then
  screen<='1';
 else 
  screen<='0';
 end if;
end if;
end process;   

hsyn<='0' when hsync='0' else '1';
vsyn<='0' when vsync='0' else '1';

process(screen1,blank,hcnt,vid,vidc,pfe,flash,del)
variable selector: std_logic_vector(2 downto 0);
begin
selector:=vid & flash(4) & vidc(7);
if (del(0)'event and del(0)='0') then
 if blank='1' then
  if screen1='1' then
   case selector is
    when "000"!"010"!"011"!"101"=>to_scan(3)<=vidc(3);					
							      to_scan(0)<=(vidc(3) and vidc(6));
                                  to_scan(5)<=vidc(4);
                                  to_scan(2)<=(vidc(4) and vidc(6));
                                  to_scan(4)<=vidc(5);
                                  to_scan(1)<=(vidc(5) and vidc(6));
    when "100"!"001"!"111"!"110"=>to_scan(3)<=vidc(0);
							      to_scan(0)<=(vidc(0) and vidc(6));
                                  to_scan(5)<=vidc(1);
                                  to_scan(2)<=(vidc(1) and vidc(6));
                                  to_scan(4)<=vidc(2);
                                  to_scan(1)<=(vidc(2) and vidc(6));
   end case;                 
 else 
  to_scan(3)<=pfe(0);
  to_scan(5)<=pfe(1);
  to_scan(4)<=pfe(2);
  to_scan(2)<='0';
  to_scan(1)<='0';
  to_scan(0)<='0'; 
 end if;
 else
  to_scan(3)<='0';
  to_scan(5)<='0';
  to_scan(4)<='0';
  to_scan(2)<='0';
  to_scan(1)<='0';
  to_scan(0)<='0';
 end if;
end if;  
end process; 

r<=from_scan(5);
g<=from_scan(4);
b<=from_scan(3);
rb<=from_scan(2);
gb<=from_scan(1);
bb<=from_scan(0);                                        

-------------------------------------------------------------------------------------------
ram_ce<='1' when (adr_m(4 downto 2)="111" and wr_n='0') else '0';
ram_we<='0' when (sel='0' and mreq_n='0' and wr_n='0' and (romsel='0' or sd_boot='0') and clock='1') else '1';
ram_oe<='0' when (sel='1' or (mreq_n='0' and rd_n='0')) else '1';
romsel<='1' when (a_buff(15 downto 14)="00" and mreq_n='0') else '0';
sel<='1' when (hcnt(2 downto 0)="100" and del(0)='0') else '0';
csfe<='1' when (cskb='1' and wr_n='0') else '0';
cskb<='1' when (a_buff(7 downto 0)="11111110" and iorq_n='0') else '0';
res_n<='0' when (res_key='1') else '1';
ka<=a_buff(15 downto 8) when (cskb='1') else "11111110";
flash<=(flash+1) when (vcnt(8)'event and vcnt(8)='0');
dac_regsound<="10000000" when pfe(4)='1' else "00000000";
csfd<='1' when (a_buff(7 downto 0)="11111101" and iorq_n='0' and wr_n='0') else '0';
cs7ffd<='1' when (a_buff(15 downto 12)="0111" and csfd='1') else '0';
cs1ffd<='1' when (a_buff(15 downto 12)="0001" and csfd='1') else '0';
tape_out<='1' when pfe(3)='1' else '0';
csms<='1' when (a_buff(15 downto 11)="11111" and a_buff(7 downto 0)="11011111" and iorq_n='0') else '0';
cs_b<='1' when (csms='1' and a_buff(10 downto 8)="010") else '0';
cs_x<='1' when (csms='1' and a_buff(10 downto 8)="011") else '0';
cs_y<='1' when (csms='1' and a_buff(10 downto 8)="111") else '0';
cs_joy<='1' when (a_buff(7 downto 0)="00011111" and iorq_n='0' and dos='0' and rd_n='0') else '0';
left_hand<=not(left_hand) when (button(1)'event and button(1)='1' and button(0)='1');
left_joy<=not(left_joy) when (kempston(0)'event and kempston(0)='1' and kempston(1)='1' and kempston(2)='1');
video_mode<=not(video_mode) when (f(12)'event and f(12)='1');
csts <= '0' when (dataO(7 downto 1) = "1111111" and ayBC1='1' and ayBDIR='1') else '1';
csSOUNDRIVE <= '0' when (a_buff(1)='1' and iorq_n='0' and wr_n='0' and m1_n = '1' and dos = '0') else '1';
sd_switch<=not(sd_switch) when (f(11)'event and f(11)='1');

process(clock,res_n,a_buff,iorq_n,wr_n)
begin
if (clock'event and clock='1') then
 if (res_n='0') then
  sd_boot<='0';
 elsif (a_buff(15 downto 0)=0 and m1_n='0') then
  sd_boot<='1';
 end if;
end if; 
end process;   

process(a_buff,p7ffd)
begin
case a_buff(15 downto 14) is
 when "00"=>adr_m<="00000";
 when "01"=>adr_m<="00101";
 when "10"=>adr_m<="00010";
 when "11"=>adr_m<=p7ffd(7) & p7ffd(6) & p7ffd(2 downto 0); ------ìàïïåð ÎÇÓ-------
end case; 
end process;

process(clock,res_n,dataO,cs7ffd,dos)
begin
if (clock'event and clock='1') then
 if (res_n='0') then
  p7ffd<="00000000";
   elsif (cs7ffd='1'and dos='1' and p7ffd(5)='0') then
  p7ffd<=dataO;
   elsif (cs7ffd='1'and dos='1' and p7ffd(5)='1') then
  p7ffd<=dataO(7 downto 6) & "1" & dataO(4 downto 0);
   elsif (cs7ffd='1' and p7ffd(5)='0' and dos='0') then
  p7ffd(5 downto 0)<=dataO(5 downto 0); 
 end if;
end if;
end process;

process(clock,res_n,dataO,cs1ffd)
begin
if (clock'event and clock='0') then
 if (res_n='0') then
  p1ffd<='0';
 elsif cs1ffd='1' then
  p1ffd<=dataO(1); 
 end if;
end if;
end process;

process(clock,dataO,csfe)
begin
if (clock'event and clock='1') then
if (csfe='1') then
 pfe<=dataO; 
end if;
end if;
end process;

---------------------------------------------Adress & Data---------------------------------------------------------

process(clock,sel,vcnt,hcnt,a_buff,adr_m,p7ffd,sd_boot,romsel,dos,p1ffd)
variable selector: std_logic_vector(1 downto 0);
begin
selector:=(sel & sd_boot);
case selector is
 when "11"!"10"=>case clock is
			      when '1'=>a<="001" & p7ffd(3) & "10" & vcnt(7 downto 6) & vcnt(2 downto 0)& vcnt(5 downto 3) & hcnt(7 downto 3);
			      when '0'=>a<="001" & p7ffd(3) & "10110" & vcnt(7 downto 3) & hcnt(7 downto 3);
		         end case;		    	
 when "01"=>case romsel is 
			 when '0'=>a<=adr_m & a_buff(13 downto 0);
			 when '1'=>a<="111" & (not(dos) and not(p1ffd)) & (p7ffd(4) and not(p1ffd)) & a_buff(13 downto 0);
			end case;
 when "00"=>a<="111" & a_buff(15 downto 0);			 
end case;
end process; 

process(clock,cskb,romsel,d,kb,rom_d,tape_in,sd_read,z_data,sd_boot,mreq_n,cs_b,cs_x,cs_y,cs_joy,left_hand,numlock,kempston,present)
begin
if (clock'event and clock='0') then
 if (sd_read='1') then
  dataI<=z_data;
 elsif (romsel='1' and sd_boot='0') then
  dataI<=rom_d;
 elsif cskb='1' then
  dataI<='1' & tape_in & '1' & kb;
 elsif (cs_b='1' and present='1' and left_hand='0') then
  dataI<="11111" & not(button);
 elsif (cs_b='1' and present='1' and left_hand='1') then
  dataI<="11111" & not(button(2) & button(0) & button(1));  
 elsif (cs_x='1' and present='1') then
  dataI<=mouse_x;
 elsif (cs_y='1' and present='1') then
  dataI<=mouse_y;
 elsif (cs_joy='1' and numlock='1' and left_joy='0') then
  dataI<="000" & kempston;    
 elsif (cs_joy='1' and numlock='1' and left_joy='1') then
  dataI<="000" & not kempston;      
 elsif mreq_n='0' then  
  dataI<=d;
 elsif (a_buff(15 downto 0)=65533 and iorq_n='0' and m1_n = '1') then
  dataI<=ay_data;  
 else
  dataI<="11111111"; 
 end if;
end if; 
end process;
 
process(sel,mreq_n,wr_n,dataO)
begin
 if sel='1' then
  d<="ZZZZZZZZ";
 elsif (mreq_n='0' and wr_n='0') then
  d<=dataO;
 else
  d<="ZZZZZZZZ";
 end if;
end process;  

-----------------------------------------------DAC & AY----------------------------------------------------------------
ayBC1 <= '1' when m1_n = '1' and iorq_n = '0' and a_buff(15 downto 14) = "11" and a_buff(1 downto 0) = "01" else '0';
ayBDIR <= '1' when m1_n = '1' and iorq_n = '0' and wr_n = '0' and a_buff(15) = '1' and a_buff(1 downto 0) = "01" else '0';   
ayBC1a <='1' when (ayBC1 = '1' and trst = '1')else '0';
ayBC1b <='1' when (ayBC1 = '1' and trst = '0')else '0';
ayBDIRa <='1' when (ayBDIR = '1' and trst = '1')else '0';
ayBDIRb <='1' when (ayBDIR = '1' and trst = '0')else '0';

cova <='1' when (a_buff(6 downto 5) = "00" and a_buff(2) ='1') else '0';
covb <='1' when (a_buff(6 downto 5) = "10" and a_buff(2) ='1') else '0';
sodra <='1' when (a_buff(3 downto 2) = "00") else '0';
sodrb <='1' when (a_buff(3 downto 2) = "10") else '0';


process(clock,dac_regSa,dac_regSb,sodra,csSOUNDRIVE,cova,covb)
begin
if ((clock'event and clock='1') ) then  
	if sodra = '1' and csSOUNDRIVE ='0' then
	dac_regSa <= dataO;
	elsif sodrb = '1' and csSOUNDRIVE ='0' then
	dac_regSb <= dataO;
	elsif cova = '1' and csSOUNDRIVE ='0' then
	dac_regSa <= dataO;
	elsif covb = '1' and csSOUNDRIVE ='0' then
	dac_regSb <= dataO;
 end if;
end if;
end process;

process(clock,trst,res_n,csts)
begin
if (res_n = '0') then
	trst <= '0';
	else
 if ((clock'event and clock='0') and csts = '0') then
	if dataO(0)='0'then
	trst <= '0';
	elsif dataO(0)='1'then
    trst <= '1';
   end if;
 end if;
end if;
end process;

process(clock,ay_databuff,ay_databuff1)
begin
if ((clock'event and clock='0') ) then 
	if trst = '1' then
	ay_data <= ay_databuff;
	elsif trst = '0' then
	ay_data <= ay_databuff1;
    end if;
end if;
end process;
 
process(clock,ram_clk,del,dac_bufA,dac_regA,dac_cntA,dac_bufB,dac_regB,dac_cntB)
begin
if ((ram_clk'event and ram_clk='0') ) then
 if (dac_cntA>0) then
  dac_cntA<=dac_cntA-1;
  if dac_bufA>0 then 
   dac_bufA<=dac_bufA-1;
   ay_ouA<='1'; 
  else
   ay_ouA<='0'; 
  end if;
 else
  dac_cntA<="11111111";
  dac_bufA<=dac_regA; 
 end if;
 
  if (dac_cntB>0) then
  dac_cntB<=dac_cntB-1;
  if dac_bufB>0 then 
   dac_bufB<=dac_bufB-1;
   ay_ouB<='1'; 
  else
   ay_ouB<='0'; 
  end if;
 else
  dac_cntB<="11111111";
  dac_bufB<=dac_regB; 
 end if;

  if (dac_cntC>0) then
  dac_cntC<=dac_cntC-1;
  if dac_bufC>0 then 
   dac_bufC<=dac_bufC-1;
   ay_ouC<='1'; 
  else
   ay_ouC<='0'; 
  end if;
 else
  dac_cntC<="11111111";
  dac_bufC<=dac_regC; 
 end if;
 
  if (dac_cntD>0) then
  dac_cntD<=dac_cntD-1;
  if dac_bufD>0 then 
   dac_bufD<=dac_bufD-1;
   ay_ouD<='1'; 
  else
   ay_ouD<='0'; 
  end if;
 else
  dac_cntD<="11111111";
  dac_bufD<=dac_regD; 
 end if;
 
  if (dac_cntE>0) then
  dac_cntE<=dac_cntE-1;
  if dac_bufE>0 then 
   dac_bufE<=dac_bufE-1;
   ay_ouE<='1'; 
  else
   ay_ouE<='0'; 
  end if;
 else
  dac_cntE<="11111111";
  dac_bufE<=dac_regE; 
 end if;

  if (dac_cntF>0) then
  dac_cntF<=dac_cntF-1;
  if dac_bufF>0 then 
   dac_bufF<=dac_bufF-1;
   ay_ouF<='1'; 
  else
   ay_ouF<='0'; 
  end if;
 else
  dac_cntF<="11111111";
  dac_bufF<=dac_regF; 
 end if;

  if (dac_cntSa>0) then
  dac_cntSa<=dac_cntSa-1;
  if dac_bufSa>0 then 
   dac_bufSa<=dac_bufSa-1;
   SOUNDRIVEa<='1'; 
  else
   SOUNDRIVEa<='0'; 
  end if;
 else
  dac_cntSa<="11111111";
  dac_bufSa<=dac_regSa; 
 end if;
 
  if (dac_cntSb>0) then
  dac_cntSb<=dac_cntSb-1;
  if dac_bufSb>0 then 
   dac_bufSb<=dac_bufSb-1;
   SOUNDRIVEb<='1'; 
  else
   SOUNDRIVEb<='0'; 
  end if;
 else
  dac_cntSb<="11111111";
  dac_bufSb<=dac_regSb; 
 end if;
 
  if (dac_cntsound>0) then
  dac_cntsound<=dac_cntsound-1;
  if dac_bufsound>0 then 
   dac_bufsound<=dac_bufsound-1;
   sound<='1'; 
  else
   sound<='0'; 
  end if;
 else
  dac_cntsound<="11111111";
  dac_bufsound<=dac_regsound; 
 end if;
 

end if;
end process;

process(clock,ram_clk,ay_ouA,ay_ouB,ay_ouC,ay_outA,ay_outB,sd_switch)
begin
if ((ram_clk'event and ram_clk ='0'))then
 if (delmux=0) then
	ay_outA <= ay_ouA;
	ay_outB <= ay_ouB;
   elsif (delmux=1) then
	ay_outA <= ay_ouC;
	ay_outB <= ay_ouC;
   elsif (delmux=2) then
	ay_outA <= ay_ouD;
	ay_outB <= ay_ouE;
   elsif (delmux=3) then
	ay_outA <= ay_ouF;
	ay_outB <= ay_ouF;	
   elsif (delmux=4 and sd_switch='1') then
	ay_outA <= SOUNDRIVEa;
	ay_outB <= SOUNDRIVEb;
   else 
	ay_outA <= sound;
	ay_outB <= sound;
 end if;	
end if;	
end process;

---------------------------------------------MOUSE--------------------------------------------
ps2_ms_clk<='0' when mouse_clk_out ='0' else 'Z';
ps2_ms_dat<='0' when mouse_dat_out ='0' else 'Z';  

---------------------------------------------MODULES------------------------------------------
ROM:lpm_rom1           --------ROM---------
port map
	(
		address		=>a_buff(11 downto 0),
		clock		=>clock,
		q			=>rom_d
	);  
	
Scan:lpm_ram_dp0
port map
	(
		clock		=>ram_clk,
		data		=>to_scan,
		rdaddress	=>not(scan_cnt(10)) & scan_cnt(8 downto 0),
		wraddress	=>scan_page & hcnt,
		wren		=>not(del(0)),
		q			=>from_scan
	);	 

pll: altpll0           ---------PLL--------
port map
	(
		inclk0		=>clk,
		c0			=>clock,
		c1			=>ay_clk,
		c2			=>ram_clk
	);

AY : YM2149     ----------------- AY1 -----------------
		port map(
			RESET_L => (res_n),
			CLK     => ay_clk,
			I_DA    => dataO,
			O_DA    => ay_databuff,
			O_DA_OE_L	=> open,
			
			ENA		=> '1',
			I_SEL_L => '1',
			
			I_IOA	=> x"00",
			I_IOB	=> x"00",
			
			I_A9_L	=> '0',
			I_A8	=> '1',
			I_BDIR	=> ayBDIRa,
			I_BC2	=> '1',
			I_BC1	=> ayBC1a,
			
			O_AUDIO_A	=> dac_regA,
			O_AUDIO_B	=> dac_regC,
			O_AUDIO_C	=> dac_regB											
		);
		
AY1 : YM2149     ----------------- AY2 -----------------
		port map(
			RESET_L => (res_n),
			CLK     => ay_clk,
			I_DA    => dataO,
			O_DA    => ay_databuff1,
			O_DA_OE_L	=> open,
			
			ENA		=> '1',
			I_SEL_L => '1',
			
			I_IOA	=> x"00",
			I_IOB	=> x"00",
			
			I_A9_L	=> '0',
			I_A8	=> '1',
			I_BDIR	=> ayBDIRb,
			I_BC2	=> '1',
			I_BC1	=> ayBC1b,
			
			O_AUDIO_A	=> dac_regD,
			O_AUDIO_B	=> dac_regF,
			O_AUDIO_C	=> dac_regE											
		);		

SPIports: ZCSPI 
port map(
--INPUTS
	DIN		=>dataO,
	nRD     =>rd_n,
	nWR     =>wr_n,
	nIORQ   =>iorq_n,
	nRES    =>res_n,
	CLC     =>(clock),                
	A       =>a_buff(7 downto 0),
	MISO    =>sd_di,
	--OUTPUTS
	DOUT	=>z_data,
	nSDCS   =>sd_cs,
	SCK     =>sd_clk,
	MOSI    =>sd_do,
	ZC_PORTS_READ	=>sd_read
);

mouse:io_ps2_mouse
port map(
		clk				=>clock,
		ps2_clk_in		=>ps2_ms_clk,
		ps2_dat_in	 	=>ps2_ms_dat,
		ps2_clk_out		=>mouse_clk_out,
		ps2_dat_out		=>mouse_dat_out,
		
		mousePresent 	=>present,
		
		leftButton 		=>button(1),
		middleButton 	=>button(2),
		rightButton 	=>button(0),
		X 				=>mouse_x,
		Y 				=>mouse_y
	);	

zxkey:zxkbd           ---- PS2/Keyboard controller ----
port map(
	clk                 =>(clock),
	reset               =>'0',
	res_k               =>res_key,
	f					=>f,
	ps2_clk             =>ps2_clk,
	ps2_data            =>ps2_data,
	zx_kb_scan          =>ka,
	zx_kb_out           =>kb,
	k_joy				=>kempston,
	num_joy				=>numlock
);	
	
Z80:T80s              --------- Z80 core (T80) -----------
port map(
		RESET_n		=>res_n,
		CLK_n		=>cpu_clk,
		WAIT_n		=>'1',
		INT_n		=>int_n,
		NMI_n		=>'1',
		BUSRQ_n		=>'1',
		M1_n		=>m1_n,
		MREQ_n		=>mreq_n,
		IORQ_n		=>iorq_n,
		RD_n		=>rd_n,
		WR_n		=>wr_n,
		RFSH_n		=>open,
		HALT_n		=>open,
		BUSAK_n		=>open,
		A			=>a_buff(15 downto 0),
		DI			=>dataI(7 downto 0),
		DO			=>dataO(7 downto 0),
		RestorePC_n =>'1'
	);	

end speccy_arch;