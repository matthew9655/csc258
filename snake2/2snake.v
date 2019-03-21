//KEY[0] active low reset
//KEY[1] go signal


module snake_2(KEY, CLOCK_50, VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK, VGA_R, VGA_G, VGA_B, PS2_CLK, PS2_DAT);
    input [3:0] KEY;
    input CLOCK_50;
    output VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK;
	 output [9:0] VGA_R, VGA_G, VGA_B;
	 inout PS2_CLK, PS2_DAT;
	 
	 
    wire resetn;
	 wire draw;
    assign resetn = KEY[0];
	 assign draw = KEY[1];

    part2 u0(
        .clk(CLOCK_50),
        .resetn(resetn),
		  .draw(draw),
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
	 input draw,
	 output VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK,
	 output [9:0] VGA_R, VGA_G, VGA_B,
	 inout PS2_CLK, PS2_DAT
	 
	 
    );
	 // wires for food generation
	 wire gen;
	 wire [6:0] foodx;
	 wire [6:0] foody;
	 
	 // wires for moving the bit
    wire move, enable, plot, stop, delay;
	 wire left, right, up, down;
	 wire [6:0] x_out; 
	 wire [6:0] y_out;
	 wire [2:0] c_out, colour;
	 
	 // wires to contain the other values on the keyboard
	 wire not_used[5:0];
	 
	 wire enable_d;
	 
	 
	 
	 RateDivider r0(
			.cout(delay),
			.reset(reset),
			.clk(clk),
			.d({4'b0, 24'd12500000}),
			.enable_d(enable_d)
	 );
	 
	 
	 food_gen(
			.clk(clk),
			.gen(gen),
			.randomX(foodx),
			.randomY(foody)
	 );
	 
	 
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
		  .draw(draw),
		  .stop(stop),
		  .delay(delay),
		  
        .move(move),
        .enable(enable),
        .plot(plot),
		  .colour(colour),
		  .enable_d(enable_d)
        
    );

    datapath D0(
        .clk(clk),
        .resetn(resetn),
		  .left(left),
		  .right(right),
		  .up(up),
		  .down(down),
		  .move(move),
		  .foodx(foodx),
		  .foody(foody),
        .enable(enable), 

		  
		  .stop(stop),
		  .food_gen(gen),
        .x_out(x_out),
		  .y_out(y_out)
    );
	 
	 keyboard_tracker #(.PULSE_OR_HOLD(1)) KB0 (
			.clock(clk),
			.reset(reset),
			.PS2_CLK(PS2_CLK),
			.PS2_DAT(PS2_DAT),
			.w(not_used[5]),
			.a(not_used[4]),
			.s(not_used[3]),
			.d(not_used[2]),
			.space(not_used[1]),
			.enter(not_used[0]),
			.left(left),
			.right(right),
			.up(up),
			.down(down)
	 );
	 
                
 endmodule        
                

