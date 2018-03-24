proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
    add wave -position end sim:/execute_tb/clk
    add wave -position end sim:/execute_tb/s_pc_in
    add wave -position end sim:/execute_tb/s_dest_reg_in
    add wave -position end sim:/execute_tb/s_regs
    add wave -position end sim:/execute_tb/s_regt
    add wave -position end sim:/execute_tb/s_regd
    add wave -position end sim:/execute_tb/s_opcode
    add wave -position end sim:/execute_tb/s_func
    add wave -position end sim:/execute_tb/s_shift
    add wave -position end sim:/execute_tb/s_immed
    add wave -position end sim:/execute_tb/s_target
    add wave -position end sim:/execute_tb/s_result
	add wave -position end sim:/execute_tb/s_pc_out
	add wave -position end sim:/execute_tb/s_dest_reg_out
	add wave -position end sim:/execute_tb/s_is_new_pc
	add wave -position end sim:/execute_tb/s_is_load
	add wave -position end sim:/execute_tb/s_is_store
}

vlib work

;# Compile components if any
vcom execute.vhd
vcom execute_tb.vhd

;# Start simulation
vsim execute_tb

;# Generate a clock with 1ns period
#force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 50 ns
run 40ns
