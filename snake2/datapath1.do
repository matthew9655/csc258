vlib work

vlog -timescale 1ns/1ns 2snake.v

vsim datapath
log {/*}

add wave {/*}

force {clk} 0 0, 1 10 -repeat 20

force {resetn} 0 0, 1 400

force {right} 1 0, 0 20 -repeat 20


run 10000ns 


