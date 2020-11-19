transcript on

vlib work

vlog -sv fifo.sv
vlog -sv fifo_alter.v
vlog -sv scfifo.v
vlog -sv top_tb_fifo.sv


vsim -novopt top_tb_fifo
add log -r /*
add wave -r *
run -all