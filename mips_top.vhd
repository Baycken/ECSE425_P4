
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY mips32 IS
PORT (
   clk_i : IN STD_LOGIC;
   rst_i : IN STD_LOGIC;

   -- Interface to instruction cache
   pc_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   inst_read_o : OUT STD_LOGIC;
   inst_data_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   inst_wait_i : IN STD_LOGIC;

   -- Interface to user memory
	mem_read_data : in std_logic_vector (31 downto 0);
	mem_waitrequest : in std_logic;
	mem_write : out std_logic;
	mem_read : out std_logic;
	mem_addr : out integer RANGE 0 TO 8191;
	mem_write_data : out std_logic_vector (31 downto 0);
   out_registers : out std_logic_vector(1023 downto 0)
);
END mips32;

ARCHITECTURE behaviour OF mips32 IS

-- Component declaration
-- Instruction fetching
COMPONENT fetch IS
	PORT(
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
END COMPONENT;

-- Instruction Decoding
COMPONENT decode IS
	PORT(
		--inputs
		if_pc : in std_logic_vector(31 downto 0); --program counter
		if_instr : in std_logic_vector (31 downto 0); --32 bit mips instruction
		wb_register : in std_logic_vector(31 downto 0); --register to store wb_data
		wb_data : in std_logic_vector(31 downto 0); --data from writeback stage to put into register
		clk : in std_logic;
		reset : in std_logic;

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
		hazard : out std_logic; --high if hazard

		--Registers
		out_registers : out std_logic_vector(1023 downto 0)
	);
END COMPONENT;

-- Execution
COMPONENT execute IS
	PORT(
		--Inputs
		clk : in std_logic;
		reset: in std_logic;
		pc_in : in std_logic_vector(31 downto 0); --For J and R type inst

		--R and I type instructions
		regs : in std_logic_vector(31 downto 0);
		regt : in std_logic_vector(31 downto 0);
		opcode: in std_logic_vector(5 downto 0);

		--R type only
		regd : in std_logic_vector(31 downto 0); --register d
		shift : in std_logic_vector(4 downto 0); --shift amount
		func : in std_logic_vector(5 downto 0); -- function

		--I type only
		immed : in std_logic_vector(31 downto 0); --for I type instructions

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
END COMPONENT;

COMPONENT mem_stage IS
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
end COMPONENT;

-- Writeback
COMPONENT writeback IS
	PORT(
		clk : in std_logic;
		reset : in std_logic;
		mem_register : in std_logic_vector(31 downto 0);
		mem_data : in std_logic_vector(31 downto 0);

		id_register : out std_logic_vector(31 downto 0);
		id_data : out std_logic_vector(31 downto 0)

	);
END COMPONENT;

SIGNAL if_pc : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL if_instr : STD_LOGIC_VECTOR(31 downto 0);


SIGNAL id_hazard : STD_LOGIC;
SIGNAL id_pc : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL id_instr : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL id_opcode : STD_LOGIC_VECTOR(5 downto 0);
SIGNAL id_shift : STD_LOGIC_VECTOR(4 downto 0);
SIGNAL id_func : STD_LOGIC_VECTOR(5 downto 0);
SIGNAL id_regs : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL id_regt : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL id_regd : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL id_immed : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL id_target : STD_LOGIC_VECTOR(25 downto 0);

SIGNAL ex_jump_target : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL ex_jump_flag : STD_LOGIC;
SIGNAL ex_alu_out : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL ex_dest_reg : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL ex_is_load : STD_LOGIC;
SIGNAL ex_is_store : STD_LOGIC;

SIGNAL mem_wb_reg : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL mem_wb_data : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL mem_stall : STD_LOGIC;

SIGNAL wb_register : STD_LOGIC_VECTOR(31 downto 0);
SIGNAL wb_data : STD_LOGIC_VECTOR(31 downto 0);

BEGIN

fetch_inst: fetch
PORT MAP(
	clock => clk_i,
	reset => rst_i,

	--communication with pc (getting and sending back the incremented one or the completely new pc)
	addr => (others => '0'),
	s_write => '0',
	s_writedata => (others => '0'),
	s_waitrequest => open,

	--communication with ID stage
	hazard_detect => id_hazard,

	--communication with EX stage
	ex_is_new_pc => ex_jump_flag,
	ex_pc => ex_jump_target,

	--communication with decode stage (**no need to write so comment)
	instruction => if_instr,
	instruction_read  => open,
	current_pc_to_dstage => if_pc
);

decode_inst: decode
PORT MAP(
	if_pc => if_pc,
	if_instr => if_instr,
	wb_register => wb_register,
	wb_data => wb_data,
	clk => clk_i,
	reset => rst_i,

	--outputs for both R and I instructions
	ex_pc => id_pc,
	ex_opcode => id_opcode,
	ex_regs => id_regs,
	ex_regt => id_regt,

	--R instructions
	ex_regd => id_regd,
	ex_shift => id_shift,
	ex_func => id_func,

	--I instructions
	ex_immed => id_immed,

	--J instructions
	target => id_target,

	--Data Hazard Detection
	hazard => id_hazard,
	
	--Registers
	out_registers => out_registers
);

execute_inst: execute
PORT MAP(
	--Inputs
	clk => clk_i,
	reset => rst_i,
	pc_in => id_pc,

	--R and I type instructions
	regs => id_regs,
	regt => id_regt,
	opcode => id_opcode,

	--R type only
	regd => id_regd,
	shift => id_shift,
	func => id_func,

	--I type only
	immed => id_immed,

	--J type onlt
	target => id_target,

	--Outputs
	result => ex_alu_out,
	pc_out => ex_jump_target,
	dest_reg_out => ex_dest_reg,
	is_new_pc => ex_jump_flag,
	is_load => ex_is_load,
	is_store => ex_is_store
);

mem_inst : mem_stage
PORT MAP(
	reset => rst_i,
	clk => clk_i,

	--execution stage communication
	ex_result => ex_alu_out,
	ex_dest_reg => ex_dest_reg,
	ex_load => ex_is_load,
	ex_store => ex_is_store,

	--writeback stage communication
	wb_data => mem_wb_data,
	wb_dest_reg => mem_wb_reg,

	--data memory communication
	mem_read_data => mem_read_data,
	mem_waitrequest => mem_waitrequest,
	mem_write => mem_write,
	mem_read => mem_read,
	mem_addr => mem_addr,
	mem_write_data => mem_write_data,

	--memory stall
	stall => mem_stall
);

writeback_inst : writeback
PORT MAP(
	reset => rst_i,
	clk => clk_i,
	mem_register => mem_wb_reg,
	mem_data => mem_wb_data,
	
	id_register => wb_register,
	id_data => wb_data
);

END;
