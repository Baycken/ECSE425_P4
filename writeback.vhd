library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity writeback is
port(
	clk : in std_logic;
	mem_register : in std_logic_vector(31 downto 0);
	mem_data : in std_logic_vector(31 downto 0);

	id_register : out std_logic_vector(31 downto 0);
	id_data : out std_logic_vector(31 downto 0)

);
end writeback;

architecture behaviour of writeback is



begin

process (clk)
begin
if rising_edge(clk) then
	id_register <= mem_register;
	id_data <= mem_data;
end if;

end process;
end behaviour;