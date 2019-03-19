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
					 S_CYCLE_3: next_state = stop ? WAIT : S_CYCLE_2;
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

//module keyboard_tracker #(parameter PULSE_OR_HOLD = 0) (
//    input clock,
//	 input reset,
//	 
//	 inout PS2_CLK,
//	 inout PS2_DAT,
//	 
//	 output w, a, s, d,
//	 output left, right, up, down,
//	 output space, enter
//	 );
//	 
//	 // A flag indicating when the keyboard has sent a new byte.
//	 wire byte_received;
//	 // The most recent byte received from the keyboard.
//	 wire [7:0] newest_byte;
//	 	 
//	 localparam // States indicating the type of code the controller expects
//	            // to receive next.
//	            MAKE            = 2'b00,
//	            BREAK           = 2'b01,
//					SECONDARY_MAKE  = 2'b10,
//					SECONDARY_BREAK = 2'b11,
//					
//					// Make/break codes for all keys that are handled by this
//					// controller. Two keys may have the same make/break codes
//					// if one of them is a secondary code.
//					// TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS	
//					W_CODE = 8'h1d,
//					A_CODE = 8'h1c,
//					S_CODE = 8'h1b,
//					D_CODE = 8'h23,
//					LEFT_CODE  = 8'h6b,
//					RIGHT_CODE = 8'h74,
//					UP_CODE    = 8'h75,
//					DOWN_CODE  = 8'h72,
//					SPACE_CODE = 8'h29,
//					ENTER_CODE = 8'h5a;
//					
//    reg [1:0] curr_state;
//	 
//	 // Press signals are high when their corresponding key is being pressed,
//	 // and low otherwise. They directly represent the keyboard's state.
//	 // TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS	 
//    reg w_press, a_press, s_press, d_press;
//	 reg left_press, right_press, up_press, down_press;
//	 reg space_press, enter_press;
//	 
//	 // Lock signals prevent a key press signal from going high for more than one
//	 // clock tick when pulse mode is enabled. A key becomes 'locked' as soon as
//	 // it is pressed down.
//	 // TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS
//	 reg w_lock, a_lock, s_lock, d_lock;
//	 reg left_lock, right_lock, up_lock, down_lock;
//	 reg space_lock, enter_lock;
//	 
//	 // Output is equal to the key press wires in mode 0 (hold), and is similar in
//	 // mode 1 (pulse) except the signal is lowered when the key's lock goes high.
//	 // TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS
//    assign w = w_press && ~(w_lock && PULSE_OR_HOLD);
//    assign a = a_press && ~(a_lock && PULSE_OR_HOLD);
//    assign s = s_press && ~(s_lock && PULSE_OR_HOLD);
//    assign d = d_press && ~(d_lock && PULSE_OR_HOLD);
//
//    assign left  = left_press && ~(left_lock && PULSE_OR_HOLD);
//    assign right = right_press && ~(right_lock && PULSE_OR_HOLD);
//    assign up    = up_press && ~(up_lock && PULSE_OR_HOLD);
//    assign down  = down_press && ~(down_lock && PULSE_OR_HOLD);
//
//    assign space = space_press && ~(space_lock && PULSE_OR_HOLD);
//    assign enter = enter_press && ~(enter_lock && PULSE_OR_HOLD);
//	 
//	 // Core PS/2 driver.
//	 PS2_Controller #(.INITIALIZE_MOUSE(0)) core_driver(
//	     .CLOCK_50(clock),
//		  .reset(~reset),
//		  .PS2_CLK(PS2_CLK),
//		  .PS2_DAT(PS2_DAT),
//		  .received_data(newest_byte),
//		  .received_data_en(byte_received)
//		  );
//		  
//    always @(posedge clock) begin
//	     // Make is default state. State transitions are handled
//        // at the bottom of the case statement below.
//		  curr_state <= MAKE;
//		  
//		  // Lock signals rise the clock tick after the key press signal rises,
//		  // and fall one clock tick after the key press signal falls. This way,
//		  // only the first clock cycle has the press signal high while the
//		  // lock signal is low.
//		  // TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS
//		  w_lock <= w_press;
//		  a_lock <= a_press;
//		  s_lock <= s_press;
//		  d_lock <= d_press;
//		  
//		  left_lock <= left_press;
//		  right_lock <= right_press;
//		  up_lock <= up_press;
//		  down_lock <= down_press;
//		  
//		  space_lock <= space_press;
//		  enter_lock <= enter_press;
//		  
//	     if (~reset) begin
//		      curr_state <= MAKE;
//				
//				// TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS
//				w_press <= 1'b0;
//				a_press <= 1'b0;
//				s_press <= 1'b0;
//				d_press <= 1'b0;
//				left_press  <= 1'b0;
//				right_press <= 1'b0;
//				up_press    <= 1'b0;
//				down_press  <= 1'b0;
//				space_press <= 1'b0;
//				enter_press <= 1'b0;
//				
//				w_lock <= 1'b0;
//				a_lock <= 1'b0;
//				s_lock <= 1'b0;
//				d_lock <= 1'b0;
//				left_lock  <= 1'b0;
//				right_lock <= 1'b0;
//				up_lock    <= 1'b0;
//				down_lock  <= 1'b0;
//				space_lock <= 1'b0;
//				enter_lock <= 1'b0;
//        end
//		  else if (byte_received) begin
//		      // Respond to the newest byte received from the keyboard,
//				// by either making or breaking the specified key, or changing
//				// state according to special bytes.
//				case (newest_byte)
//				    // TODO: ADD TO HERE WHEN IMPLEMENTING NEW KEYS
//		          W_CODE: w_press <= curr_state == MAKE;
//					 A_CODE: a_press <= curr_state == MAKE;
//					 S_CODE: s_press <= curr_state == MAKE;
//					 D_CODE: d_press <= curr_state == MAKE;
//					 
//					 LEFT_CODE:  left_press  <= curr_state == MAKE;
//					 RIGHT_CODE: right_press <= curr_state == MAKE;
//					 UP_CODE:    up_press    <= curr_state == MAKE;
//					 DOWN_CODE:  down_press  <= curr_state == MAKE;
//					 
//					 SPACE_CODE: space_press <= curr_state == MAKE;
//					 ENTER_CODE: enter_press <= curr_state == MAKE;
//
//					 // State transition logic.
//					 // An F0 signal indicates a key is being released. An E0 signal
//					 // means that a secondary signal is being used, which will be
//					 // followed by a regular set of make/break signals.
//					 8'he0: curr_state <= SECONDARY_MAKE;
//					 8'hf0: curr_state <= curr_state == MAKE ? BREAK : SECONDARY_BREAK;
//		      endcase
//        end
//        else begin
//		      // Default case if no byte is received.
//		      curr_state <= curr_state;
//		  end
//    end
//endmodule

module food_gen (clk, gen, randomX, randomY);
	input clk, gen;
	output reg [9:0] randomX;
	output reg [8:0] randomY;

	reg [7:0] x = 10; //.5 -> 0 - 255 -> 62
	reg [6:0] y = 10; //.5 -> 0 - 127 -> 46
	
	always@(posedge clk)
		x <= x + 4;
		
	always@(posedge clk)
		y <= y + 2;
	
	always@(posedge clk)
	begin
		if (gen == 1)
		begin
			if(x > 62)
			begin
				randomX <= ((x % 62) + 1) * 10;
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

