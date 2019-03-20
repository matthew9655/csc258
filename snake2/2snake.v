// Sw[9:7] colour
// SW[6:0] input

//KEY[0] active low reset
//KEY[1] go signal
// enable KEY[3]
//LEDR displays result
//HEX0 & HEX1 also displays result

module snake_2(SW, KEY, CLOCK_50, VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK, VGA_R, VGA_G, VGA_B);
    input [9:0] SW;
    input [3:0] KEY;
    input CLOCK_50;
    output VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK;
	 output [9:0] VGA_R, VGA_G, VGA_B;

    wire resetn;
    wire go;
	 wire draw;
    assign go = ~KEY[3];
    assign resetn = KEY[0];
	 assign draw = KEY[1];

    part2 u0(
        .clk(CLOCK_50),
        .resetn(resetn),
        .go(go),
		  .draw(draw),
		  .color(SW[9:7]),
        .VGA_HS(VGA_HS),
		  .VGA_VS(VGA_VS),
		  .VGA_BLANK(VGA_BLANK),
		  .VGA_SYNC(VGA_SYNC),
		  .VGA_CLK(VGA_CLK),
		  .VGA_R(VGA_R),
		  .VGA_G(VGA_G),
		  .VGA_B(VGA_B)
    );

endmodule

module part2(
    input clk,
    input resetn,
    input go,
	 input draw, stop, delay,
	 input [2:0] color,
	 output VGA_HS, VGA_VS, VGA_BLANK,VGA_SYNC, VGA_CLK,
	 output [9:0] VGA_R, VGA_G, VGA_B,
	 inout PS2_CLK, PS2_DAT
	 
	 
    );
	 // wires for food generation
	 wire gen;
	 wire [7:0] food_x;
	 wire [6:0] food_y;
	 
	 // wires for moving the bit
    wire black, move, ld_c, enable, plot;
	 wire left, right, up, down;
	 wire [7:0] x_out; 
	 wire [6:0] y_out;
	 wire [2:0] c_out;
	 
	 // wires to contain the other values on the keyboard
	 wire not_used[5:0];
	 
	 // the stop wire from the datapath to the FSM
	 wire stop_counter;
	 
	 
	 RateDivider r0(
			.cout(delay),
			.reset(reset),
			.clk(clk),
			.d({4'b0, 24'd12500000})
	 );
	 
	 
	 food_gen(
			.clk(clk),
			.gen(gen),
			.randomX(food_x),
			.randomY(food_y)
	 );
	 
	 
	 vga_adapter a0(
			.resetn(resetn),
			.clock(clk),
			.colour(c_out),
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
        .go(go),
		  .draw(draw),
		  .stop(stop_counter),
		  .delay(delay),
        .black(black),
        .move(move),
        .ld_c(ld_c),
        .enable(enable),
        .plot(plot)
        
    );

    datapath D0(
        .clk(clk),
        .resetn(resetn),
		  .left(left),
		  .right(right),
		  .up(up),
		  .down(down),
        .black(black),
		  .move(move),
		  .food_x(food_x),
		  .food_y(food_y),
        .enable(enable),
        .ld_c(ld_c), 
		  .colour(color),
		  
		  .stop(stop),
		  .gen_food(gen)
        .x_out(x_out),
		  .y_out(y_out),
		  .c_out(c_out)
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
    input go,
	 input draw,
	 input stop,
	 input delay,
	 input food_gen
	 

    output reg  black, move, ld_c, enable, plot
    );

    reg [3:0] current_state, next_state; 
    
    localparam 
                S_LOAD_C        = 4'd1,
                S_LOAD_C_WAIT   = 4'd2,
					 DRAW            = 4'd3,
					 DRAW_WAIT       = 4'd4,
					 BLACK           = 4'd5,
                S_CYCLE_0       = 4'd6,
					 S_CYCLE_1       = 4'd7,
					 MOVE				  = 4'd8,
					 S_CYCLE_2       = 4'd9,
					 S_CYCLE_3       = 4'd10,
					 WAIT            = 4'd11;
					 
					 
    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_C: next_state = go ? S_LOAD_C_WAIT : S_LOAD_C; // Loop in current state until value is input
                S_LOAD_C_WAIT: next_state = go ? S_LOAD_C_WAIT : DRAW; // Loop in current state until go signal goes low
					 DRAW: next_state = draw ? DRAW_WAIT : DRAW;
					 DRAW_WAIT: next_state = draw ? DRAW_WAIT : BLACK;
					 BLACK: next_state = S_CYCLE_0;
                S_CYCLE_0: next_state = S_CYCLE_1;
					 S_CYCLE_1: next_state = stop ? MOVE : S_CYCLE_0; 
					 MOVE: next_state = S_CYCLE_2;
					 S_CYCLE_2: next_state = S_CYCLE_3;
					 S_CYCLE_3: next_state = stop ? FOOD_WAIT : S_CYCLE_2;
					 FOOD_WAIT: next_state = food_gen ? FOOD : WAIT;
					 FOOD: next_state = S_CYCLE_4;
					 S_CYCLE_4: next_state = S_CYCLE_5;
					 S_CYCLE_5: next_state = stop ? WAIT : S_CYCLE_4;
					 WAIT: next_state = delay ? BLACK : WAIT;
            default:     next_state = S_LOAD_C;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ld_c = 1'b0;
		  enable = 1'b0;
		  plot = 1'b0;
		  black = 1'b0;
		  move = 1'b0;


        case (current_state)
            S_LOAD_C: begin
                ld_c = 1'b1;
                end
				BLACK: begin 
					black = 1'b1;
					end
            S_CYCLE_0: begin 
					 enable = 1'b1;
					 plot = 1'b1;
					 end
				S_CYCLE_1: begin 
					 enable = 1'b1;
					 plot = 1'b1;
					 end
				MOVE: begin
					 move = 1'b1;
					 ld_c = 1'b1;
					 enable = 1'b0;
					 plot = 1'b0;
					 end
				S_CYCLE_2: begin 
					 enable = 1'b1;
					 plot = 1'b1;
					 end
				S_CYCLE_3: begin 
					 enable = 1'b1;
					 plot = 1'b1;
					 end
					 
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_C;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

