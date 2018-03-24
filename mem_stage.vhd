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
		mem_addr : out integer;
		mem_write_data : out std_logic_vector (31 downto 0)
	);
end mem_stage;

architecture mem_arch of mem_stage is

signal mem_busy : std_logic:='0';

begin

--DATA_MEMORY USES AVALON INTERFACE, THEREFORE LOADS AND STORES TAKE AN EXTRA FEW CLOCK CYCLES
--THIS CAN BE IGNORED IF IT IS A STORE HAPPENING EVERY FEW INSTRUCTIONS
--SINCE THE MEM WONT BE BUSY. WE DONT HAVE TO WAIT FOR IT TO COMPLETE TO MOVE ON.
--LOAD WE DO HAVE TO WAIT TO GET DATA FROM MEMORY
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
	if (ex_load = '1') then --read from mem and put it into register
		if (mem_busy = '1') then
			--stall
		end if;
		mem_busy <= '1';
		
		--result is mem address
		mem_read <='1';
		mem_addr <= to_integer(unsigned(ex_result));

		--dest reg is dest reg
		--wait x cycles to retrieve mem
		
	elsif (ex_store = '1') then
		if (mem_busy = '1') then
			--stall
		end if;
		mem_busy <='1';

		--dest_reg is address
		mem_write <='1';
		mem_addr <= to_integer(unsigned(ex_dest_reg));

		--result is data into address
		mem_write_data <= ex_result;
	else --pass EX data to WB stage
		wb_data<=ex_result;
		wb_dest_reg<=ex_dest_reg;
		mem_busy <= '0';
	end if;
end if;
end process;
end mem_arch;