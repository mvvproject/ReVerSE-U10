-- -----------------------------------------------------------------------
--
-- Syntiac VHDL support files.
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2009 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com
--
-- This source file is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published
-- by the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This source file is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program. If not, see <http://www.gnu.org/licenses/>.
--
-- -----------------------------------------------------------------------
--
-- PS/2 mouse driver
--
-- -----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

-- -----------------------------------------------------------------------

entity io_ps2_mouse is
	generic (
		clockFilter : integer := 15;
		ticksPerUsec : integer := 33   -- 33 Mhz clock
	);
	port (
		clk: in std_logic;
		ps2_clk_in: in std_logic;
		ps2_dat_in: in std_logic;
		ps2_clk_out: out std_logic;
		ps2_dat_out: out std_logic;
		
		mousePresent : out std_logic;
		
		leftButton : out std_logic;
		middleButton : out std_logic;
		rightButton : out std_logic;
		X : out std_logic_vector(7 downto 0);
		Y : out std_logic_vector(7 downto 0)
	);
end entity;

-- -----------------------------------------------------------------------

architecture rtl of io_ps2_mouse is
	constant ticksPer100Usec : integer := ticksPerUsec * 100;
	constant tickTimeout : integer := ticksPerUsec * 3500000;
	type comStateDef is (
		stateIdle, stateWait100, stateWaitClockLow, stateWaitClockHigh, stateClockAndDataLow, stateWaitAck,
		stateRecvBit, stateWaitHighRecv);
	type mainStateDef is (
		stateInit, stateInitAA, stateInitID, stateReset, stateResetAck, 
		stateSetStreamMode, stateSetStreamModeAck, stateSetDataReporting, stateSetDataReportingAck,
		stateWaitByte1, stateWaitByte2, stateWaitByte3);

	signal comState : comStateDef := stateIdle;
	signal masterState : mainStateDef := stateInit;
	signal clkReg: std_logic := '1';
	signal clkFilterCnt: integer range 0 to clockFilter;
	signal waitCount : integer range 0 to ticksPer100Usec := 0;
	signal timeoutCount : integer range 0 to tickTimeout;
	signal currentBit : std_logic;
	signal bitCount : unsigned(3 downto 0);
	signal parity : std_logic;

	signal recvTrigger : std_logic := '0';
	signal sendTrigger : std_logic := '0';
	signal sendByte : unsigned(7 downto 0);
	signal recvByte : unsigned(10 downto 0);
	
	signal currentX : unsigned(7 downto 0);
	signal currentY : unsigned(7 downto 0);
	signal cursorX : signed(7 downto 0):=X"7F";
	signal cursorY : signed(7 downto 0):=X"7F";
	signal trigger : std_logic:='0';
	signal DeltaX : signed(7 downto 0);
	signal DeltaY : signed(7 downto 0);
	
