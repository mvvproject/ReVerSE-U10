library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity ZCSPI is
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
end;

architecture rtl of ZCSPI is

signal PORTS_ADDR       : std_logic;

signal PORT_77_CS       : std_logic;
signal PORT_57_CS       : std_logic;

signal PORT_77_WRSTB    : std_logic;
signal PORT_77_RDSTB    : std_logic;
signal PORT_57_WRSTB    : std_logic;
signal PORT_57_RDSTB    : std_logic;

signal SPI_DO           : std_logic_vector(7 downto 0);
signal SPI_DI           : std_logic_vector(7 downto 0);

COMPONENT SPI               
    port(
        --INPUTS
        DI      : in std_logic_vector(7 downto 0);
        CLC     : in std_logic;
        MISO    : in std_logic;
        START   : in std_logic;
        WR_EN   : in std_logic;
        --OUTPUTS
        DO      : out std_logic_vector(7 downto 0);
        SCK     : out std_logic;
        MOSI    : out std_logic
        );
END COMPONENT ;

begin
        SPI_DI <= DIN when PORT_57_WRSTB = '1' else "11111111";
        
        spi1: SPI
            PORT MAP (START => PORT_57_CS, DI => SPI_DI, CLC => CLC, MISO => MISO,
                DO => SPI_DO, SCK => SCK, MOSI => MOSI, WR_EN => PORT_57_WRSTB);

        PORTS_ADDR      <= A(6) and A(4) and A(2) and A(1) and A(0) and not A(7) and not A(3);

        PORT_77_CS      <= A(5) and PORTS_ADDR and not nIORQ;
        PORT_57_CS      <= not A(5) and PORTS_ADDR and not nIORQ;
        
        PORT_77_WRSTB   <= '1' when PORT_77_CS = '1' and nWR = '0' else '0';
        PORT_77_RDSTB   <= '1' when PORT_77_CS = '1' and nRD = '0' else '0';
        PORT_57_WRSTB   <= '1' when PORT_57_CS = '1' and nWR = '0' else '0';
        PORT_57_RDSTB   <= '1' when PORT_57_CS = '1' and nRD = '0' else '0';
        
        ZC_PORTS_READ	<= PORT_77_RDSTB or PORT_57_RDSTB;
        
        process(PORT_77_RDSTB,PORT_57_RDSTB,SPI_DO)
        begin
            if PORT_77_RDSTB = '1' then 
                DOUT <= "11111100";
            elsif PORT_57_RDSTB = '1' then
                DOUT <= SPI_DO;
            else
                DOUT <= "11111111";
            end if;
        end process;
        
        process(PORT_77_WRSTB,nRES)
        begin
            if nRES = '0' then
                nSDCS <= '1';
            elsif PORT_77_WRSTB'event and PORT_77_WRSTB = '0' then
                nSDCS <= DIN(1);
            end if;
        end process;
        
end rtl;