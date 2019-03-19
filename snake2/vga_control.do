vlib work

vlog -timescale 1ns/1ns vga.v


vsim combined

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}

force {clk} 0 0, 1 10 -repeat 20ns
force {resetn} 0 0, 1 20

force {color} 111 20
force {data_in} 0000000 20

force {go} 1 20, 0 40
force {go} 1 60, 0 80
force {go} 1 100, 0 120
force {draw} 1 140, 0 160
 
run 500ns


