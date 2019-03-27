vlib work

vlog -timescale 1ns/1ns snake.v

vsim food_gen

log {/*}

add wave {/*}

force {clk} 0 0, 1 10 -repeat 20

force {food_gen} 1 60, 0 80

force {food_gen} 1 120, 0 180

force {food_gen} 1 240, 0 260

run 320ns

