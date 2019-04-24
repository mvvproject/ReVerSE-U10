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
--------------------------------------- Входные/выходные пины -----------------------------------------
        clk         : in std_logic;                                         -- входная частота 50 МГц
        rxd         : in std_logic;                                         -- добавлен для снятия возможного конфликта МАХ232 с ПЛИС
        ps2_clk     : in std_logic;                                         -- синхронизация с PS/2 клавиатуры
        ps2_data    : in std_logic;                                         -- данные с PS/2 клавиатуры
        miso        : in std_logic;                                         -- последовательный вход данных с SD карты
        sd_ins      : in std_logic;                                         -- датчик наличия SD карты      

        md          : inout std_logic_vector (7 downto 0);                  -- шина данных внешней ОЗУ
                        
        h_sync      : out std_logic;                                        -- СГИ
        v_sync      : out std_logic;                                        -- КГИ
        red         : out std_logic;                                        -- выход сигнала красного цвета
        green       : out std_logic;                                        -- выход сигнала зелёного цвета
        blue        : out std_logic;                                        -- выход сигнала синего цвета
        rb          : out std_logic;                                        -- выход сигнала яркости красного цвета
        gb          : out std_logic;                                        -- выход сигнала яркости зелёного цвета
        bb          : out std_logic;                                        -- выход сигнала яркости синего цвета
        sound       : out std_logic;                                        -- выход звука
                    
        ma          : out std_logic_vector (19 downto 0);                   -- шина адреса внешней ОЗУ      
        ram_oe      : out std_logic;                                        -- сигнал активации выходов внешней ОЗУ
        ram_we      : out std_logic;                                        -- сигнал записи/чтения внешней ОЗУ     
        ram_ce      : out std_logic;                                        -- выборка внешней ОЗУ      
        mosi        : out std_logic;                                        -- последовательный выход данных на SD карту
        sd_clk      : out std_logic;                                        -- синхронизауия SD карты
        sd_cs       : out std_logic;                                        -- выборка SD карты
        led_red     : out std_logic;                                        -- светодиод "OPERATE"
        led_green   : out std_logic                                         -- светодиод "INSERT"
);      
end spets_fpga;  

architecture spets_fpga_arch of spets_fpga is

-------------------------------------------- Интерфейсы -----------------------------------------------

component T8080se is                                                        -- микропроцессор 8080
    generic(
        Mode        : integer := 2;                                         -- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
        T2Write     : integer := 0                                          -- 0 => WR_n active in T3, /=0 => WR_n active in T2
    );
    port(
        RESET_n     : in std_logic;                                         -- сигнал сброса
        CLK         : in std_logic;                                         -- синхронизация 4/8 МГц
        CLKEN       : in std_logic;
        READY       : in std_logic;
        HOLD        : in std_logic;
        INT         : in std_logic;
        INTE        : out std_logic;
        DBIN        : out std_logic;                                        -- сигнал чтения
        SYNC        : out std_logic;
        VAIT        : out std_logic;
        HLDA        : out std_logic;
        WR_n        : out std_logic;                                        -- сигнал записи
        A           : out std_logic_vector (15 downto 0);                   -- шина адреса
        DI          : in std_logic_vector (7 downto 0);                     -- входная шина данных
        DO          : out std_logic_vector (7 downto 0)                     -- выходная шина данных
    );
end component;

component lpm_dos1 is                                                       -- ПЗУ 8 кБайт - SD Loader
    port                                                                    
    (
        address     : in std_logic_vector (12 downto 0);                    -- адресная шина
        clock       : in std_logic:= '1';                                   -- вход тактовой частоты
        q           : out std_logic_vector (7 downto 0)                     -- выходная шина данных
    );
end component;

component lpm_test_m is                                                     -- ПЗУ 2 кБайт - Тест-М
    port                                                                    
    (
        address     : in std_logic_vector (10 downto 0);                    -- адресная шина
        clock       : in std_logic:= '1';                                   -- вход тактовой частоты
        q           : out std_logic_vector (7 downto 0)                     -- выходная шина данных
    );
end component;

component lpm_dos2 is                                                       -- ПЗУ 27 кБайт - RAMFOS
    port                                                                    
    (
        address     : in std_logic_vector (14 downto 0);                    -- адресная шина
        clock       : in std_logic:= '1';                                   -- вход тактовой частоты
        q           : out std_logic_vector (7 downto 0)                     -- выходная шина данных
    );
end component;

component lpm_test_mx is                                                    -- ПЗУ 2 кБайт - Тест_МX
    port                                                                    
    (
        address     : in std_logic_vector (10 downto 0);                    -- адресная шина
        clock       : in std_logic:= '1';                                   -- вход тактовой частоты
        q           : out std_logic_vector (7 downto 0)                     -- выходная шина данных
    );
end component;

