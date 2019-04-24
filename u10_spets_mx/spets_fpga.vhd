------------------------------------------------------
-- 		 	Spetz_MX_FPGA alfa version				--
-- 					 14/12/2011						--
-- 			Fifan, Ewgeny7, HardWareMan				--
--					www.zx.pk.ru					--
--				www.spetsialist-mx.ru				--
------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;

entity spets_fpga is
port(
--------------------------------------- �������/�������� ���� -----------------------------------------
        clk         : in std_logic;                                         -- ������� ������� 50 ���
        rxd         : in std_logic;                                         -- �������� ��� ������ ���������� ��������� ���232 � ����
        ps2_clk     : in std_logic;                                         -- ������������� � PS/2 ����������
        ps2_data    : in std_logic;                                         -- ������ � PS/2 ����������
        miso        : in std_logic;                                         -- ���������������� ���� ������ � SD �����
        sd_ins      : in std_logic;                                         -- ������ ������� SD �����      

        md          : inout std_logic_vector (7 downto 0);                  -- ���� ������ ������� ���
                        
        h_sync      : out std_logic;                                        -- ���
        v_sync      : out std_logic;                                        -- ���
        red         : out std_logic;                                        -- ����� ������� �������� �����
        green       : out std_logic;                                        -- ����� ������� ������� �����
        blue        : out std_logic;                                        -- ����� ������� ������ �����
        rb          : out std_logic;                                        -- ����� ������� ������� �������� �����
        gb          : out std_logic;                                        -- ����� ������� ������� ������� �����
        bb          : out std_logic;                                        -- ����� ������� ������� ������ �����
        sound       : out std_logic;                                        -- ����� �����
                    
        ma          : out std_logic_vector (19 downto 0);                   -- ���� ������ ������� ���      
        ram_oe      : out std_logic;                                        -- ������ ��������� ������� ������� ���
        ram_we      : out std_logic;                                        -- ������ ������/������ ������� ���     
        ram_ce      : out std_logic;                                        -- ������� ������� ���      
        mosi        : out std_logic;                                        -- ���������������� ����� ������ �� SD �����
        sd_clk      : out std_logic;                                        -- ������������� SD �����
        sd_cs       : out std_logic;                                        -- ������� SD �����
        led_red     : out std_logic;                                        -- ��������� "OPERATE"
        led_green   : out std_logic                                         -- ��������� "INSERT"
);      
end spets_fpga;  

architecture spets_fpga_arch of spets_fpga is

-------------------------------------------- ���������� -----------------------------------------------

component T8080se is                                                        -- �������������� 8080
    generic(
        Mode        : integer := 2;                                         -- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
        T2Write     : integer := 0                                          -- 0 => WR_n active in T3, /=0 => WR_n active in T2
    );
    port(
        RESET_n     : in std_logic;                                         -- ������ ������
        CLK         : in std_logic;                                         -- ������������� 4/8 ���
        CLKEN       : in std_logic;
        READY       : in std_logic;
        HOLD        : in std_logic;
        INT         : in std_logic;
        INTE        : out std_logic;
        DBIN        : out std_logic;                                        -- ������ ������
        SYNC        : out std_logic;
        VAIT        : out std_logic;
        HLDA        : out std_logic;
        WR_n        : out std_logic;                                        -- ������ ������
        A           : out std_logic_vector (15 downto 0);                   -- ���� ������
        DI          : in std_logic_vector (7 downto 0);                     -- ������� ���� ������
        DO          : out std_logic_vector (7 downto 0)                     -- �������� ���� ������
    );
end component;

component lpm_dos1 is                                                       -- ��� 8 ����� - SD Loader
    port                                                                    
    (
        address     : in std_logic_vector (12 downto 0);                    -- �������� ����
        clock       : in std_logic:= '1';                                   -- ���� �������� �������
        q           : out std_logic_vector (7 downto 0)                     -- �������� ���� ������
    );
end component;

component lpm_test_m is                                                     -- ��� 2 ����� - ����-�
    port                                                                    
    (
        address     : in std_logic_vector (10 downto 0);                    -- �������� ����
        clock       : in std_logic:= '1';                                   -- ���� �������� �������
        q           : out std_logic_vector (7 downto 0)                     -- �������� ���� ������
    );
end component;

component lpm_dos2 is                                                       -- ��� 27 ����� - RAMFOS
    port                                                                    
    (
        address     : in std_logic_vector (14 downto 0);                    -- �������� ����
        clock       : in std_logic:= '1';                                   -- ���� �������� �������
        q           : out std_logic_vector (7 downto 0)                     -- �������� ���� ������
    );
end component;

component lpm_test_mx is                                                    -- ��� 2 ����� - ����_�X
    port                                                                    
    (
        address     : in std_logic_vector (10 downto 0);                    -- �������� ����
        clock       : in std_logic:= '1';                                   -- ���� �������� �������
        q           : out std_logic_vector (7 downto 0)                     -- �������� ���� ������
    );
end component;

component altpll0 is                                                        -- �������� �������
    port
    (
        inclk0      : in std_logic:= '0';                                   -- ������� ������� 50 ���
        c0          : out std_logic                                         -- �������� ������� 32 ���
    );
