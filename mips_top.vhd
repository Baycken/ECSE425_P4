LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

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
   mem_addr_o : OUT INTEGER RANGE 0 TO 32767;
   mem_write_o : OUT STD_LOGIC;
   mem_read_o : OUT STD_LOGIC;
   mem_read_data_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   mem_write_data_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   mem_wait_i : IN STD_LOGIC
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
	wb_flag : in std_logic;
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
	out_registers : out data_array
);
END COMPONENT;

-- Execution
COMPONENT execute IS
PORT(
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
   clk_i : IN STD_LOGIC; -- Clock Input
   rst_i : IN STD_LOGIC; -- Reset Input, Reset on '1'
   write_data_i : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   write_reg_i : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
   write_flag_i : OUT STD_LOGIC

   write_data_o : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   write_reg_o : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
   write_flag_o : OUT STD_LOGIC
);
END COMPONENT;

SIGNAL if_reg_pc : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL if_reg_inst : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL if_inst_read : STD_LOGIC;

SIGNAL id_reg1_data : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL id_reg2_data : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL id_reg_immediate : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL id_reg_rt : STD_LOGIC_VECTOR (4 DOWNTO 0);
SIGNAL id_reg_rd : STD_LOGIC_VECTOR (4 DOWNTO 0);
SIGNAL id_reg_pc : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL id_reg_inst : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL id_reg_ctr_opcode : STD_LOGIC_VECTOR (5 DOWNTO 0);
SIGNAL id_reg_ctr_shamt : STD_LOGIC_VECTOR (4 DOWNTO 0);
SIGNAL id_reg_ctr_funct : STD_LOGIC_VECTOR (5 DOWNTO 0);
SIGNAL id_reg_ctr_wb : STD_LOGIC_VECTOR (1 DOWNTO 0);
SIGNAL id_is_hazard : STD_LOGIC;
SIGNAL id_reg_forward_a : STD_LOGIC_VECTOR (1 DOWNTO 0);
SIGNAL id_reg_forward_b : STD_LOGIC_VECTOR (1 DOWNTO 0);
SIGNAL id_reg_bht_token : STD_LOGIC_VECTOR (1 DOWNTO 0);

SIGNAL ex_reg_alu_out : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL ex_reg_reg2_data : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL ex_reg_write_reg : STD_LOGIC_VECTOR (4 DOWNTO 0);
SIGNAL ex_reg_ctr_opcode : STD_LOGIC_VECTOR (5 DOWNTO 0);
SIGNAL ex_reg_ctr_wb : STD_LOGIC_VECTOR (1 DOWNTO 0);
SIGNAL ex_write_reg : STD_LOGIC_VECTOR (4 DOWNTO 0);
SIGNAL ex_regwrite_flag : STD_LOGIC;
SIGNAL ex_reg_bht_token : STD_LOGIC_VECTOR (1 DOWNTO 0);
SIGNAL ex_reg_pc : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL ex_pc_branch : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL ex_pc_jump : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL ex_pc_next : STD_LOGIC_VECTOR (31 DOWNTO 0);

SIGNAL m_reg_mem_out : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL m_reg_alu_out : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL m_reg_write_reg : STD_LOGIC_VECTOR (4 DOWNTO 0);
SIGNAL m_reg_ctr_wb : STD_LOGIC_VECTOR (1 DOWNTO 0);
SIGNAL m_is_flush : STD_LOGIC;

SIGNAL m_real_token : STD_LOGIC;
SIGNAL m_jump_token : STD_LOGIC;
SIGNAL m_is_mem_stall : STD_LOGIC;
SIGNAL m_bht_write_addr : STD_LOGIC_VECTOR (9 DOWNTO 0);
SIGNAL m_bht_we : STD_LOGIC;
SIGNAL m_bht_din : STD_LOGIC_VECTOR (31 DOWNTO 0);

SIGNAL wb_write_data : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL wb_regwrite_flag : STD_LOGIC;

BEGIN

fetch_inst: fetch
PORT MAP(
   clock => clk_i,
   reset => rst_i,

   addr => pc_o,
   s_write  => inst_read_o,
   s_writedata => inst_data_i,

   s_waitrequest => inst_wait_i,
   ex_pc => ex_pc_branch,
   ex_is_new_pc => ex_jump_token,
   is_hazard_i => id_is_hazard,
   is_mem_stall_i => m_is_mem_stall,

);

