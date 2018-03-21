

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

package my_pkg is 
	type data_array is array(31 downto 0) of std_logic_vector(31 downto 0);
end;
use work.my_pkg.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity testbench is
end testbench;

architecture behavior of testbench is

component cache is
generic(
    ram_size : INTEGER := 32768
);
port(
    	clock : in std_logic;
    	reset : in std_logic;

    --inputs
	if_pc : in std_logic_vector(31 downto 0); --program counter
	if_instr : in std_logic_vector (31 downto 0); --32 bit mips instruction
	wb_register : in std_logic_vector(31 downto 0); --register to store wb_data
	wb_data : in std_logic_vector(31 downto 0); --data from writeback stage to put into register
	
	mem_register : in std_logic_vector(31 downto 0);
	mem_data : in std_logic_vector(31 downto 0);

	memwrite: in std_logic_vector(31 downto 0);
	writedata: in std_logic_vector(31 downto 0);


	--outputs for both R and I instructions
	ex_pc : out std_logic_vector(31 downto 0); --program counter
	ex_opcode: out std_logic_vector(5 downto 0); --intruction opcode
	ex_regs : out std_logic_vector(31 downto 0); --register s
	ex_regt : out std_logic_vector(31 downto 0); --register t

	--R instructions
	ex_regd : out std_logic_vector(31 downto 0); --register d
	ex_shift : out std_logic_vector(3 downto 0); --shift amount
	ex_func : out std_logic_vector(5 downto 0); -- function

	--I instructions
	ex_immed : out std_logic_vector(15 downto 0); --immediate value	

	--J instructions
	target : out std_logic_vector(25 downto 0); --branch target
	-- outputs of operations
	id_register : out std_logic_vector(31 downto 0);
	id_data : out std_logic_vector(31 downto 0);

	out_registers: out data_array;
);
end component;

component memory is 
GENERIC(
    ram_size : INTEGER := 32768;
    mem_delay : time := 10 ns;
    clock_period : time := 2 ns
);
PORT (
    clock: IN STD_LOGIC;
    writedata: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
    address: IN INTEGER RANGE 0 TO 8191;
    memwrite: IN STD_LOGIC;
    memread: IN STD_LOGIC;
    readdata: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
    waitrequest: OUT STD_LOGIC
);
end component;
	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 2 ns;

--inputs
signal if_pc : std_logic_vector(31 downto 0); --program counter
signal if_instr : std_logic_vector (31 downto 0); --32 bit mips instruction
signal wb_register : std_logic_vector(31 downto 0); --register to store wb_data
signal wb_data : std_logic_vector(31 downto 0); --data from writeback stage to put into register

	
signal mem_register : std_logic_vector(31 downto 0);
signal mem_data : std_logic_vector(31 downto 0);

signal memwrite : std_logic_vector(31 downto 0);
signal writedata : std_logic_vector(31 downto 0);

--outputs for both R and I instructions
signal ex_pc : std_logic_vector(31 downto 0); --program counter
signal ex_opcode: std_logic_vector(5 downto 0); --intruction opcode
signal ex_regs : std_logic_vector(31 downto 0); --register s
signal ex_regt : std_logic_vector(31 downto 0); --register t

--R instructions
signal ex_regd : std_logic_vector(31 downto 0); --register d
signal ex_shift : std_logic_vector(3 downto 0); --shift amount
signal ex_func : std_logic_vector(5 downto 0); -- function

--I instructions
signal ex_immed : std_logic_vector(15 downto 0); --immediate value	

--J instructions
signal target : std_logic_vector(25 downto 0); --branch target

signal id_register : std_logic_vector(31 downto 0);
signal id_data : std_logic_vector(31 downto 0);

signal out_registers :  data_array;

begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: cache 
port map(
    	clock => clk,
    	reset => reset,

    --inputs
	if_pc => if_pc,
	if_instr => if_instr,
	wb_register => wb_register,
	wb_data => wb_data,
	
	mem_register => mem_register,
	mem_data => mem_data,
	
	memwrite => memwrite,
	write_data => write_data,
	

	ex_pc => ex_pc,
	ex_opcode => ex_opcode,
	ex_regs => ex_regs, --register s
	ex_regt => ex_regt,--register t

	--R instructions
	ex_regd =>  ex_regd, --register d
	ex_shift => ex_shift, --shift amount
	ex_func => ex_func, -- function

	--I instructions
	ex_immed => ex_immed, --immediate value	

	--J instructions
	target => target,--branch target

	id_register => id_register,
	id_data => id_data,

	out_registers => out_registers
   
);

				

clk_process : process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
end process;

test_process : process

file     program:            text; 
variable program_line:       line;

file     mem_file:	     text;
variable mem_line:	     line;

file 	 register_file:      text;
variable register_line:      line;

begin
	file_open(program,"program.txt", read_mode);
	
        --init	
        reset <= '1';
        wait for 3*clk_period;
        reset <= '0';
	
	while (not endfile(program)) loop
		if (clk'event and clk = '1') then
                	readline(program, program_line);
			read(program_line, write_data);
			mem_write <= '1';
			wait for clk_period;
			mem_write <= '0';
		end if;
	end loop;
	file_close(program);
	
	wait for 9000*clk_period;

	
	file_open(register_file,"register_file.txt",write_mode);
	
	for i in 0 to 31 loop
		write(register_line, out_registers(i));
		writeline(register_file, register_line);
	end loop;
	file_close(register_file);


	file_open(mem_file,"memory.txt",write_mode);
	for i in 0 to 8191 loop
		address <= i;
		write(mem_line, readdata);
		writeline(mem_file, mem_line); 
	end loop;
	file_close(program);
		

	--wait for clk_period;
--	if_instr <= x"00010005"; --I instruction (addi $1 $0 5)
--	wait for 3*clk_period;
--	assert(ex_regs = x"00000000") report "Register s should contain 0's" severity error;
--	assert(ex_regt = x"00000005") report "Register t should contain value of 5" severity error;
--	if_instr <= x"00020001"; --I instruction (addi $2 $0 1)
--	wait for 3*clk_period;
--	assert(ex_regs = x"00000000") report "Register s should contain 0's" severity error;
--	assert(ex_regt = x"00000001") report "Register t should contain value of 1" severity error;
--	if_instr <= x"00220018";  -- R instruction (mult $1 $2)
--	wait for 10*clk_period;
--	assert(ex_regs = x"00000005") report "Register s (1) should contain value of 5" severity error;
--	assert(ex_regt = x"00000001") report "Register t (2) should contain value of 1" severity error;
--	assert(id_register = x"00000001") report "Result should be stored in register 1" severity error;
--	assert(id_data = x"00000005") report "Result should be 5*1 or 5" severity error;

	
	wait;

end process;
end;
