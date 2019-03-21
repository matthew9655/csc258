
vlib work

vlog -timescale 1ns/1ns 2snake.v



vsim datapath



# Log all signals and add some signals to waveform window.

log {/*}

# add wave {/*} would add all items in top level simulation module.

add wave {/*}

# Test Reset
force {clk} 1 
force {resetn} 0 
force {enable} 1
force {left} 1
force {right} 0
force {up} 0 
force {down} 0 
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
force {enable} 0
run 5ns

# Test Go left
force {clk} 1 
force {resetn} 1 
force {enable} 0
force {left} 1
force {right} 0
force {up} 0 
force {down} 0 
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
force {enable} 0
run 5ns

# Test Go left twice 
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 1
force {right} 0
force {up} 0 
force {down} 0 
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
force {enable} 0
run 5ns

# Test left go right 
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 0
force {right} 1
force {up} 0
force {down} 0 
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
run 5ns

# Test left go up
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 0
force {right} 0
force {up} 1
force {down} 0 
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
run 5ns

# Test left go up twice
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 0
force {right} 0
force {up} 1
force {down} 0 
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
run 5ns

# Test up to down 
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 0
force {right} 0
force {up} 0
force {down} 1 
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
run 5ns

# Test up to right 
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 0
force {right} 1
force {up} 0
force {down} 0 
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
run 5ns

# Test right twice 
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 0
force {right} 1
force {up} 0
force {down} 0 
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
run 5ns

# Test right to left 
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 1
force {right} 0
force {up} 0
force {down} 0 
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
run 5ns

# Test right to down
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 0
force {right} 0
force {up} 0
force {down} 1
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
run 5ns

# Test down twice
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 0
force {right} 0
force {up} 0
force {down} 1
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns


force {clk} 0
run 5ns

# Test down to up
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 0
force {right} 0
force {up} 1
force {down} 0
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
run 5ns

# Test down to left
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 1
force {right} 0
force {up} 0
force {down} 0
force {move} 1
force {foodx} 0010100
force {foody} 1010001
run 10ns

force {clk} 0
run 5ns

# Test  left twice to eat food
force {clk} 1 0 
force {resetn} 1 
force {enable} 0
force {left} 1
force {right} 0
force {up} 0
force {down} 0
force {move} 1
force {foodx} 1001110
force {foody} 0111100
run 10ns

force {clk} 0
run 5ns

# Test go left after eat the food 
force {clk} 1 0 
force {resetn} 1 
force {enable} 1
force {left} 1
force {right} 0
force {up} 0
force {down} 0
force {move} 1
force {foodx} 1001110
force {foody} 0111100
run 10ns

# Test colour pickel
force {clk} 1 0, 0 1 -repeat 10
force {enable} 1
force {resetn} 1 
force {enable} 1
force {left} 0
force {right} 0
force {up} 0
force {down} 0
force {move} 0
force {foodx} 1001110
force {foody} 0111100
run 200ns
#

# Test go left after eat the food 
force {clk} 1 0 
force {resetn} 0
force {enable} 1
force {left} 0
force {right} 0
force {up} 0
force {down} 0
force {move} 0
force {foodx} 1001110
force {foody} 0111100
run 10ns
