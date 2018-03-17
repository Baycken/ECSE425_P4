LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY mips32 IS
PORT (
   clk_i : IN STD_LOGIC;
   rst_i : IN STD_LOGIC;

   -- Interface to instruction cache
   pc_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   inst_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
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
   clk_i : IN STD_LOGIC;
   rst_i : IN STD_LOGIC;
   inst_wait_i : IN STD_LOGIC;
   inst_i: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   pc_branch_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   pc_jump_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   pc_next_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   real_token_i : IN STD_LOGIC;
   jump_token_i : IN STD_LOGIC;
   is_hazard_i: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   is_flush_i: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   is_cache_stall_i: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_pc_o: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_inst_o: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_bht_token_o: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);

   bht_write_addr_i: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
   bht_we_i: IN STD_LOGIC;
   bht_din_i: IN STD_LOGIC
);
END COMPONENT;

COMPONENT decode IS
PORT(
   clk_i : IN STD_LOGIC;
   rst_i : IN STD_LOGIC;
   inst_wait_i : IN STD_LOGIC;
   pc_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   inst_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);

   reg_write_flag_i : IN STD_LOGIC;
   reg_write_reg_i : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
   reg_write_data_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);

   is_flush_i : IN STD_LOGIC;
   is_cache_stall_i : IN STD_LOGIC;

   reg1_data_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg2_data_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_immediate_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_inst_o : STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_rt_o : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
   reg_rd_o : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);

   reg_pc_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_ctr_ex_o : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
   reg_ctr_m_o : OUT STD_LOGIC_VECTOR (5 DOWNTO 0);
   reg_ctr_wb_o : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
   is_hazard_o : OUT STD_LOGIC;

   -- Bypass Interface
   ex_write_reg_i : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
   ex_regwrite_flag_i : IN STD_LOGIC;
   mem_write_reg_i : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
   mem_regwrite_flag_i : IN STD_LOGIC;
   reg_forward_a_o: OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
   reg_forward_b_o: OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
   reg_alu_cmd_o: OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
   bht_token_i: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
   reg_bht_token_o: OUT STD_LOGIC_VECTOR (1 DOWNTO 0)
);
END COMPONENT;

COMPONENT execute IS
PORT(
   clk_i : IN STD_LOGIC;
   rst_i : IN STD_LOGIC;
   ctr_ex_i : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
   ctr_m_i : IN STD_LOGIC_VECTOR (5 DOWNTO 0);
   ctr_wb_i : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
   pc_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   inst_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg1_data_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg2_data_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   immediate_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   rt_i : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
   rd_i : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
   is_flush_i : IN STD_LOGIC;
   is_cache_stall_i : IN STD_LOGIC;
   alu_cmd_i : IN STD_LOGIC_VECTOR (3 DOWNTO 0);

   reg_alu_out_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_reg2_data_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_write_reg_o : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
   reg_ctr_m_o : OUT STD_LOGIC_VECTOR (5 DOWNTO 0);
   reg_ctr_wb_o : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);

   -- Bypass Interface
   ex_mem_data_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   mem_wb_data_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   forward_a_i: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
   forward_b_i: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
   ex_write_reg_o: OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
   ex_regwrite_flag_o: OUT STD_LOGIC;
   bht_token_i: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
   reg_bht_token_o: OUT STD_LOGIC_VECTOR (1 DOWNTO 0);

   reg_pc_o : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_pc_branch_o : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_pc_jump_o : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_pc_next_o : IN STD_LOGIC_VECTOR (31 DOWNTO 0)
);
END COMPONENT;

COMPONENT mem IS
PORT(
   clk_i : IN STD_LOGIC;
   rst_i : IN STD_LOGIC;

   ctr_m_i : IN STD_LOGIC_VECTOR (5 DOWNTO 0);
   ctr_wb_i : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
   alu_out_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);

   reg2_data_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   write_reg_i : IN STD_LOGIC_VECTOR (4 DOWNTO 0);

   reg_mem_out_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_alu_out_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   reg_write_reg_o : OUT STD_LOGIC_VECTOR (4 DOWNTO 0);
   reg_ctr_wb_o : OUT STD_LOGIC_VECTOR (1 DOWNTO 0);
   is_flush_o : OUT STD_LOGIC;
   is_cache_stall_o : OUT STD_LOGIC;

   pc_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   pc_branch_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   pc_jump_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   real_token_o : OUT STD_LOGIC;
   jump_token_o : OUT STD_LOGIC;
   bht_token_i : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
   bht_write_addr_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   bht_we_o : OUT STD_LOGIC;
   bht_din_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);

   mem_addr_o : OUT INTEGER RANGE 0 TO 32767;
   mem_write_o : OUT STD_LOGIC;
   mem_read_o : OUT STD_LOGIC;
   mem_read_data_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   mem_write_data_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   mem_wait_i : IN STD_LOGIC
);
END COMPONENT;

