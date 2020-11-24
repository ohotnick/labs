transcript on

vlib work

vlog -sv lifo.sv
vlog -sv top_tb_lifo.sv


vsim -novopt top_tb_lifo
add log -r /*
add wave -r *
run -all