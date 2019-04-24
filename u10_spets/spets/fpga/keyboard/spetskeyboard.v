// Keyboard matrix module

`default_nettype none
module spetskeyboard
(
input		clk,						// синхронизация
input		reset,						// вход сброса
output   	res_k,						// выход сброса
input       metod,						// метод сканирования клавиатуры
input		ps2_clk,					// синхронизация PS/2 клавиатуры
input		ps2_data,					// данные PS/2 клавиатуры
input		[11:0]	sp_kb_scan,			// сканируемый код
input		mode,						// режим работы
output		[11:0]	sp_kb_out,			// код ответа		
output		key_ss,						// клавиша "НР" нажата
output   	test_k,						// клавиша теста
output		turbo_k,					// сигнал "турбо/нормал"
output   	mx_k						// клавиша "МХ / Стандарт"
//input		ind_rus_lat					// со светодиода "РУС / LAT"
);

//Соответствие клавиш:
//Shift - НР
//Caps Lock - РУС / LAT
//Esc - Сброс
//Num - МХ / Стандарт
//Scroll Lock - Тест включён
//Home - Тест выключен
//Page Up - режим Turbo
//Page Down - режим Normal

// при mode=1 нужно:
// при metod=1 - вывод "все нули" на 12 выходов, ответ на 6 входов
// при metod=0 - вывод на 6 выходов, ответ на 12 входов

assign		key_ss = shift;
assign     	res_k = res_key;
assign     	test_k = test_key;
assign		turbo_k = turbo_key;
assign     	mx_k = mx_st_key;
assign		sp_kb_out = sp_kb_out_;		

reg			shift;
reg			ps2rden;	
reg			[7:0]	sp_kb;
reg			[3:0]	state = 0;
reg			[3:0] 	col;
reg			[5:0]	keymatrixa[0:11];
wire		[0:11]	keymatrixb[5:0];

assign 		keymatrixb[0][0] = keymatrixa[11][5];
assign 		keymatrixb[0][1] = keymatrixa[10][5];
assign 		keymatrixb[0][2] = keymatrixa[9][5];
assign 		keymatrixb[0][3] = keymatrixa[8][5];
assign 		keymatrixb[0][4] = keymatrixa[7][5];
assign 		keymatrixb[0][5] = keymatrixa[6][5];
assign 		keymatrixb[0][6] = keymatrixa[5][5];
assign 		keymatrixb[0][7] = keymatrixa[4][5];
assign 		keymatrixb[0][8] = keymatrixa[3][5];
assign 		keymatrixb[0][9] = keymatrixa[2][5];
assign 		keymatrixb[0][10] = keymatrixa[1][5];
assign 		keymatrixb[0][11] = keymatrixa[0][5];

assign 		keymatrixb[1][0] = keymatrixa[11][4];
assign 		keymatrixb[1][1] = keymatrixa[10][4];
assign 		keymatrixb[1][2] = keymatrixa[9][4];
assign 		keymatrixb[1][3] = keymatrixa[8][4];
assign 		keymatrixb[1][4] = keymatrixa[7][4];
assign 		keymatrixb[1][5] = keymatrixa[6][4];
assign 		keymatrixb[1][6] = keymatrixa[5][4];
assign 		keymatrixb[1][7] = keymatrixa[4][4];
assign 		keymatrixb[1][8] = keymatrixa[3][4];
assign 		keymatrixb[1][9] = keymatrixa[2][4];
assign 		keymatrixb[1][10] = keymatrixa[1][4];
assign 		keymatrixb[1][11] = keymatrixa[0][4];

assign 		keymatrixb[2][0] = keymatrixa[11][3];
assign 		keymatrixb[2][1] = keymatrixa[10][3];
assign 		keymatrixb[2][2] = keymatrixa[9][3];
assign 		keymatrixb[2][3] = keymatrixa[8][3];
assign 		keymatrixb[2][4] = keymatrixa[7][3];
assign 		keymatrixb[2][5] = keymatrixa[6][3];
assign 		keymatrixb[2][6] = keymatrixa[5][3];
assign 		keymatrixb[2][7] = keymatrixa[4][3];
assign 		keymatrixb[2][8] = keymatrixa[3][3];
assign 		keymatrixb[2][9] = keymatrixa[2][3];
assign 		keymatrixb[2][10] = keymatrixa[1][3];
assign 		keymatrixb[2][11] = keymatrixa[0][3];

assign 		keymatrixb[3][0] = keymatrixa[11][2];
assign 		keymatrixb[3][1] = keymatrixa[10][2];
assign 		keymatrixb[3][2] = keymatrixa[9][2];
assign 		keymatrixb[3][3] = keymatrixa[8][2];
assign 		keymatrixb[3][4] = keymatrixa[7][2];
assign 		keymatrixb[3][5] = keymatrixa[6][2];
assign 		keymatrixb[3][6] = keymatrixa[5][2];
assign 		keymatrixb[3][7] = keymatrixa[4][2];
assign 		keymatrixb[3][8] = keymatrixa[3][2];
assign 		keymatrixb[3][9] = keymatrixa[2][2];
assign 		keymatrixb[3][10] = keymatrixa[1][2];
assign 		keymatrixb[3][11] = keymatrixa[0][2];

assign 		keymatrixb[4][0] = keymatrixa[11][1];
assign 		keymatrixb[4][1] = keymatrixa[10][1];
assign 		keymatrixb[4][2] = keymatrixa[9][1];
assign 		keymatrixb[4][3] = keymatrixa[8][1];
assign 		keymatrixb[4][4] = keymatrixa[7][1];
assign 		keymatrixb[4][5] = keymatrixa[6][1];
assign 		keymatrixb[4][6] = keymatrixa[5][1];
assign 		keymatrixb[4][7] = keymatrixa[4][1];
assign 		keymatrixb[4][8] = keymatrixa[3][1];
assign 		keymatrixb[4][9] = keymatrixa[2][1];
assign 		keymatrixb[4][10] = keymatrixa[1][1];
assign 		keymatrixb[4][11] = keymatrixa[0][1];

assign 		keymatrixb[5][0] = keymatrixa[11][0];
assign 		keymatrixb[5][1] = keymatrixa[10][0];
assign 		keymatrixb[5][2] = keymatrixa[9][0];
assign 		keymatrixb[5][3] = keymatrixa[8][0];
assign 		keymatrixb[5][4] = keymatrixa[7][0];
assign 		keymatrixb[5][5] = keymatrixa[6][0];
assign 		keymatrixb[5][6] = keymatrixa[5][0];
assign 		keymatrixb[5][7] = keymatrixa[4][0];
assign 		keymatrixb[5][8] = keymatrixa[3][0];
assign 		keymatrixb[5][9] = keymatrixa[2][0];
assign 		keymatrixb[5][10] = keymatrixa[1][0];
assign 		keymatrixb[5][11] = keymatrixa[0][0];


//значения при инициализации
reg     	res_key = 1'b0;
reg     	test_key = 1'b0;
reg			turbo_key = 1'b0;
reg     	mx_st_key = 1'b0;
reg 		mx_st;
reg			ex_code	= 0;	
reg			press_release;
reg			strobe;
reg			[11:0]	sp_kb_out_;

wire		[7:0]	ps2q;	
wire		ps2dsr;

always@ (posedge mx_st) mx_st_key <= (~mx_st_key);

always @(posedge clk) begin
	if (reset) begin
		res_key <= 0;
		test_key <= 0;				
		state <= 0;
	end 
	else begin
		case (state)
		0:
			begin
				if (ps2dsr)
					begin
						ps2rden <= 1;
						state <= 1;
					end
			end
		1:
			begin
				state <= 2;
				ps2rden <= 0;
			end
		2:
			begin
				ps2rden <= 0;
				if (ps2q == 8'hf0)
					begin
						state <= 6;
					end
				else
					if (ps2q == 8'he0)
						begin
							ex_code	<= 1;
							state <= 0;
						end
					else
						begin
							state <= 4;
						end
					end		
		4:
			begin
				if ((ps2q == 8'h12) && ex_code)
					begin
						ex_code <= 0;
						state <= 0;
					end
				else
					case ({ex_code,ps2q})						//реакция на приход сканкода нажатия
						9'h076:         res_key <= 1'b1;        //Esc - Сброс
						9'h07e:			test_key <= 1'b1;		//Scroll Lock - Тест включён
						9'h16c:			test_key <= 1'b0;		//Home - Тест выключен
						9'h17d:			turbo_key <= 1'b1;		//Page Up - режим Turbo
						9'h17a:			turbo_key <= 1'b0;		//Page Down - режим Normal
						9'h077: 		begin 
											mx_st <= 1'b1;     		//Num - МХ / Стандарт
											res_key <= 1'b1;
										end		
						default:
							begin
								sp_kb <= ps2q;
								press_release	<= 1'b1;
								strobe	<=	1'b1;
							end
						endcase
					state <= 5;
				end
		5:
			begin
				strobe <= 1'b0;
				state <= 0;
				ex_code <=  0;
			end		
		6:
			begin
				if (ps2dsr)
					begin
						ps2rden <= 1;
						state <= 7;
					end
				end		
		7:
			begin
				ps2rden <= 0;
				state <= 8;
			end	
		8:
			begin
				if (ps2q == 8'he0)
					begin
						ex_code <= 1'b1;
						state <= 6;
					end
				else
					begin	
						state <= 9;
					end
				end
		9:
			begin
				if ((ps2q == 8'h12) && ex_code)
					begin
						ex_code <= 0;
						state <= 6;
					end
				else
					case({ex_code,ps2q})						//реакция на приход сканкода с префиксом на отпускание
						9'h076:         res_key <= 1'b0;        //Esc - Сброс
						9'h07e:			test_key <= 1'b1;		//Scroll Lock - Тест - Тест включён
						9'h16c:			test_key <= 1'b0;		//Home - Тест выключен
						9'h17d:			turbo_key <= 1'b1;		//Page Up - режим Turbo
						9'h17a:			turbo_key <= 1'b0;		//Page Down - режим Normal
						9'h077:			begin 
											mx_st <= 1'b0;     		//МХ / Стандарт
											res_key <= 1'b0;
										end																	
						default: 
							begin
								sp_kb <= ps2q;
								press_release <= 1'b0;
								strobe <= 1'b1;
							end
					endcase
					state <= 10;
				end
		10:
			begin
        ex_code <=  0;
				strobe <= 1'b0;
				state <= 0;
			end
		endcase
	end
end

always 
	begin
		if (mode == 1'b0) 
			begin
			if (metod == 1'b0) 	
				begin
				sp_kb_out_ = ~({6'h0,   ((sp_kb_scan[0]==1'b0)? keymatrixa[0]: 6'h0) |
										((sp_kb_scan[1]==1'b0)? keymatrixa[1]: 6'h0) |
										((sp_kb_scan[2]==1'b0)? keymatrixa[2]: 6'h0) |
										((sp_kb_scan[3]==1'b0)? keymatrixa[3]: 6'h0) |
										((sp_kb_scan[4]==1'b0)? keymatrixa[4]: 6'h0) |
										((sp_kb_scan[5]==1'b0)? keymatrixa[5]: 6'h0) |
										((sp_kb_scan[6]==1'b0)? keymatrixa[6]: 6'h0) |
										((sp_kb_scan[7]==1'b0)? keymatrixa[7]: 6'h0) |
										((sp_kb_scan[8]==1'b0)? keymatrixa[8]: 6'h0) |
										((sp_kb_scan[9]==1'b0)? keymatrixa[9]: 6'h0) |
										((sp_kb_scan[10]==1'b0)? keymatrixa[10]: 6'h0) |
										((sp_kb_scan[11]==1'b0)? keymatrixa[11]: 6'h0) });
				end
			else 				
				begin
				sp_kb_out_ = ~( ((sp_kb_scan[0]==1'b0)? keymatrixb[5]: 12'h0) |
								((sp_kb_scan[1]==1'b0)? keymatrixb[4]: 12'h0) |
								((sp_kb_scan[2]==1'b0)? keymatrixb[3]: 12'h0) |
								((sp_kb_scan[3]==1'b0)? keymatrixb[2]: 12'h0) |
								((sp_kb_scan[4]==1'b0)? keymatrixb[1]: 12'h0) |
								((sp_kb_scan[5]==1'b0)? keymatrixb[0]: 12'h0) );
				end
			end
		else			
			begin
//		режим МХ
			if (metod == 1'b0) 
				begin
// режим 0 - опрос - посылка 12 нулей, ответ 6 линий, если хоть один 0, то переход на режим 1
				sp_kb_out_ = ~({6'h0,   ((sp_kb_scan[0]==1'b0)? keymatrixa[0]: 6'h0) |
										((sp_kb_scan[1]==1'b0)? keymatrixa[1]: 6'h0) |
										((sp_kb_scan[2]==1'b0)? keymatrixa[2]: 6'h0) |
										((sp_kb_scan[3]==1'b0)? keymatrixa[3]: 6'h0) |
										((sp_kb_scan[4]==1'b0)? keymatrixa[4]: 6'h0) |
										((sp_kb_scan[5]==1'b0)? keymatrixa[5]: 6'h0) |
										((sp_kb_scan[6]==1'b0)? keymatrixa[6]: 6'h0) |
										((sp_kb_scan[7]==1'b0)? keymatrixa[7]: 6'h0) |
										((sp_kb_scan[8]==1'b0)? keymatrixa[8]: 6'h0) |
										((sp_kb_scan[9]==1'b0)? keymatrixa[9]: 6'h0) |
										((sp_kb_scan[10]==1'b0)? keymatrixa[10]: 6'h0) |
										((sp_kb_scan[11]==1'b0)? keymatrixa[11]: 6'h0) });
				end
			else			
				begin
// режим 1 - ответ клавиатуры - 12 линий
				sp_kb_out_ = ~( ((sp_kb_scan[0]==1'b0)? keymatrixb[5]: 12'h0) |
								((sp_kb_scan[1]==1'b0)? keymatrixb[4]: 12'h0) |
								((sp_kb_scan[2]==1'b0)? keymatrixb[3]: 12'h0) |
								((sp_kb_scan[3]==1'b0)? keymatrixb[2]: 12'h0) |
								((sp_kb_scan[4]==1'b0)? keymatrixb[1]: 12'h0) |
								((sp_kb_scan[5]==1'b0)? keymatrixb[0]: 12'h0) );	
				end
		end
end					

always	@(posedge clk)
begin
	if (reset)
			begin
			keymatrixa[0] <= 6'h00;
			keymatrixa[1] <= 6'h00;
			keymatrixa[2] <= 6'h00;
			keymatrixa[3] <= 6'h00;
			keymatrixa[4] <= 6'h00;
			keymatrixa[5] <= 6'h00;
			keymatrixa[6] <= 6'h00;
			keymatrixa[7] <= 6'h00;
			keymatrixa[8] <= 6'h00;
			keymatrixa[9] <= 6'h00;
			keymatrixa[10] <= 6'h00;
			keymatrixa[11] <= 6'h00;			
			end
	else
		begin
		    if (strobe)
					begin							
						case ({ex_code,sp_kb[7:0]})

							9'h005:	keymatrixa[11][5]	<= press_release; //F1
							9'h006:	keymatrixa[10][5] 	<= press_release; //F2
							9'h004:	keymatrixa[9][5]	<= press_release; //F3
							9'h00c:	keymatrixa[8][5]	<= press_release; //F4
							9'h003:	keymatrixa[7][5]	<= press_release; //F5
							9'h00b:	keymatrixa[6][5]	<= press_release; //F6
							9'h083:	keymatrixa[5][5]	<= press_release; //F7
							9'h00a:	keymatrixa[4][5]	<= press_release; //F8
							9'h001:	keymatrixa[3][5]	<= press_release; //F9
							9'h009:	keymatrixa[2][5]	<= press_release; //ЧФ
							9'h078:	keymatrixa[1][5] 	<= press_release; //БФ
							9'h007:	keymatrixa[0][5] 	<= press_release; //СТР

							9'h04c:	keymatrixa[11][4]   <= press_release; //;
							9'h079:	begin 
										shift <= press_release;
										keymatrixa[11][4]   <= press_release; //;
									end	
							9'h016:	keymatrixa[10][4]	<= press_release; //1
							9'h01e:	keymatrixa[9][4]	<= press_release; //2
							9'h026:	keymatrixa[8][4]	<= press_release; //3
							9'h025:	keymatrixa[7][4]	<= press_release; //4
							9'h02e:	keymatrixa[6][4]	<= press_release; //5
							9'h036:	keymatrixa[5][4]	<= press_release; //6
							9'h03d:	keymatrixa[4][4]	<= press_release; //7
							9'h03e:	keymatrixa[3][4]	<= press_release; //8
							9'h046:	keymatrixa[2][4]	<= press_release; //9
							9'h045:	keymatrixa[1][4] 	<= press_release; //0
							9'h04e:	keymatrixa[0][4] 	<= press_release; //=
							9'h07b:	keymatrixa[0][4] 	<= press_release; //=
							
							9'h070: keymatrixa[1][4]	<= press_release; // 0
							9'h069:	keymatrixa[10][4]	<= press_release; // 1
							9'h072:	keymatrixa[9][4]	<= press_release; // 2
							9'h07a:	keymatrixa[8][4]	<= press_release; // 3
							9'h06b:	keymatrixa[7][4]	<= press_release; // 4
							9'h073:	keymatrixa[6][4]	<= press_release; // 5
							9'h074:	keymatrixa[5][4]	<= press_release; // 6
							9'h06c:	keymatrixa[4][4]	<= press_release; // 7
							9'h075:	keymatrixa[3][4]	<= press_release; // 8
							9'h07d:	keymatrixa[2][4]	<= press_release; // 9							

							9'h03b:	keymatrixa[11][3]	<= press_release; //J
							9'h021:	keymatrixa[10][3]	<= press_release; //C
							9'h03c:	keymatrixa[9][3]	<= press_release; //U
							9'h042:	keymatrixa[8][3]	<= press_release; //K
							9'h024:	keymatrixa[7][3]	<= press_release; //E
							9'h031:	keymatrixa[6][3]	<= press_release; //N
							9'h034:	keymatrixa[5][3]	<= press_release; //G
							9'h054:	keymatrixa[4][3]	<= press_release; //[
							9'h05b:	keymatrixa[3][3]	<= press_release; //]
							9'h01a:	keymatrixa[2][3]	<= press_release; //Z
							9'h033:	keymatrixa[1][3] 	<= press_release; //H
							9'h07c:	keymatrixa[0][3] 	<= press_release; //*

							9'h02B:	keymatrixa[11][2]	<= press_release; //F
							9'h035:	keymatrixa[10][2]	<= press_release; //Y
							9'h01d:	keymatrixa[9][2]	<= press_release; //W
							9'h01c:	keymatrixa[8][2]	<= press_release; //A
							9'h04d:	keymatrixa[7][2]	<= press_release; //P
							9'h02d:	keymatrixa[6][2]	<= press_release; //R
							9'h044:	keymatrixa[5][2]	<= press_release; //O
							9'h04b:	keymatrixa[4][2]	<= press_release; //L
							9'h023:	keymatrixa[3][2]	<= press_release; //D
							9'h02a:	keymatrixa[2][2]	<= press_release; //V
							9'h05d:	keymatrixa[1][2] 	<= press_release; ///
							9'h049:	keymatrixa[0][2] 	<= press_release; //.
							9'h071:	keymatrixa[0][2] 	<= press_release; //.

							9'h015:	keymatrixa[11][1]	<= press_release; //Q
							9'h00e:	keymatrixa[10][1]	<= press_release; //^
							9'h01b:	keymatrixa[9][1]	<= press_release; //S
							9'h03a:	keymatrixa[8][1]	<= press_release; //M
							9'h043:	keymatrixa[7][1]	<= press_release; //I
							9'h02c:	keymatrixa[6][1]	<= press_release; //T
							9'h022:	keymatrixa[5][1]	<= press_release; //X
							9'h032:	keymatrixa[4][1]	<= press_release; //B
							9'h052:	keymatrixa[3][1]	<= press_release; //@
							9'h041:	keymatrixa[2][1]	<= press_release; //,
							9'h04a:	keymatrixa[1][1] 	<= press_release; // '/'
							9'h14a:	keymatrixa[1][1] 	<= press_release; // '/'
							9'h066:	keymatrixa[0][1] 	<= press_release; //Backspace

							9'h058:	keymatrixa[11][0]	<= press_release; //РУС/LAT
							9'h170:	keymatrixa[10][0]	<= press_release; //Insert - Home
							9'h175:	keymatrixa[9][0]	<= press_release; //Up
							9'h172:	keymatrixa[8][0]	<= press_release; //Down
							9'h00d:	keymatrixa[7][0]	<= press_release; //Tab
							9'h171:	keymatrixa[6][0]	<= press_release; //Delete - Esc
							9'h029:	keymatrixa[5][0]	<= press_release; //Space
							9'h16b:	keymatrixa[4][0]	<= press_release; //Left
							9'h014:	keymatrixa[3][0]	<= press_release; //Ctrl
							9'h114:	keymatrixa[3][0]	<= press_release; //Ctrl
							9'h174:	keymatrixa[2][0]	<= press_release; //Right
							9'h011:	keymatrixa[1][0] 	<= press_release; //LF
							9'h05a:	keymatrixa[0][0] 	<= press_release; //Enter
							9'h15a:	keymatrixa[0][0] 	<= press_release; //Enter
							9'h012,9'h059: shift <= press_release;		  //Shift

						endcase
					end	
				end		
end
	
ps2_keyboard ps2_keyboard(
	.clk				(clk),
	.reset				(reset),
	.ps2_clk_i			(ps2_clk),
	.ps2_data_i			(ps2_data),
	.rx_released		(),
	.rx_shift_key_on	(),
	.rx_scan_code		(ps2q),
	.rx_ascii			(),
	.rx_data_ready		(ps2dsr),       								// rx_read_o
	.rx_read			(ps2rden)       								// rx_read_ack_i
  );

endmodule
