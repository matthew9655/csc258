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
	 input l, r, u, d;
	 output VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK,
	 output [9:0] VGA_R, VGA_G, VGA_B,
	 inout PS2_CLK, PS2_DAT
    );
	
	 wire left, right, up, down, stop;
	 
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
			.plot(1'b1),
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
        .clk(control_clk),
        .resetn(resetn),
		  .dir(dir),
		  
        .left(left),
		  .right(right),
		  .up(up),
		  .down(down),
		  .stop(stop)
    );
	 

    datapath D0(
        .clk(clk),
        .resetn(resetn),
		  .left(left),
		  .right(right),
		  .up(up),
		  .down(down),
		  .stop(stop),

		  
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
			.d(28'd8)
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
    input resetn,
	 input [1:0] dir, // 0 for left, 1 for right, 2 for up, 3 for down
	 
	 output reg left, right, up ,down, stop
	 );
	
    reg [3:0] current_state, next_state; 
    
    localparam  
					 START			  = 4'd0,
					 RIGHT           = 4'd1,
					 RIGHT_WAIT		  = 4'd2,
					 LEFT		        = 4'd3,
					 LEFT_WAIT		  = 4'd4,
					 UP              = 4'd5,
					 UP_WAIT			  = 4'd6,
					 DOWN				  = 4'd7,
					 DOWN_WAIT		  = 4'd8;
				
			
    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
				START: next_state = RIGHT;
				RIGHT: 
				begin 
					if (dir == 2'd2)
					begin
						next_state = UP;
					end
					else if (dir == 2'd3)
					begin
						next_state = DOWN;
					end
					else
					begin
						next_state = RIGHT_WAIT;
					end
				end
				
				RIGHT_WAIT: next_state = RIGHT;
				
				LEFT: 
				begin 
					if (dir == 2'd2)
					begin
						next_state = UP;
					end
					else if (dir == 2'd3)
					begin
						next_state = DOWN;
					end
					else
					begin
						next_state = LEFT_WAIT;
					end
				end
				
				LEFT_WAIT: next_state = LEFT;
				
				UP: 
				begin 
					if (dir == 2'd0)
					begin
						next_state = LEFT;
					end
					else if (dir == 2'd1)
					begin
						next_state = RIGHT;
					end
					else
					begin
						next_state = UP_WAIT;
					end
				end
				
				UP_WAIT: next_state = UP;
				
				
				DOWN: 
				begin 
					if (dir == 2'd0)
					begin
						next_state = LEFT;
					end
					else if (dir == 2'd1)
					begin
						next_state = RIGHT;
					end
					else
					begin
						next_state = DOWN_WAIT;
					end
				end
				
				DOWN_WAIT: next_state = DOWN;
					 
            default: next_state = RIGHT;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
		  left = 1'b0;
		  right = 1'b0;
		  up = 1'b0;
		  down = 1'b0;


        case (current_state)
				START:
				begin
					stop = 1'b1;
					left = 1'b0;
					right = 1'b0;
					up = 1'b0;
					down = 1'b0;
				end
            LEFT: 
				begin
					stop = 1'b0;
					left = 1'b1;
					right = 1'b0;
					up = 1'b0;
					down = 1'b0;
            end
				RIGHT: 
				begin 
				   stop = 1'b0;
					left = 1'b0;
					right = 1'b1;
					up = 1'b0;
					down = 1'b0;
					 
				end	
				UP: 
				begin 
					stop = 1'b0;
					left = 1'b0;
					right = 1'b0;
					up = 1'b1;
					down = 1'b0;
				end
				DOWN: 
				begin
					stop = 1'b0;
					left = 1'b0;
					right = 1'b0;
					up = 1'b0;
					down = 1'b1;
			   end
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= START;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

module datapath(
	 // moving snake
    input clk,
    input resetn,
	 input left, right, up, down,
	 input stop,
	 
	 // food 
	 input [7:0] foodx,
	 input [6:0] foody,
	 output reg food_gen,
	 
	 
    output reg [7:0] x_out,
	 output reg [6:0] y_out,
	 output reg [2:0] colour
    );
	 
	 reg [7:0] headx, x1, x2, x3, x4, x5, tailx;
	 reg [6:0] heady, y1, y2, y3, y4, y5, taily;
	 
	 
	 
	 wire new_clk;
	 RateDivider r0 (
			.cout(new_clk),
			.resetn(resetn),
			.clk(clk),
			.d(28'd2)
	 );
	 
	 wire delay;
	 counter6 c6 (
			.resetn(resetn),
			.clk(new_clk),
			.enable(1'b1),
			.out(delay)
	 );
	
	 
	 
	 wire [3:0] pixel;
	 counter16 p0 (
			.resetn(resetn),
			.clk(clk),
			.enable(1'b1),
			.out(pixel)
	 );
	 
	 
	 
	 always @ (posedge new_clk, negedge resetn) 
	 begin 
		if (!resetn) 
		begin 
			x1 <= 8'd80;
			y1 <= 7'd60;
			
			headx <= x1;
			heady <= y1;
			
			x5 <= x4 - 8'd4; 
			x4 <= x3 - 8'd4; 
			x3 <= x2 - 8'd4; 
			x2 <= x1 - 8'd4; 
	
			tailx <= x5 - 8'd4;
			
			y5 <= y4; 
			y4 <= y3; 
			y3 <= y2; 
			y2 <= y1; 
			
			
			taily <= y5;
			

			food_gen <= 1'b0;
			colour <= 3'b000;
			
	   end
	 
		else 
		 begin
				tailx <= x5;
				x5 <= x4; 
				x4 <= x3; 
				x3 <= x2; 
				x2 <= x1; 
				
				taily <= y5;
				y5 <= y4;
				y4 <= y3; 
				y3 <= y2; 
				y2 <= y1; 
				
				
				if (right == 1'b1)
				begin
					x1 <= x1 + 3'b100;
				end
				else if (left == 1'b1)
				begin 
					x1 <= x1 - 3'b100;
				end
				else if (down == 1'b1)
				begin
					y1 <= y1 + 3'b100;
				end
				else if (up == 1'b1)
				begin 
					y1 <= y1 - 3'b100;
				end
						
				if ((headx == foodx) && (heady == foody))
					begin
						food_gen <= 1'b1;				
					end
		
				if (food_gen == 0)
				begin 
					if (delay == 0)
					begin					
					headx <= x1;
					heady <= y1;
					colour <= 3'b001;
					end

					else if (delay == 1)
					begin 	
						headx <= tailx;
						heady <= taily;
						colour <= 3'b000;
					end
            end
			
				else 
				begin
					headx <= foodx;
					heady <= foody;
					colour <= 3'b001;
					food_gen <= 1'b0;
				
				end
			end
		end
		
		
	 always @(posedge clk)
	 begin
			if (!resetn)
			begin
				x_out <= 8'd80;
				y_out <= 7'd60;
			end
			else 
				begin 
					x_out <= headx + pixel[1:0];
					y_out <= heady + pixel[3:2];
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
	output reg [6:0] randomX;
	output reg [6:0] randomY;

	reg [6:0] x = 7'd48;
	reg [6:0] y = 7'd92;
	
	always@(posedge clk)
	begin
		if (gen == 1)
		begin
			if(x < 7'd112)
			begin
				randomX <= x;
				x<= x + 1;
			end
			else
			begin
				randomX <= x;
				x <= 7'd48;
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


module combined(clk, resetn, dir, x_out, y_out, colour);
	input clk, resetn; 
	input [1:0] dir;
	output [7:0] x_out; 
	output [6:0] y_out;
	output [2:0] colour;
	
	wire left, right, up, down, stop;
	

	control C0(
        .clk(clk),
        .resetn(resetn),
		  .dir(dir),
		  
        .left(left),
		  .right(right),
		  .up(up),
		  .down(down),
		  .stop(stop)
    );
	 

    datapath D0(
        .clk(clk),
        .resetn(resetn),
		  .left(left),
		  .right(right),
		  .up(up),
		  .down(down),
		  .stop(stop),

		  
		  .food_gen(gen),
        .x_out(x_out),
		  .y_out(y_out),
		  .colour(colour)
    );
endmodule