COMPONENT writeback IS
PORT(
   ctr_wb_i : IN STD_LOGIC_VECTOR (1 DOWNTO 0);
   mem_out_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   alu_out_i : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
   write_data_o : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
   regwrite_flag_o : OUT STD_LOGIC;
);
END COMPONENT;

SIGNAL if_reg_pc : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL if_reg_inst : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL if_reg_bht_token : STD_LOGIC_VECTOR (1 DOWNTO 0);

SIGNAL id_reg1_data : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL id_reg2_data : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL id_reg_immediate : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL id_reg_rt : STD_LOGIC_VECTOR (4 DOWNTO 0);
SIGNAL id_reg_rd : STD_LOGIC_VECTOR (4 DOWNTO 0);
SIGNAL id_reg_pc : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL id_reg_inst : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL id_reg_ctr_ex : STD_LOGIC_VECTOR (3 DOWNTO 0);
SIGNAL id_reg_ctr_m : STD_LOGIC_VECTOR (5 DOWNTO 0);
SIGNAL id_reg_ctr_wb : STD_LOGIC_VECTOR (1 DOWNTO 0);
SIGNAL is_hazard : STD_LOGIC;
SIGNAL id_reg_forward_a : STD_LOGIC_VECTOR (1 DOWNTO 0);
SIGNAL id_reg_forward_b : STD_LOGIC_VECTOR (1 DOWNTO 0);
SIGNAL id_reg_alu_cmd : STD_LOGIC_VECTOR (3 DOWNTO 0);
SIGNAL id_reg_bht_token : STD_LOGIC_VECTOR (1 DOWNTO 0);

SIGNAL ex_reg_alu_out : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL ex_reg_reg2_data : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL ex_reg_write_reg : STD_LOGIC_VECTOR (4 DOWNTO 0);
SIGNAL ex_reg_ctr_m : STD_LOGIC_VECTOR (5 DOWNTO 0);
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
SIGNAL m_is_cache_stall : STD_LOGIC;
SIGNAL m_bht_write_addr : STD_LOGIC_VECTOR (9 DOWNTO 0);
SIGNAL m_bht_we : STD_LOGIC;
SIGNAL m_bht_din : STD_LOGIC_VECTOR (31 DOWNTO 0);

SIGNAL wb_write_data : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL wb_regwrite_flag : STD_LOGIC;

BEGIN

fetch_inst: fetch
PORT MAP(
   clk_i => clk_i;
   rst_i => rst_i;
   inst_wait_i => inst_wait_i;
   pc_branch_i => pc_branch;
   pc_jump_i => pc_jump;
   pc_next_i => pc_next;
   real_token_i => real_token;
   jump_token_i => jump_token;
   is_hazard_i => is_hazard;
   is_flush_i => is_flush;
   is_cache_stall_i => m_is_cache_stall;
   reg_pc_o => if_reg_pc;
   reg_inst_o => if_reg_inst;
   reg_bht_token_o => if_reg_bht_token;
   bht_write_addr_i => bht_write_addr;
   bht_we_i => m_bht_we;
   bht_din_i => m_bht_din
);

