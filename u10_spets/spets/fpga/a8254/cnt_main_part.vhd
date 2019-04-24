  LIBRARY IEEE; 
 LIBRARY  my_lib; 
USE IEEE.std_logic_1164.ALL; 
USE my_lib.mode_set.all; 
USE IEEE.STD_LOGIC_UNSIGNED.ALL; 
ENTITY cnt_main_part IS 
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
       CE_0     :in  std_logic_vector(15  downto 0); 
    CE_1     :in  std_logic_vector(15 downto 0); 
    CE_2     :in  std_logic_vector(15 downto 0); 
 
          wr_finish  : in std_logic; 
          out_sgnl   : OUT std_logic_vector(2 DOWNTO 0) 
    ); 
END; 
 
 
 
ARCHITECTURE main OF cnt_main_part IS 
 
----------------------------------------------------------------- 
-- Internal Architecture Signal declarations 
----------------------------------------------------------------- 
 
signal i: integer:=0; 
signal j: integer:=0; 
signal  ce0: integer:=conv_integer(ce_0); 
signal   cr: integer; 
signal  cee: integer:=1;  
signal gat : std_logic; 
signal gate_t: std_logic:='0'; 
----------------------------------------------------------------- 
-- Architecture body 
----------------------------------------------------------------- 
BEGIN    
cnt_prc: process(clk) 
begin 
   
    if(clk'event and  clk='1')  then  
 
 case   cnt_choice  is  
  when "00"  => 
       out_sgnl(0)<='0'; 
   case mode_choice is  
          when "000" =>  
                   
        if(ce0=cee) then  
         i<=i; 
         else  
         i<=0; 
         end if; 
        cee<=ce0; 
    
  if(ce0>0)   then  
          if (i  --mode1 
      
                  
             
        out_sgnl(0)<='1'; 
       if(ce0=cee) then  
         i<=i; 
         else  
         i<=0; 
         end if; 
        cee<=ce0; 
        
	   if(ce0>0) then   
		    if (i ---mode2 
              out_sgnl(0)<='1'; 
         
         
   
        if(ce0=cee) then  
         i<=i; 
         else  
         i<=0; 
         end if; 
        cee<=ce0; 
    
      if(ce0>0)   then  
          if (i     -----mode3  
             
        out_sgnl(0)<='1'; 
            
  
        if(ce0=cee) then  
         i<=i; 
         else  
         i<=0; 
         end if; 
        cee<=ce0; 
      
     if(ce0>0)   then  
        if(ce_0(0)='0')  then  
            if (i  
     if(ce0=cee) then  
         i<=i; 
         else  
         i<=0; 
         end if; 
        cee<=ce0; 
  
                if(ce0>0) then  
              if (i  -----mode5  
		 
	 
		out_sgnl(0)<='1'; 
	 if(ce0=cee) then  
		 i<=i; 
		 else  
	     
		 i<=0; 
	    end if; 
		cee<=ce0; 
	  
	 if(ce0>0) then   
		    if (ice0-2 and gate_t='1') then  
                i<=ce0-1; 
               out_sgnl(0)<='1'; 
		    else   
				 i<=0; 
				 out_sgnl(0)<='1'; 
		    end if; 
	   end if; 
	   
	    
   out_sgnl(1)<=gate_t; 
           
       when others =>  
       null; 
     end case ; 
   
 
  
 when others => 
  null; 
  end case;  
 end if; 
end process cnt_prc; 
gatt : process(clk)  
begin  
 if(clk'event and clk='1') then  
   gat<=gate(0); 
  if (gate(0)='0' and gat='1') then  
   gate_t<='1'; 
  elsif( gate(0)='1' and gat='0') then  
    gate_t<='0'; 
  end if; 
end if; 
end process gatt; 
out_sgnl(2)<=gate_t; 
end main;  