vlib work

vlog -timescale 1ns/1ns 2snake.v

vsim counter6
log {/*}

add wave {/*}

force {clk} 0 0, 1 10 -repeat 20

force {resetn} 0 0, 1 20

force {enable} 1 0



run 500ns


