LIBRARY IEEE; 
USE IEEE.std_logic_1164.ALL; 
 
----------------------------------------------------------------- 
--Entity Definition 
----------------------------------------------------------------- 
 
ENTITY mode_reg IS 
    PORT (clk : in  std_logic; 
          nCS : IN  std_logic; 
          adrs : IN  std_logic_vector(1 DOWNTO 0); 
          nWR: IN  std_logic; 
          nRD   : IN  std_logic; 
          data  :in      std_logic_vector( 7 downto 0); 
           
           wr_finish : inout std_logic:='0'; 
          rwmode   : INOUT std_logic_vector(1 DOWNTO 0); 
        mode_choice: inout std_logic_vector(2 downto 0); 
        cnt_choice  : inout  std_logic_vector(1 downto 0); 
         binnbcd    :inout   std_logic 
         
    ); 
END; 
 
ARCHITECTURE main OF mode_reg IS 
---------------------------------------------------------------- 
-- Internal Architecture Signal declarations 
----------------------------------------------------------------- 
 
----------------------------------------------------------------- 
-- Architecture body 
----------------------------------------------------------------- 
BEGIN    
 
main_proc : PROCESS(clk) 
 BEGIN 
        if(clk'event and clk='1') then  
    if( nCS='0' and adrs="11" and nWR='0')  then 
      cnt_choice=data(7 downto 6); 
      rwmode=data(5 downto 4); 
      mode_choice=data( 3 downto 1); 
      binnbcd = data(0); 
      wr_finish='1'; 
     else  
       cnt_choice=cnt_choice; 
       rwmode=rwmode; 
      mode_choice=mode_choice; 
      binnbcd=binnbcd; 
     -- wr_finish='1'; 
    end if ; 
 end if; 
 
 
end process main_proc; 
end main; 