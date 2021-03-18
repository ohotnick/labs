transcript on

vlib work

vlog -sv packet_classer.sv
vlog -sv packet_resolver.sv
vlog -sv fifo.sv
vlog -sv top_tb_lab4.sv


vsim -novopt top_tb_lab4
add log -r /*
add wave -r *
run -all