decode_inst: decode
PORT MAP(
   clk_i => clk_i;
   rst_i => rst_i;
   pc_i => if_reg_pc;
   inst_i => if_reg_inst;
   reg_write_flag_i => wb_regwrite_flag;
   reg_write_reg_i => m_reg_write_reg;
   reg_write_data_i => wb_write_data;
   is_flush_i => m_is_flush;
   is_cache_stall_i => m_is_cache_stall;
   reg1_data_o => id_reg1_data;
   reg2_data_o => id_reg2_data;
   reg_immediate_o => id_reg_immediate;
   reg_inst_o => id_reg_inst;
   reg_rt_o => id_reg_rt;
   reg_rd_o => id_reg_rd;
   reg_pc_o => id_reg_pc;
   reg_ctr_ex_o => id_reg_ctr_ex;
   reg_ctr_m_o => id_reg_ctr_m;
   reg_ctr_wb_o => id_reg_ctr_wb;
   is_hazard_o => m_is_hazard;
   ex_write_reg_i => ex_write_reg;
   ex_regwrite_flag_i => ex_regwrite_flag;
   mem_write_reg_i => ex_reg_write_reg;
   mem_regwrite_flag_i => ex_reg_ctr_wb[1];
   reg_forward_a_o => id_reg_forward_a;
   reg_forward_b_o => id_reg_forward_b;
   reg_alu_cmd_o => id_reg_alu_cmd;
   bht_token_i => if_reg_bht_token;
   reg_bht_token_o => id_reg_bht_token
);

execute_inst: execute
PORT MAP(
   clk_i => clk_i;
   rst_i => rst_i;
   ctr_ex_i => id_reg_ctr_ex;
   ctr_m_i => id_reg_ctr_m;
   ctr_wb_i => id_reg_ctr_wb;
   pc_i =>  id_reg_pc;
   inst_i => id_reg_inst;
   reg1_data_i => id_reg1_data;
   reg2_data_i => id_reg2_data;
   immediate_i => id_reg_immediate;
   rt_i => id_reg_rt;
   rd_i => id_reg_rd;
   is_flush_i => m_is_flush;
   is_cache_stall_i => m_is_cache_stall;
   alu_cmd_i => id_reg_alu_cmd;
   reg_alu_out_o => ex_reg_alu_out;
   reg_reg2_data_o => ex_reg_reg2_data;
   reg_write_reg_o => ex_reg_write_reg;
   reg_ctr_m_o => ex_reg_ctr_m;
   reg_ctr_wb_o => ex_reg_ctr_wb;
   ex_mem_data_i => ex_reg_alu_out;
   mem_wb_data_i => wb_write_data;
   forward_a_i => id_reg_forward_a;
   forward_b_i => id_reg_forward_b;
   ex_write_reg_o => ex_write_reg;
   ex_regwrite_flag_o => ex_regwrite_flag;
   bht_token_i => id_reg_bht_token;
   reg_bht_token_o => ex_reg_bht_token;
   reg_pc_o => ex_reg_pc;
   reg_pc_branch_o => ex_pc_branch;
   reg_pc_jump_o => ex_pc_jump;
   reg_pc_next_o => ex_pc_next
);

mem_inst : mem
PORT MAP(
   clk_i => clk_i;
   rst_i => rst_i;
   ctr_m_i => ex_reg_ctr_m;
   ctr_wb_i => ex_reg_ctr_wb;
   alu_out_i => ex_reg_alu_out;
   reg2_data_i => ex_reg_reg2_data;
   write_reg_i => ex_reg_write_reg;
   reg_mem_out_o => m_reg_mem_out;
   reg_alu_out_o => m_reg_alu_out;
   reg_write_reg_o => m_reg_write_reg;
   reg_ctr_wb_o => m_reg_ctr_wb;
   is_flush_o => m_is_flush;
   is_cache_stall_o => m_is_cache_stall;
   pc_i => ex_reg_pc;
   pc_branch_i => ex_pc_branch;
   pc_jump_i => ex_pc_jump;
   real_token_o => m_real_token;
   jump_token_o => m_jump_token;
   bht_token_i => m_bht_we;
   bht_write_addr_o => m_bht_write_addr
   bht_we_o => m_bht_we;
   bht_din_i => m_bht_din;

   mem_addr_o => mem_addr_o;
   mem_write_o => mem_write_o;
   mem_read_o => mem_read_o;
   mem_read_data_i => mem_read_data_i;
   mem_write_data_o => mem_write_data_o;
   mem_wait_i => mem_wait_i
);

writeback_inst : writeback
PORT MAP(
   ctr_wb_i => m_reg_ctr_wb;
   mem_out_i => m_reg_mem_out;
   alu_out_i => m_reg_alu_out;
   write_data_o => wb_write_data;
   regwrite_flag_o => wb_regwrite_flag
);

END;
