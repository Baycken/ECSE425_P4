library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity instructionFetch is
generic(
	ram_size : INTEGER := 32768
);
port(
	clock : in std_logic;
	reset : in std_logic;
	
	-- Avalon interface --
	--communication with pc (getting and sending back the incremented one or the completely new pc)
	addr : in std_logic_vector (31 downto 0);
	--reply_back_pc : out std_logic_vector (31 downto 0);
	--test
	s_write : in std_logic;
	s_writedata : in std_logic_vector (31 downto 0);
	s_waitrequest : out std_logic; -- not really using it

	--communication with ID stage
	hazard_detect : in std_logic:='0';

	--communication with EX stage
	ex_is_new_pc : in std_logic:='0';
	ex_pc : in std_logic_vector(31 downto 0);

	--communication with decode stage (**no need to write so comment)
	instruction : out std_logic_vector(31 downto 0);
	instruction_read : out std_logic;
	current_pc_to_dstage : out std_logic_vector(31 downto 0)
);

end instructionFetch;

architecture arch of instructionFetch is

--declarations
signal pc_address : INTEGER RANGE 0 TO 1023;
signal instruction_read_sig : std_logic;

component instructionMemory
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

begin

U1: component instructionMemory
--generic map (ram_size,mem_delay,clock_period)
port map (clock,s_writedata,pc_address,s_write,instruction_read_sig,instruction,s_waitrequest);

	inst_get: process(clock)
	begin
		if(hazard_detect = '0') then
			if(ex_is_new_pc = '1') then 
				pc_address <= to_integer(unsigned(ex_pc));
			else
				pc_address <= pc_address + 1;
			end if;
		else
			pc_address <= pc_address;
		end if;

	end process;

current_pc_to_dstage <= std_logic_vector(to_unsigned(pc_address,32));
instruction_read <= instruction_read_sig;

end arch;
