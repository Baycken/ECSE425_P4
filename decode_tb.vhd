library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
package my_pkg is 
	type data_array is array(31 downto 0) of std_logic_vector(31 downto 0);
end;
use work.my_pkg.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decode_tb is
end decode_tb;

architecture behavior of decode_tb is

component decode is
port(--inputs
	if_pc : in std_logic_vector(31 downto 0); --program counter
	if_instr : in std_logic_vector (31 downto 0); --32 bit mips instruction
	wb_flag : in std_logic;
	wb_register : in std_logic_vector(31 downto 0); --register to store wb_data
	wb_data : in std_logic_vector(31 downto 0); --data from writeback stage to put into register
	clk : in std_logic;
	reset : in std_logic;

	--outputs for both R and I instructions
	ex_pc : out std_logic_vector(31 downto 0); --program counter
	ex_opcode: out std_logic_vector(5 downto 0); --intruction opcode
	ex_regs : out std_logic_vector(31 downto 0); --register s
	ex_regt : out std_logic_vector(31 downto 0); --register t

	--R instructions
	ex_regd : out std_logic_vector(31 downto 0); --register d
	ex_shift : out std_logic_vector(4 downto 0); --shift amount
	ex_func : out std_logic_vector(5 downto 0); -- function

	--I instructions
	ex_immed : out std_logic_vector(31 downto 0); --immediate value	

	--J instructions
	target : out std_logic_vector(25 downto 0); --branch target

	--Data Hazard Detection
	hazard : out std_logic; --high if hazard

	--Registers
	out_registers : out data_array
);
end component;

signal if_pc : std_logic_vector(31 downto 0); --program counter
signal if_instr : std_logic_vector (31 downto 0); --32 bit mips instruction
signal	wb_flag : std_logic;
signal	wb_register : std_logic_vector(31 downto 0); --register to store wb_data
signal	wb_data : std_logic_vector(31 downto 0); --data from writeback stage to put into register
signal	clk : std_logic;
constant clk_period : time := 2 ns;
signal	reset : std_logic;

	--outputs for both R and I instructions
signal	ex_pc : std_logic_vector(31 downto 0); --program counter
signal	ex_opcode: std_logic_vector(5 downto 0); --intruction opcode
signal	ex_regs : std_logic_vector(31 downto 0); --register s
signal	ex_regt : std_logic_vector(31 downto 0); --register t

	--R instructions
signal	ex_regd : std_logic_vector(31 downto 0); --register d
signal	ex_shift : std_logic_vector(4 downto 0); --shift amount
signal	ex_func : std_logic_vector(5 downto 0); -- function

	--I instructions
signal	ex_immed : std_logic_vector(31 downto 0); --immediate value	

	--J instructions
signal	target : std_logic_vector(25 downto 0); --branch target

	--Data Hazard Detection
signal	hazard : std_logic; --high if hazard

	--Registers
signal	out_registers : data_array;

begin

dut: decode
port map(
	clk => clk,
	reset =>reset,
	if_pc => if_pc,
	if_instr => if_instr,
	ex_pc => ex_pc,
	ex_opcode => ex_opcode,
	ex_regs => ex_regs,
	ex_regt => ex_regt,
	ex_regd => ex_regd,
	ex_immed => ex_immed,
	target => target,
	hazard => hazard,
	out_registers=>out_registers,

	wb_flag=>wb_flag,
	wb_register =>wb_register,
	wb_data=>wb_data
);

clk_process : process
begin
  clk <= '0';
  wait for clk_period/2;
  clk <= '1';
  wait for clk_period/2;
end process;

test_process: process
begin
	--initialize decode stage
	if_pc <=x"12345678";
	if_instr <= x"00000000";
	reset<='1';
	wait for clk_period;
	reset<='0';
	wait for clk_period/2;

	--begin testing
	wait for clk_period;
	--addi $1, $0, 3 ($1 = Data in $0 + 3)
	if_instr <= "00100000000000010000000000000011";
	wait for clk_period;
	--addi $2, $5, 17 ($2 = Data in $5 + 17)
	if_instr <= "00100000101000100000000000010001";
	wait for clk_period;
	if_instr <= x"00000000";
	wait for clk_period;
	--addi $1, $0, 3 should cause data hazard
	if_instr <= "00100000000000010000000000000111";
	wait for clk_period;
	--fix data hazard by sending updated register value
	wb_flag<='1';
	wb_register<=x"00000001";
	wb_data<=x"00000001";
	if_instr <= x"00000000";
	wait for clk_period;
	
	wb_flag<='0';
	if_instr <= "00100000101000110000000000010001";
	wait for clk_period;
	if_instr <= x"00000000";
	wait;
end process;
end;