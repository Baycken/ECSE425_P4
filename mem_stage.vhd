LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY mem_stage IS
	PORT (
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
		mem_read_data : in std_logic_vector (31 downto 0);
		mem_waitrequest : in std_logic;
		mem_write : out std_logic;
		mem_read : out std_logic;
		mem_addr : out integer RANGE 0 TO 8191;
		mem_write_data : out std_logic_vector (31 downto 0);

		--memory stall
		stall : out std_logic
	);
end mem_stage;

architecture mem_arch of mem_stage is

signal wait_for_data : std_logic:='0'; --load takes two cycles
signal load_reg : std_logic_vector(31 downto 0); --register address for load

begin

--DATA_MEMORY USES AVALON INTERFACE, THEREFORE LOADS AND STORES TAKE AN EXTRA CLOCK CYCLE.
--THIS CAN BE IGNORED IF IT IS A STORE HAPPENING EVERY FEW INSTRUCTIONS SINCE THE MEM WONT BE BUSY
--WE DONT HAVE TO WAIT FOR A STORE TO COMPLETE TO MOVE ON.
--LOAD WE DO HAVE TO WAIT TO GET DATA FROM MEMORY.
--ONLY STALL ON LOAD FOR 1 CYCLE
mem_stage_process : process(clk,reset)
begin
if (reset = '1') then
	--reset data_memory
elsif (rising_edge(clk)) then
	mem_read<='0';
	mem_write<='0';
	mem_write_data<=x"00000000";
	mem_addr<=0;
	wb_data<=x"00000000";
	wb_dest_reg<=x"00000000";
	stall<='0';

	if wait_for_data = '1' then--get data from previous load
		wait_for_data<='0';
		wb_dest_reg<=load_reg;
		wb_data<=mem_read_data;
		stall<='1';
	elsif (ex_load = '1') then --read from mem and put it into register
		--result is mem address
		mem_read <='1';
		mem_addr <= to_integer(unsigned(ex_result));

		--dest reg is dest reg
		--wait a cycles to retrieve mem
		wait_for_data <='1';
		load_reg<=ex_dest_reg;
		stall<='1';
		
	elsif (ex_store = '1') then

		--dest_reg is address
		mem_write <='1';
		mem_addr <= to_integer(unsigned(ex_dest_reg));

		--result is data into address
		mem_write_data <= ex_result;
	else --pass EX data to WB stage
		wb_data<=ex_result;
		wb_dest_reg<=ex_dest_reg;
	end if;
end if;
end process;
end mem_arch;