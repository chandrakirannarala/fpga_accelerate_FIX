vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/fifo_generator_v13_2_7
vlib questa_lib/msim/xil_defaultlib

vmap fifo_generator_v13_2_7 questa_lib/msim/fifo_generator_v13_2_7
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work fifo_generator_v13_2_7  -incr -mfcu \
"../../../ipstatic/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_7  -93 \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_7  -incr -mfcu \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib  -incr -mfcu \
"../../../../fpga_accelerate_FIX.gen/sources_1/ip/fifo_generator_0_1/sim/fifo_generator_0.v" \


vlog -work xil_defaultlib \
"glbl.v"

