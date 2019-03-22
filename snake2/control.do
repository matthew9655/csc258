vlib work

vlog -timescale 1ns/1ns 2snake.v

vsim control

log {/*}

add wave {/*}

force {clk} 0 0, 1 10 -repeat 20

force {resetn} 0 0, 1 20

force {draw} 1 20, 0 40

force {stop} 1 80, 0 100

force {delay} 1 100, 0 120

force {stop} 1 140, 0 160

force {food_gen} 1 160, 0 180

force {stop} 1 200, 0 220
 
run 300ns



