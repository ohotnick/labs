transcript on

vlib work

vlog -sv bit_population_counter.sv
vlog -sv top_tb6.sv

vsim -novopt top_tb6
add log -r /*
add wave -r *
run 20000