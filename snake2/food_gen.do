vlib work

vlog -timescale 1ns/1ns 2snake.v

vsim food_gen

log {/*}

add wave {/*}

force {gen} 1 0, 0 2 -repeat 4
force {clk} 1 0, 0 2 -repeat 4
run 5ns
# enable
# reset_n
force {gen} 1 0, 0 2 -repeat 4
force {clk} 1 0, 0 2 -repeat 4
run 5ns