component altpll0 is                                                        -- делитель частоты
    port
    (
        inclk0      : in std_logic:= '0';                                   -- входная частота 50 МГц
        c0          : out std_logic                                         -- выходная частота 32 МГц
    );
end component;

component spetskeyboard is                                                  -- контроллер клавиатуры                                        
    port(
        clk         : in std_logic;                                         -- синронизация
        reset       : in std_logic;                                         -- сброс интерфейса
        res_k       : out std_logic;                                        -- клавиша "Сброс"
        metod       : in std_logic;                                         -- метод опроса
        ps2_clk     : in std_logic;                                         -- синхронизация с PS/2 клавиатуры
        ps2_data    : in std_logic;                                         -- данные с PS/2 клавиатуры
        sp_kb_scan  : in std_logic_vector (11 downto 0);                    -- код опроса
        mode    	: in std_logic;                                         -- режим "Стандарт / МХ"
        rus_lat    	: in std_logic;                                         -- режим клавиатуры "РУС / LAT" 
        sp_kb_out   : out std_logic_vector (11 downto 0);                   -- код ответа
        key_ss      : out std_logic;                                        -- клавиша "НР"
        test_k      : out std_logic;                                        -- клавиша "Тест"
        ruslat_k    : out std_logic;                                        -- клавиша "РУС / LAT"
        turbo_k     : out std_logic;                                        -- клавиша "Турбо"
        mx_k        : out std_logic                                         -- клавиша "МХ / Стандарт"
);
end component;

component SPI is                                                            -- SPI интерфейс
    port(
        A0          : in std_logic;                                         -- адрес        
        WR          : in std_logic;                                         -- сигнал записи
        CS          : in std_logic;                                         -- выборка SPI интерфейса       
        MISO        : in std_logic;                                         -- последовательный вход данных с SD карты
        INSERT      : in std_logic;                                         -- датчик наличия SD карты      
        CLK         : in std_logic;                                         -- входная частота 16 МГц
        DI0         : in std_logic;                                         -- входная шина данных
        DI1         : in std_logic;                                         -- входная шина данных
        DI2         : in std_logic;                                         -- входная шина данных
        DI3         : in std_logic;                                         -- входная шина данных
        DI4         : in std_logic;                                         -- входная шина данных
        DI5         : in std_logic;                                         -- входная шина данных
        DI6         : in std_logic;                                         -- входная шина данных
        DI7         : in std_logic;                                         -- входная шина данных
        RESET       : in std_logic;                                         -- сигнал сброса
        LED_RED     : out std_logic;                                        -- светодиод "OPERATE"
        LED_GREEN   : out std_logic;                                        -- светодиод "INSERT"
        HI          : out std_logic;                                        -- верхняя частота SPI интерфейса
        LO          : out std_logic;                                        -- нижняя частота SPI интерфейса    
        SD_CLK      : out std_logic;                                        -- синхронизация SD карты
        MOSI        : out std_logic;                                        -- последовательный выход данных на SD карту
        SD_CS       : out std_logic;                                        -- выборка SD карты
        DO0         : out std_logic;                                        -- выходная шина данных
        DO1         : out std_logic;                                        -- выходная шина данных
        DO2         : out std_logic;                                        -- выходная шина данных
        DO3         : out std_logic;                                        -- выходная шина данных
        DO4         : out std_logic;                                        -- выходная шина данных
        DO5         : out std_logic;                                        -- выходная шина данных
        DO6         : out std_logic;                                        -- выходная шина данных
        DO7         : out std_logic                                         -- выходная шина данных
);
end component;

component AddrSelector is                                                   -- селектор адресов
    port(
		A0          : in std_logic;                                         -- адрес
		A1          : in std_logic;                                         -- адрес
		A2          : in std_logic;                                         -- адрес
		A3          : in std_logic;                                         -- адрес
		A4          : in std_logic;                                         -- адрес
		A5          : in std_logic;                                         -- адрес
		A6          : in std_logic;                                         -- адрес
		A7          : in std_logic;                                         -- адрес
		A8          : in std_logic;                                         -- адрес
		A9          : in std_logic;                                         -- адрес
		A10         : in std_logic;                                         -- адрес
		A11         : in std_logic;                                         -- адрес
		A12         : in std_logic;                                         -- адрес
		A13         : in std_logic;                                         -- адрес
		A14         : in std_logic;                                         -- адрес
		A15         : in std_logic;                                         -- адрес
		RESET       : in std_logic;                                         -- сигнал сброса
		WR          : in std_logic;                                         -- сигнал записи
		TEST        : in std_logic;                                         -- тест
		U0          : out std_logic;                                        -- выборка RAM/ROM-дисков
		U1          : out std_logic;                                        -- выборка контроллера цвета
		U2          : out std_logic;                                        -- выборка резервных портов
		U3          : out std_logic;                                        -- выборка контроллера дисковода
		U4          : out std_logic;                                        -- выборка таймера
		U5          : out std_logic;                                        -- выборка контроллера дисковода
		U6          : out std_logic;                                        -- выборка портов программатора
		U7          : out std_logic;                                        -- выборка портов клавиатуры
		RAMD        : out std_logic;                                        -- выборка RAM-диска
		ROM         : out std_logic;                                        -- выборка ROM-диска
		RAM         : out std_logic                                         -- выборка основного ОЗУ
);
end component;

