proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
    add wave -position end sim:/instructionFetch_tb/clock
    add wave -position end sim:/instructionFetch_tb/reset
    add wave -position end sim:/instructionFetch_tb/addr
    add wave -position end sim:/instructionFetch_tb/s_write
    add wave -position end sim:/instructionFetch_tb/s_writedata
    add wave -position end sim:/instructionFetch_tb/s_waitrequest
    add wave -position end sim:/instructionFetch_tb/hazard_detect
    add wave -position end sim:/instructionFetch_tb/ex_is_new_pc
    add wave -position end sim:/instructionFetch_tb/ex_pc
    add wave -position end sim:/instructionFetch_tb/instruction
    add wave -position end sim:/instructionFetch_tb/instruction_read
    add wave -position end sim:/instructionFetch_tb/current_pc_to_dstage
}

vlib work

;# Compile components if any
vcom instructionFetch.vhd
vcom instructionMemory.vhd
vcom instructionFetch_tb.vhd

;# Start simulation
vsim instructionFetch_tb

;# Generate a clock with 1ns period
#force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 100 ns
run 100ns
