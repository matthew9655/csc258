
vlib work

vlog -timescale 1ns/1ns snake.v


vsim combined


# Log all signals and add some signals to waveform window.

log {/*}

# add wave {/*} would add all items in top level simulation module.

add wave {/*}

force {clk} 0 0, 1 10 -repeat 20

force {resetn} 0 0, 1 20

force {r} 1 20

run 400ns