component pit8253 is                                                      	-- таймер 8253
  port(
		clk         : in std_logic;                                         -- синхронизация
		ce          : in std_logic;                                         -- разрешение работы от синхронизации
		tce         : in std_logic;                                         -- разрешение работы от синхронизации таймеров
		a           : in std_logic_vector (1 downto 0);                     -- шина адреса
		wr          : in std_logic;                                         -- сигнал записи
		rd          : in std_logic;                                         -- сигнал чтения
		gate        : in std_logic_vector (2 downto 0);                     -- входы разрешения, неиспользуются
		din         : in std_logic_vector (7 downto 0);                     -- входная шина данных
		clk2		: in std_logic;                                         -- синхронизация для счётчика №2
		dout        : out std_logic_vector (7 downto 0);                    -- выходная шина данных
		t_out       : out std_logic_vector (2 downto 0)                    	-- выходы таймеров
);
end component;

------------------------------------------- Переменные ------------------------------------------------
signal clock_32:        std_logic;                                          -- синхронизация 32 МГц
signal clock:           std_logic;                                          -- синхронизация 16 МГц
signal res_k:           std_logic;                                          -- клавиша "Сброс"
signal hcnt:            std_logic_vector (8 downto 0) register;             -- счетчик пикселей
signal vcnt:            std_logic_vector (9 downto 0) register;             -- счетчик строк
signal hsync:           std_logic;                                          -- строчный синхроимпульс
signal vsync:           std_logic;                                          -- кадровый синхроимпульс
signal r:               std_logic;                                          -- красный цвет
signal g:               std_logic;                                          -- зелёный цвет
signal b:               std_logic;                                          -- синий цвет
signal i:               std_logic;                                          -- яркость
signal r1:              std_logic;                                          -- красный цвет буфер
signal b1:              std_logic;                                          -- зелёный цвет буфер
signal g1:              std_logic;                                          -- синий цвет буфер
signal screen_pre:      std_logic;                                          -- границы экрана буфер
signal screen:          std_logic;                                          -- границы экрана
signal sel:             std_logic;                                          -- активность видеогенератора на шинах
signal vid_buf:         std_logic_vector (7 downto 0) register;             -- видеоданные, пиксели
signal vid_bw:          std_logic_vector (7 downto 0) register;             -- видеоданные, пиксели
signal vidc_buf:        std_logic_vector (7 downto 0) register;             -- видеоданные, атрибуты
signal vid_c:           std_logic_vector (7 downto 0) register;             -- видеоданные, атрибуты
signal vid_pix:         std_logic;                                          -- выводимый на экран пиксель
signal del:             std_logic_vector (2 downto 0);                      -- буфер частоты
signal dataI:           std_logic_vector (7 downto 0);                      -- входная шина данных процессора
signal dataO:           std_logic_vector (7 downto 0);                      -- выходная шина данных процессора
signal a_buff:          std_logic_vector (15 downto 0);                     -- адресная шина процессора
signal wr_n:            std_logic;                                          -- запись
signal rd_n:            std_logic;                                          -- чтение
signal rd:              std_logic;                                          -- чтение
signal mreq_n:          std_logic;                                          -- выбор памяти ОЗУ для операций
signal ram:             std_logic_vector (19 downto 0);                     -- адресная шина ОЗУ
signal romd_d:          std_logic_vector (7 downto 0);                      -- шина данных ПЗУ
signal romd_d1:         std_logic_vector (7 downto 0);                      -- шина данных ПЗУ
signal romd_d2:         std_logic_vector (7 downto 0);                      -- шина данных ПЗУ
signal romd_d3:         std_logic_vector (7 downto 0);                      -- шина данных ПЗУ
signal romd_d4:         std_logic_vector (7 downto 0);                      -- шина данных ПЗУ
signal rom_addr:        std_logic;                                          -- область памяти ПЗУ
signal romsel_test:     std_logic;                                          -- выборка ПЗУ "Тест-М"
signal romsel_dos:      std_logic;                                          -- выборка ПЗУ "DOS"
signal u0:              std_logic;                                          -- выборка RAM/ROM-дисков
signal u1:              std_logic;                                          -- выборка контроллера цвета
--signal u2:              std_logic;                                        -- выборка резервных портов
signal u3:              std_logic;                                          -- выборка контроллера дисковода
signal u4:                std_logic;                                      	-- выборка таймера
--signal u5:              std_logic;                                        -- выборка контроллера дисковода
signal u6:              std_logic;                                          -- выборка портов программатора
signal u7:              std_logic;                                          -- выборка портов клавиатуры
signal u6mx:            std_logic;                                          -- выборка портов программатора в режиме "МХ"
signal u7mx:            std_logic;                                          -- выборка портов клавиатуры в режиме "МХ"
--signal u4wr:            std_logic;                                          -- запись в таймер
signal u4rd:            std_logic;                                          -- чтение из таймера
signal u7wr:            std_logic;                                          -- запись в порт клавиатуры
signal u7rd:            std_logic;                                          -- чтение из порта клавиатуры
signal res_n:           std_logic;                                          -- сброс
signal clk_cpu:         std_logic;                                          -- синхронизация для процессора
signal scan_in:         std_logic_vector (11 downto 0);                     -- код опроса клавиатуры
signal scan_out:        std_logic_vector (11 downto 0);                     -- код ответа клавиатуры
signal shift:           std_logic;                                          -- клавиша "НР"                         
signal test_key:        std_logic;                                          -- клавиша "Тест"
signal metod:           std_logic;                                          -- метод опроса клавиатуры
signal porta:           std_logic_vector (7 downto 0);                      -- порт А клавиатуры
signal porta1:          std_logic_vector (7 downto 0);                      -- порт А клавиатуры
signal portb:           std_logic_vector (7 downto 0);                      -- порт В клавиатуры
signal portb1:          std_logic_vector (7 downto 0);                      -- порт В клавиатуры
signal portc:           std_logic_vector (3 downto 0);                      -- порт С клавиатуры
signal portc1:          std_logic_vector (3 downto 0);                      -- порт С клавиатуры
signal portr:           std_logic_vector (7 downto 0);                      -- порт РУС клавиатуры
signal snd:             std_logic;                                          -- выход звука в режиме "Стандарт"
signal snd_mx:          std_logic;                                          -- выход звука в режиме "МХ"
signal test:            std_logic:= '0';                                    -- тест отключён/включён    
signal cd_in:           std_logic_vector (7 downto 0);                      -- входная шина данных видео ОЗУ цвета
signal turbo_key:       std_logic;                                          -- клавиша "Турбо"
signal turbo:           std_logic:= '0';                                    -- скорость: 4 МГц/2 МГц
signal np:              std_logic:= '1';                                    -- триггер начального пуска
signal sd_i:            std_logic_vector (7 downto 0);                      -- входная шина данных SD контроллера
signal sd_o:            std_logic_vector (7 downto 0);                      -- выходная шина данных SD контроллера
signal spi_cs:          std_logic;                                          -- выборка SD интерфейса
signal mode:            std_logic;                                          -- режим "Стандарт" / "МХ"
signal mx_st_key:       std_logic;                                          -- клавиша "Стандарт" / "МХ"
signal ramdisk:         std_logic;                                    		-- выборка RAM-диска
signal romdisk:         std_logic;                                    		-- выборка ROM-диска
signal page:			std_logic_vector (1 downto 0);						-- страника RAM-диска
signal ruslat:         	std_logic;                                    		-- режим клавиатуры "РУС / LAT" 
signal rs_lt_key:      	std_logic;                                    		-- клавиша "РУС / LAT"
signal t_i:          	std_logic_vector (7 downto 0);                      -- входная шина данных таймера
signal t_o:          	std_logic_vector (7 downto 0);                      -- выходная шина данных таймера
signal t_out:        	std_logic_vector (2 downto 0);                      -- выходы таймеров
signal clk2:      		std_logic;                                    		-- входная частота для счётчика №2

