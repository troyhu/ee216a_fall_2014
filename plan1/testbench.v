//--------------------------------------------------------------------
//		Timescale
//		Means that if you do #1 in the initial block of your
//		testbench, time is advanced by 100ps instead of 1ps
//--------------------------------------------------------------------
`timescale 100ps/1ps


//--------------------------------------------------------------------
//		Defines
//--------------------------------------------------------------------
`define CYCLE		20					// Modify your clock period here (1 = 1ns)
`define BKGND_COLOR 12'b1011_1001_0111  // Background Color
`define GM_MODE 	2'd00  				// Game Mode
`define SDFFILE		"./SGDE.sdf"		// Modify your sdf file name
`define INDATAFILE	"./input1.dat"		// Input Patterns for X, Y, Type
`define OUTDATAFILE	"./output1.dat"		// The output of your Frame Buffer
`define GOLDENDATA	"./golden1.dat"		// Solution for the input pattern


//--------------------------------------------------------------------
//		PROJECT TESTBENCH (DO NOT TOUCH)
//--------------------------------------------------------------------
module project_testbench;


	//----------------------------------------------------------------
	//		PARAMETERS (DO NOT TOUCH)
	//----------------------------------------------------------------
	parameter	PATTERN			= `INDATAFILE;
	parameter	SOLUTION		= `GOLDENDATA;
	parameter	DATAOUT			= `OUTDATAFILE;
	parameter	COLOR 			= `BKGND_COLOR;
	parameter	MODE 			= `GM_MODE;
	parameter	n_sprite_max	= 20;
	parameter	fb_size			= 4096;
	parameter	CLOCK			= `CYCLE*10;
	
	
	//----------------------------------------------------------------
	//		SIGNAL DECLARATIONS (DO NOT TOUCH)
	//----------------------------------------------------------------
	reg				clk;
	reg				reset;
	reg				sprite;
	reg				start;
	reg		[1:0]	type;
	reg		[5:0]	X, Y;
	wire	[12:0]	SR0_Q;
	wire	[12:0]	SR1_Q;
	wire	[11:0]	FB_Q;
	wire			ready;
	wire			done;
	wire			SR0_CEN;
	wire			SR1_CEN;
	wire			FB_CEN;
	wire			FB_WEN;
	wire	[8:0]	SR0_A;
	wire	[8:0]	SR1_A;
	wire	[11:0]	FB_A; 
	wire	[11:0]	FB_D; 
	reg		[6:0]	xx;
	reg		[6:0]	yy;
	reg		[13:0]	data [0:n_sprite_max];
	reg		[11:0]	frame_buffer [0:4095];
	reg		[13:0]	in_temp;
	reg		[11:0]	fb_temp;
	reg				fb_ctrl;
	reg				comp_flag;
	reg				out_FB_CEN;
	reg				out_FB_WEN;
	reg				over;
	reg				stop;
	reg		[11:0]	out_FB_A;
	reg		[11:0]	res_frame_buffer [0:4095];
	wire			i_FB_CEN;
	wire			i_FB_WEN;
	wire	[11:0]	i_FB_A;
	integer			i;
	integer			j;
	integer			err;
	integer			a;
	integer			b;
	integer			k;
	integer			h;
	integer			xpmfile;
	integer			adder;
	integer			n_sprite;
	
	
	//----------------------------------------------------------------
	//		ASSIGN STATEMENTS (DO NOT TOUCH)
	//----------------------------------------------------------------
	assign i_FB_CEN		= (fb_ctrl)?out_FB_CEN:FB_CEN;
	assign i_FB_WEN		= (fb_ctrl)?out_FB_WEN:FB_WEN;
	assign i_FB_A		= (fb_ctrl)?out_FB_A:FB_A;
	
	
	//----------------------------------------------------------------
	//		Your SDGE.v module being tested (DO NOT TOUCH)
	//----------------------------------------------------------------
	SGDE 		sgde0 (	.ready(ready),
						.done(done),
						.clk(clk),
						.reset(reset),
						.sprite(sprite),
						.start(start),
						.type(type),
						.X(X),
						.Y(Y),
						.SR0_CEN(SR0_CEN),
						.SR0_A(SR0_A),
						.SR0_Q(SR0_Q),
						.SR1_CEN(SR1_CEN),
						.SR1_A(SR1_A),
						.SR1_Q(SR1_Q),
						.FB_CEN(FB_CEN),
						.FB_WEN(FB_WEN),
						.FB_A(FB_A),
						.FB_D(FB_D),
						.FB_Q(FB_Q),
						.bg_color(COLOR),
						.game_mode(MODE)); 
	
	SR 			sr0 (	.Q(SR0_Q),
						.CLK(clk),
						.CEN(SR0_CEN),
						.A(SR0_A));
	
	SR 			sr1 (	.Q(SR1_Q),
						.CLK(clk),
						.CEN(SR1_CEN),
						.A(SR1_A));
	
	FB			fb0	(	.Q(FB_Q),
						.CLK(clk),
						.CEN(i_FB_CEN),
						.WEN(i_FB_WEN),
						.A(i_FB_A),
						.D(FB_D));
	
	
	//---------------------------------------------------------------
	// SDF FILE: uncomment for post-synthesis simulations
	//---------------------------------------------------------------
	//initial $sdf_annotate(`SDFFILE, sgde0);
	
	//---------------------------------------------------------------
	// INITIALIZE MEMORIES (DO NOT TOUCH)
	//---------------------------------------------------------------
	initial $readmemb (PATTERN, data);
	initial $readmemb (SOLUTION, frame_buffer);
	initial $readmemb ("SR0.bit", sr0.mem );
	initial $readmemb ("SR1.bit", sr1.mem );
	
	
	//---------------------------------------------------------------
	//		CLOCK SOURCE (DO NOT TOUCH)
	//---------------------------------------------------------------
	always begin #(CLOCK/2) clk = ~clk; end
	
	
	//---------------------------------------------------------------
	// RESET MODULES (DO NOT TOUCH)
	//---------------------------------------------------------------
	initial begin
		clk = 1'b0;
		reset = 1'b0;
		i = 0; j = 0; err = 0;
		fb_ctrl = 1'b0;
		comp_flag = 1'b0;
		start = 1'b0;
		sprite = 1'b0;
		over = 1'b0;
		stop = 1'b0;
		xx = 7'd0;
		yy = 7'd0;
		#CLOCK reset = 1'b1;
		#CLOCK reset = 1'b0;
	end
	
	
	//----------------------------------------------------------------
	//		TEST DESIGN (DO NOT TOUCH)
	//----------------------------------------------------------------
	always @(posedge clk) begin
		if (reset == 1) begin
			n_sprite = data[0];
			i = 1;
			in_temp = 0;
		end else begin
			if (ready == 1) begin
				@(negedge clk)
				if (i <= n_sprite) begin
					sprite = 1'b1;
					in_temp = data[i];
					X = in_temp[13:8];
					Y = in_temp[7:2];
					type = in_temp[1:0];
					i = i+1;
				end else if (i == n_sprite+1) begin
					start = 1'b1;
					sprite = 1'b0;
					@(negedge clk) start = 1'b0;
						i = i+1;
					end
				end
			else begin
				@(negedge clk)
				sprite = 1'b0;
			end
		end
	end
	
	
	//----------------------------------------------------------------
	//		VCD FILE DUMP (DO NOT TOUCH)
	//----------------------------------------------------------------
	initial begin
		//$dumpfile("SDGE.vcd");
		//$dumpvars;  
	end
	
	
	//----------------------------------------------------------------
	//		TOTAL EXECUTION TIME (DO NOT TOUCH)
	//----------------------------------------------------------------
	always @(posedge done) begin
		$display ("==================================================");
		$display ("=  Total Execution Time:%d ns  =", $time/10);
		$display ("==================================================\n");
		@(negedge clk) out_FB_CEN = 1'b0;
			fb_ctrl = 1'b1;
			out_FB_WEN = 1'b1;
			out_FB_A = 0;
		@(posedge clk) 
			comp_flag = 1'b1;
	end
	
	
	//----------------------------------------------------------------
	//		CHECK FOR ERRORS (DO NOT TOUCH)
	//----------------------------------------------------------------
	always @(posedge clk) begin
		if (fb_ctrl ==1) begin
			if (j < fb_size ) begin
				fb_temp = frame_buffer[j]; 
				if ((j%64) == 0)
					xx = 7'd0;
				else 
					xx = (j)%64;
				if (j <= 63)
					yy = yy;
				else if((j)%64 == 0)
					yy = yy+1;
			end
		end
	end
	
	always @(negedge clk) begin
		if (comp_flag == 1) begin
			res_frame_buffer[out_FB_A]=FB_Q;
			out_FB_A = out_FB_A+1;
			if (FB_Q !== fb_temp) begin
				$display("ERROR at coordinate (%d,%d):	output %b !=	expect %b ", xx, yy, FB_Q, fb_temp);
				err = err + 1;
			end
			j = j+1;
			if (j >= fb_size) begin
				comp_flag = 0;
				over = 1'b1;
				@(negedge clk) stop = 1'b1;
			end  
		end
	end
	
	
	//----------------------------------------------------------------
	//		DISPLAY TEST RESULTS (DO NOT TOUCH)
	//----------------------------------------------------------------
	initial begin
		@(posedge stop) 
		if (over == 1) begin
			$display("------------------------------------------\n");
			if (err == 0)  begin
				$display("All data has been generated successfully!\n");
				$display("-------------------PASS-------------------\n");
			end else begin
				$display("There are %d errors!\n", err);
				$display("-------------------FAIL-------------------\n");
			end
		end else begin
			$display("------------------------------------------\n");
			$display("Error!!! There isn't any output data ...!\n");
			$display("-------------------FAIL-------------------\n");
		end
		$writememb(DATAOUT, res_frame_buffer);
		$finish;
	end

endmodule