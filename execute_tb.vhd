LIBRARY ieee;
USE ieee.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

ENTITY execute_tb IS
END execute_tb;

ARCHITECTURE behaviour OF execute_tb is

COMPONENT execute IS
port (clk, reset : in std_logic;
		pc_in, dest_reg_in, regs, regt, regd : in std_logic_vector(31 downto 0);
		opcode, func: in std_logic_vector(5 downto 0);
		shift : in std_logic_vector(3 downto 0); 
		immed : in std_logic_vector(31 downto 0);
		target : in std_logic_vector(25 downto 0);
		result, pc_out, dest_reg_out : out std_logic_vector(31 downto 0);
		is_new_pc, is_load, is_store : out std_logic
	);
end component;

SIGNAL clk, reset: STD_LOGIC := '0';
signal s_pc_in, s_dest_reg_in, s_regs, s_regt, s_regd : std_logic_vector(31 downto 0) :=x"00000000";
signal s_opcode, s_func: std_logic_vector(5 downto 0) :="000000";
signal s_shift :std_logic_vector(3 downto 0) :="0000";
signal s_immed :std_logic_vector(31 downto 0) :=x"00000000";
signal s_target :std_logic_vector(25 downto 0) :="00000000000000000000000000";
signal s_result, s_pc_out, s_dest_reg_out :std_logic_vector(31 downto 0) :=x"00000000";
signal s_is_new_pc, s_is_load, s_is_store :std_logic :='0';

CONSTANT clk_period : time := 2 ns;
BEGIN
dut: execute
port map(clk,reset, s_pc_in, s_dest_reg_in, s_regs, s_regt, s_regd, s_opcode, s_func, s_shift,s_immed,s_target,s_result, s_pc_out, s_dest_reg_out,s_is_new_pc, s_is_load, s_is_store);

clk_process : PROCESS
BEGIN
	clk <= '0';
	WAIT FOR clk_period/2;
	clk <= '1';
	WAIT FOR clk_period/2;
END PROCESS;

stim_process: PROCESS
BEGIN 
wait for clk_period/2; --wait for rising edge

s_opcode <="000000";	--Lets test some R type inst
s_func <="100000";	--Add d=s+t
s_regs<="00000000000000000000000000000101";	--s=5
s_regt<="00000000000000000000000000000111";	--t=7
s_regd<="00000000000000000000000000001010"; --store result in register 10
wait for (2*clk_period);

s_func <="100100";	--AND Function
assert (s_result="00000000000000000000000000001100") report "Result of add is not 12";
assert (s_dest_reg_out="00000000000000000000000000001010") report "Dest Reg from add is not 10";
wait for (2*clk_period);

assert (s_result="00000000000000000000000000000101") report "Result of bitwise AND is not 101";
s_func <= "011000"; --multiply function
wait for (2*clk_period);

s_func <="010010";	--move from low
wait for (2*clk_period);

assert (s_result="00000000000000000000000000100011") report "Result of 5x7 is not 35";
s_func<="000000";	--Shift Left Logical
s_shift<="0010";	--Shift left by 2
wait for (2*clk_period);

assert (s_result="00000000000000000000000000011100") report "SLL failed";
s_opcode<="001000"; --Try some I type Inst, rt=rs+immed
s_func<="001000";	--ADDI
s_immed<=x"0000000F"; --immed=15
wait for (2*clk_period);

assert (s_result="00000000000000000000000000010100") report "ADDI Failed"; --Assert 5+15=20
s_func<="001010"; --Set Less Than Immed
wait for (2*clk_period);

assert (s_result="00000000000000000000000000000001") report "SLTi Failed"; --Assert 5<15
s_opcode<="000010";	--Test a J type Inst
s_func<="000010";	--Test Jump
s_target<="00000000000000000000001101"; --target=13
wait for (2*clk_period);

assert (s_pc_out="00000000000000000000000000001101") report "Jump Failed"; --Assert new pc is jump addr
assert(s_is_new_pc='1') report "Jump Failed";


wait;
END PROCESS stim_process;
END;
