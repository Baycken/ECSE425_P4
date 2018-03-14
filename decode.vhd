library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decode is
port(
	--inputs
	if_pc : in std_logic_vector(31 downto 0); --program counter
	if_instr : in std_logic_vector (31 downto 0); --32 bit mips instruction
	wb_register : in std_logic_vector(31 downto 0); --register to store wb_data
	wb_data : in std_logic_vector(31 downto 0); --data from writeback stage to put into register
	clk : in std_logic;

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
	target : out std_logic_vector(25 downto 0) --branch target
);
end decode;

architecture behaviour of decode is
--
type data_array is array(31 downto 0) of std_logic_vector(31 downto 0);
signal registers : data_array;--32 registers of 32 bits

signal opcode : std_logic_vector(5 downto 0);
signal regs_addr, regt_addr, regd_addr : integer; --register array address

signal stall : std_logic;

begin

--TODO: I instruction extended immediates, stalls

process (clk)
begin
if rising_edge(clk) then
	--write data to registers from the write back stage
	registers(to_integer(unsigned(wb_register))) <= wb_data;
if stall = '1' then --add r0, r0, r0
	ex_regs <= registers(0);
	ex_regt <= registers(0);
	ex_regd <= registers(0);

	ex_shift <= "00000";
	ex_func <= "100000";
else
	ex_pc <= if_pc;

	--split input instruction into corresponding output functions
	opcode <= if_instr(31 downto 26);
	ex_opcode <= if_instr(31 downto 26);

	if ((opcode = "000011") or (opcode = "000010")) then --if J instruction
		target <= if_instr(25 downto 0);

	elsif (opcode = "000000") then --if R instruction
		--get data from registers and send them to EX
		regs_addr <= to_integer(unsigned(if_instr(25 downto 21)));
		ex_regs <= registers(regs_addr);
		regt_addr <= to_integer(unsigned(if_instr(20 downto 16)));
		ex_regt <= registers(regt_addr);

		ex_shift <= if_instr(10 downto 6);
		ex_func <= if_instr(5 downto 0);

		--register to store resulting operation
		regd_addr <= to_integer(unsigned(if_instr(15 downto 11)));
		ex_regd <= std_logic_vector(to_unsigned(regd_addr, ex_regd'length));
	
	else --if I instruction
		--get data from registers and send them to EX
		regs_addr <= to_integer(unsigned(if_instr(25 downto 21)));
		ex_regs <= registers(regs_addr);

		--register to store resulting operation
		regt_addr <= to_integer(unsigned(if_instr(20 downto 16)));
		ex_regt <= std_logic_vector(to_unsigned(regt_addr, ex_regt'length));

		--TODO figure this out
		--andi, ori are ZeroExtImm instructions
		if (opcode = "001100" or opcode = "001101") then
			ex_immed <= if_instr(15 downto 0);
		else
			ex_immed <= if_instr(15 downto 0);
		end if;	
	end if;	
end if;
end if;

end process;
end behaviour;