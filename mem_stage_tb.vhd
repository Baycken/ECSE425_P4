library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_stage_tb is
end mem_stage_tb;

architecture behavior of mem_stage_tb is

component mem_stage is
port(
		reset : in std_logic;
		clk : in std_logic;

		--execution stage communication
		ex_result: in std_logic_vector(31 downto 0);
		ex_dest_reg : in std_logic_vector(31 downto 0);	
		ex_load : in std_logic;
		ex_store : in std_logic;

		--writeback stage communication
		wb_data : out std_logic_vector(31 downto 0);
		wb_dest_reg : out std_logic_vector(31 downto 0);

		--data memory communication
		mem_data_in : in std_logic_vector (31 downto 0);
		mem_waitrequest : in std_logic;
		mem_write : out std_logic;
		mem_read : out std_logic;
		mem_addr : out integer;
		mem_data_out : out std_logic_vector (31 downto 0)
);
end component;

component data_memory IS
	GENERIC(
		ram_size : INTEGER := 32768;
		clock_period : time := 1 ns
	);
	PORT (
		clock: IN STD_LOGIC;
		writedata: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		address: IN INTEGER RANGE 0 TO 8192-1;
		memwrite: IN STD_LOGIC;
		memread: IN STD_LOGIC;
		readdata: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		waitrequest: OUT STD_LOGIC
	);
end component;

signal reset : std_logic;
signal clk : std_logic;

--execution stage communication
signal ex_result: std_logic_vector(31 downto 0);
signal ex_dest_reg : std_logic_vector(31 downto 0);	
signal ex_load : std_logic;
signal ex_store : std_logic;

--writeback stage communication
signal wb_data : std_logic_vector(31 downto 0);
signal wb_dest_reg : std_logic_vector(31 downto 0);

--data memory communication
signal mem_data_in : std_logic_vector (31 downto 0);
signal mem_waitrequest : std_logic;
signal mem_write : std_logic;
signal mem_read : std_logic;
signal mem_addr : integer;
signal mem_data_out : std_logic_vector (31 downto 0);

constant clk_period : time := 2 ns;

begin

dut: mem_stage
port map(
	clk => clk,
	reset =>reset,
	ex_result=>ex_result,
	ex_dest_reg=>ex_dest_reg,
	ex_load=>ex_load,
	ex_store=>ex_store,
	wb_data=>wb_data,
	wb_dest_reg=>wb_dest_reg,
	mem_data_in=>mem_data_in,
	mem_waitrequest=>mem_waitrequest,
	mem_write=>mem_write,
	mem_read=>mem_read,
	mem_addr=>mem_addr,
	mem_data_out=>mem_data_out
);

mem: data_memory
port map(
	clock=>clk,
	writedata=>mem_data_out,
	address=>mem_addr,
	memwrite=>mem_write,
	memread=>mem_read,
	readdata=>mem_data_in,
	waitrequest=>mem_waitrequest
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
	--test stuff
	wait;
end process;
end;