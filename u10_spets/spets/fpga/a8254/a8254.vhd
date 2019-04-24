LIBRARY IEEE; 
USE IEEE.std_logic_1164.ALL; 
 
----------------------------------------------------------------- 
--Entity Definition 
----------------------------------------------------------------- 
 
ENTITY a8254 IS 
    PORT ( 
        nCS          : IN     std_logic;												  
        nWR          : IN     std_logic;						   
        nRD          : IN     std_logic;						   
        gate         : IN     std_logic_vector(2 downto 0);						   
       	CLK			 : in        std_logic;   
        data         : in      std_logic_vector( 7 downto 0); 
        adrs         : in      std_logic_vector(1 downto 0);  ---decide the address to read or write together with nCS 
 
                 
       out_sgnl      : OUT    std_logic_vector(2 DOWNTO 0)	   
     				   
        ); 
END; 
 
----------------------------------------------------------------- 
--ARCHITECTURE Definition 
----------------------------------------------------------------- 
 
ARCHITECTURE main_part OF a8254 IS 
 
----------------------------------------------------------------- 
-- COMPONENT Declarations 
----------------------------------------------------------------- 
 
COMPONENT mode_reg  
   PORT ( clk    : in  std_logic; 
          nCS    : IN  std_logic; 
          adrs   : IN  std_logic_vector(1 DOWNTO 0); 
          nWR    : IN  std_logic; 
          nRD    : IN  std_logic; 
          data   : in      std_logic_vector( 7 downto 0); 
           
          wr_finish : out std_logic; 
          rwmode    : OUT std_logic_vector(1 DOWNTO 0); 
        mode_choice : out std_logic_vector(2 downto 0); 
        cnt_choice  : out  std_logic_vector(1 downto 0); 
         binnbcd    : out   std_logic 
        
        ); 
 
END COMPONENT; 
 
COMPONENT cnt_reg  
     PORT ( clk    : in std_logic; 
            adrs   : in std_logic_vector( 1 downto 0); 
            nCS    : in std_logic; 
            nWR    : IN  std_logic; 
        mode_choice: in std_logic_vector(2 downto 0); 
           rwmode  : IN  std_logic_vector(1 DOWNTO 0); 
            data   : IN  std_logic_vector(7 DOWNTO 0); 
           
           countmsb0  : inout std_logic_vector(7 downto 0); 
           countlsb0  : INOUT std_logic_vector(7 DOWNTO 0); 
            countmsb1 : inout std_logic_vector(7 downto 0); 
           countlsb1  : INOUT std_logic_vector(7 DOWNTO 0); 
           countmsb2  : inout std_logic_vector(7 downto 0); 
           countlsb2  : INOUT std_logic_vector(7 DOWNTO 0); 
 
    CE_0     :out  std_logic_vector(15  downto 0); 
    ce_1     :out  std_logic_vector(15 downto 0); 
    ce_2     :out  std_logic_vector(15 downto 0); 
 
 
           mode0_start : out std_logic; 
           mode1_start : out std_logic;   
           mode2_start : out std_logic; 
           mode3_start : out std_logic; 
           mode4_start : out std_logic; 
           mode5_start : out std_logic	   
     				   
        ); 
 
END COMPONENT; 
 
COMPONENT cnt_main_part 
     PORT ( 
          mode_choice : IN  std_logic_vector(2 DOWNTO 0); 
          cnt_choice : IN  std_logic_vector(1 DOWNTO 0); 
          binnbcd    : IN  std_logic; 
          gate       :   in  std_logic_vector(2 downto 0); 
          clk        :   in   std_logic; 
         mode0_start : in std_logic; 
           mode1_start : in std_logic;   
           mode2_start : in std_logic; 
           mode3_start : in std_logic; 
           mode4_start : in std_logic; 
           mode5_start : in std_logic; 
         ce_0     :in  std_logic_vector(15  downto 0); 
    ce_1     :in  std_logic_vector(15 downto 0); 
    ce_2     :in  std_logic_vector(15 downto 0); 
 
         wr_finish   : in std_logic; 
          
          out_sgnl   : OUT std_logic_vector(2 DOWNTO 0));	   
     				   
 
