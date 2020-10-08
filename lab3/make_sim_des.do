transcript on

vlib work

vlog -sv deserializer.sv
vlog -sv top_tb3_short.sv


vsim -novopt top_tb3
add log -r /*
add wave -r *
run -all