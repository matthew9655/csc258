//KEY[0] active low reset
//KEY[1] go signal


module snake_2(SW, KEY, CLOCK_50, VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK, VGA_R, VGA_G, VGA_B, PS2_CLK, PS2_DAT);
	 input [9:0] SW;
    input [3:0] KEY;
    input CLOCK_50;
    output VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK;
	 output [9:0] VGA_R, VGA_G, VGA_B;
	 inout PS2_CLK, PS2_DAT;
	 
	 
    wire resetn;
    assign resetn = KEY[0];

    part2 u0(
        .clk(CLOCK_50),
        .resetn(resetn),
		  .l(SW[0]),
		  .r(SW[1]),
		  .u(SW[2]),
		  .d(SW[3]),
        .VGA_HS(VGA_HS),
		  .VGA_VS(VGA_VS),
		  .VGA_BLANK(VGA_BLANK),
		  .VGA_SYNC(VGA_SYNC),
		  .VGA_CLK(VGA_CLK),
		  .VGA_R(VGA_R),
		  .VGA_G(VGA_G),
		  .VGA_B(VGA_B),
		  .PS2_CLK(PS2_CLK),
		  .PS2_DAT(PS2_DAT)
    );

endmodule

module part2(
    input clk,
    input resetn,
	 input l, r, u, d,
	 output VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK,
	 output [9:0] VGA_R, VGA_G, VGA_B,
	 inout PS2_CLK, PS2_DAT
    );
	 
	 // wires for control
	 wire plot; 
	 wire [1:0] direction;
	 wire [2:0] state;
	 
	 // wires for datapath
	 wire [2:0] colour;
	 wire [7:0] x_out; 
	 wire [6:0] y_out;
	 
	 wire [1:0] dir;
	  
	 wire kleft, kright, kup, kdown;
	 wire not_used[5:0];
	 
	 wire enable_d;
	 
	 wire gen;
	 wire [7:0] foodx;
	 wire [6:0] foody;
	 
	 wire control_clock;
	 
	 
	 
	 vga_adapter a0(
			.resetn(resetn),
			.clock(clk),
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
		
	 
    control C0(
        .clk(clk),
        .resetn(resetn),
		  .delay(delay),
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

        .x_out(x_out),
		  .y_out(y_out),
		  .colour(colour)
    );
	 

	 keyboard_reader k0 (
			.left(l),
			.right(r),
			.up(u),
			.down(d),
			.out(dir)
	 );
	 
//	 keyboard_tracker #(.PULSE_OR_HOLD(1)) KB0 (
//			.clock(clk),
//			.reset(reset),
//			.PS2_CLK(PS2_CLK),
//			.PS2_DAT(PS2_DAT),
//			.w(not_used[5]),
//			.a(not_used[4]),
//			.s(not_used[3]),
//			.d(not_used[2]),
//			.space(not_used[1]),
//			.enter(not_used[0]),
//			.left(kleft),
//			.right(kright),
//			.up(kup),
//			.down(kdown)
//	 );
	
	 RateDivider r0(
			.cout(control_clock),
			.resetn(reset),
			.clk(clk),
			.d(28'd1666666)
	 );
	 
//	 food_gen fg0(
//			.clk(clk),
//			.gen(gen),
//			.randomX(foodx),
//			.randomY(foody)
//	 );
                
 endmodule        
                

module control(
    input clk,
	 input delay,
    input resetn,
	 input [1:0] dir, // 0 for left, 1 for right, 2 for up, 3 for down
	 
	 output reg plot,
	 output reg [1:0] direction,
	 output [2:0] state
	 
	 );
	
    reg [2:0] current_state, next_state; 
    
    localparam  
					 CLEAR_WAIT			  = 3'd0,
					 CLEAR              = 3'd1,
					 MOVE_WAIT		     = 3'd2,
					 MOVE		           = 3'd3,
					 EAT_WAIT		     = 3'd4,
					 EAT                = 3'd5,
					 REPEAT			     = 3'd6;
	 
	 localparam 
					LEFT = 2'b0,
					RIGHT = 2'b01,
					UP = 2'b10,
					DOWN = 2'b11;

				
			
    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
					CLEAR_WAIT: next_state = CLEAR;
					CLEAR: next_state = MOVE_WAIT;
					MOVE_WAIT: next_state = MOVE;
					MOVE: next_state = EAT_WAIT;
					EAT_WAIT: next_state = EAT;
					EAT: next_state = REPEAT;
					REPEAT: next_state = delay ? CLEAR_WAIT : REPEAT;
					default: next_state = REPEAT;
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
					current_state <= REPEAT;
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
    input [2:0] state,
	 
	 
    output reg [7:0] x_out,
	 output reg [6:0] y_out,
	 output reg [2:0] colour
    );
	 
	 reg [5:0] length;
	 reg food_gen;
	 reg [7:0] headx, foodx;
	 reg [6:0] heady, foody;
	 reg [7:0] bodyx[0:127];
	 reg [6:0] bodyy[0:127];
	 integer i;
	 
	 
	 
	 localparam  
					 CLEAR_WAIT			  = 3'd0,
					 CLEAR              = 3'd1,
					 MOVE_WAIT		     = 3'd2,
					 MOVE		           = 3'd3,
					 EAT_WAIT		     = 3'd4,
					 EAT                = 3'd5,
					 REPEAT			     = 3'd6;
	 
	 localparam 
					LEFT = 2'b0,
					RIGHT = 2'b01,
					UP = 2'b10,
					DOWN = 2'b11;
					
	 wire [7:0] randx;
	 wire [6:0] randy;
	 
	 
	 food_gen fg0(
			.clk(clk),
			.gen(food_gen),
			.randomX(randx),
			.randomY(randy)
	 );
	 
					
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
		foodx <= 8'd50;
		foody <= 7'd70;
		colour <= 3'b000;
		food_gen <= 1'b0;
		length <= 1'd1;
		end
		
		
		else
		begin 
			case (state)
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
				x_out <= bodyx[length - 1];
				y_out <= bodyy[length - 1];
				colour <= 3'b000;
			end
			MOVE_WAIT:
			begin 
				if (foodx == headx && foody == heady) 
					length <= length + 1'b1;
				colour <= 3'b001;
			end
			
			MOVE:
			begin 
				x_out <= headx;
				y_out <= heady;
				bodyx[0] <= headx;
				bodyy[0] <= heady;
				
				for (i = 0; i < 127; i = i + 1)
				begin 
					if (bodyx[i] > 0)
					begin
						bodyx[i + 1] <= bodyx[i] - 1'b1;
					end 
					else 
					begin
						bodyx[i + 1] <= 8'b0;
					end 
					
					if (bodyy[i] > 0)
					begin
						bodyy[i + 1] <= bodyy[i] - 1'b1;
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
				if (foodx == headx && foody == heady)
					food_gen <= 1;
					
				
			end
			
			endcase
	  end
	end
				
			 
endmodule

module counter6(resetn, clk, enable, out) ;
	input resetn, clk, enable;
	output out;
	
	reg [2:0] count;
	
	
	always @ (posedge clk, negedge resetn) 
	 begin
        if (!resetn) 
		  begin
            count <= 3'b0; 
				
        end
        else if (enable)
		  begin
           if (count == 3'd6) 
			  begin
					count <= 0;
			  end
			  else 
			  begin
					count <= count + 1;
			  end
		  end
	 end
	 assign out = (count == 3'd6) ? 1 : 0;
	 
endmodule
	
module counter16(resetn, clk, enable, out) ;
	input resetn, clk, enable;
	output reg [3:0] out;
	
	
	always @ (posedge clk) 
	 begin
        if (!resetn) 
		  begin
            out <= 4'b0; 
				
        end
        else if (enable)
		  begin
           if (out == 4'b1111) 
			  begin
					out <= 0;
			  end
			  else 
			  begin
					out <= out + 1;
			  end
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


module food_gen (clk, gen, randomX, randomY);
	input clk, gen;
	output reg [7:0] randomX;
	output reg [6:0] randomY;

	reg [7:0] x = 8'd48;
	reg [6:0] y = 7'd92;
	
	always@(posedge clk)
	begin
		if (gen == 0)
		begin 
			if (x < 8'd159)
				x <= x + 1'b1;
			else 
				x <= 0;
		end
		if (gen == 1)
		begin
			if(x < 8'd159)
			begin
				randomX <= x;
				x<= x + 1;
			end
			else
			begin
				randomX <= x;
				x <= 7'd0;
			end
		end
	end
	
	always@(posedge clk)
	begin
		if (gen == 1)
		begin
			if(y > 7'd28)
			begin
				randomY <= y;
				y <= y - 1;
			end
			else
			begin
				randomY <= y;
				y <= 7'd92;
			end
		end
	end
	
endmodule 


module combined(clk, resetn, l, r, u, d, x_out, y_out, colour);
	input clk, resetn; 
	input l, r, u, d;
	
	output [7:0] x_out; 
	output [6:0] y_out;
	output [2:0] colour;
	
	wire delay, plot;
	wire [1:0] direction;
	wire [2:0] state;
	wire [1:0] dir;
	
	RateDivider r0(
		  .cout(delay),
		  .resetn(resetn),
		  .clk(clk),
		  .d(28'd1)
	);
	
	control C0(
        .clk(clk),
        .resetn(resetn),
		  .delay(delay),
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
		  
		  .food_gen(gen),
        .x_out(x_out),
		  .y_out(y_out),
		  .colour(colour)
    );
	 

	 keyboard_reader k0 (
			.left(l),
			.right(r),
			.up(u),
			.down(d),
			.out(dir)
	 );
endmodule
