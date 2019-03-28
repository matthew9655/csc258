
vlib work

vlog -timescale 1ns/1ns snake.v

vsim combined

log {/*}

add wave {/*}

force {clk} 0 0, 1 10 -repeat 20

force {resetn} 0 0, 1 20

force {start} 0 20, 1 40 

force {d} 1 2000

run 10000ns



