proc AddWaves {} {
	;#TODO ADD WAVES BASED ON PORTS
    add wave -position end sim:/testbench/clk
    add wave -position end sim:/testbench/reset
    add wave -position end sim:/testbench/out_registers
}

vlib work

;# Compile components if any
vcom decode.vhd
vcom execute.vhd
vcom writeback.vhd
vcom memory.vhd
vcom fetch.vhd
vcom instr_mem.vhd
vcom mem_stage.vhd
vcom mips_top.vhd
vcom data_memory.vhd
vcom testbench.vhd

;# Start simulation
vsim testbench

;# Generate a clock with 1ns period
#force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 10000 1ns - clock cycles
run 10000ns
