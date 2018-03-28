
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity testbench is
end testbench;

architecture behavior of testbench is

component instr_mem is
GENERIC(
		ram_size : INTEGER := 32768;
		mem_delay : time := 10 ns;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO 1023;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
end component;

component data_memory is 
GENERIC(
		ram_size : INTEGER := 32768;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO 8191;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
end component;

component mips32 is 
PORT (
   clk_i : IN STD_LOGIC;
   rst_i : IN STD_LOGIC;

   -- Interface to instruction cache
   pc_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   inst_read_o : OUT STD_LOGIC;
   inst_data_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   inst_wait_i : IN STD_LOGIC;

   -- Interface to user memory
	mem_read_data : in std_logic_vector (31 downto 0);
	mem_waitrequest : in std_logic;
	mem_write : out std_logic;
	mem_read : out std_logic;
	mem_addr : out integer RANGE 0 TO 8191;
	mem_write_data : out std_logic_vector (31 downto 0);
   out_registers : out std_logic_vector(1023 downto 0)
);
end component;
	
-- test signals 
signal reset : std_logic := '0';
signal clk : std_logic := '0';
constant clk_period : time := 2 ns;

signal pc_o : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal inst_read_o : STD_LOGIC;
signal inst_data_i : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal inst_wait_i : STD_LOGIC;

signal mem_read_data: STD_LOGIC_VECTOR(31 downto 0);
signal mem_waitrequest : STD_LOGIC;
signal mem_write : STD_LOGIC;
signal mem_read : STD_LOGIC;
signal mem_addr : INTEGER RANGE 0 to 8191;
signal mem_write_data : STD_LOGIC_VECTOR (31 DOWNTO 0);
signal out_registers : STD_LOGIC_VECTOR(1023 downto 0);

signal inst_writedata : STD_LOGIC_VECTOR (31 DOWNTO 0);
signal inst_address : INTEGER RANGE 0 TO 1023;
signal inst_memwrite : STD_LOGIC;
signal inst_memread : STD_LOGIC;
signal inst_readdata :  STD_LOGIC_VECTOR (31 DOWNTO 0);
signal inst_waitrequest: STD_LOGIC;

signal data_writedata : STD_LOGIC_VECTOR (31 DOWNTO 0);
signal data_address : INTEGER RANGE 0 TO 8191;
signal data_memwrite : STD_LOGIC;
signal data_memread : STD_LOGIC;
signal data_readdata :  STD_LOGIC_VECTOR (31 DOWNTO 0);
signal data_waitrequest: STD_LOGIC;

signal count : INTEGER RANGE 0 TO 1023;

begin

-- Connect the components which we instantiated above to their
-- respective signals.
I_MEM: instr_mem 
port map(

clock => clk,
writedata => inst_writedata,
address => inst_address,
memwrite => inst_memwrite,
memread => inst_memread,
readdata => inst_readdata,
waitrequest => inst_waitrequest
    	
);

D_MEM: data_memory 
port map(

clock => clk,
writedata => data_writedata,
address => data_address,
memwrite => data_memwrite,
memread => data_memread,
readdata => data_readdata,
waitrequest => data_waitrequest
    	
   
);

M_32: mips32
port map(

	clk_i => clk,
	rst_i => reset,
 
	pc_o => pc_o,
	inst_read_o => inst_read_o,
	inst_wait_i => inst_wait_i,
	inst_data_i => inst_data_i,
	mem_read_data => mem_read_data,
	mem_waitrequest => mem_waitrequest,
	mem_write => mem_write,
	mem_read => mem_read,
	mem_addr => mem_addr,
	mem_write_data => mem_write_data,
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

variable current_line : std_logic_vector(31 downto 0);

begin
	
        --init	
        reset <= '1';
        wait for 3*clk_period;
        reset <= '0';
	
	file_open(program,"program.txt", read_mode);
	for i in 0 to 1023 loop
		if (not endfile(program)) then
			--if (clk'event and clk = '1') then
              		readline(program, program_line);
			read(program_line, current_line);
			inst_writedata <= current_line;
			inst_address <= count;
			inst_memwrite <= '1';
			wait for clk_period;
			inst_memwrite <= '0';
			count <= count + 1;
		--end if;
		end if;
	end loop;
	file_close(program);
	
	wait for 2000*clk_period;

	
	file_open(register_file,"register_file.txt",write_mode);
	
	for i in 0 to 31 loop
		write(register_line, out_registers(32*(i+1)-1 downto 32*i));
		writeline(register_file, register_line);
	end loop;
	file_close(register_file);

	file_open(mem_file,"memory.txt",write_mode);
	for i in 0 to 8191 loop
		data_address <= i;
		data_memread <= '1';
		wait for 1*clk_period;
		data_memread <= '0';
		write(mem_line, data_readdata);
		writeline(mem_file, mem_line); 
	end loop;
	file_close(program);	

	--wait for clk_period;
	--if_instr <= x"00010005"; --I instruction (addi $1 $0 5)
	--wait for 3*clk_period;
	--assert(ex_regs = x"00000000") report "Register s should contain 0's" severity error;
	--assert(ex_regt = x"00000005") report "Register t should contain value of 5" severity error;
	--if_instr <= x"00020001"; --I instruction (addi $2 $0 1)
	--wait for 3*clk_period;
	--assert(ex_regs = x"00000000") report "Register s should contain 0's" severity error;
	--assert(ex_regt = x"00000001") report "Register t should contain value of 1" severity error;
	--if_instr <= x"00220018";  -- R instruction (mult $1 $2)
	--wait for 10*clk_period;
	--assert(ex_regs = x"00000005") report "Register s (1) should contain value of 5" severity error;
	--assert(ex_regt = x"00000001") report "Register t (2) should contain value of 1" severity error;
	--assert(id_register = x"00000001") report "Result should be stored in register 1" severity error;
	--assert(id_data = x"00000005") report "Result should be 5*1 or 5" severity error;

	
	wait;

end process;
end
