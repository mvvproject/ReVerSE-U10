// Keyboard matrix module
// Modify for Spetsialist by Ewgeny7 & Fifan

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
input		mode,						// режим работы "МХ / Стандарт"
input		rus_lat,					// режим клавиатуры "РУС / LAT"
output		[11:0]	sp_kb_out,			// код ответа		
output		key_ss,						// клавиша "НР" нажата
output   	test_k,						// клавиша теста
output   	ruslat_k,					// клавиша "РУС / LAT"
output		turbo_k,					// сигнал "турбо/нормал"
output   	mx_k						// клавиша "МХ / Стандарт"
);

//Соответствие клавиш:
//Shift - НР
//Alt - РУС / LAT
//Delete - Сброс
//Num/Pause - МХ / Стандарт
//Scroll Lock - Тест включен/выключен
//Page Up - режим Turbo
//Page Down - режим Normal

// при mode=1 нужно:
// при metod=1 - вывод "все нули" на 12 выходов, ответ на 6 входов
// при metod=0 - вывод на 6 выходов, ответ на 12 входов

assign		key_ss = shift;
assign     	res_k = res_key;
assign     	test_k = test_key;
assign    	ruslat_k = rl_key;
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
reg			turbo_key = 1'b0;
reg     	mx_st_key = 1'b0;
reg     	test_key = 1'b0;
reg     	rl_key = 1'b0;
reg 		mx_st;
reg 		rl_st;
reg 		test;
reg			ex_code	= 0;	
reg			press_release;
reg			strobe;
reg			[11:0]	sp_kb_out_;

wire		[7:0]	ps2q;	
wire		ps2dsr;

always@ (posedge mx_st) mx_st_key <= (~mx_st_key);

always@ (posedge test) test_key <= (~test_key);

always@ (posedge rl_st) rl_key <= (~rl_key);

always @(posedge clk) begin
	if (reset) begin
		res_key <= 0;