decode_inst: decode
PORT MAP(
   clk_i => clk_i,
   rst_i => rst_i,
   pc_i => if_reg_pc,
   inst_i => if_reg_inst,
   reg_write_flag_i => wb_regwrite_flag,
   reg_write_reg_i => m_reg_write_reg,
   reg_write_data_i => wb_write_data,
   is_flush_i => m_is_flush,
   is_mem_stall_i => m_is_mem_stall,
   reg1_data_o => id_reg1_data,
   reg2_data_o => id_reg2_data,
   reg_immediate_o => id_reg_immediate,
   reg_inst_o => id_reg_inst,
   reg_rt_o => id_reg_rt,
   reg_rd_o => id_reg_rd,
   reg_pc_o => id_reg_pc,

   reg_ctr_opcode_o => id_reg_ctr_opcode,
   reg_ctr_shamt_o => id_reg_ctr_shamt,
   reg_ctr_funct_o => id_reg_ctr_funct,
   reg_ctr_wb_o => id_reg_ctr_wb,

   is_hazard_o => id_is_hazard,
   ex_write_reg_i => ex_write_reg,
   ex_regwrite_flag_i => ex_regwrite_flag,
   mem_write_reg_i => ex_reg_write_reg,
   mem_regwrite_flag_i => ex_reg_ctr_wb[1],
   reg_forward_a_o => id_reg_forward_a,
   reg_forward_b_o => id_reg_forward_b,
   bht_token_i => if_reg_bht_token,
   reg_bht_token_o => id_reg_bht_token
),

execute_inst: execute
PORT MAP(
   clk_i => clk_i,
   rst_i => rst_i,

   ctr_opcode_i => id_reg_ctr_opcode,
   ctr_shamt_i => id_reg_ctr_shamt,
   ctr_funct_i => id_reg_ctr_funct,
   ctr_wb_i => id_reg_ctr_wb,

   pc_i =>  id_reg_pc,
   inst_i => id_reg_inst,
   reg1_data_i => id_reg1_data,
   reg2_data_i => id_reg2_data,
   immediate_i => id_reg_immediate,
   rt_i => id_reg_rt,
   rd_i => id_reg_rd,
   is_flush_i => m_is_flush,
   is_mem_stall_i => m_is_mem_stall,
   reg_alu_out_o => ex_reg_alu_out,
   reg_reg2_data_o => ex_reg_reg2_data,
   reg_write_reg_o => ex_reg_write_reg,
   reg_ctr_opcode_o => ex_reg_ctr_opcode,
   reg_ctr_wb_o => ex_reg_ctr_wb,
   ex_mem_data_i => ex_reg_alu_out,
   mem_wb_data_i => wb_write_data,
   forward_a_i => id_reg_forward_a,
   forward_b_i => id_reg_forward_b,
   ex_write_reg_o => ex_write_reg,
   ex_regwrite_flag_o => ex_regwrite_flag,
   bht_token_i => id_reg_bht_token,
   reg_bht_token_o => ex_reg_bht_token,
   reg_pc_o => ex_reg_pc,
   reg_pc_branch_o => ex_pc_branch,
   reg_pc_jump_o => ex_pc_jump,
   reg_pc_next_o => ex_pc_next
);

mem_inst : mem
PORT MAP(
   clk_i => clk_i,
   rst_i => rst_i,
   ctr_opcode_i => ex_reg_ctr_opcode,
   ctr_wb_i => ex_reg_ctr_wb,
   alu_out_i => ex_reg_alu_out,
   reg2_data_i => ex_reg_reg2_data,
   write_reg_i => ex_reg_write_reg,
   reg_mem_out_o => m_reg_mem_out,
   reg_alu_out_o => m_reg_alu_out,
   reg_write_reg_o => m_reg_write_reg,
   reg_ctr_wb_o => m_reg_ctr_wb,
   is_flush_o => m_is_flush,
   is_mem_stall_o => m_is_mem_stall,
   pc_i => ex_reg_pc,
   pc_branch_i => ex_pc_branch,
   pc_jump_i => ex_pc_jump,
   real_token_o => m_real_token,
   jump_token_o => m_jump_token,
   bht_token_i => m_bht_we,
   bht_write_addr_o => m_bht_write_addr
   bht_we_o => m_bht_we,
   bht_din_i => m_bht_din,

   mem_addr_o => mem_addr_o,
   mem_write_o => mem_write_o,
   mem_read_o => mem_read_o,
   mem_read_data_i => mem_read_data_i,
   mem_write_data_o => mem_write_data_o,
   mem_wait_i => mem_wait_i
);

writeback_inst : writeback
PORT MAP(
   ctr_wb_i => m_reg_ctr_wb,
   mem_out_i => m_reg_mem_out,
   alu_out_i => m_reg_alu_out,
   write_data_o => wb_write_data,
   regwrite_flag_o => wb_regwrite_flag
);

END;
