//KEY[0] active low reset
//KEY[1] go signal

module snake(SW, KEY, CLOCK_50, VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK, VGA_R, VGA_G, VGA_B);
    input [3:0] KEY;
	 input [9:0] SW;
    input CLOCK_50;
    output VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK;
	 output [9:0] VGA_R, VGA_G, VGA_B;
	
	 
	 wire [7:0] x_out;
	 wire [6:0] y_out;
	 wire [2:0] colour;
	 wire plot;
	 
	 
	 vga_adapter a0(
			.resetn(SW[9]),
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
			
	 combined c0(CLOCK_50, KEY[0], KEY[1], SW[0], SW[1], SW[2], SW[3], x_out, y_out, colour, plot);
	
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
	
	RateDivider r0(
		  .cout(delay),
		  .resetn(resetn),
		  .clk(clk),
		  .d(28'd2)
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
		  .food_gen(food_gen)
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
					 CLEAR_WAIT			  = 4'd2,
					 CLEAR              = 4'd3,
					 MOVE_WAIT		     = 4'd4,
					 MOVE		           = 4'd5,
					 EAT_WAIT		     = 4'd6,
					 EAT                = 4'd7,
					 REPEAT			     = 4'd8;
	 
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
					START_WAIT: next_state = start ? CLEAR_WAIT: START_WAIT;
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
	 output reg food_gen
    );
	 
	 reg [5:0] length;
	 reg start;
	 reg [7:0] headx, foodx;
	 reg [6:0] heady, foody;
	 reg [7:0] bodyx[0:127];
	 reg [6:0] bodyy[0:127];
	 integer i;
	 
	 
	 
	 localparam  
					 START 				  = 4'b000,
					 START_WAIT			  = 4'b001,
					 CLEAR_WAIT			  = 4'b010,
					 CLEAR              = 4'b011,
					 MOVE_WAIT		     = 4'b100,
					 MOVE		           = 4'b101,
					 EAT_WAIT		     = 4'b110,
					 EAT                = 4'b111,
					 REPEAT			     = 4'b110;
	 
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
			
			CLEAR_WAIT:
			begin 
				food_gen <= 1'b0;
				
				if (direction == 2'b0)
					headx <= headx - 1'b1;
				else if (direction == 2'b01)
					headx <= headx + 1'b1;
				else if (direction == 2'b10)
					heady <= heady - 1'b1;
				else if (direction == 2'b11)
					heady <= heady + 1'b1;
			end
			CLEAR:
			begin
				if (headx == foodx && heady == foody)
					colour <= 3'b111;
				else 
					colour <= 3'b000;
				
				x_out <= bodyx[length - 1];
				y_out <= bodyy[length - 1];
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
				x_out <= headx;
				y_out <= heady;
				colour <= 3'b111;
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
						bodyy[i + 1] <= 8'b0;
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

	reg [7:0] x = 8'd48;
	reg [6:0] y = 7'd92;
	
	always@(posedge clk)
	begin
		if (food_gen == 0)
		begin 
			if (x < 8'd159)
				x <= x + 1'b1;
			else 
				x <= 0;
			if (y > 0)
				y <= y - 1'b1;
			else
				y <= 7'd119;
		end
		if (food_gen == 1)
		begin
			randomX <= x;
			randomY <= y;
		end
	end
	
endmodule 


