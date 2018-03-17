library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity execute is
port(
	--Inputs
	clk : in std_logic;
	pc_in : in std_logic_vector(31 downto 0); --For J and R type inst
	dest_reg_in : in std_logic_vector(31 downto 0);	

	--R and I type instructions
	regs : in std_logic_vector(31 downto 0);
	regt : in std_logic_vector(31 downto 0);
	opcode: in std_logic_vector(5 downto 0);

	--R type only
	regd : in std_logic_vector(31 downto 0); --register d
	shift : in std_logic_vector(3 downto 0); --shift amount
	func : in std_logic_vector(5 downto 0); -- function

	--I type only
	immed : in std_logic_vector(15 downto 0); --for I type instructions

	--J type onlt
	target : in std_logic_vector(25 downto 0); --branch target
	
	--Outputs
	result : out std_logic_vector(31 downto 0); --ALU result
	pc_out : out std_logic_vector(31 downto 0); --Modified PC
	dest_reg_out : out std_logic_vector(31 downto 0);	--destination reg for ALU output
	is_new_pc: out std_logic :='0';
	is_load: out std_logic :='0';
	is_store: out std_logic :='0'
);
end execute;

architecture behaviour of execute is
signal result_local :  std_logic_vector(31 downto 0);
signal long_result : std_logic_vector(63 downto 0); --For mult and 
signal result_hi_local : std_logic_vector(31 downto 0); --used for mfhi
signal result_low_local : std_logic_vector(31 downto 0); --used for mflow 
signal zeros : std_logic_vector( to_integer(unsigned(shift)-1)downto 0); --Get zeros for padding shift 

begin

process(clk)
begin
	is_new_pc<='0'; --reset is_new_pc variable (assume no jump at first)
	is_load<='0';
	is_store<='0';
	if (opcode = "000000") then --if R instruction 
	
	--determine fcn to be performed 
		case func is
			when "100000" => 	result_local <= std_logic_vector(signed(regs) + signed(regt));	--add inst
			when "100010" =>	result_local <=std_logic_vector(signed(regs) - signed(regt));	--subtract inst
			when "011000" =>
				long_result<= std_logic_vector(signed(regs)*signed(regt)); --mult
				result_low_local<= long_result(31 downto 0);
				result_hi_local<=long_result(63 downto 32);
			when "111010"	=>	--div
				long_result<=std_logic_vector(signed(regs) / signed(regt));
				result_low_local<=long_result(31 downto 0);
				result_hi_local<=std_logic_vector(signed(regs) mod signed(regt));
			when "101010"	=>	--Set Less Than (slt)
				if(regs<regt) then
					result_local <=x"1";
				else result_local<=x"0";
				end if;
			when "100100"	=>	result_local <= regs AND regt; --AND
			when "100101"	=>	result_local <=regs OR regt;	--OR
			when "100111"	=>	result_local <=regs NOR regt;	--NOR
			when "100110"	=>	result_local <=regs XOR regt;	--XOR
			when "010000"	=>	result_local <=result_hi_local;	--Move from hi
			when "010010"	=>	result_local <=result_low_local;	--Move from low	
			when "000000"	=>	--Shift Left Logical
				result_local(31 downto to_integer(unsigned(shift))) <= regt((31-to_integer(unsigned(shift)))downto 0);
				result_local( (to_integer(unsigned(shift))-1) downto 0) <= (others => '0');
			when "000010"	=>   --Shift Right Logical
				result_local(31-to_integer(unsigned(shift)) downto 0) <= regt(31 downto to_integer(unsigned(shift)));
				result_local(31 downto  32-to_integer(unsigned(shift))) <= (others => '0');
			when "000011"	=>	  --Shift Right Arithmetic - preserve sign
				result_local(31-to_integer(signed(shift)) downto 0) <= regt(31 downto to_integer(signed(shift)));
				result_local(31 downto  32-to_integer(signed(shift))) <= (others => '0');
			when "001000"	=>	pc_out <= regs; --Jump Register
				is_new_pc<='1'; 
			when others	=>	report "Instruction not supported";
		end case;

	elsif ((opcode = "000011") or (opcode = "000010")) then --J type Inst
		case func is 
			when "000010" => pc_out<= "000000" & target; --jump
				is_new_pc<='1'; --Let IF know to take new PC
			when "000011" => --Jump and Link
				dest_reg_out<= x"0000001F"; --save old PC in address of register 31 "x1F"
				result_local<=std_logic_vector(unsigned(pc_in) + x"00000001"); --old PC to be stored in register 31
				pc_out<= "000000" & target; --Assign new PC to be target
				is_new_pc<='1';
			when others	=>	report "Instruction not supported";
		end case;

	else	--I type inst
		case func is
			when "001000" => result_local<=std_logic_vector(signed(regs) + signed(immed));	--Add Immed
			when "001010" => --Set Less Than Immed
				if(to_integer(signed(regs))<to_integer(signed(immed))) then
					result_local<=x"1";
				else result_local<=x"0";
				end if;
			when "001100" => result_local<= regs AND "0000000000000000"&immed;	--And Immediate (ZeroExt)
			when "001101" => result_local<= regs OR "0000000000000000"&immed;	--Or Immediate (ZeroExt)
			when "001110" => result_local<=regs XOR "0000000000000000"&immed; --XOR Immed (ZeroExt)
			when "001111" => result_local<= immed(15 downto 0) & "0000000000000000"; --Load Upper Immed
			when "100011" => is_load<='1';	--Load Word
			when "101011" => is_store<='1';	--Store Word
			when "000100" => --Branch on equal
				if(regs=regt) then
					pc_out<=std_logic_vector(unsigned(pc_in)+"0000000000000000"&unsigned(immed));
				end if;
			when "000101" => --Branch on not equal
				if(regs/=regt) then
					pc_out<=std_logic_vector(unsigned(pc_in)+"0000000000000000"&unsigned(immed));
				end if;
			when others=> report "Instruction not supported";
		end case;
	end if;
result<=result_local;	--Assert the result to the output
end process;
end behaviour;