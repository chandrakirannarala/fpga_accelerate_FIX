vlib work
vlib activehdl

vlib activehdl/fifo_generator_v13_2_7
vlib activehdl/xil_defaultlib

vmap fifo_generator_v13_2_7 activehdl/fifo_generator_v13_2_7
vmap xil_defaultlib activehdl/xil_defaultlib

vlog -work fifo_generator_v13_2_7  -v2k5 \
"../../../ipstatic/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_7 -93 \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_7  -v2k5 \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib  -v2k5 \
"../../../../fpga_accelerate_FIX.gen/sources_1/ip/fifo_generator_0_1/sim/fifo_generator_0.v" \


vlog -work xil_defaultlib \
"glbl.v"