end component;

component spetskeyboard is                                                  -- ���������� ����������                                        
    port(
        clk         : in std_logic;                                         -- ������������
        reset       : in std_logic;                                         -- ����� ����������
        res_k       : out std_logic;                                        -- ������� "�����"
        metod       : in std_logic;                                         -- ����� ������
        ps2_clk     : in std_logic;                                         -- ������������� � PS/2 ����������
        ps2_data    : in std_logic;                                         -- ������ � PS/2 ����������
        sp_kb_scan  : in std_logic_vector (11 downto 0);                    -- ��� ������
        mode    	: in std_logic;                                         -- ����� "�������� / ��"
        rus_lat    	: in std_logic;                                         -- ����� ���������� "��� / LAT" 
        sp_kb_out   : out std_logic_vector (11 downto 0);                   -- ��� ������
        key_ss      : out std_logic;                                        -- ������� "��"
        test_k      : out std_logic;                                        -- ������� "����"
        ruslat_k    : out std_logic;                                        -- ������� "��� / LAT"
        turbo_k     : out std_logic;                                        -- ������� "�����"
        mx_k        : out std_logic                                         -- ������� "�� / ��������"
);
end component;

component SPI is                                                            -- SPI ���������
    port(
        A0          : in std_logic;                                         -- �����        
        WR          : in std_logic;                                         -- ������ ������
        CS          : in std_logic;                                         -- ������� SPI ����������       
        MISO        : in std_logic;                                         -- ���������������� ���� ������ � SD �����
        INSERT      : in std_logic;                                         -- ������ ������� SD �����      
        CLK         : in std_logic;                                         -- ������� ������� 16 ���
        DI0         : in std_logic;                                         -- ������� ���� ������
        DI1         : in std_logic;                                         -- ������� ���� ������
        DI2         : in std_logic;                                         -- ������� ���� ������
        DI3         : in std_logic;                                         -- ������� ���� ������
        DI4         : in std_logic;                                         -- ������� ���� ������
        DI5         : in std_logic;                                         -- ������� ���� ������
        DI6         : in std_logic;                                         -- ������� ���� ������
        DI7         : in std_logic;                                         -- ������� ���� ������
        RESET       : in std_logic;                                         -- ������ ������
        LED_RED     : out std_logic;                                        -- ��������� "OPERATE"
        LED_GREEN   : out std_logic;                                        -- ��������� "INSERT"
        HI          : out std_logic;                                        -- ������� ������� SPI ����������
        LO          : out std_logic;                                        -- ������ ������� SPI ����������    
        SD_CLK      : out std_logic;                                        -- ������������� SD �����
        MOSI        : out std_logic;                                        -- ���������������� ����� ������ �� SD �����
        SD_CS       : out std_logic;                                        -- ������� SD �����
        DO0         : out std_logic;                                        -- �������� ���� ������
        DO1         : out std_logic;                                        -- �������� ���� ������
        DO2         : out std_logic;                                        -- �������� ���� ������
        DO3         : out std_logic;                                        -- �������� ���� ������
        DO4         : out std_logic;                                        -- �������� ���� ������
        DO5         : out std_logic;                                        -- �������� ���� ������
        DO6         : out std_logic;                                        -- �������� ���� ������
        DO7         : out std_logic                                         -- �������� ���� ������
);
end component;

component AddrSelector is                                                   -- �������� �������
    port(
		A0          : in std_logic;                                         -- �����
		A1          : in std_logic;                                         -- �����
		A2          : in std_logic;                                         -- �����
		A3          : in std_logic;                                         -- �����
		A4          : in std_logic;                                         -- �����
		A5          : in std_logic;                                         -- �����
		A6          : in std_logic;                                         -- �����
		A7          : in std_logic;                                         -- �����
		A8          : in std_logic;                                         -- �����
		A9          : in std_logic;                                         -- �����
		A10         : in std_logic;                                         -- �����
		A11         : in std_logic;                                         -- �����
		A12         : in std_logic;                                         -- �����
		A13         : in std_logic;                                         -- �����
		A14         : in std_logic;                                         -- �����
		A15         : in std_logic;                                         -- �����
		RESET       : in std_logic;                                         -- ������ ������
		WR          : in std_logic;                                         -- ������ ������
		TEST        : in std_logic;                                         -- ����
		U0          : out std_logic;                                        -- ������� RAM/ROM-������
		U1          : out std_logic;                                        -- ������� ����������� �����
		U2          : out std_logic;                                        -- ������� ��������� ������
		U3          : out std_logic;                                        -- ������� ����������� ���������
		U4          : out std_logic;                                        -- ������� �������
		U5          : out std_logic;                                        -- ������� ����������� ���������
		U6          : out std_logic;                                        -- ������� ������ �������������
		U7          : out std_logic;                                        -- ������� ������ ����������
		RAMD        : out std_logic;                                        -- ������� RAM-�����
		ROM         : out std_logic;                                        -- ������� ROM-�����
		RAM         : out std_logic                                         -- ������� ��������� ���
);
end component;