begin

	process(clk)
		variable newX : signed(7 downto 0);
		variable newY : signed(7 downto 0);
	begin
		if rising_edge(clk) then

			newX := cursorX + deltaX;
			newY := cursorY + deltaY;

			if trigger = '1' then
				cursorX <= newX;
				cursorY <= newY;
			end if;
		end if;
	end process;
	
	x<= std_logic_vector(cursorX);
	y<= std_logic_vector(cursorY);

	process(clk)
	begin
		if rising_edge(clk) then
			clkReg <= ps2_clk_in;
			if clkReg /= ps2_clk_in then
				clkFilterCnt <= clockFilter;
			elsif clkFilterCnt /= 0 then
				clkFilterCnt <= clkFilterCnt - 1;
			end if;
		end if;
	end process;

	process(clk)
	begin
		if rising_edge(clk) then
			ps2_clk_out <= '1';
			ps2_dat_out <= '1';
			recvTrigger <= '0';
			if waitCount /= 0 then
				waitCount <= waitCount - 1;
			end if;

			case comState is
			when stateIdle =>
				bitCount <= (others => '0');
				parity <= '1';
				if sendTrigger = '1' then
					waitCount <= ticksPer100Usec;
					comState <= stateWait100;
				end if;
				if (clkReg = '0') and (clkFilterCnt = 0) then
					comState <= stateRecvBit;
				end if;
			--
			-- Host announces its wish to send by pulling clock low for 100us
			when stateWait100 =>
				ps2_clk_out <= '0';
				if waitCount = 0 then
					comState <= stateClockAndDataLow;
					waitCount <= ticksPerUsec * 10;
				end if;
			--
			-- Pull data low while keeping clock low. This is host->device start bit.
			-- Now the device will take over and provide the clock so host must release.
			-- Next state is waitClockHigh to check that clock indeed is released
			when stateClockAndDataLow =>
				ps2_clk_out <= '0';
				ps2_dat_out <= '0';
				if waitCount = 0 then
					currentBit <= '0';
					comState <= stateWaitClockHigh;
				end if;
			--
			-- Wait for 0->1 transition on clock for send.
			-- The device reads current bit while clock is low.
			when stateWaitClockHigh =>
				ps2_dat_out <= currentBit;
				if (clkReg = '1') and (clkFilterCnt = 0) then
					comState <= stateWaitClockLow;
				end if;
			--
			-- Wait for 1->0 transition on clock for send
			-- Host can now change the data line for next bit.
			when stateWaitClockLow =>
				ps2_dat_out <= currentBit;
				if (clkReg = '0') and (clkFilterCnt = 0) then
					if bitCount = 10 then
						comState <= stateWaitAck;
					elsif bitCount = 9 then
						-- Send stop bit
						currentBit <= '1';
						comState <= stateWaitClockHigh;
						bitCount <= bitCount + 1;
					elsif bitCount = 8 then
						-- Send parity bit
						currentBit <= parity;
						comState <= stateWaitClockHigh;
						bitCount <= bitCount + 1;
					else
						currentBit <= sendByte(to_integer(bitCount));
						parity <= parity xor sendByte(to_integer(bitCount));
						comState <= stateWaitClockHigh;
						bitCount <= bitCount + 1;
					end if;
				end if;
			--
			-- Transmission of byte done, wait for ack from device then return to idle.
			when stateWaitAck =>
				if (clkReg = '1') and (clkFilterCnt = 0) then
					comState <= stateIdle;
				end if;
			--
			-- Receive a single bit.
			when stateRecvBit =>
				if (clkReg = '0') and (clkFilterCnt = 0) then
					recvByte <= ps2_dat_in & recvByte(recvByte'high downto 1);
					bitCount <= bitCount + 1;
					comState <= stateWaitHighRecv;
				end if;
			--
			-- Wait for 0->1 transition on clock for receive.
			when stateWaitHighRecv =>
				if (clkReg = '1') and (clkFilterCnt = 0) then
					comState <= stateRecvBit;
					if bitCount = 11 then
						recvTrigger <= '1';
						comState <= stateIdle;
					end if;
				end if;
			end case;

			--
			-- Timeout watchdog will reset communication state machine.
			if timeoutCount = 0 then
				comState <= stateIdle;
			end if;

		end if;
	end process;

--
-- Master state machine
	process(clk)
	begin
		if rising_edge(clk) then
			mousePresent <= '0';
			trigger <= '0';
			sendTrigger <= '0';
			if timeoutCount /= 0 then
				timeoutCount <= timeoutCount - 1;
			else
				masterState <= stateReset;
			end if;

			case masterState is
			when stateInit =>
				-- Wait for mouse to perform self-test
				timeoutCount <= tickTimeout;
				masterState <= stateInitAA;
			when stateInitAA =>
				-- Receive selftest result. It should be AAh.
				if recvTrigger = '1' then
					if recvByte(8 downto 1) = X"AA" then
						masterState <= stateInitID;
					end if;
				end if;
			when stateInitID =>
				-- Receive device ID (it isn't checked)
				if recvTrigger = '1' then
					timeoutCount <= tickTimeout;
					masterState <= stateSetStreamMode;
				end if;
			when stateReset =>
				timeoutCount <= tickTimeout;
				-- Reset mouse
				if comState = stateIdle then
					sendByte <= X"FF";
					sendTrigger <= '1';
					masterState <= stateResetAck;
				end if;
			when stateResetAck =>
				if recvTrigger = '1' then
					masterState <= stateInit;
				end if;
			when stateSetStreamMode =>
				if comState = stateIdle then
					sendByte <= X"EA";
					sendTrigger <= '1';
					masterState <= stateSetStreamModeAck;
				end if;
			when stateSetStreamModeAck =>
				if recvTrigger = '1' then
					masterState <= stateSetDataReporting;
				end if;
			when stateSetDataReporting =>
				if comState = stateIdle then
					sendByte <= X"F4";
					sendTrigger <= '1';
					masterState <=  stateSetDataReportingAck;
				end if;
			when stateSetDataReportingAck =>
				if recvTrigger = '1' then
					masterState <= stateWaitByte1;
				end if;
			when stateWaitByte1 =>
				mousePresent <= '1';
				timeoutCount <= tickTimeout;
				if recvTrigger = '1' then
					leftButton <= recvByte(1);
					rightButton <= recvByte(2);
					middleButton <= recvByte(3);
					deltaX(7) <= recvByte(5);
					deltaY(7) <= recvByte(6);
					masterState <= stateWaitByte2;
				end if;
			when stateWaitByte2 =>
				mousePresent <= '1';
				if recvTrigger = '1' then
					deltaX(7 downto 0) <= signed(recvByte(8 downto 1));
					masterState <= stateWaitByte3;
				end if;
			when stateWaitByte3 =>
				mousePresent <= '1';
				if recvTrigger = '1' then
					deltaY(7 downto 0) <= signed(recvByte(8 downto 1));
					trigger <= '1';
					masterState <= stateWaitByte1;
				end if;
			end case;
		end if;
	end process;


	
end architecture;

