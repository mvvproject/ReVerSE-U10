module zports(

	input clk,   // z80 clock
	input fclk,  // global FPGA clock
	input rst_n, // system reset

	input      [7:0] din,
	output reg [7:0] dout,
	input [7:0] a,

	input iorq_n,
	input rd_n,
	input wr_n,
	
	output reg sdcs_n,
	output sd_start,
	output [7:0] sd_datain,
	input [7:0] sd_dataout
);


// dout data

	always @*
	begin
		case( a[7:0] )
		 8'h77:dout = 8'h00; 
		 8'h57:dout = sd_dataout;
		 default:dout = 8'hFF;
		endcase
	end


// SD card (z-control¸r compatible)

	reg sdcfg_wr,sddat_wr,sddat_rd;
	
	always@*
		begin
			if ((a[7:0]==8'h77) && (~iorq_n) && (~wr_n))
				sdcfg_wr=1'b1;
			else
				sdcfg_wr=1'b0;
				
			if ((a[7:0]==8'h57) && (~iorq_n) && (~wr_n))
				sddat_wr=1'b1;
			else
				sddat_wr=1'b0;
				
			if ((a[7:0]==8'h57) && (~iorq_n) && (~rd_n))
				sddat_rd=1'b1;
			else
				sddat_rd=1'b0;
				
		end				

	// SDCFG write - sdcs_n control
	always @(posedge clk, negedge rst_n)
	begin
		if( !rst_n )
			sdcs_n <= 1'b1;
		else // posedge clk
			if( sdcfg_wr )
				sdcs_n <= din[1];
	end


	// start signal for SPI module with resyncing to fclk

	reg sd_start_toggle;
	reg [2:0] sd_stgl;

	// Z80 clock
	always @(posedge clk)
		if( sddat_wr || sddat_rd )
			sd_start_toggle <= ~sd_start_toggle;

	// FPGA clock
	always @(posedge fclk)
		sd_stgl[2:0] <= { sd_stgl[1:0], sd_start_toggle };

	assign sd_start = ( sd_stgl[1] != sd_stgl[2] );


	// data for SPI module
	assign sd_datain = wr_n ? 8'hFF : din;



endmodule