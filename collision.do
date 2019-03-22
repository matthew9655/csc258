vlib work

vlog -timescale 1ns/1ns collision.v

vsim collision_test
log {/*}

add wave {/*}
force {clk} 0
run 5ns
# Test x be 0
force {clk} 1
force {regx} 0000101
force {regy} 0000000
run 10ns

force {clk} 0
run 5ns
# Test y be 0
force {clk} 1
force {regx} 01011011
force {regy} 0
run 10ns

force {clk} 0
run 5ns
# Test x be 159
force {clk} 1
force {regx} 10011111
force {regy} 1110111
run 10ns

force {clk} 0
run 5ns
# Test y be 119
force {clk} 1
force {regx} 01011010
force {regy} 1110111
run 10ns

force {clk} 0
run 5ns
# Non-collision_test
force {clk} 1
force {regx} 01011010
force {regy} 1110110
run 10ns