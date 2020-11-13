transcript on

vlib work

vlog -sv fifo.v
vlog -sv scfifo.v
vlog -sv top_tb3.sv



vsim -novopt top_tb3
add log -r /*
add wave -r *
run -all