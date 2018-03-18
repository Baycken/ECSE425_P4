LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY mem_stage IS
	PORT (
		clk : in std_logic;
		result: in std_logic_vector(31 downto 0);
		dest_reg_in : in std_logic_vector(31 downto 0);	
		is_load : in std_logic;
		is_store : in std_logic;

		data : out std_logic_vector(31 downto 0);
		dest_reg_out : out std_logic_vector(31 downto 0)
	);
end mem_stage;

architecture mem_arch of mem_stage is

begin
	mem_stage_process : process(clk)
	begin
		data<=result;
		dest_reg_out<=dest_reg_in;
	end process;
end mem_arch;
