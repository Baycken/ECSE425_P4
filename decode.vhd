library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decode is
port(
	--inputs
	if_pc : in std_logic_vector(31 downto 0); --program counter
	if_instr : in std_logic_vector (31 downto 0); --32 bit mips instruction
	wb_flag : in std_logic;
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
	ex_shift : out std_logic_vector(4 downto 0); --shift amount
	ex_func : out std_logic_vector(5 downto 0); -- function

	--I instructions
	ex_immed : out std_logic_vector(31 downto 0); --immediate value	

	--J instructions
	target : out std_logic_vector(25 downto 0); --branch target

	--Data Hazard Detection
	hazard : out std_logic --high if hazard
);
end decode;

architecture behaviour of decode is
--
type data_array is array(31 downto 0) of std_logic_vector(31 downto 0);
type bit_array is array(31 downto 0) of std_logic;

signal registers : data_array;--32 registers of 32 bits
signal write_busy : bit_array; --busy

signal opcode : std_logic_vector(5 downto 0);
signal regs_addr, regt_addr, regd_addr : integer; --register array address

signal temp_pc : std_logic_vector (31 downto 0);
signal temp_instr : std_logic_vector (31 downto 0);
signal stall : std_logic;

begin

--TODO: I instruction extended immediates, stalls

process (clk)
procedure bubble IS
begin
	stall <= '1';
	hazard <= '1';
	ex_regs <= registers(0);
	ex_regt <= registers(0);
	ex_regd <= registers(0);

	ex_shift <= "00000";
	ex_func <= "100000";
end procedure;

begin
if rising_edge(clk) then
	--write data to registers from the write back stage
	if (wb_flag = '1') then
		registers(to_integer(unsigned(wb_register))) <= wb_data;
		write_busy(to_integer(unsigned(wb_register))) <= '0';
	end if;

	hazard<= '0';--reset hazard. It will be asserted again if a hazard persists.
	
	--if stall, do not update instruction or pc
	if stall = '0' then
		temp_pc <= if_pc;
		temp_instr <= if_instr;
	end if;
	ex_pc <= temp_pc;

	--split input instruction into corresponding output functions
	opcode <= if_instr(31 downto 26);
	ex_opcode <= if_instr(31 downto 26);

	if ((opcode = "000011") or (opcode = "000010")) then --if J instruction
		target <= if_instr(25 downto 0);

	elsif (opcode = "000000") then --if R instruction
		--get data from registers and send them to EX
		regs_addr <= to_integer(unsigned(temp_instr(25 downto 21)));
		regt_addr <= to_integer(unsigned(temp_instr(20 downto 16)));
		--check if those registers are going to be written to
		if (write_busy(regs_addr) = '1' or write_busy(regt_addr) = '1') then
			bubble;
		else
			ex_regt <= registers(regt_addr);
			ex_regs <= registers(regs_addr);
			ex_shift <= temp_instr(10 downto 6);
			ex_func <= temp_instr(5 downto 0);	
		end if;

		--register to store resulting operation
		regd_addr <= to_integer(unsigned(if_instr(15 downto 11)));
		if (write_busy(regd_addr) = '1' or regd_addr = 0) then --Rd is being used in previous instruction
			bubble;
		else
			ex_regd <= std_logic_vector(to_unsigned(regd_addr, ex_regd'length));
			write_busy(regd_addr)<='1';
		end if;
	
	else --if I instruction
		--get data from registers and send them to EX
		regs_addr <= to_integer(unsigned(temp_instr(25 downto 21)));
		if (write_busy(regs_addr) = '1') then
			bubble;
		else
			ex_regs <= registers(regs_addr);
		end if;

		--register to store resulting operation
		regt_addr <= to_integer(unsigned(temp_instr(20 downto 16)));
		if (write_busy(regt_addr) = '1' or regd_addr = 0) then --Rt is being used in previous instruction
			bubble;
		else
			ex_regt <= std_logic_vector(to_unsigned(regt_addr, ex_regt'length));
			write_busy(regt_addr)<='1';
		end if;

		--andi, ori are ZeroExtImm instructions
		if (opcode = "001100" or opcode = "001101") then
			ex_immed <= x"0000" & temp_instr(15 downto 0);
		else --sign extended
			if temp_instr(15) = '1' then
				ex_immed <= x"1111" & temp_instr(15 downto 0);
			else
				ex_immed <= x"0000" & temp_instr(15 downto 0);
			end if;
		end if;	
	end if;	
end if;

end process;
end behaviour;