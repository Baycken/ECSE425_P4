# ECSE425_P4
ECSE425 Project Phase 4

FILES:
mips_top.vhd:
  Top level controller that interconnects the 5 stages

instructionFetch.vhd:
  Instruction fetch stage. Read new instruction from instructionMemory.vhd and send it to decode.vhd. 
  instructionMemory.vhd is word aligned meaning PC+1 is next instruction instead of PC+4 for byte aligned.
  
instructionFetch_tb.vhd and .tcl
  Testbench files for instructionFetch.vhd
  TEST|STATUS:
    Read from memory | PASS
    
execute.vhd: Performs the operation specified by the ID Stage. It Outputs the result of the operation and where to store the result. It also lets the system know if the PC needs updating or if a memory operation needs to be preformed.

execute_tb.vhd and execute_tb.tcl:
tests R, I, and J type instuctions. Prints errors if they occur and shows outputs in a waveform.
    
decode.vhd
  Instruction decode stage. Parses instruction from IF stage.
  
decode_tb.vhd and .tcl
  Testbench files for decode.vhd
  TEST|STATUS
    Parse Jump and Branch instructions  | PASS
    Parse I instructions                | PASS
    Parse R instructions                | PASS
    Detect Data Hazard                  | PASS
    add $0,$0,0 when Hazard             | PASS
    Signal IF stage when Hazard         | PASS
    Recieve new register data from WB   | PASS