begin

------------------------------------------- Синхрогенератор -------------------------------------------
clock <= not clock when (clock_32'event and clock_32 = '0');                -- выходная частота 16 МГц

----------------------------------- Делитель частоты для процессора -----------------------------------
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
                clk_cpu <= del (1);                                         -- "Турбо" режим 4 МГц
            else
                clk_cpu <= del (2);                                         -- "Нормальный" режим 2 МГц
            end if;
        end if;
end process;

------------------------------------- Сигналы выбора и управления -------------------------------------
mreq_n <= '0';                                                              -- используется в Z80      
sel <= '1' when (hcnt (2 downto 0) = "000" and del(0) = '0') else '0';      -- арбитр работы ОЗУ с процессором либо с синхрогенератором
res_n <= '0' when (res_k = '1') else '1';                                   -- сигнал сброса
mode <= '1' when (mx_st_key = '1') else '0';                                -- режим работы: "Стандарт/МХ"
test <= '1' when (test_key = '1') else '0';                                 -- тест отключён/включён
ruslat <= '1' when (rs_lt_key = '1') else '0';                              -- режим клавиатуры "РУС / LAT" 
rd_n <= not rd;                                                             -- сигнал чтения                
turbo <= '1' when (turbo_key = '1') else '0';                               -- скорость: 4 МГц/2 МГц
clk2 <= t_out (1);															-- синхронизация для счётчика №2
   
----------------------------------------- Селектор адресов ------------------------------------------
rom_addr <= a_buff (15) and a_buff (14) and not (a_buff (13) and a_buff (12)); 		    -- адресное пространство ПЗУ
--u4wr <= not (u4 or wr_n);                                                  -- доступ процессору на запись в таймер
u4rd <= not (u4 or rd_n);                                                  -- доступ процессору на чтение из таймера
--u0 <= '1' when (a_buff (15 downto 2) = x"3FFF" and mode = '1' and wr_n = '0') else '0';	-- выборка RAM/ROM-дисков в режиме МХ
--u1 <= '1' when (a_buff(15 downto 0) = x"FFF8" and wr_n = '0') else '0';
--u3 <= '1' when (a_buff (15 downto 2) = x"3FFC" and mode = '1') else '1';    -- выборка К1816ВГ93 в режиме МХ
u6 <= '1' when ((a_buff (15 downto 11) = "11110" and mode = '0') 
	or (u6mx = '0' and mode = '1')) else '0';  								-- выборка портов программатора
--u6mx <= '0' when (a_buff(15 downto 2) = x"3FF9") else '1'; 
u7 <= '1' when ((a_buff (15 downto 11) = "11111" and mode = '0') 
	or (u7mx = '0' and mode = '1')) else '0';  								-- выборка портов клавиатуры
u7wr <= (u7 and not (mreq_n or wr_n));                                      -- доступ процессору на запись в порт клавиатуры
u7rd <= (u7 and not (mreq_n or rd_n));										-- доступ процессору на чтение из порта клавиатуры
--u7mx <= '0' when (a_buff(15 downto 2) = x"3FF8") else '1';                                     
spi_cs <= u6 when mode = '0' else not u3;                                   -- выборка SPI интерфейса

process (res_n,u0,mode,dataO (1 downto 0))
	begin
		if res_n = '0' then													-- сброс
			page <= "00";													-- сброс номера страницы
		elsif ((u0'event and u0 = '1') and mode = '1') then			
			page <= dataO (1 downto 0);										-- номер страницы
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
			romsel_dos <= np and not a_buff (15) and not test;				-- выборка ПЗУ при DOSе
			romsel_test <= ((np and test) or (not np and rom_addr and test));	-- выборка ПЗУ при Тесте-М  
		else			
			romsel_dos <= not (romdisk or test);							-- выборка ПЗУ и ROM-диска	
			romsel_test <= not (romdisk or not test);						-- выборка ПЗУ при Тесте_МХ
		end if;
end process;

--------------------------------------- Чтение из процессора ------------------------------------------
process(clock,res_n,u7wr,a_buff (1 downto 0),dataO,u1,mode)
    begin
        if res_n = '0' then
            porta <= "00000000";
            portb <= "00000000";
            portc <= "0000";
            portr <= "00000000";
            cd_in <= "11111111";                                            -- эмуляция Z-состояния порта С для ч/б вывода
            np <= '1';                                                      -- триггер начального пуска         
        elsif (clock'event and clock = '0') then
			if (u7wr = '1') then
            case a_buff (1 downto 0) is
                when "00" =>                                                -- порт А клавиатуры
                    porta <= dataO;                                         -- код опроса
                when "01" =>                                                -- порт В клавиатуры
                    portb <= dataO;                                         -- код опроса
                when "10" =>                                                -- порт С клавиатуры
                    portc <= dataO (3 downto 0);                            -- код опроса
                    if mode = '0' then
                        cd_in <= "11111" & not dataO (4) & not dataO (6) & not dataO (7);   -- ввод данных о цвете
                    end if;
                when "11" =>                                                -- порт РУС клавиатуры
                    portr <= dataO;                                         
                    np <= '0';                                              -- сброс триггера начального пуска
            end case;
			elsif (u1 = '1' and mode = '1') then 							-- запись в регистр цвета
				cd_in <= dataO;                                             -- ввод данных о цвете            
			end if;
		end if;
end process;

process(clock,portc,portb (7 downto 2),porta)                               -- эмуляция Z-состояния входов 8255
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
            
scan_in <= (portc1 & porta1) when (metod = '0') else ("111111" & portb1 (7 downto 2));      -- код опроса

----------------------------------------- Коммутация адресов ----------------------------------------------------
process(clock,sel,hcnt (8 downto 3),vcnt (8 downto 1),a_buff,ramdisk,wr_n,mode,page)
    begin
        if sel = '1' then
            ram <= "000" & clock & "10" & hcnt (8 downto 3) & vcnt (8 downto 1);    -- адрес с синхрогенератора
        else
			if (clock = '1' and a_buff (15 downto 14) = "10" and ramdisk = '1' and wr_n = '0') then
				ram <= "0001" & a_buff;                       				-- 8000...BFFF - видео ОЗУ цвета
			else
				if (ramdisk = '0' and mode = '1') then						-- 0000...FFBF - RAM-диск
					ram <= "01" & page & a_buff;			
				else														-- 0000...BFFF - ОЗУ							
					ram <= "0000" & a_buff;
				end if;                       				
			end if;	
		end if;
end process;   
 
ma <= ram;

----------------------------------------- Коммутация данных ------------------------------------------- 
md 	<= 	dataO when (sel = '0' and mreq_n = '0' and clock = '0' and wr_n = '0') else  
		cd_in when (sel = '0' and mreq_n = '0' and clock = '1' and wr_n = '0') else 
		"ZZZZZZZZ";   -- шина данных ОЗУ
sd_i <= dataO when (spi_cs = '1' and (clock'event and clock = '1'));        -- входная шина данных SD интерфейса
t_i <= dataO when (u4 = '0' and (clk_cpu'event and clk_cpu = '1'));     	-- входная шина данных таймера

---------------------------------------- Запись в процессор -------------------------------------------
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
                dataI <= romd_d3;                                           -- чтение данных с ПЗУ
            elsif (spi_cs = '1') then
                dataI <= sd_o;                                              -- вывод данных с SD интерфейса
			elsif (u4rd = '1') then
				dataI <= t_o;                                               -- вывод данных с таймера
            elsif (u7rd = '1') then                                         -- запись в порты клавиатуры
                case a_buff (1 downto 0) is
                    when "00" =>                                            -- порт А клавиатуры
                        dataI <= scan_out (7 downto 0);                     -- код ответа
                        metod <= '1';
                    when "01" =>                                            -- порт В клавиатуры
                        dataI <= scan_out (5 downto 0) & not shift & '1';   -- код ответа
                        metod <= '0';
                    when "10" =>                                            -- порт С клавиатуры
                        dataI <= "0000" & scan_out (11 downto 8);           -- код ответа
                        metod <= '1';
                    when "11" =>                                            -- порт РУС клавиатуры
                        dataI <= portr;
                end case;
            else 
                dataI <= md;                                                -- на шину данных процессора - данные с ОЗУ
            end if;
        end if;
end process;
 
--------------------------------------- Секция видео системы ------------------------------------------
process(clock,hcnt)                                                         -- горизонтальная синхронизация
    begin
        if (clock'event and clock = '1') then                          
            if hcnt = 32 then
                hsync <= '0';
            elsif hcnt = 90 then
                hsync <= '1'; 
            end if;
        end if; 
end process;

process(clock,vcnt (9 downto 1))                                         	-- вертикальная синхронизация
    begin
        if (clock'event and clock = '1') then
            if vcnt (9 downto 1) = 278 then
                vsync <= '0';
            elsif vcnt (9 downto 1) = 282 then
                vsync <= '1';
            end if;
        end if;
end process;                                           

process(clock,hcnt,vcnt (9))                                            	-- экран/заэкранье         
    begin
        if (clock'event and clock = '1') then
            if (hcnt = 128 and vcnt (9) = '0') then
                screen_pre <='1';
            elsif (hcnt = 511) then
                screen_pre <= '0';
            end if;
        end if;
end process;
  
--------------------------------------- Чтение видео данных -------------------------------------------
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

process(hcnt (2 downto 0),vid_bw)                                         	-- регистр сдвига видео данных
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

process(clock,hcnt (2 downto 0),vid_buf,vidc_buf,screen_pre)                -- подготовка видеоданных для мультиплексирования
    begin
        if hcnt (2 downto 0) = "111" then
            if clock'event and clock = '1' then
                vid_bw <= vid_buf;
                vid_c  <= vidc_buf;
                screen <= screen_pre;                                       -- реально отображаемый экран
            end if;
        end if;
end process;    

process(clock,screen,vid_pix,mode,vid_c)                                    -- видеомультиплексирование
    begin
     if clock'event and clock = '1' then
        if screen = '1' then 
            if vid_pix = '1' then
                if mode = '0' then
                    r <= vid_c (0);                                         -- сигнал красного цвета
                    g <= vid_c (1);                                         -- сигнал зелёного цвета
                    b <= vid_c (2);                                         -- сигнал синего цвета
                    i <= '1';                                               -- сигнал яркости
                else                                                        -- цвет INK:
                    r <= vid_c (6);                                         -- сигнал красного цвета
                    g <= vid_c (5);                                         -- сигнал зелёного цвета
                    b <= vid_c (4);                                         -- сигнал синего цвета
                    i <= vid_c (7);                                         -- сигнал яркости
                end if;
            else
                if mode = '0' then
                    r <= '0';
                    g <= '0';
                    b <= '0';
                    i <= '0';
                else                                                        -- цвет PAPER:
                    r <= vid_c (2);                                         -- сигнал красного цвета
                    g <= vid_c (1);                                         -- сигнал зелёного цвета
                    b <= vid_c (0);                                         -- сигнал синего цвета
                    i <= vid_c (3);                                         -- сигнал яркости
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

----------------------------------------- Вывод сигналов ----------------------------------------------
ma <= ram;                                                                  -- вывод шины адреса ОЗУ
h_sync <= '0' when hsync = '0' else '1';                                    -- СГИ
v_sync <= '0' when vsync = '0' else '1';                                    -- КГИ

--snd <= not (portr (0)) when (portr (7) = '0' and (clock'event and clock = '0')); -- вывод звука в режиме "Стандарт"
--snd_mx <= not snd or (not (t_out (0) or t_out (2)));                    	-- вывод звука в режиме МХ
--sound <= '0' when ((snd = '0' and mode = '0') or (snd_mx = '1' and mode = '1')) else '1';    -- вывод звука

sound <= not ((portr(0) and t_out(2)) or t_out(0)) or portr(7);


ram_ce <= '0';                                   							-- выборка ОЗУ
ram_oe <= '0' when ((sel = '1') or (rd_n = '0')) else '1';  				-- выборка выходов ОЗУ
ram_we <= '0' when (sel = '0' and wr_n = '0' and clock_32 = '1') else '1';	-- сигнал чтения/записи ОЗУ

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

------------------------------------------ Интерфейсы -------------------------------------------------

VM80:T8080se                                                                -- микропроцессор 8080
port map(
            RESET_n         => res_n,                                       -- сигнал сброса
            CLK             => clk_cpu,                                     -- синхронизация 2/4 МГц
            CLKEN           => '1',
            READY           => '1',
            HOLD            => '0',
            INT             => '0',
            INTE            => open,
            DBIN            => rd,                                          -- сигнал чтения
            SYNC            => open,
            VAIT            => open,
            HLDA            => open,
            WR_n            => wr_n,                                        -- сигнал записи
            A               => a_buff (15 downto 0),                        -- шина адреса
            DI              => dataI (7 downto 0),                          -- входная шина данных
            DO              => dataO (7 downto 0)                           -- выходная шина данных
    );      

monitor2:lpm_dos1                                                           -- 8 кБайт - DOS
port map(
            address         => a_buff (12 downto 0),                        -- адресная шина    
            clock           => not clock,                                   -- синронизация
            q               => romd_d1                                      -- выходная шина данных     
    );
    
test_m:lpm_test_m                                                           -- ПЗУ 2 кБайт - Тест-М
port map(
            address         => a_buff (10 downto 0),                        -- адресная шина
            clock           => not clock,                                   -- синронизация
            q               => romd_d2                                      -- выходная шина данных
    );

ramfos:lpm_dos2                                                             -- 27 кБайт - DOS
port map(
            address         => a_buff (14 downto 0),                        -- адресная шина
            clock           => not clock,                                   -- синронизация
            q               => romd_d3                                      -- выходная шина данных     
    );
    
test_mx:lpm_test_mx                                                         -- ПЗУ 2 кБайт - Тест_МX
port map(
            address         => a_buff (10 downto 0),                        -- адресная шина
            clock           => not clock,                                   -- синронизация
            q               => romd_d4                                      -- выходная шина данных
    );

pll: altpll0
port map(
            inclk0          => clk,                                         -- 50 МГц
            c0              => clock_32                                     -- 32 МГц
    );
        
spetskey:spetskeyboard                                                      -- контроллер клавиатуры                                                        
port map(
            clk             => clock_32,                                	-- синхронизация                                 
            reset           => '0',                                         -- сброс интерфейса                                     
            res_k           => res_k,                                       -- клавиша "Сброс"
            metod           => metod,                                       -- метод опроса                             
            ps2_clk         => ps2_clk,                                     -- синхронизация с PS/2 клавиатуры                                  
            ps2_data        => ps2_data,                                    -- данные с PS/2 клавиатуры                                 
            sp_kb_scan      => scan_in,                                     -- код опроса
            mode      		=> mode,                                     	-- режим "Стандарт / МХ"
            rus_lat      	=> ruslat,                                     	-- режим клавиатуры "РУС / LAT" 
            sp_kb_out       => scan_out,                                    -- код ответа
            key_ss          => shift,                                       -- клавиша "НР"                                      
            test_k          => test_key,                                    -- клавиша "Тест"
            ruslat_k      	=> rs_lt_key,                                   -- клавиша "РУС / LAT"
            turbo_k         => turbo_key,                                   -- клавиша "Турбо"                                               
            mx_k            => mx_st_key                                    -- клавиша "МХ / Стандарт"                             
);

SD:SPI                                                                      -- SPI интерфейс
port map(
            A0              => a_buff (0),                                  -- адрес            
            WR              => wr_n,                                        -- сигнал записи
            CS              => not spi_cs,                                  -- выборка SPI интерфейса
            MISO            => miso,                                        -- последовательный вход данных с SD карты
            INSERT          => sd_ins,                                      -- датчик наличия SD карты
            CLK             => not clock,                                   -- входная частота 16 МГц
            DI0             => sd_i (0),                                    -- входная шина данных
            DI1             => sd_i (1),                                    -- входная шина данных
            DI2             => sd_i (2),                                    -- входная шина данных
            DI3             => sd_i (3),                                    -- входная шина данных
            DI4             => sd_i (4),                                    -- входная шина данных
            DI5             => sd_i (5),                                    -- входная шина данных
            DI6             => sd_i (6),                                    -- входная шина данных
            DI7             => sd_i (7),                                    -- входная шина данных
            RESET           => res_n,                                       -- сигнал сброса
			LED_RED         => led_red,                                     -- светодиод "OPERATE"
			LED_GREEN       => led_green,                                   -- светодиод "INSERT"
            HI              => open,                                        -- верхняя частота SPI интерфейса
            LO              => open,                                        -- нижняя частота SPI интерфейса
            SD_CLK          => sd_clk,                                      -- синхронизация SD карты
            MOSI            => mosi,                                        -- последовательный выход данных на SD карту
            SD_CS           => sd_cs,                                       -- выборка SD карты     
            DO0             => sd_o (0),                                    -- выходная шина данных
            DO1             => sd_o (1),                                    -- выходная шина данных
            DO2             => sd_o (2),                                    -- выходная шина данных
            DO3             => sd_o (3),                                    -- выходная шина данных
            DO4             => sd_o (4),                                    -- выходная шина данных
            DO5             => sd_o (5),                                    -- выходная шина данных
            DO6             => sd_o (6),                                    -- выходная шина данных
            DO7             => sd_o (7)                                     -- выходная шина данных         
);

AS:AddrSelector                                                   	    	-- селектор адресов
port map(
            A0              => a_buff (0),                                  -- адрес
			A1              => a_buff (1),                                  -- адрес
			A2              => a_buff (2),                                  -- адрес
			A3              => a_buff (3),                                  -- адрес
			A4              => a_buff (4),                                  -- адрес
			A5              => a_buff (5),                                  -- адрес
			A6              => a_buff (6),                                  -- адрес
			A7              => a_buff (7),                                  -- адрес
			A8              => a_buff (8),                                  -- адрес
			A9              => a_buff (9),                                  -- адрес
			A10             => a_buff (10),                                 -- адрес
			A11             => a_buff (11),                                 -- адрес
			A12             => a_buff (12),                                 -- адрес
			A13             => a_buff (13),                                 -- адрес
			A14             => a_buff (14),                                 -- адрес
			A15             => a_buff (15),                                 -- адрес
			RESET           => res_n,                                       -- сигнал сброса
			WR              => wr_n,                                        -- сигнал записи
			TEST            => test,                                        -- тест
			U0              => u0,                                          -- выборка RAM/ROM-дисков
			U1              => u1,                                        	-- выборка контроллера цвета
			U2              => open,                                        -- резерв
			U3              => u3,                                          -- выборка контроллера дисковода
			U4              => u4,                                        	-- выборка таймера
			U5              => open,                                        -- выборка контроллера дисковода
			U6              => u6mx,                                        -- выборка портов программатора
			U7              => u7mx,                                        -- выборка портов клавиатуры
			RAMD            => ramdisk,                                     -- выборка RAM-диска
			ROM             => romdisk,                                     -- выборка ROM-диска
			RAM             => open                                       	-- выборка основного ОЗУ
);

t8253:pit8253                                                             	-- таймер 8253
port map(
			clk           	=> clk_cpu,                                 	-- синхронизация
			ce              => not u4,                                      -- разрешение работы от синхронизации
			tce             => not u4,                                      -- разрешение работы от синхронизации таймеров
			a      			=> a_buff (1 downto 0),                         -- шина адреса
			wr              => wr_n,                                    	-- сигнал записи
			rd              => rd_n,                                    	-- сигнал чтения
			gate            => "111",                                      	-- входы разрешения, не используются
			din             => t_i (7 downto 0),                            -- входная шина данных
			clk2			=> clk2,                                        -- сихронизация для счётчика №2
			dout            => t_o (7 downto 0),                            -- выходная шина данных
			t_out           => t_out (2 downto 0)                          	-- выходы таймеров
  );

end spets_fpga_arch;