component pit8253 is                                                      	-- ������ 8253
  port(
		clk         : in std_logic;                                         -- �������������
		ce          : in std_logic;                                         -- ���������� ������ �� �������������
		tce         : in std_logic;                                         -- ���������� ������ �� ������������� ��������
		a           : in std_logic_vector (1 downto 0);                     -- ���� ������
		wr          : in std_logic;                                         -- ������ ������
		rd          : in std_logic;                                         -- ������ ������
		gate        : in std_logic_vector (2 downto 0);                     -- ����� ����������, ��������������
		din         : in std_logic_vector (7 downto 0);                     -- ������� ���� ������
		clk2		: in std_logic;                                         -- ������������� ��� �������� �2
		dout        : out std_logic_vector (7 downto 0);                    -- �������� ���� ������
		t_out       : out std_logic_vector (2 downto 0)                    	-- ������ ��������
);
end component;

------------------------------------------- ���������� ------------------------------------------------
signal clock_32:        std_logic;                                          -- ������������� 32 ���
signal clock:           std_logic;                                          -- ������������� 16 ���
signal res_k:           std_logic;                                          -- ������� "�����"
signal hcnt:            std_logic_vector (8 downto 0) register;             -- ������� ��������
signal vcnt:            std_logic_vector (9 downto 0) register;             -- ������� �����
signal hsync:           std_logic;                                          -- �������� �������������
signal vsync:           std_logic;                                          -- �������� �������������
signal r:               std_logic;                                          -- ������� ����
signal g:               std_logic;                                          -- ������ ����
signal b:               std_logic;                                          -- ����� ����
signal i:               std_logic;                                          -- �������
signal r1:              std_logic;                                          -- ������� ���� �����
signal b1:              std_logic;                                          -- ������ ���� �����
signal g1:              std_logic;                                          -- ����� ���� �����
signal screen_pre:      std_logic;                                          -- ������� ������ �����
signal screen:          std_logic;                                          -- ������� ������
signal sel:             std_logic;                                          -- ���������� ��������������� �� �����
signal vid_buf:         std_logic_vector (7 downto 0) register;             -- �����������, �������
signal vid_bw:          std_logic_vector (7 downto 0) register;             -- �����������, �������
signal vidc_buf:        std_logic_vector (7 downto 0) register;             -- �����������, ��������
signal vid_c:           std_logic_vector (7 downto 0) register;             -- �����������, ��������
signal vid_pix:         std_logic;                                          -- ��������� �� ����� �������
signal del:             std_logic_vector (2 downto 0);                      -- ����� �������
signal dataI:           std_logic_vector (7 downto 0);                      -- ������� ���� ������ ����������
signal dataO:           std_logic_vector (7 downto 0);                      -- �������� ���� ������ ����������
signal a_buff:          std_logic_vector (15 downto 0);                     -- �������� ���� ����������
signal wr_n:            std_logic;                                          -- ������
signal rd_n:            std_logic;                                          -- ������
signal rd:              std_logic;                                          -- ������
signal mreq_n:          std_logic;                                          -- ����� ������ ��� ��� ��������
signal ram:             std_logic_vector (19 downto 0);                     -- �������� ���� ���
signal romd_d:          std_logic_vector (7 downto 0);                      -- ���� ������ ���
signal romd_d1:         std_logic_vector (7 downto 0);                      -- ���� ������ ���
signal romd_d2:         std_logic_vector (7 downto 0);                      -- ���� ������ ���
signal romd_d3:         std_logic_vector (7 downto 0);                      -- ���� ������ ���
signal romd_d4:         std_logic_vector (7 downto 0);                      -- ���� ������ ���
signal rom_addr:        std_logic;                                          -- ������� ������ ���
signal romsel_test:     std_logic;                                          -- ������� ��� "����-�"
signal romsel_dos:      std_logic;                                          -- ������� ��� "DOS"
signal u0:              std_logic;                                          -- ������� RAM/ROM-������
signal u1:              std_logic;                                          -- ������� ����������� �����
--signal u2:              std_logic;                                        -- ������� ��������� ������
signal u3:              std_logic;                                          -- ������� ����������� ���������
signal u4:                std_logic;                                      	-- ������� �������
--signal u5:              std_logic;                                        -- ������� ����������� ���������
signal u6:              std_logic;                                          -- ������� ������ �������������
signal u7:              std_logic;                                          -- ������� ������ ����������
signal u6mx:            std_logic;                                          -- ������� ������ ������������� � ������ "��"
signal u7mx:            std_logic;                                          -- ������� ������ ���������� � ������ "��"
--signal u4wr:            std_logic;                                          -- ������ � ������
signal u4rd:            std_logic;                                          -- ������ �� �������
signal u7wr:            std_logic;                                          -- ������ � ���� ����������
signal u7rd:            std_logic;                                          -- ������ �� ����� ����������
signal res_n:           std_logic;                                          -- �����
signal clk_cpu:         std_logic;                                          -- ������������� ��� ����������
signal scan_in:         std_logic_vector (11 downto 0);                     -- ��� ������ ����������
signal scan_out:        std_logic_vector (11 downto 0);                     -- ��� ������ ����������
signal shift:           std_logic;                                          -- ������� "��"                         
signal test_key:        std_logic;                                          -- ������� "����"
signal metod:           std_logic;                                          -- ����� ������ ����������
signal porta:           std_logic_vector (7 downto 0);                      -- ���� � ����������
signal porta1:          std_logic_vector (7 downto 0);                      -- ���� � ����������
signal portb:           std_logic_vector (7 downto 0);                      -- ���� � ����������
signal portb1:          std_logic_vector (7 downto 0);                      -- ���� � ����������
signal portc:           std_logic_vector (3 downto 0);                      -- ���� � ����������
signal portc1:          std_logic_vector (3 downto 0);                      -- ���� � ����������
signal portr:           std_logic_vector (7 downto 0);                      -- ���� ��� ����������
signal snd:             std_logic;                                          -- ����� ����� � ������ "��������"
signal snd_mx:          std_logic;                                          -- ����� ����� � ������ "��"
signal test:            std_logic:= '0';                                    -- ���� ��������/�������    
signal cd_in:           std_logic_vector (7 downto 0);                      -- ������� ���� ������ ����� ��� �����
signal turbo_key:       std_logic;                                          -- ������� "�����"
signal turbo:           std_logic:= '0';                                    -- ��������: 4 ���/2 ���
signal np:              std_logic:= '1';                                    -- ������� ���������� �����
signal sd_i:            std_logic_vector (7 downto 0);                      -- ������� ���� ������ SD �����������
signal sd_o:            std_logic_vector (7 downto 0);                      -- �������� ���� ������ SD �����������
signal spi_cs:          std_logic;                                          -- ������� SD ����������
signal mode:            std_logic;                                          -- ����� "��������" / "��"
signal mx_st_key:       std_logic;                                          -- ������� "��������" / "��"
signal ramdisk:         std_logic;                                    		-- ������� RAM-�����
signal romdisk:         std_logic;                                    		-- ������� ROM-�����
signal page:			std_logic_vector (1 downto 0);						-- �������� RAM-�����
signal ruslat:         	std_logic;                                    		-- ����� ���������� "��� / LAT" 
signal rs_lt_key:      	std_logic;                                    		-- ������� "��� / LAT"
signal t_i:          	std_logic_vector (7 downto 0);                      -- ������� ���� ������ �������
signal t_o:          	std_logic_vector (7 downto 0);                      -- �������� ���� ������ �������
signal t_out:        	std_logic_vector (2 downto 0);                      -- ������ ��������
signal clk2:      		std_logic;                                    		-- ������� ������� ��� �������� �2

