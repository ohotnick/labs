transcript on

vlib work

vlog -sv debouncer.sv
vlog -sv top_tb7.sv

vsim -novopt top_tb7
add log -r /*
add wave -r *
run -all