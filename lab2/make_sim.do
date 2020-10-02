transcript on

vlib work

vlog -sv serializer.sv
vlog -sv top_tb2.sv

vsim -novopt top_tb2
add log -r /*
add wave -r *
run -all