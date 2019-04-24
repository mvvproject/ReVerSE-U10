  LIBRARY IEEE; 
USE IEEE.std_logic_1164.ALL; 
 
----------------------------------------------------------------- 
--Entity Definition 
----------------------------------------------------------------- 
 
ENTITY cnt_reg IS 
    PORT (  clk     :in std_logic; 
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
 
       ce_0     :out  std_logic_vector(15  downto 0); 
     ce_1     :out  std_logic_vector(15 downto 0); 
     ce_2     :out  std_logic_vector(15 downto 0); 
 
           mode0_start : out std_logic:='0'; 
           mode1_start : out std_logic:='0';   
           mode2_start : out std_logic:='0'; 
           mode3_start : out std_logic:='0'; 
           mode4_start : out std_logic:='0'; 
           mode5_start : out std_logic:='0' 
 ); 
END; 
 
 
 
ARCHITECTURE main OF cnt_reg IS 
 
----------------------------------------------------------------- 
-- Internal Architecture Signal declarations 
----------------------------------------------------------------- 
 -- signal   CE_0     :  std_logic_vector(15  downto 0); 
-- signal    CE_1     :  std_logic_vector(15 downto 0); 
-- signal    CE_2     :  std_logic_vector(15 downto 0); 
 
----------------------------------------------------------------- 
-- Architecture body 
----------------------------------------------------------------- 
BEGIN    
 
cnt_reg_proc : PROCESS(clk) 
BEGIN   
  if( clk'event and clk='0') then  
   if ( nCS='0' and adrs="00" and nWR='0') then 
       if(rwmode="01") then  
              countlsb0<=data; 
              countmsb0<="00000000"; 
       elsif(rwmode="10") then  
              countmsb0<=data; 
              countlsb0<="00000000"; 
       elsif(rwmode="11" )then 
             countlsb0<=data;  
             countmsb0<=data; 
       --   if( nWR'event and nWR='1') then  countlsb0<=data; 
         -- elsif(nWR,event and nWR='1' )then countmsb0<=data; 
         
      --  else  
        -- countlsb0<=countlsb0; 
        -- countmsb0<=countmsb0; 
         end if; 
  elsif ( nCS='0' and adrs="01" and nWR='0') then 
       if(rwmode="01") then  
              countlsb1<=data; 
              countmsb1<="00000000"; 
       elsif(rwmode="10") then  
              countmsb1<=data; 
              countlsb1<="00000000"; 
      elsif(rwmode="11" )then 
              countlsb1<=data;  
             countmsb1<=data;  
     --     if( nWR'event and nWR='1') then  countlsb1<=data; 
     --     elsif(nWR,event and nWR='1' )then countmsb1<=data; 
      --   end if; 
  -- else  
       --  countlsb1<=countlsb1; 
       --  countmsb1<=countmsb1; 
       end if; 
elsif ( nCS='0' and adrs="10" and nWR='0') then 
       if(rwmode="01") then  
              countlsb2<=data; 
               countmsb2<="00000000"; 
       elsif(rwmode="10" and nWR='1') then  
              countmsb2<=data; 
              countlsb2<="00000000"; 
      elsif(rwmode="11" )then 
              countlsb2<=data;  
              countmsb2<=data;       
--    if( nWR'event and nWR='1') then  countlsb2<=data; 
      --    elsif(nWR,event and nWR='1' )then countmsb2<=data; 
      --   end if; 
    --     else  
      --   countlsb2<=countlsb2; 
      --   countmsb2<=countmsb2; 
       end if; 
 end if; 
 
   
      -- difference of different mode to start the count activity and get the signal mode_start. 
  case mode_choice is  
     when "000" => --the befinning of mode0 
     --   if(clk'event and clk='0')  then  
    if (  adrs="00"  )     
      then  ce_0(7 downto 0)<=countlsb0(7 downto 0); 
            ce_0(15 downto 8) <= countmsb0(7 downto 0); 
    
           
       end if; 
      
      mode0_start<='1' ; 
 
   when "001" => 
     if (  adrs="00"  )     
      then  ce_0(7 downto 0)<=countlsb0(7 downto 0); 
            ce_0(15 downto 8) <= countmsb0(7 downto 0); 
   
       end if; 
     mode1_start<='1' ; 
  
   when "010" => 
     if (  adrs="00"  )     
      then  ce_0(7 downto 0)<=countlsb0(7 downto 0); 
            ce_0(15 downto 8) <= countmsb0(7 downto 0); 
   
       end if; 
     mode2_start<='1' ; 
       
    when "011" => 
    if (  adrs="00"  )     
      then  ce_0(7 downto 0)<=countlsb0(7 downto 0); 
            ce_0(15 downto 8) <= countmsb0(7 downto 0); 
   
       end if; 
       mode3_start<='1' ; 
    when "100" => 
         --   if (clk'event and clk='0')then  
      if (adrs="00")     
      then  ce_0(7 downto 0)<= countlsb0(7 downto 0); 
            ce_0(15 downto 8) <= countmsb0(7 downto 0); 
    elsif (adrs="01")     
      then  ce_1(7 downto 0)<= countlsb1(7 downto 0); 
            ce_1(15 downto 8) <= countmsb1(7 downto 0); 
    elsif (adrs="10")     
      then  ce_2(7 downto 0)<= countlsb2(7 downto 0); 
            ce_2(15 downto 8) <= countmsb2(7 downto 0); 
           
      end if; 
   --end if; 
 
 mode4_start<='1' ; 
    when "101" => 
      if (  adrs="00"  )     
      then  ce_0(7 downto 0)<=countlsb0(7 downto 0); 
            ce_0(15 downto 8) <= countmsb0(7 downto 0); 
   
       end if; 
 mode5_start<='1' ; 
   when others => null; 
   end case;    
end if;  
end process ; 
 
 
end main; 