module datapath(
	 // moving snake
    input clk,
    input resetn, enable,
	 input left, right, up, down,// if y_dir is 1, go down else up. if x_dir is 1, go right, else left.
    input [2:0] colour,
    input ld_c,
	 input move, // if move is high, move x y based on x_dir, y_dir
	 input black, // colour the pixel black if black is high
	 
	 // food 
	 input [7:0] food_x,
	 input [6:0] food_y,
	 output reg gen_food,
	 
	 
    output [8:0] x_out,
	 output [7:0] y_out,
	 output [2:0] c_out,
	 output reg stop
    );
	 
	 // registers for coordinates of x ,y
	 reg [8:0] regx;
	 reg [7:0] regy;
	 reg [2:0] regc;
	 
	 reg [3:0] count; 
	 
	 // registers for directions
	 reg x_dir, y_dir;
	 reg ver, hor;
	 
	 
    // registers for regc
	 
    always @ (posedge clk) 
	 begin
        if (!resetn) 
		  begin
				regc <= 3'b0;
				
        end
        else 
		  begin
				if (ld_c == 1)
				begin
					regc <= colour;
				end
				else if (black == 1)
				begin 
					regc <= 3'b0;
				end
        end
		  
    end
	 
	 // setting the logic direction bits
	 always @ (posedge clk) 
	 begin 
		if (!resetn)
		begin
		    ver <= 1'b0;
			 hor <= 1'b0;
			 x_dir <= 1'b0;
			 y_dir <= 1'b0;
			 
		end
		else
		begin 
			if (left == 1)
			begin 
				hor <= 1'b1;
				ver <= 1'b0;
				x_dir <= 1'b0;
			end
			else if (right == 1)
			begin 
				hor <= 1'b1;
				ver <= 1'b0;
				x_dir <= 1'b1;
			end
			else if (up == 1)
			begin 
				ver <= 1'b1;
				hor <= 1'b0;
				y_dir <= 1'b0;
			end
			else if (down == 1)
			begin
				ver <= 1'b1;
				hor <= 1'b0;
				y_dir <= 1'b1;
			end
		end
	 end
	 
	 
	 // moving the blocks of x and y
	 
	 always @ (posedge clk) 
	 begin 
		if (!resetn)
		begin
		    regx <= 8'd80;
			 regy <= 7'd60;
		end
		
		else 
		begin
			if (move == 1) 
			begin
				if (x_dir == 1 && ver == 1)
				begin
					regx <= regx + 1;
				end
				else if (x_dir == 0 && ver == 1)
				begin
					regx <= regx - 1;
				end
				
				if (y_dir == 1 && hor == 1)
				begin 
					regy <= regy + 1;
				end
				else if (y_dir == 0 && hor == 1)
				begin 
					regy <= regy - 1;
				end
				
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
	 
	 
	 assign x_out = regx + count[1:0];
	 assign y_out = regy + count[3:2];
	 assign c_out = regc;
	 
	 // checking for food 
	 always @ (posedge clk) 
	 begin
		if (regx == food_x) && (regy == food_y)
			begin 
			gen_food <= 1'b1;
			end
	 end

    
endmodule

module RateDivider(cout, reset, clk, d) ; // need to take into account of the frames too
	input [27:0] d;
	input reset, clk;
	output cout; 
	
	reg [27:0] count;
	
	always @ (posedge clk)
	begin 
		if (reset == 1'b0)
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
	output reg [9:0] randomX;
	output reg [8:0] randomY;

	reg [6:0] x = 10; //.5 -> 0 - 127 -> 62
	reg [6:0] y = 10; //.5 -> 0 - 127 -> 46
	
	always@(posedge clk)
		x <= x + 4;
		
	always@(posedge clk)
		y <= y + 2;
	
	always@(posedge clk)
	begin
		if (gen == 1)
		begin
			if(x > 46)
			begin
				randomX <= ((x % 46) + 1) * 10;
			end
			else if (x < 5)
			begin
				randomX <= ((x + 1) * 4) * 10;
			end
			else
			begin
				randomX <= (x * 10);
			end
		end
	end
	
	always@(posedge clk)
	begin
		if (gen == 1)
		begin
			if(y > 46)
			begin
				randomY <= ((y % 46) + 1) * 10;
			end
			else if (y < 5)
			begin
				randomY <= ((y + 1) * 3) * 10;
			end
			else
			begin
				randomY <= (y * 10);
			end
		end
	end
	endmodule 
	
module foodTest(CLOCK_50, snakeX, snakeY, foodX, foodY, outX, outY);
	input CLOCK_50;
	 input[9:0] snakeX, foodX;
	 input[8:0] snakeY, foodY;
	 output reg[9:0] outX;
	 output reg[8:0] outY;
	 wire[9:0] x;
	 wire[8:0] y;
	 random_generator ran(CLOCK_50, x, y);
	 assign regenerate_food = (snakeX == foodX)&&(snakeY == foodY);
	 always @(posedge CLOCK_50)
	 begin
		if(regenerate_food == 1'b1)
		begin
			outX <= x;
			outY <= y;
		end
		else
		begin
			outX <= foodX;
			outY <= foodY;
		end
	end
	endmodule

