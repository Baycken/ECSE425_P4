proc AddWaves {} {
	;#Add waves we're interested in to the Wave window
    add wave -position end sim:/decode_tb/clk
    add wave -position end sim:/decode_tb/dut/reset
    add wave -position end sim:/decode_tb/dut/no_instr
    add wave -position end sim:/decode_tb/reset
    add wave -position end sim:/decode_tb/if_pc
    add wave -position end sim:/decode_tb/if_instr
    add wave -position end sim:/decode_tb/ex_pc
    add wave -position end sim:/decode_tb/ex_opcode
    add wave -position end sim:/decode_tb/ex_regs
    add wave -position end sim:/decode_tb/ex_regd
    add wave -position end sim:/decode_tb/ex_regt
    add wave -position end sim:/decode_tb/ex_immed
    add wave -position end sim:/decode_tb/dut/registers
    add wave -position end sim:/decode_tb/dut/write_busy
    add wave -position end sim:/decode_tb/out_registers
    add wave -position end sim:/decode_tb/dut/test
    add wave -position end sim:/decode_tb/dut/stall
    add wave -position end sim:/decode_tb/hazard


}

vlib work

;# Compile components if any
vcom decode.vhd
vcom decode_tb.vhd

;# Start simulation
vsim decode_tb

;# Generate a clock with 1ns period
#force -deposit clk 0 0 ns, 1 0.5 ns -repeat 1 ns

;# Add the waves
AddWaves

run 100ns
