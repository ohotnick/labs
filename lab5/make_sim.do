transcript on

vlib work

vlog -sv priority_encoder.sv
vlog -sv top_tb5.sv

vsim -novopt top_tb5
add log -r /*
add wave -r *
run 20000