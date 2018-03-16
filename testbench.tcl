proc AddWaves {} {
	;#TODO ADD WAVES BASED ON PORTS
    add wave -position end sim:/testbench/clk
    add wave -position end sim:/testbench/reset
    add wave -position end sim:/testbench/if_instr
    add wave -position end sim:/testbench/ex_opcode
    add wave -position end sim:/testbench/ex_regs
    add wave -position end sim:/testbench/ex_regt
    add wave -position end sim:/testbench/id_data
    add wave -position end sim:/testbench/id_register  



}

vlib work

;# Compile components if any
vcom decode.vhd
vcom writeback.vhd
vcom memory.vhd
vcom testbench.vhd

;# Start simulation
vsim testbench

;# Generate a clock with 1ns period
#force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

;# Run for 10000 1ns - clock cycles
run 10000ns
