# ECSE425_P4
ECSE425 Project Phase 4

Aidan Piwowar 260625505
Alexander Orzechowski 260610696
Moetassem Abdelazim 260685819
Bei Chen Liu 270527856
Isaac Berman 260616501

********************IMPORTANT NOTES***************************
What works:
  Each stage and it's testbench prove independent component functionality.
  Data Hazard is properly implemented.
  Forwarding is partially functional.
**************************************************************

FILES:
mips_top.vhd:
  Top level controller that interconnects the 5 stages.

testbench.vhd and .tcl
  Creates instances of Instruction Memory, Data Memory, and Mips23.
  Reads program from "program.txt", that must be in same source directory as rest of files, and loads instructions into instruction
  memory. Takes registers from Mips23, and data memory from data_memory and writes to files "register_file.txt" and "memory.txt" respetively.

data_mem.vhd and instr_mem.vhd
  Refactored memory model provided from P3. Reduced delay to 0 ns. Changed from byte aligned to word aligned.

fetch.vhd:
  Instruction fetch stage. Read new instruction from instructionMemory.vhd and send it to decode.vhd. 
  instructionMemory.vhd is word aligned meaning PC+1 is next instruction instead of PC+4 for byte aligned.
  
fetch_tb.vhd and .tcl
  Testbench files for instructionFetch.vhd
  TEST|STATUS:
    Read from memory | PASS

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
    Preempt data memory hazard		      | PASS
    
execute.vhd: 
  Performs the operation specified by the ID Stage. It Outputs the result of the operation and where to store the result.
  It also lets the system know if the PC needs updating or if a memory operation needs to be preformed.

execute_tb.vhd and execute_tb.tcl:
  TEST|STATUS
    R type instructions			| PASS
    I type instructions 		| PASS
    J type instructions 		| PASS

mem_stage.vhd
  If the instruction is a load or store, this stage takes care of the data memory access. 
  A store will simply set the address and the data to be put into data memory and can finish this task in 1 clock cycle.
  A load will ask for a word from memory and the data memory will put the word on the bus the next cycle.
  Because of this clock cycle delay, the decode stage sends a dummy instruction to simulate a delay.

mem_stage_tb.vhd and .tcl
  Testbench for the memory stage
  TEST|STAUS
    Pass data and register to WB stage	| PASS
    Store word into data memory		      | PASS
    Load previously stored word	      	| PASS
  
writeback.vhd
  Update registers with new data based on instruction. Registers are stored in decode stage so pass data and address to ID.


  
