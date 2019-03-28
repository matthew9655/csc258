//KEY[0] active low reset
//KEY[1] go signal

module snake(SW, KEY, CLOCK_50, VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK, VGA_R, VGA_G, VGA_B, PS2_CLK, PS2_DAT);
    input [3:0] KEY;
	 input [9:0] SW;
    input CLOCK_50;
	 inout PS2_CLK, PS2_DAT;
    output VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK;
	 output [9:0] VGA_R, VGA_G, VGA_B;
	
	 
	 wire [7:0] x_out;
	 wire [6:0] y_out;
	 wire [2:0] colour;
	 wire plot;
	 
	 wire kleft, kright, kup, kdown; 
	 
	 wire [5:0] not_used;
	 
	 
	 vga_adapter a0(
			.resetn(KEY[0]),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x_out), 
			.y(y_out),
			.plot(plot),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK),
			.VGA_SYNC(VGA_SYNC),
			.VGA_CLK(VGA_CLK)
			);
			defparam a0.RESOLUTION = "160x120";
		   defparam a0.MONOCHROME = "FALSE";
		   defparam a0.BITS_PER_COLOUR_CHANNEL = 1;
         defparam a0.BACKGROUND_IMAGE = "black.mif";
			
			
	 keyboard_tracker #(.PULSE_OR_HOLD(1)) KB0 (
			.clock(CLOCK_50),
			.reset(KEY[0]),
			.PS2_CLK(PS2_CLK),
			.PS2_DAT(PS2_DAT),
			.w(not_used[5]),
			.a(not_used[4]),
			.s(not_used[3]),
			.d(not_used[2]),
			.space(not_used[1]),
			.enter(not_used[0]),
			.left(kleft),
			.right(kright),
			.up(kup),
			.down(kdown)	 
	);
			
	 combined c0(CLOCK_50, KEY[0], KEY[1], kleft, kright, kup, kdown, x_out, y_out, colour, plot);
	
endmodule      


module combined(clk, resetn, start, l, r, u, d, x_out, y_out, colour, plot);
	input clk, resetn, start;
	input l, r, u, d;
	
	output [7:0] x_out; 
	output [6:0] y_out;
	output [2:0] colour;
	output plot;
	
	wire delay;
	wire [1:0] direction;
	wire [3:0] state;
	wire [1:0] dir;
	wire [7:0] randx;
	wire [6:0] randy;
	wire food_gen;
	wire [27:0] timer;
	
	
	time_controller t0(
		.out(timer),
		.select(select)
	);
	
	RateDivider r0(
		  .cout(delay),
		  .resetn(resetn),
		  .clk(clk),
		  .d(timer)
	);
	
	control C0(
        .clk(clk),
        .resetn(resetn),
		  .delay(delay),
		  .start(start),
		  .dir(dir),
		  
		  
		  .plot(plot),
		  .direction(direction),
		  .state(state)
    );
	 

    datapath D0(
        .clk(clk),
        .resetn(resetn),
		  .direction(direction),
		  .state(state),
		  .randx(randx),
		  .randy(randy),
		  
        .x_out(x_out),
		  .y_out(y_out),
		  .colour(colour),
		  .food_gen(food_gen),
		  .select(select)
    );
	 

	 keyboard_reader k0 (
			.left(l),
			.right(r),
			.up(u),
			.down(d),
			.out(dir)
	 );
	 
	 
	 food_gen fg0(
			.clk(clk),
			.food_gen(food_gen),
			.randomX(randx),
			.randomY(randy)
	 );
	 
	 
endmodule
                