END COMPONENT; 
 
----------------------------------------------------------------- 
-- SIGNAL Declarations 
----------------------------------------------------------------- 
 
 signal      rwmode       :  std_logic_vector(1 DOWNTO 0); 
 signal      mode_choice  :  std_logic_vector(2 downto 0); 
 signal       cnt_choice  :   std_logic_vector(1 downto 0); 
 signal        binnbcd    :    std_logic; 
 signal        countmsb0  :  std_logic_vector(7 downto 0); 
signal         countlsb0  :  std_logic_vector(7 DOWNTO 0); 
signal         countmsb1  :  std_logic_vector(7 downto 0); 
 signal        countlsb1  :  std_logic_vector(7 DOWNTO 0); 
  signal       countmsb2  :  std_logic_vector(7 downto 0); 
 signal        countlsb2  :  std_logic_vector(7 DOWNTO 0); 
 signal   ce_0     :  std_logic_vector(15  downto 0); 
 signal   ce_1     :  std_logic_vector(15 downto 0); 
  signal   ce_2     : std_logic_vector(15 downto 0); 
 
    signal       mode0_start : std_logic; 
    signal       mode1_start :  std_logic;   
   signal        mode2_start :  std_logic; 
    signal       mode3_start :  std_logic; 
    signal       mode4_start :  std_logic; 
    signal       mode5_start :  std_logic;	   
  signal        wr_finish    :  std_logic; 
----------------------------------------------------------------- 
-- Architecture Body 
----------------------------------------------------------------- 
BEGIN 
 
	-- Rename some  of the control register outputs 
  
      
	-- Instaniate Read/Write Control module 
   a8254_1 : mode_reg 
    PORT MAP(clk=>clk, 
        nCS  => nCS,    					 
        adrs  => adrs,      					  
        nWR  => nWR,    				   
        nRD  => nRD,       				  
        data =>  data,        					  
       	wr_finish => wr_finish,			 
        rwmode =>rwmode, 
       mode_choice =>mode_choice, 
       cnt_choice =>cnt_choice, 
       binnbcd =>binnbcd 
     ); 
 
 a8254_2 : cnt_reg 
    PORT MAP( clk=>clk, 
             adrs=>adrs,   
            nCS=>nCS,     
            nWR=>nWR,    
        mode_choice=>mode_choice,  
           rwmode=>rwmode , 
            data=>data,   
           
           countmsb0=>countmsb0,  
           countlsb0=>countlsb0,   
            countmsb1=>countmsb1,  
           countlsb1=>countlsb1 , 
           countmsb2=>countmsb2  , 
           countlsb2=>countlsb2 , 
              ce_0=>ce_0 ,     
               ce_1=>ce_1 ,     
              ce_2=>ce_2 ,     
           mode0_start=>mode0_start,  
           mode1_start=>mode1_start , 
           mode2_start=>mode2_start , 
           mode3_start=>mode3_start,  
           mode4_start=>mode4_start , 
           mode5_start=>mode5_start 	          
             ); 
 a8254_3 :cnt_main_part 
    PORT MAP( 
          mode_choice=>mode_choice, 
          cnt_choice=>cnt_choice , 
          binnbcd=>binnbcd,   
          gate=>gate ,      
          clk=>clk ,  
           mode0_start=>mode0_start,  
           mode1_start=>mode1_start , 
           mode2_start=>mode2_start , 
           mode3_start=>mode3_start,  
           mode4_start=>mode4_start , 
           mode5_start=>mode5_start ,	       
              ce_0=>ce_0 ,     
              ce_1=>ce_1 ,     
              ce_2=>ce_2 ,     
     wr_finish=> wr_finish,       
      out_sgnl=>out_sgnl       
             ); 
 END main_part;