begin

------------------------------------------- ��������������� -------------------------------------------
clock <= not clock when (clock_32'event and clock_32 = '0');                -- �������� ������� 16 ���

----------------------------------- �������� ������� ��� ���������� -----------------------------------
process(clock)
    begin
        if (clock'event and clock = '1') then
            del <= del + 1;
        end if;
end process;  

process(clock,del)
    begin
        if (clock'event and clock = '1') then
            if turbo = '1' then
                clk_cpu <= del (1);                                         -- "�����" ����� 4 ���
            else
                clk_cpu <= del (2);                                         -- "����������" ����� 2 ���
            end if;
        end if;
end process;

------------------------------------- ������� ������ � ���������� -------------------------------------
mreq_n <= '0';                                                              -- ������������ � Z80      
sel <= '1' when (hcnt (2 downto 0) = "000" and del(0) = '0') else '0';      -- ������ ������ ��� � ����������� ���� � �����������������
res_n <= '0' when (res_k = '1') else '1';                                   -- ������ ������
mode <= '1' when (mx_st_key = '1') else '0';                                -- ����� ������: "��������/��"
test <= '1' when (test_key = '1') else '0';                                 -- ���� ��������/�������
ruslat <= '1' when (rs_lt_key = '1') else '0';                              -- ����� ���������� "��� / LAT" 
rd_n <= not rd;                                                             -- ������ ������                
turbo <= '1' when (turbo_key = '1') else '0';                               -- ��������: 4 ���/2 ���
clk2 <= t_out (1);															-- ������������� ��� �������� �2
   
----------------------------------------- �������� ������� ------------------------------------------
rom_addr <= a_buff (15) and a_buff (14) and not (a_buff (13) and a_buff (12)); 		    -- �������� ������������ ���
--u4wr <= not (u4 or wr_n);                                                  -- ������ ���������� �� ������ � ������
u4rd <= not (u4 or rd_n);                                                  -- ������ ���������� �� ������ �� �������
--u0 <= '1' when (a_buff (15 downto 2) = x"3FFF" and mode = '1' and wr_n = '0') else '0';	-- ������� RAM/ROM-������ � ������ ��
--u1 <= '1' when (a_buff(15 downto 0) = x"FFF8" and wr_n = '0') else '0';
--u3 <= '1' when (a_buff (15 downto 2) = x"3FFC" and mode = '1') else '1';    -- ������� �1816��93 � ������ ��
u6 <= '1' when ((a_buff (15 downto 11) = "11110" and mode = '0') 
	or (u6mx = '0' and mode = '1')) else '0';  								-- ������� ������ �������������
--u6mx <= '0' when (a_buff(15 downto 2) = x"3FF9") else '1'; 
u7 <= '1' when ((a_buff (15 downto 11) = "11111" and mode = '0') 
	or (u7mx = '0' and mode = '1')) else '0';  								-- ������� ������ ����������
u7wr <= (u7 and not (mreq_n or wr_n));                                      -- ������ ���������� �� ������ � ���� ����������
u7rd <= (u7 and not (mreq_n or rd_n));										-- ������ ���������� �� ������ �� ����� ����������
--u7mx <= '0' when (a_buff(15 downto 2) = x"3FF8") else '1';                                     
spi_cs <= u6 when mode = '0' else not u3;                                   -- ������� SPI ����������

process (res_n,u0,mode,dataO (1 downto 0))
	begin
		if res_n = '0' then													-- �����
			page <= "00";													-- ����� ������ ��������
		elsif ((u0'event and u0 = '1') and mode = '1') then			
			page <= dataO (1 downto 0);										-- ����� ��������
		end if;
end process;

process(clock,hcnt)
    begin
        if (clock'event and clock = '1') then
            if hcnt = 511 then
                hcnt <= "000000000";
            else
                hcnt <= hcnt + 1;
            end if;
        end if; 
end process;

process(hcnt (8),vcnt)
    begin
        if (hcnt (8)'event and hcnt (8) = '0') then
            if vcnt (9 downto 1) = 319 then
                vcnt <= "0000000000";
            else
                vcnt <= vcnt + 1;
            end if;
        end if;
end process;

process (clock,mode,np,a_buff (15),test,rom_addr,romdisk)
    begin
		if mode = '0' then
			romsel_dos <= np and not a_buff (15) and not test;				-- ������� ��� ��� DOS�
			romsel_test <= ((np and test) or (not np and rom_addr and test));	-- ������� ��� ��� �����-�  
		else			
			romsel_dos <= not (romdisk or test);							-- ������� ��� � ROM-�����	
			romsel_test <= not (romdisk or not test);						-- ������� ��� ��� �����_��
		end if;
end process;

--------------------------------------- ������ �� ���������� ------------------------------------------
process(clock,res_n,u7wr,a_buff (1 downto 0),dataO,u1,mode)
    begin
        if res_n = '0' then
            porta <= "00000000";
            portb <= "00000000";
            portc <= "0000";
            portr <= "00000000";
            cd_in <= "11111111";                                            -- �������� Z-��������� ����� � ��� �/� ������
            np <= '1';                                                      -- ������� ���������� �����         
        elsif (clock'event and clock = '0') then
			if (u7wr = '1') then
            case a_buff (1 downto 0) is
                when "00" =>                                                -- ���� � ����������
                    porta <= dataO;                                         -- ��� ������
                when "01" =>                                                -- ���� � ����������
                    portb <= dataO;                                         -- ��� ������
                when "10" =>                                                -- ���� � ����������
                    portc <= dataO (3 downto 0);                            -- ��� ������
                    if mode = '0' then
                        cd_in <= "11111" & not dataO (4) & not dataO (6) & not dataO (7);   -- ���� ������ � �����
                    end if;
                when "11" =>                                                -- ���� ��� ����������
                    portr <= dataO;                                         
                    np <= '0';                                              -- ����� �������� ���������� �����
            end case;
			elsif (u1 = '1' and mode = '1') then 							-- ������ � ������� �����
				cd_in <= dataO;                                             -- ���� ������ � �����            
			end if;
		end if;
end process;

process(clock,portc,portb (7 downto 2),porta)                               -- �������� Z-��������� ������ 8255
    begin
        if (clock'event and clock = '1') then
            if portr (4) = '0' then
                portc1 <= portc;
            else
                portc1 <= "1111";        
            end if;
            if portr (1) = '0' then
                portb1 (7 downto 2) <= portb (7 downto 2);
            else
                portb1 (7 downto 2) <= "111111";         
            end if;
            if portr (4) = '0' then
                porta1 <= porta;
            else
                porta1 <= "11111111";       
            end if;
        end if;         
end process;
            
scan_in <= (portc1 & porta1) when (metod = '0') else ("111111" & portb1 (7 downto 2));      -- ��� ������

----------------------------------------- ���������� ������� ----------------------------------------------------
process(clock,sel,hcnt (8 downto 3),vcnt (8 downto 1),a_buff,ramdisk,wr_n,mode,page)
    begin
        if sel = '1' then
            ram <= "000" & clock & "10" & hcnt (8 downto 3) & vcnt (8 downto 1);    -- ����� � ����������������
        else
			if (clock = '1' and a_buff (15 downto 14) = "10" and ramdisk = '1' and wr_n = '0') then
				ram <= "0001" & a_buff;                       				-- 8000...BFFF - ����� ��� �����
			else
				if (ramdisk = '0' and mode = '1') then						-- 0000...FFBF - RAM-����
					ram <= "01" & page & a_buff;			
				else														-- 0000...BFFF - ���							
					ram <= "0000" & a_buff;
				end if;                       				
			end if;	
		end if;
end process;   
 
ma <= ram;

----------------------------------------- ���������� ������ ------------------------------------------- 
md 	<= 	dataO when (sel = '0' and mreq_n = '0' and clock = '0' and wr_n = '0') else  
		cd_in when (sel = '0' and mreq_n = '0' and clock = '1' and wr_n = '0') else 
		"ZZZZZZZZ";   -- ���� ������ ���
sd_i <= dataO when (spi_cs = '1' and (clock'event and clock = '1'));        -- ������� ���� ������ SD ����������
t_i <= dataO when (u4 = '0' and (clk_cpu'event and clk_cpu = '1'));     	-- ������� ���� ������ �������

---------------------------------------- ������ � ��������� -------------------------------------------
process(clock,mode,romsel_test,romsel_dos,romd_d1,romd_d2,romd_d3,romd_d4,np,spi_cs,sd_o,u4rd,t_o,u7rd,a_buff (1 downto 0),scan_out,shift,portr,md)
    begin
        if (clock'event and clock = '0') then
            if (mode = '0' and romsel_test = '1') then
                dataI <= romd_d2;
            elsif (mode = '0' and romsel_dos = '1' and np = '1') then
                dataI <= romd_d1;
            elsif (mode = '1' and romsel_test = '1') then
                dataI <= romd_d4;
            elsif (mode = '1' and romsel_dos = '1') then
                dataI <= romd_d3;                                           -- ������ ������ � ���
            elsif (spi_cs = '1') then
                dataI <= sd_o;                                              -- ����� ������ � SD ����������
			elsif (u4rd = '1') then
				dataI <= t_o;                                               -- ����� ������ � �������
            elsif (u7rd = '1') then                                         -- ������ � ����� ����������
                case a_buff (1 downto 0) is
                    when "00" =>                                            -- ���� � ����������
                        dataI <= scan_out (7 downto 0);                     -- ��� ������
                        metod <= '1';
                    when "01" =>                                            -- ���� � ����������
                        dataI <= scan_out (5 downto 0) & not shift & '1';   -- ��� ������
                        metod <= '0';
                    when "10" =>                                            -- ���� � ����������
                        dataI <= "0000" & scan_out (11 downto 8);           -- ��� ������
                        metod <= '1';
                    when "11" =>                                            -- ���� ��� ����������
                        dataI <= portr;
                end case;
            else 
                dataI <= md;                                                -- �� ���� ������ ���������� - ������ � ���
            end if;
        end if;
end process;
 
--------------------------------------- ������ ����� ������� ------------------------------------------
process(clock,hcnt)                                                         -- �������������� �������������
    begin
        if (clock'event and clock = '1') then                          
            if hcnt = 32 then
                hsync <= '0';
            elsif hcnt = 90 then
                hsync <= '1'; 
            end if;
        end if; 
end process;

process(clock,vcnt (9 downto 1))                                         	-- ������������ �������������
    begin
        if (clock'event and clock = '1') then
            if vcnt (9 downto 1) = 278 then
                vsync <= '0';
            elsif vcnt (9 downto 1) = 282 then
                vsync <= '1';
            end if;
        end if;
end process;                                           

process(clock,hcnt,vcnt (9))                                            	-- �����/���������         
    begin
        if (clock'event and clock = '1') then
            if (hcnt = 128 and vcnt (9) = '0') then
                screen_pre <='1';
            elsif (hcnt = 511) then
                screen_pre <= '0';
            end if;
        end if;
end process;
  
--------------------------------------- ������ ����� ������ -------------------------------------------
process(clock,sel,md)
    begin
        if (clock'event and clock = '1' and sel = '1') then
            vid_buf <= md;
        end if;
end process;

process(clock,sel,md)
    begin
        if (clock'event and clock = '0' and sel = '1') then
            vidc_buf <= md;
        end if;
end process;

process(hcnt (2 downto 0),vid_bw)                                         	-- ������� ������ ����� ������
    begin
        case hcnt (2 downto 0) is
            when "000" =>
				vid_pix <= vid_bw(7); 
            when "001" =>
				vid_pix <= vid_bw(6);
            when "010" =>
				vid_pix <= vid_bw(5);
            when "011" =>
				vid_pix <= vid_bw(4);
            when "100" =>
				vid_pix <= vid_bw(3);
            when "101" =>
				vid_pix <= vid_bw(2);
            when "110" =>
				vid_pix <= vid_bw(1);
            when "111" =>
				vid_pix <= vid_bw(0);
        end case;
end process;

process(clock,hcnt (2 downto 0),vid_buf,vidc_buf,screen_pre)                -- ���������� ����������� ��� �������������������
    begin
        if hcnt (2 downto 0) = "111" then
            if clock'event and clock = '1' then
                vid_bw <= vid_buf;
                vid_c  <= vidc_buf;
                screen <= screen_pre;                                       -- ������� ������������ �����
            end if;
        end if;
end process;    

process(clock,screen,vid_pix,mode,vid_c)                                    -- ������������������������
    begin
     if clock'event and clock = '1' then
        if screen = '1' then 
            if vid_pix = '1' then
                if mode = '0' then
                    r <= vid_c (0);                                         -- ������ �������� �����
                    g <= vid_c (1);                                         -- ������ ������� �����
                    b <= vid_c (2);                                         -- ������ ������ �����
                    i <= '1';                                               -- ������ �������
                else                                                        -- ���� INK:
                    r <= vid_c (6);                                         -- ������ �������� �����
                    g <= vid_c (5);                                         -- ������ ������� �����
                    b <= vid_c (4);                                         -- ������ ������ �����
                    i <= vid_c (7);                                         -- ������ �������
                end if;
            else
                if mode = '0' then
                    r <= '0';
                    g <= '0';
                    b <= '0';
                    i <= '0';
                else                                                        -- ���� PAPER:
                    r <= vid_c (2);                                         -- ������ �������� �����
                    g <= vid_c (1);                                         -- ������ ������� �����
                    b <= vid_c (0);                                         -- ������ ������ �����
                    i <= vid_c (3);                                         -- ������ �������
                end if;
            end if;
        else
            r <= '0';
            g <= '0';
            b <= '0';
            i <= '0';
        end if; 
     end if;
end process;

----------------------------------------- ����� �������� ----------------------------------------------
ma <= ram;                                                                  -- ����� ���� ������ ���
h_sync <= '0' when hsync = '0' else '1';                                    -- ���
v_sync <= '0' when vsync = '0' else '1';                                    -- ���

--snd <= not (portr (0)) when (portr (7) = '0' and (clock'event and clock = '0')); -- ����� ����� � ������ "��������"
--snd_mx <= not snd or (not (t_out (0) or t_out (2)));                    	-- ����� ����� � ������ ��
--sound <= '0' when ((snd = '0' and mode = '0') or (snd_mx = '1' and mode = '1')) else '1';    -- ����� �����

sound <= not ((portr(0) and t_out(2)) or t_out(0)) or portr(7);


ram_ce <= '0';                                   							-- ������� ���
ram_oe <= '0' when ((sel = '1') or (rd_n = '0')) else '1';  				-- ������� ������� ���
ram_we <= '0' when (sel = '0' and wr_n = '0' and clock_32 = '1') else '1';	-- ������ ������/������ ���

process(clock,r,g,b,i)
    begin
        if (clock'event and clock = '0') then
            red <= r;
            green <= g;
            blue <= b;
            rb <= i;
            gb <= i;
            bb <= i;  
        end if;
end process;

------------------------------------------ ���������� -------------------------------------------------

VM80:T8080se                                                                -- �������������� 8080
port map(
            RESET_n         => res_n,                                       -- ������ ������
            CLK             => clk_cpu,                                     -- ������������� 2/4 ���
            CLKEN           => '1',
            READY           => '1',
            HOLD            => '0',
            INT             => '0',
            INTE            => open,
            DBIN            => rd,                                          -- ������ ������
            SYNC            => open,
            VAIT            => open,
            HLDA            => open,
            WR_n            => wr_n,                                        -- ������ ������
            A               => a_buff (15 downto 0),                        -- ���� ������
            DI              => dataI (7 downto 0),                          -- ������� ���� ������
            DO              => dataO (7 downto 0)                           -- �������� ���� ������
    );      

monitor2:lpm_dos1                                                           -- 8 ����� - DOS
port map(
            address         => a_buff (12 downto 0),                        -- �������� ����    
            clock           => not clock,                                   -- ������������
            q               => romd_d1                                      -- �������� ���� ������     
    );
    
test_m:lpm_test_m                                                           -- ��� 2 ����� - ����-�
port map(
            address         => a_buff (10 downto 0),                        -- �������� ����
            clock           => not clock,                                   -- ������������
            q               => romd_d2                                      -- �������� ���� ������
    );

ramfos:lpm_dos2                                                             -- 27 ����� - DOS
port map(
            address         => a_buff (14 downto 0),                        -- �������� ����
            clock           => not clock,                                   -- ������������
            q               => romd_d3                                      -- �������� ���� ������     
    );
    
test_mx:lpm_test_mx                                                         -- ��� 2 ����� - ����_�X
port map(
            address         => a_buff (10 downto 0),                        -- �������� ����
            clock           => not clock,                                   -- ������������
            q               => romd_d4                                      -- �������� ���� ������
    );

pll: altpll0
port map(
            inclk0          => clk,                                         -- 50 ���
            c0              => clock_32                                     -- 32 ���
    );
        
spetskey:spetskeyboard                                                      -- ���������� ����������                                                        
port map(
            clk             => clock_32,                                	-- �������������                                 
            reset           => '0',                                         -- ����� ����������                                     
            res_k           => res_k,                                       -- ������� "�����"
            metod           => metod,                                       -- ����� ������                             
            ps2_clk         => ps2_clk,                                     -- ������������� � PS/2 ����������                                  
            ps2_data        => ps2_data,                                    -- ������ � PS/2 ����������                                 
            sp_kb_scan      => scan_in,                                     -- ��� ������
            mode      		=> mode,                                     	-- ����� "�������� / ��"
            rus_lat      	=> ruslat,                                     	-- ����� ���������� "��� / LAT" 
            sp_kb_out       => scan_out,                                    -- ��� ������
            key_ss          => shift,                                       -- ������� "��"                                      
            test_k          => test_key,                                    -- ������� "����"
            ruslat_k      	=> rs_lt_key,                                   -- ������� "��� / LAT"
            turbo_k         => turbo_key,                                   -- ������� "�����"                                               
            mx_k            => mx_st_key                                    -- ������� "�� / ��������"                             
);

SD:SPI                                                                      -- SPI ���������
port map(
            A0              => a_buff (0),                                  -- �����            
            WR              => wr_n,                                        -- ������ ������
            CS              => not spi_cs,                                  -- ������� SPI ����������
            MISO            => miso,                                        -- ���������������� ���� ������ � SD �����
            INSERT          => sd_ins,                                      -- ������ ������� SD �����
            CLK             => not clock,                                   -- ������� ������� 16 ���
            DI0             => sd_i (0),                                    -- ������� ���� ������
            DI1             => sd_i (1),                                    -- ������� ���� ������
            DI2             => sd_i (2),                                    -- ������� ���� ������
            DI3             => sd_i (3),                                    -- ������� ���� ������
            DI4             => sd_i (4),                                    -- ������� ���� ������
            DI5             => sd_i (5),                                    -- ������� ���� ������
            DI6             => sd_i (6),                                    -- ������� ���� ������
            DI7             => sd_i (7),                                    -- ������� ���� ������
            RESET           => res_n,                                       -- ������ ������
			LED_RED         => led_red,                                     -- ��������� "OPERATE"
			LED_GREEN       => led_green,                                   -- ��������� "INSERT"
            HI              => open,                                        -- ������� ������� SPI ����������
            LO              => open,                                        -- ������ ������� SPI ����������
            SD_CLK          => sd_clk,                                      -- ������������� SD �����
            MOSI            => mosi,                                        -- ���������������� ����� ������ �� SD �����
            SD_CS           => sd_cs,                                       -- ������� SD �����     
            DO0             => sd_o (0),                                    -- �������� ���� ������
            DO1             => sd_o (1),                                    -- �������� ���� ������
            DO2             => sd_o (2),                                    -- �������� ���� ������
            DO3             => sd_o (3),                                    -- �������� ���� ������
            DO4             => sd_o (4),                                    -- �������� ���� ������
            DO5             => sd_o (5),                                    -- �������� ���� ������
            DO6             => sd_o (6),                                    -- �������� ���� ������
            DO7             => sd_o (7)                                     -- �������� ���� ������         
);

AS:AddrSelector                                                   	    	-- �������� �������
port map(
            A0              => a_buff (0),                                  -- �����
			A1              => a_buff (1),                                  -- �����
			A2              => a_buff (2),                                  -- �����
			A3              => a_buff (3),                                  -- �����
			A4              => a_buff (4),                                  -- �����
			A5              => a_buff (5),                                  -- �����
			A6              => a_buff (6),                                  -- �����
			A7              => a_buff (7),                                  -- �����
			A8              => a_buff (8),                                  -- �����
			A9              => a_buff (9),                                  -- �����
			A10             => a_buff (10),                                 -- �����
			A11             => a_buff (11),                                 -- �����
			A12             => a_buff (12),                                 -- �����
			A13             => a_buff (13),                                 -- �����
			A14             => a_buff (14),                                 -- �����
			A15             => a_buff (15),                                 -- �����
			RESET           => res_n,                                       -- ������ ������
			WR              => wr_n,                                        -- ������ ������
			TEST            => test,                                        -- ����
			U0              => u0,                                          -- ������� RAM/ROM-������
			U1              => u1,                                        	-- ������� ����������� �����
			U2              => open,                                        -- ������
			U3              => u3,                                          -- ������� ����������� ���������
			U4              => u4,                                        	-- ������� �������
			U5              => open,                                        -- ������� ����������� ���������
			U6              => u6mx,                                        -- ������� ������ �������������
			U7              => u7mx,                                        -- ������� ������ ����������
			RAMD            => ramdisk,                                     -- ������� RAM-�����
			ROM             => romdisk,                                     -- ������� ROM-�����
			RAM             => open                                       	-- ������� ��������� ���
);

t8253:pit8253                                                             	-- ������ 8253
port map(
			clk           	=> clk_cpu,                                 	-- �������������
			ce              => not u4,                                      -- ���������� ������ �� �������������
			tce             => not u4,                                      -- ���������� ������ �� ������������� ��������
			a      			=> a_buff (1 downto 0),                         -- ���� ������
			wr              => wr_n,                                    	-- ������ ������
			rd              => rd_n,                                    	-- ������ ������
			gate            => "111",                                      	-- ����� ����������, �� ������������
			din             => t_i (7 downto 0),                            -- ������� ���� ������
			clk2			=> clk2,                                        -- ������������ ��� �������� �2
			dout            => t_o (7 downto 0),                            -- �������� ���� ������
			t_out           => t_out (2 downto 0)                          	-- ������ ��������
  );

end spets_fpga_arch;