module control(
    input clk,
    input resetn,
	 input draw,
	 input stop,
	 input delay,
	 input food_gen,
	 
	 output reg move, enable, plot, enable_d,
	 output reg [2:0] colour
	 );
	
   

    reg [3:0] current_state, next_state; 
    
    localparam 
					 START           = 4'd0,
					 START_WAIT		  = 4'd1,
					 DRAW            = 4'd2,
					 DRAW1			  = 4'd3,
					 WAIT            = 4'd4,
					 BLACK			  = 4'd5,
					 BLACK1		     = 4'd6,
					 MOVE				  = 4'd7,
					 FOOD				  = 4'd8,
					 FOOD1			  = 4'd9;
			
    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
					 START: next_state = draw ? START_WAIT : START;
					 START_WAIT: next_state = draw ? START_WAIT : DRAW;
                DRAW: next_state = DRAW1;
					 DRAW1: next_state = stop ? WAIT : DRAW; 
					 WAIT: next_state = delay ? BLACK : WAIT;
					 BLACK: next_state = BLACK1;
					 BLACK1: next_state = stop ? MOVE : BLACK;
					 MOVE: next_state = food_gen ? FOOD : DRAW;
					 FOOD: next_state = FOOD1;
					 FOOD1: next_state = stop ? DRAW : FOOD;
            default:     next_state = START;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
		  enable = 1'b0;
		  plot = 1'b0;
		  colour = 3'b000;
		  move = 1'b0;
		  enable_d = 1'b0;


        case (current_state)
            DRAW: 
				begin
					enable = 1'b1;
					plot = 1'b1;
					colour = 3'b010;
            end
				WAIT: 
				begin 
					enable_d = 1'b1;
					 
				end	
				BLACK: 
				begin 
					 enable = 1'b1;
					 plot = 1'b1;
					 colour = 3'b111;
				end
				MOVE: 
				begin
					 move = 1'b1;
			   end
				FOOD:
				begin
					 enable = 1'b1;
					 plot = 1'b1;
					 colour = 3'b100;
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
    input resetn, enable,
	 input left, right, up, down,// if y_dir is 1, go down else up. if x_dir is 1, go right, else left.
	 input move, // if move is high, move x y based on x_dir, y_dir // colour the pixel black if black is high
	 
	 // food 
	 input [6:0] foodx,
	 input [6:0] foody,
	 output reg food_gen,
	 
	 
    output [6:0] x_out,
	 output [6:0] y_out,
	 output reg stop
    );
	 
	 // registers for coordinates of x ,y
	 reg [6:0] regx;
	 reg [6:0] regy;
	 
	 reg [3:0] count; 
	 
	 // registers for directions
	 reg r, l, u, d;
	 
	 // moving the blocks of x and y
	 
	 always @ (posedge clk) 
	 begin 
		if (!resetn)
		begin
		    regx <= 7'd80;
			 regy <= 7'd60;
			 r <= 1'b0;
			 l <= 1'b0;
			 u <= 1'b0;
			 d <= 1'b0;
		end
		
		else 
		begin
			if (move == 1) 
			begin
				if (right == 1 && l == 0)
				begin
					regx <= regx + 1;
					r <= 1'b1;
					l <= 1'b0;
					u <= 1'b0;
					d <= 1'b0;
				end
				else if (left == 1 && r == 0)
				begin
					regx <= regx - 1;
					r <= 1'b0;
					l <= 1'b1;
					u <= 1'b0;
					d <= 1'b0;
				end
				else if (up == 1 && d == 0)
				begin 
					regy <= regy + 1;
					r <= 1'b0;
					l <= 1'b0;
					u <= 1'b1;
					d <= 1'b0;
				end
				else if (down == 1 && u == 0)
				begin 
					regy <= regy - 1;
					r <= 1'b0;
					l <= 1'b0;
					u <= 1'b0;
					d <= 1'b1;
				end
			 end
		end
	 end
	 
	 always @ (posedge clk)
	 begin
		  if (!resetn)
		  begin 
				food_gen = 1'b0;
		  end
		  else
		  begin
			  if ((regx == foodx) && (regy == foody))
			  begin 
					food_gen <= 1'b1;
			  end
		  end
	 end
		
    // counter to colour in bits
    always @ (posedge clk) 
	 begin
        if (!resetn) 
		  begin
            count <= 4'b0; 
				stop <= 1'b0;
        end
        else if (enable)
		  begin
           if (count == 4'b1111) 
			  begin
					count <= 0;
					stop <= 1;
			  end
			  else 
			  begin
					count <= count + 1;
					stop <= 0;
			  end
		  end
	 end
	 
	 
	 assign x_out = food_gen ? (foodx + count[1:0]) : (regx + count[1:0]);
	 assign y_out = food_gen ? (foody + count[3:2]) : (regy + count[3:2]);
	 
	 
endmodule

module RateDivider(cout, reset, clk, d, enable_d) ; // need to take into account of the frames too
	input [27:0] d;
	input reset, clk;
	input enable_d;
	output cout; 
	
	reg [27:0] count;
	
	always @ (posedge clk)
	begin 
		if (reset == 1'b0)
		begin
			count <= d;
		end
		
		if (enable_d == 1'b1)
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
	

