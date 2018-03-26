library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fetch_tb is
end fetch_tb;

architecture behavior of fetch_tb is

component fetch is

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
end component;

	
-- test signals 
signal reset : std_logic := '0';
signal clock : std_logic := '0';
constant clk_period : time := 2 ns;

signal addr : std_logic_vector (31 downto 0);
	--reply_back_pc : out std_logic_vector (31 downto 0);
	--test
signal s_write : std_logic;
signal s_writedata : std_logic_vector (31 downto 0);
signal s_waitrequest :  std_logic; -- not really using it
signal instruction :  std_logic_vector(31 downto 0);

signal hazard_detect : std_logic;
signal ex_is_new_pc : std_logic;
signal ex_pc : std_logic_vector (31 downto 0);
signal instruction_read : std_logic;
signal current_pc_to_dstage : std_logic_vector (31 downto 0);



begin

-- Connect the components which we instantiated above to their
-- respective signals.
dut: fetch 
port map(
    clock => clock,
    reset => reset,
    addr => addr,
    s_write => s_write,
    s_writedata => s_writedata,
    s_waitrequest => s_waitrequest,
    instruction => instruction,

    hazard_detect => hazard_detect,
    ex_is_new_pc => ex_is_new_pc,
    ex_pc => ex_pc,
    instruction_read => instruction_read,
    current_pc_to_dstage =>current_pc_to_dstage

);
	

clk_process : process
begin
  clock <= '0';
  wait for clk_period/2;
  clock <= '1';
  wait for clk_period/2;
end process;

test_process : process
begin


-- put your tests here
	hazard_detect <= '0';
	ex_is_new_pc <= '1';
	ex_pc <= x"0000000A";
	addr<= x"0000000C";
	WAIT FOR 1 * clk_period;
	ASSERT (current_pc_to_dstage = x"0000000A") REPORT "pc sent to ID should be pc from ex" SEVERITY ERROR; 	

	ex_is_new_pc <= '0';
	wait for 1 * clk_period;
	
	ASSERT (current_pc_to_dstage = x"0000000C") REPORT "pc sent to ID should be incremented by 1" SEVERITY ERROR; 	

	hazard_detect <= '1';
	ASSERT (current_pc_to_dstage = x"0000000B") REPORT "pc sent to ID should be held the same if hazard" SEVERITY ERROR;
	
	WAIT;
end process;
	
end;