module control(
    input clk,
	 input delay,
    input resetn,
	 input start,
	 input [1:0] dir, // 0 for left, 1 for right, 2 for up, 3 for down
	 
	 output reg plot,
	 output reg [1:0] direction,
	 output [3:0] state
	 
	 );
	
    reg [3:0] current_state, next_state; 
    
    localparam  
					 START				  = 4'd0,
					 START_WAIT			  = 4'd1,
					 SETUP				  = 4'd2,
					 CLEAR_WAIT			  = 4'd3,
					 CLEAR              = 4'd4,
					 MOVE_WAIT		     = 4'd5,
					 MOVE		           = 4'd6,
					 EAT_WAIT		     = 4'd7,
					 EAT                = 4'd8,
					 REPEAT			     = 4'd9;
	 
	 localparam 
					LEFT = 2'b0,
					RIGHT = 2'b01,
					UP = 2'b10,
					DOWN = 2'b11;

				
			
    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
					START: next_state = start ? START : START_WAIT;
					START_WAIT: next_state = start ? SETUP : START_WAIT;
					SETUP: next_state = delay ? CLEAR_WAIT : SETUP;
					CLEAR_WAIT: next_state = CLEAR;
					CLEAR: next_state = MOVE_WAIT;
					MOVE_WAIT: next_state = MOVE;
					MOVE: next_state = EAT_WAIT;
					EAT_WAIT: next_state = EAT;
					EAT: next_state = REPEAT;
					REPEAT: next_state = delay ? CLEAR_WAIT : REPEAT;
					default: next_state = CLEAR_WAIT;
				endcase
	 end
	 
	 always@(posedge clk)
	 begin 
			if (!resetn)
			begin
				direction <= RIGHT;
			end
			else
			begin
				if (dir == 2'b0 && direction != RIGHT)
				begin
					direction <= LEFT;
				end	
				else if (dir == 2'b01 && direction != LEFT)
				begin 
					direction <= RIGHT;
				end
				else if (dir == 2'b10 && direction != DOWN)
				begin 
					direction <= UP;
				end
				else if (dir == 2'b11 && direction != UP)
				begin 
					direction <= DOWN;
				end
		  end
	end

	always@(posedge clk)
			begin: state_FFs
				 if(!resetn)
				 begin
					current_state <= START;
					plot <= 1'b0;
				 end
				 else
				 begin
					current_state <= next_state;
					plot <= 1'b1;
				 end
			 end // state_FFS
			 
	assign state = current_state;
endmodule
		 
				
					
					
module datapath(
	 // moving snake
    input clk, resetn,
	 input [1:0] direction,
    input [3:0] state,
	 input [7:0] randx,
	 input [6:0] randy,
	 
	 
    output reg [7:0] x_out,
	 output reg [6:0] y_out,
	 output reg [2:0] colour,
	 output reg food_gen,
	 output reg [4:0] select
    );
	 
	 reg [5:0] length;
	 reg start, over;
	 reg [7:0] headx, foodx, setupx;
	 reg [6:0] heady, foody, setupy;
	 reg [7:0] bodyx[0:127];
	 reg [6:0] bodyy[0:127];
	 integer i, t, j;
	 
	 
	 
	 localparam  
					 START 				  = 4'b0000,
					 START_WAIT			  = 4'b0001,
					 SETUP				  = 4'b0010,
					 CLEAR_WAIT			  = 4'b0011,
					 CLEAR              = 4'b0100,
					 MOVE_WAIT		     = 4'b0101,
					 MOVE		           = 4'b0110,
					 EAT_WAIT		     = 4'b0111,
					 EAT                = 4'b1000,
					 REPEAT			     = 4'b1001;
	 
	 localparam 
					LEFT = 2'b0,
					RIGHT = 2'b01,
					UP = 2'b10,
					DOWN = 2'b11;
					
					
	 always@(posedge clk)
	 begin 
		if (!resetn)
		begin 
		x_out <= 8'b0;
		y_out <= 7'b0;
		headx <= 8'd80;
		heady <= 7'd60;
		setupx <= 8'b0;
		setupy <= 7'b0;
		bodyx[0] <= 8'd80;
		bodyy[0] <= 7'd60;
		foodx <= 8'd69;
		foody <= 7'd69;
		colour <= 3'b000;
		food_gen <= 1'b0;
		length <= 1'b1;
		start <= 1'b1;
		over <= 1'b0;
		select <= 5'b0;
		end
		
		
		else
		begin 
			case (state)
			START:
			begin 
			end
			START_WAIT:
			begin 
			end
			
			SETUP:
			begin
				if ((setupx < 8'd48 && setupy < 8'd28) || (setupx > 8'd112 && setupy > 92))
					colour <= 3'b000;
				else
					colour <= 3'b111;
				
				x_out <= setupx;
				y_out <= setupy;
				
				for (t = 0; t < 120; t = t + 1)
				begin 
					for (j = 0; j < 160; j = j + 1) 
						setupx <= setupx + 1'b1;
						
					if (setupx == 8'd159)
						setupx <= 8'd0;
						
					setupy <= setupy + 1'b1;
				end
				
				if (setupy == 8'd119)
					setupy <= 8'b0;
				
			end
			
			CLEAR_WAIT:
			begin 
				food_gen <= 1'b0;
				if (direction == LEFT)
				begin
					if (headx == 8'b0)
						over <= 1'b1;
					else
						headx <= headx - 1'b1;
				end
				else if (direction == RIGHT)
				begin
					if(headx == 8'd159)
						over <= 1'b1;
					else
						headx <= headx + 1'b1; 
				end
				else if (direction == UP)
				begin
					if(heady == 1'b0)
						over <= 1'b1;
					else
						heady <= heady - 1'b1;
				end
				else if (direction == DOWN)
				begin
					if(heady  == 7'd119)
						over <= 1'b1;
					else
						heady <= heady + 1'b1;
				end
			end
//				if (direction == LEFT)
//					over <= 1'b1;
//				else if (
//					headx <= headx - 1'b1;
//				else if (direction == RIGHT)
//					headx <= headx + 1'b1;
//				else if (direction == UP)
//					heady <= heady - 1'b1;
//				else if (direction == DOWN)
//					heady <= heady + 1'b1;
			CLEAR:
			begin
				if (headx == foodx && heady == foody)
					colour <= 3'b001;
				else 
					colour <= 3'b111;
				
				x_out <= bodyx[length - 1];
				y_out <= bodyy[length - 1];
				
				if (over)
				begin
				x_out <= 8'b0;
				y_out <= 7'b0;
				headx <= 8'b0;
				heady <= 7'b0;
				bodyx[0] <= 8'b0;
				bodyy[0] <= 7'b0;
				foodx <= 8'd6;
				foody <= 7'd0;
				colour <= 3'b000;
				food_gen <= 1'b0;
				length <= 1'b1;
				start <= 1'b1;
				over <= 1'b0;
				select <= 4'b0000;
				end
					
			end
			MOVE_WAIT:
			begin 
				if (foodx == headx && foody == heady) 
				begin
					length <= length + 1'b1;
					food_gen <= 1'b1;
				end
				
			end
			
			MOVE:
			begin 
				if ((length % 4) == 0) 
				begin 
					select <= select + 1'b1;
				end 
				
				
				x_out <= headx;
				y_out <= heady;
				colour <= 3'b001;
				bodyx[0] <= headx;
				bodyy[0] <= heady;
				
				for (i = 0; i < 127; i = i + 1)
				begin 
					if (bodyx[i] > 0)
					begin
						bodyx[i + 1] <= bodyx[i];
					end 
					else 
					begin
						bodyx[i + 1] <= 8'b0;
					end 
					
					if (bodyy[i] > 0)
					begin
						bodyy[i + 1] <= bodyy[i];
					end 
					else 
					begin
						bodyy[i + 1] <= 7'b0;
					end 
				end
			end
			EAT_WAIT:
			begin 
			end
			EAT:
			begin 
				if (start)
				begin
					x_out <= foodx;
					y_out <= foody;
					colour <= 3'b010;
					start <= 1'b0;
				end
					
				else if ((foodx == headx && foody == heady))
				begin
					foodx <= randx;
					foody <= randy;
				
					x_out <= randx;
					y_out <= randy;
					colour <= 3'b010;
				end
					
			end
			
			endcase
	  end
	end
				
			 
endmodule


module keyboard_reader(left, right, up, down, out);
	input left, right, up, down;
	output reg [1:0] out;
	
	always@(*)
	begin 
		if (left)
		begin 
			out <= 2'b0;
		end
		if (right)
		begin
			out <= 2'd1;
		end
		if (up)
		begin
			out <= 2'd2;
		end
		if (down)
		begin 
			out <= 2'd3;
		end
	end
endmodule


module time_controller(out, select);
	output reg [27:0] out; 
	input [4:0] select; 
	
	always @(*)
	begin 
			case (select)
				5'b00000: out = 28'd6400000;
				5'b00001: out = 28'd4500000;
				5'b00010: out = 28'd3200000;
				5'b00011: out = 28'd1666667;
				5'b00100: out = 28'd866666;
				default: out = 28'd866666;
			endcase
	end 
endmodule


module RateDivider(cout, resetn, clk, d) ; // need to take into account of the frames too
	input [27:0] d;
	input resetn, clk;
	output cout; 
	
	reg [27:0] count;
	
	always @ (posedge clk)
	begin 
		if (resetn == 1'b0)
		begin
			count <= d;
		end
		
		else 
		begin 
			if (count == 0)
			begin
				count <= d;
			end
			else
			begin
				count <= count - 1;
			end
		end
	end
	
	assign cout = (count == 0) ? 1 : 0;
	
endmodule


module food_gen (clk, food_gen, randomX, randomY);
	input clk, food_gen;
	output reg [7:0] randomX;
	output reg [6:0] randomY;

	reg [6:0] x = 8'd48;
	reg [6:0] y = 7'd92;
	
	always@(posedge clk)
	begin
		if (food_gen == 0)
		begin 
			if (x < 7'd112)
				x <= x + 1'b1;
			else 
				x <= 0;
			if (y > 0)
				y <= y - 1'b1;
			else
				y <= 7'd92;
		end
		if (food_gen == 1)
		begin
			randomX <= x;
			randomY <= y;
		end
	end
	
endmodule 


