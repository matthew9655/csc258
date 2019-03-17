module csc258project (CLOCK_50, KEY, SW,

        // The ports below are for the VGA output.  Do not change.

        VGA_CLK,                        //  VGA Clock

        VGA_HS,                         //  VGA H_SYNC

        VGA_VS,                         //  VGA V_SYNC

        VGA_BLANK_N,                        //  VGA BLANK

        VGA_SYNC_N,                     //  VGA SYNC

        VGA_R,                          //  VGA Red[9:0]

        VGA_G,                          //  VGA Green[9:0]

        VGA_B                           //  VGA Blue[9:0]

        );

 

    input CLOCK_50;

    input [8:0] KEY;

    input [2:0] SW;

    wire [27:0] rateCount;

    wire [11:0] hexCount;

    wire reset;

    wire go, start, win;

    wire [4:0] in;

    assign reset = ~SW[0];

    assign start = SW[1];

    assign go = (SW[1]^!KEY[3]^!KEY[2]^!KEY[1]^!KEY[0]); //change back in modelsim

    assign in = {SW[1], !KEY[3], !KEY[2], !KEY[1], !KEY[0]};

   

   

    // Do not change the following outputs

    output          VGA_CLK;                //  VGA Clock

    output          VGA_HS;                 //  VGA H_SYNC

    output          VGA_VS;                 //  VGA V_SYNC

    output          VGA_BLANK_N;                //  VGA BLANK

    output          VGA_SYNC_N;             //  VGA SYNC

    output  [9:0]   VGA_R;                  //  VGA Red[9:0]

    output  [9:0]   VGA_G;                  //  VGA Green[9:0]

    output  [9:0]   VGA_B;                  //  VGA Blue[9:0]

 

    wire drawWall, drawSnake, drawapple, restart, move;

    wire printed, snakePrinted, applePrinted, moved;

   

    wire [7:0] x;//, x_test;

    wire [6:0] y;//, y_test;

    wire [2:0] colour_out;

    wire [5:0] state_test;

    wire [7:0] i_test;

    wire [5:0] is_test;

    wire b_test;

    wire snakePlacetest, applePlacetest;

    wire [7:0] snakePos, applePos;
	 
	 
	/////////////////////////////////

	///////////The Wall//////////////

	/////////////////////////////////

	wire [239:0] wall;

	wire [239:0] walltemp;
	assign wall = {

	16'b1111111111111111,

	16'b1000010001000001,

	16'b1001010111111011,

	16'b1001000100110001,

	16'b1001111100110111,

	16'b1001000001110001,

	16'b1001000001010111,

	16'b1001111101010101,

	16'b1000000101010101,

	16'b1111110101000001,

	16'b1100010101011101,

	16'b1001000001000101,

	16'b1011111111110101,

	16'b1000000000000101,

	16'b1111111111111111

	};
	// Create an Instance of a VGA controller - there can be only one!

    // Define the number of colours as well as the initial background

    // image file (.MIF) for the controller.

    vga_adapter VGA(

            .resetn(reset),

            .clock(CLOCK_50),

            .colour(colour_out),

            .x(x),

            .y(y),

            .plot(1'b1),

            // Signals for the DAC to drive the monitor.

            .VGA_R(VGA_R),

            .VGA_G(VGA_G),

            .VGA_B(VGA_B),

            .VGA_HS(VGA_HS),

            .VGA_VS(VGA_VS),

            .VGA_BLANK(VGA_BLANK_N),

            .VGA_SYNC(VGA_SYNC_N),

            .VGA_CLK(VGA_CLK));

        defparam VGA.RESOLUTION = "160x120";

        defparam VGA.MONOCHROME = "FALSE";

        defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;

        defparam VGA.BACKGROUND_IMAGE = "black.mif";

    control c0(state_test, CLOCK_50, reset, printed, sunPrinted, moonPrinted, go, win, start, moved,drawMaze, drawSun, drawMoon,restart, move);

    datapath d0(CLOCK_50, reset, drawMaze, drawSun, drawMoon, restart, move, in, maze, mazetemp, x, y, colour_out, printed, sunPrinted, moonPrinted, win, moved, moveCount, sunPos, moonPos, i_test, b_test, is_test, sunPlacetest, moonPlacetest/*, test, i_test, x_test, y_test*/);

    RateDivider rd0 (28'h2faf080, !SW[0], start, 1'b1, CLOCK_50, rateCount);
endmodule

module control(state_test,clk, resetn, printed, snakePrinted, 
applePrinted, go, win, start, moved, drawWall, drawSnake, drawApple, restart, move);
	// This is the finite state machine records the state of the Snake

    input clk;

   input resetn;

    input printed, snakePrinted, applePrinted,go,start,moved, win;

    output reg drawSnake, drawWall, drawApple, restart, move;

    output [5:0] state_test;

   reg [5:0] current_state, next_state;  

    assign state_test = current_state;
     
     //assign state_test = current_state[2:0];

    localparam  RESET = 6'd1,

                     DRAW_Wall = 6'd2,

                     DRAW_Snake = 6'd3,

                     DRAW_Apple = 6'd4,

                     INPUT = 6'd5,

                     CHECK_INPUT = 6'd6,

                     INPUT_WAIT = 6'd7,

                     RESTART = 6'd8,

                     MOVE = 6'd9,

                     CHECK_WIN = 6'd10;

    // Next state logic aka our state table

    always@(*)

    begin: state_table

            case (current_state)

                    RESET: next_state = DRAW_Wall; // *

                     DRAW_Wall: next_state = printed ? DRAW_Snake : DRAW_Wall;

                     DRAW_Snake: next_state = SnakePrinted ? DRAW_Apple : DRAW_Snake;

                     DRAW_Apple: next_state = ApplePrinted ? INPUT : DRAW_Apple;

                     INPUT: next_state = go ? CHECK_INPUT : INPUT;

                     CHECK_INPUT: next_state = start ? RESTART : INPUT_WAIT;

                     INPUT_WAIT: next_state = go ? INPUT_WAIT : MOVE;

                     RESTART: next_state = go ? RESTART : DRAW_MAZE;

                     MOVE: next_state = moved ? CHECK_WIN : MOVE; 

                     CHECK_WIN: next_state = win ? RESTART : DRAW_Wall;

            default: next_state = RESET;

        endcase

    end // state_table
 

    // Output logic aka all of our datapath control signals

    always @(*)

    begin: enable_signals

        // By default make all our signals 0

            drawWall = 1'b0;

            drawSnake = 1'b0;

            drawApple = 1'b0;

         restart = 1'b0;

            move = 1'b0;

 

        case (current_state)

            RESET: begin

                drawWall = 1'b0;

                drawSnake = 1'b0;

                drawApple = 1'b0;

                restart = 1'b0;

                move = 1'b0;

            end
           
            DRAW_Wall: begin

                drawWall = 1'b1;

                restart = 1'b0;

            end

            DRAW_Snake: begin

                drawSnake = 1'b1;

            end          

            DRAW_Apple: begin

                drawApple = 1'b1;

            end

            RESTART: begin

               restart = 1'b1;

            end

            INPUT: begin

            drawApple = 1'b0;

         end

         INPUT_WAIT: begin

            drawApple = 1'b0;

         end

            CHECK_INPUT: begin

                drawApple = 1'b0;

            end

            MOVE: begin

               move = 1'b1;

           end
           
            CHECK_WIN: begin

                drawApple = 1'b0;

            end           

         default: next_state = RESET;

        endcase

    end // enable_signal

    // current_state registers

    always@(posedge clk)

    begin: state_FFs

        if(!resetn)

            current_state <= RESET;

        else

            current_state <= next_state;

    end // state_FFS

endmodule
module datapath(clk, reset, drawWall, drawSnake, drawApple, restart, 
move,in, wall, walltemp, x, y, colour_out, printed, 
SnakePrinted, applePrinted, win, moved, moveCount, 
snakePos, applePos, i_test, b_test, is_test, 
snakePlacetest, applePlacetest);


    input clk;

    input reset;

    input drawWall, drawSnake, drawApple,restart, move;

   // you can define the size of the wall
		input[] wall;
		output [7:0] x;

   output [6:0] y;

    output [2:0] colour_out;

    output printed, snakePrinted, applePrinted, moved, win;

    output snakePlacetest, applePlacetest;

	 output [11:0] moveCount;   

    input [4:0] in;

    wire [3:0] xm, ym;

    wire [7:0] xb, xs, xap;

    wire [6:0] yb, ys, yap;

    wire nextblock, snakePlaced, applePlaced;

    wire bEnable, sEnable, aEnable;

    output [7:0] i_test;

    output [5:0] is_test;

    output b_test;

    output [7:0] snakePos, applePos;

    assign b_test = bEnable;

    assign snakePlacetest = snakePlaced;

    assign applePlacetest = applePlaced;

    assign colour_out = bEnable*drawWall*3'b110 + sEnable*drawSnake*3'b110 + aEnable*drawApple*3'b111;

    assign x = xm*4'b1000 + xb*drawWall + xs*drawSnake + xap*drawApple + 5'd16;

    assign y = ym*4'b1000 + yb*drawWall + ys*drawSnake + yap*drawApple;

    printSnake ps (clk, drawSnake, snakePlaced, reset, xs, ys, sEnable, snakePrinted, is_test);

endmodule

module printSnake(cll, drawSnake, snakePlace, reset, xs, ys, WriteEn, snakePrinted, is_test);
	input clk, snakePlace, reset, drawSun;

    output reg [7:0] x;

    output reg [6:0] y;

    output reg snalePrinted;

    output reg WriteEn;

    output reg [5:0] is_test;

    wire [63:0] snake;

    reg [63:0] snakeTemp;

   
	// I temporary set every every pickel be 1 and you can change it later
    assign snake = {

    8'b11111111,
	 8'b11111111,
	 8'b11111111,
	 8'b11111111,
	 8'b11111111,
	 8'b11111111,
	 8'b11111111,
	 8'b11111111
    };

   

    reg [7:0] i;

   

    always @ (posedge clk) begin

        is_test <= i[5:0];

        if (!reset) begin

            x <= 8'b00000000; // Default start 80

            y <= 7'b0000000;

            i <= 8'b00000000;

            snakePrinted <= 1'b0;

            WriteEn <= 1'b0;

        end

       

        else if (snakePlaced && drawSnake) begin

            x <= i[2:0];

            y <= i[5:3];

            snakePrinted <= 1'b0;

 

            if (i == 8'b00000000) begin //if initial not done (first pixel)

                i <= 8'b10000000;

                snakeTemp <= snake << 1'b1;

                WriteEn <= snakeTemp[15];

            end

            else if (8'b11000001 > i && i > 8'b01111111) begin // once initial done (pixel 2 to 16)

                i <= i + 1'b1;

                snakeTemp <= snake << (i[5:0] + 1'b1);

                WriteEn <= snakeTemp[63];   
            end

            else if (i == 8'b11000001) begin //when i[3:0] > 1111 (6'b101111 is 17)

                i <= 8'b00000000;

                snakePrinted <= 1'b1;

            end

        end

    end

endmodule

module RateDivider (d, Clear_b, start, Enable, clock, q); /*Parload,*/

    output reg [27:0] q;

    input wire [27:0] d;

    input Clear_b, start;

    //input Parload;

    input Enable;

    input clock;

   

    always @ (posedge clock) //Triggered every time clock rises

    begin

            if (!Clear_b || start) //when Clear_b is 0

                q <= 28'b0; //q is set to 0

            //else if (Parload == 1'b1) //Check if parallel load

            //  q <= d; // load d

            else if (q == 28'b0) //

                q <= d; //q reset to 0

            else if (Enable) // decrement q only when Enable is 1

                q <= q - 1;

    end

endmodule