//		test_key <= 0;				
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
						9'h171:         res_key <= 1'b1;        //Delete - Сброс
						9'h07e: 		begin 
											test <= 1'b1;     	//Num  - Тест включён
											res_key <= 1'b1;
										end						
						
						9'h17d:			turbo_key <= 1'b1;		//Page Up - режим Turbo
						9'h17a:			turbo_key <= 1'b0;		//Page Down - режим Normal
						9'h077: 		begin 
											mx_st <= 1'b1;     	//Num - МХ / Стандарт
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
						9'h171:         res_key <= 1'b0;        //Delete - Сброс
						9'h07e: 		begin 
											test <= 1'b0;     	//Num  - Тест выключен
											res_key <= 1'b0;
										end	
						
						9'h17d:			turbo_key <= 1'b1;		//Page Up - режим Turbo
						9'h17a:			turbo_key <= 1'b0;		//Page Down - режим Normal
						9'h077:			begin 
											mx_st <= 1'b0;     	//МХ / Стандарт
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

							9'h005: begin
								if (mx_st_key == 1'b0) 
									keymatrixa[11][5]	<= press_release; //F1
								else
									keymatrixa[9][5]	<= press_release; //F1
								end
								
							9'h006: begin
								if (mx_st_key == 1'b0) 
									keymatrixa[10][5] 	<= press_release; //F2
								else
									keymatrixa[8][5]	<= press_release; //F2
								end
								
							9'h004:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[9][5]	<= press_release; //F3
								else
									keymatrixa[7][5]	<= press_release; //F3
								end
								
							9'h00c:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[8][5]	<= press_release; //F4
								else
									keymatrixa[6][5]	<= press_release; //F4
								end
								
							9'h003:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[7][5]	<= press_release; //F5
								else
									keymatrixa[5][5]	<= press_release; //F5
								end
								
							9'h00b:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[6][5]	<= press_release; //F6
								else
									keymatrixa[4][5]	<= press_release; //F6
								end
								
							9'h083:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[5][5]	<= press_release; //F7
								else
									keymatrixa[3][5]	<= press_release; //F7
								end
								
							9'h00a:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[4][5]	<= press_release; //F8
								else
									keymatrixa[2][5]	<= press_release; //F8
								end
								
							9'h001:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[3][5]	<= press_release; //F9
								else
									keymatrixa[1][5] 	<= press_release; //F9
								end
														
							9'h009:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[2][5]	<= press_release; //ЧФ
								else
									keymatrixa[9][5] 	<= press_release; //КОИ
								end								
								
							9'h078:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[1][5]	<= press_release; //БФ
								else
									keymatrixa[0][5] 	<= press_release; //СТР
								end									

							9'h007:	begin
								if (mx_st_key == 1'b0) 
									keymatrixa[0][5] 	<= press_release; //СТР
								end	

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
							
							9'h00e:	keymatrixa[10][1]	<= press_release; // /\							
							
							9'h015:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[11][1]	<= press_release; //Q
								else
									keymatrixa[11][3]	<= press_release; //Й
								end
								
							9'h01d:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[9][2]	<= press_release; //W
								else
									keymatrixa[10][3]	<= press_release; //Ц
								end

							9'h024:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[7][3]	<= press_release; //E
								else
									keymatrixa[9][3]	<= press_release; //У
								end
								
							9'h02d:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[6][2]	<= press_release; //R
								else
									keymatrixa[8][3]	<= press_release; //К
								end									

							9'h02c:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[6][1]	<= press_release; //T
								else
									keymatrixa[7][3]	<= press_release; //Е
								end
								
							9'h035:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[10][2]	<= press_release; //Y
								else
									keymatrixa[6][3]	<= press_release; //Н
								end										

							9'h03c:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[9][3]	<= press_release; //U
								else
									keymatrixa[5][3]	<= press_release; //Г
								end																				

							9'h043:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[7][1]	<= press_release; //I
								else
									keymatrixa[4][3]	<= press_release; //Ш
								end
								
							9'h044:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[5][2]	<= press_release; //O
								else
									keymatrixa[3][3]	<= press_release; //Щ
								end
								
							9'h04d:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[7][2]	<= press_release; //P
								else
									keymatrixa[2][3]	<= press_release; //З
								end
								
							9'h054:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[4][3]	<= press_release; //[
								else
									keymatrixa[1][3]	<= press_release; //Х
								end
								
							9'h05b:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[3][3]	<= press_release; //]
								else
									keymatrixa[0][1]	<= press_release; //Ъ
								end
								
							9'h01c:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[8][2]	<= press_release; //A
								else
									keymatrixa[11][2]	<= press_release; //Ф
								end
								
							9'h01b:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[9][1]	<= press_release; //S
								else
									keymatrixa[10][2]	<= press_release; //Ы
								end
								
							9'h023:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[3][2]	<= press_release; //D
								else
									keymatrixa[9][2]	<= press_release; //В
								end
								
							9'h02b:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[11][2]	<= press_release; //F
								else
									keymatrixa[8][2]	<= press_release; //А
								end
								
							9'h034:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[5][3]	<= press_release; //G
								else
									keymatrixa[7][2]	<= press_release; //П
								end
								
							9'h033:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[1][3]	<= press_release; //H
								else
									keymatrixa[6][2]	<= press_release; //Р
								end
																	
							9'h03b:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[11][3]	<= press_release; //J
								else
									keymatrixa[5][2]	<= press_release; //О
								end
																	
							9'h042:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[8][3]	<= press_release; //K
								else
									keymatrixa[4][2]	<= press_release; //Л
								end
																	
							9'h04b:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[4][2]	<= press_release; //L
								else
									keymatrixa[3][2]	<= press_release; //Д
								end
																	
							9'h04c:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[0][3]	<= press_release; //;
								else
									keymatrixa[2][2]	<= press_release; //Ж
								end
																	
							9'h052:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[3][1]	<= press_release; //@
								else
									keymatrixa[1][2]	<= press_release; //Э
								end
								
							9'h05d:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[1][2]	<= press_release; // '\'
								else
									keymatrixa[1][1]	<= press_release; // '/'
								end
								
							9'h01a:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[2][3]	<= press_release; //Z
								else
									keymatrixa[11][1]	<= press_release; //Я
								end
								
							9'h022:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[5][1]	<= press_release; //X
								else
									keymatrixa[10][1]	<= press_release; //Ч
								end
								
							9'h021:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[10][3]	<= press_release; //C
								else
									keymatrixa[9][1]	<= press_release; //С
								end
								
							9'h02a:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[2][2]	<= press_release; //V
								else
									keymatrixa[8][1]	<= press_release; //М
								end
								
							9'h032:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[4][1]	<= press_release; //B
								else
									keymatrixa[7][1]	<= press_release; //И
								end								
																							
							9'h031:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[6][3]	<= press_release; //N
								else
									keymatrixa[6][1]	<= press_release; //Т
								end
								
							9'h03a:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[8][1]	<= press_release; //M
								else
									keymatrixa[5][1]	<= press_release; //Ь
								end	
								
							9'h041:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[2][1]	<= press_release; //<
								else
									keymatrixa[4][1]	<= press_release; //Б
								end	
								
							9'h049:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[0][2]	<= press_release; //>
								else
									keymatrixa[3][1]	<= press_release; //Ю
								end	
								
							9'h04a:	begin
								if (rus_lat == 1'b0) 
									keymatrixa[1][1]	<= press_release; // '/'
								else
									keymatrixa[0][2]	<= press_release; //.
								end
																														
							9'h066:	keymatrixa[0][1] 	<= press_release; //Пробел
							
							9'h011,9'h111:begin	
									keymatrixa[11][0]	<= press_release; //Alt - РУС/LAT
									rl_st <= press_release;
									end						
							
							9'h16c:	keymatrixa[10][0]	<= press_release; //Home
							9'h175:	keymatrixa[9][0]	<= press_release; //Up
							9'h172:	keymatrixa[8][0]	<= press_release; //Down
							
							9'h00d: begin
								if (mx_st_key == 1'b0) 
									keymatrixa[7][0]	<= press_release; //Tab
								else
									keymatrixa[3][0]	<= press_release; //Tab - Таб
								end

							9'h076: begin
								if (mx_st_key == 1'b0) 
									keymatrixa[6][0]	<= press_release; //Esc
								else
									keymatrixa[11][5]	<= press_release; //Esc
								end

							9'h029:	keymatrixa[5][0]	<= press_release; //Пробел
							9'h16b:	keymatrixa[4][0]	<= press_release; //Left
							9'h174:	keymatrixa[2][0]	<= press_release; //Right
							9'h169:	keymatrixa[1][0]	<= press_release; //End - ПС
							9'h05a,9'h15a: keymatrixa[0][0] <= press_release; //Enter
							
							9'h012,9'h059: begin 
										shift <= press_release;			  //Shift - НР
										keymatrixa[11][4] <= press_release; 
									end	
									
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
