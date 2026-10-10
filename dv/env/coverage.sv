// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : coverage.sv
// Description : Functional, Cross, and FSM State Coverage Collector for AES-128-GCM
// ============================================================================

class coverage;

  // Transaction sampled variables
  bit         cov_mode;
  bit [127:0] cov_key;
  bit [95:0]  cov_iv;
  int         cov_aad_len;
  int         cov_data_len;
  bit         cov_verify_pass;
  bit         cov_verify_done;
  bit         cov_ctr_overflow;
  bit         cov_key_reused;

  // FSM sampled state
  logic [3:0] cov_fsm_state;

  int total_samples;
  int total_fsm_samples;

  // =========================================================================
  // Covergroup 1: Transaction Functional & Cross Coverage
  // =========================================================================
  covergroup cg_aes_gcm;
    option.per_instance = 1;
    option.name = "cg_aes_gcm";

    // 1. Chế độ hoạt động (ENCRYPT vs DECRYPT)
    cp_mode: coverpoint cov_mode {
      bins ENCRYPT = {1'b0};
      bins DECRYPT = {1'b1};
    }

    // 2. Phân loại Khóa Cipher Key
    cp_key_type: coverpoint cov_key {
      bins ZERO_KEY        = {128'h0};
      bins ALL_ONES_KEY    = {128'hffffffffffffffffffffffffffffffff};
      bins PATTERN_KEY     = {128'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, 128'h55555555555555555555555555555555};
      bins RANDOM_KEY      = default;
    }

    // 3. Phân loại Vector Khởi tạo IV (Zero, All-Ones, Random)
    cp_iv_type: coverpoint cov_iv {
      bins ZERO_IV         = {96'h0};
      bins ALL_ONES_IV     = {96'hffffffffffffffffffffffff};
      bins RANDOM_IV       = default;
    }

    // 4. Độ dài AAD (Số lượng block 128-bit)
    cp_aad_length: coverpoint cov_aad_len {
      bins NO_AAD          = {0};
      bins SINGLE_BLOCK    = {1};
      bins MULTI_BLOCK_LOW = {[2:4]};
      bins MULTI_BLOCK_HI  = {[5:8]};
    }

    // 5. Độ dài Payload Data In (Số lượng block 128-bit)
    cp_payload_length: coverpoint cov_data_len {
      bins SINGLE_BLOCK    = {1};
      bins SHORT_PAYLOAD   = {[2:4]};
      bins MEDIUM_PAYLOAD  = {[5:8]};
      bins LONG_PAYLOAD    = {[9:12]};
    }

    // 6. Kết quả xác thực thẻ xác thực (Chế độ Decrypt)
    cp_verify_pass: coverpoint cov_verify_pass {
      bins AUTH_PASS       = {1'b1};
      bins AUTH_FAIL       = {1'b0};
    }

    // 7. Cảnh báo CTR Counter Overflow
    cp_ctr_overflow: coverpoint cov_ctr_overflow {
      bins NO_OVERFLOW     = {1'b0};
    }

    // 8. Tái sử dụng Key (Key Reuse / Skip Key Expansion)
    cp_key_reuse: coverpoint cov_key_reused {
      bins NEW_KEY_LOADED  = {1'b0};
      bins KEY_REUSED      = {1'b1};
    }

    // =======================================================================
    // Cross Coverage
    // =======================================================================
    // Cross 1: Mode x Payload Length
    cross_mode_payload: cross cp_mode, cp_payload_length;

    // Cross 2: Mode x AAD Length
    cross_mode_aad: cross cp_mode, cp_aad_length;

    // Cross 3: Mode x Key Type
    cross_mode_key: cross cp_mode, cp_key_type;

    // Cross 4: Mode x Verify Pass (Chỉ tính ở Decrypt)
    cross_mode_verify: cross cp_mode, cp_verify_pass {
      ignore_bins enc_bins = binsof(cp_mode) intersect {1'b0};
    }

    // Cross 5: Mode x Key Reuse (Tái sử dụng Key ở cả Encrypt và Decrypt)
    cross_mode_key_reuse: cross cp_mode, cp_key_reuse;

  endgroup

  // =========================================================================
  // Covergroup 2: FSM State & Transition Coverage
  // =========================================================================
  covergroup cg_fsm;
    option.per_instance = 1;
    option.name = "cg_fsm";

    // Đo toàn bộ 11 trạng thái của CU FSM
    cp_states: coverpoint cov_fsm_state {
      bins IDLE                = {4'd0};
      bins KEY_EXPANSION       = {4'd1};
      bins WAIT_H_CAL          = {4'd2};
      bins WAIT_TAG_REF        = {4'd3};
      bins WAIT_AAD            = {4'd4};
      bins LOAD_AAD            = {4'd5};
      bins WAIT_DATA           = {4'd6};
      bins LOAD_DATA           = {4'd7};
      bins WAIT_PROCESS_FINISH = {4'd8};
      bins VERIFY_PASS         = {4'd9};
      bins FINISH              = {4'd10};
    }

    // Đo các bước chuyển trạng thái (FSM Transitions)
    cp_transitions: coverpoint cov_fsm_state {
      bins idle_to_key        = (4'd0 => 4'd1);
      bins idle_to_tagref     = (4'd0 => 4'd3); // Key reuse in Decrypt!
      bins idle_to_aad        = (4'd0 => 4'd4); // Key reuse in Encrypt!
      bins key_to_h           = (4'd1 => 4'd2);
      bins h_to_aad           = (4'd2 => 4'd4);
      bins h_to_tagref        = (4'd2 => 4'd3);
      bins tagref_to_aad      = (4'd3 => 4'd4);
      bins aad_to_loadaad     = (4'd4 => 4'd5);
      bins aad_to_waitdata    = (4'd4 => 4'd6);
      bins loadaad_to_waitdata= (4'd5 => 4'd6);
      bins waitdata_to_loaddata=(4'd6 => 4'd7);
      bins waitdata_to_finish = (4'd6 => 4'd8);
      bins loaddata_to_finish = (4'd7 => 4'd8);
      bins procfinish_to_verify=(4'd8 => 4'd9);
      bins procfinish_to_finish=(4'd8 => 4'd10);
      bins verify_to_finish   = (4'd9 => 4'd10);
      bins finish_to_idle     = (4'd10 => 4'd0);
    }
  endgroup

  // =========================================================================
  // Constructor
  // =========================================================================
  function new();
    cg_aes_gcm        = new();
    cg_fsm            = new();
    total_samples     = 0;
    total_fsm_samples = 0;
  endfunction

  // =========================================================================
  // Sample Transaction Task
  // =========================================================================
  function void sample(transaction tr);
    cov_mode         = tr.mode;
    cov_key          = tr.cipher_key;
    cov_iv           = tr.IV;
    cov_aad_len      = tr.aad_blocks.size();
    cov_data_len     = tr.data_in_blocks.size();
    cov_verify_pass  = tr.verify_pass;
    cov_verify_done  = tr.verify_done;
    cov_ctr_overflow = tr.CTR_counter_overflow;
    cov_key_reused   = tr.skip_key;

    cg_aes_gcm.sample();
    total_samples++;
  endfunction

  // =========================================================================
  // Sample FSM Task
  // =========================================================================
  function void sample_fsm(logic [3:0] fsm_st);
    if (!$isunknown(fsm_st)) begin
      cov_fsm_state = fsm_st;
      cg_fsm.sample();
      total_fsm_samples++;
    end
  endfunction

  // =========================================================================
  // Report Function
  // =========================================================================
  function void report();
    real total_cov, fsm_cov, fsm_states_cov, fsm_trans_cov;
    real cp_mode_cov, cp_key_cov, cp_iv_cov, cp_aad_cov, cp_data_cov, cp_ver_cov, cp_reuse_cov;
    real cross_mp_cov, cross_ma_cov, cross_mk_cov, cross_mv_cov, cross_mreuse_cov;

    total_cov         = cg_aes_gcm.get_coverage();
    cp_mode_cov       = cg_aes_gcm.cp_mode.get_coverage();
    cp_key_cov        = cg_aes_gcm.cp_key_type.get_coverage();
    cp_iv_cov         = cg_aes_gcm.cp_iv_type.get_coverage();
    cp_aad_cov        = cg_aes_gcm.cp_aad_length.get_coverage();
    cp_data_cov       = cg_aes_gcm.cp_payload_length.get_coverage();
    cp_ver_cov        = cg_aes_gcm.cp_verify_pass.get_coverage();
    cp_reuse_cov      = cg_aes_gcm.cp_key_reuse.get_coverage();

    cross_mp_cov      = cg_aes_gcm.cross_mode_payload.get_coverage();
    cross_ma_cov      = cg_aes_gcm.cross_mode_aad.get_coverage();
    cross_mk_cov      = cg_aes_gcm.cross_mode_key.get_coverage();
    cross_mv_cov      = cg_aes_gcm.cross_mode_verify.get_coverage();
    cross_mreuse_cov  = cg_aes_gcm.cross_mode_key_reuse.get_coverage();

    fsm_cov           = cg_fsm.get_coverage();
    fsm_states_cov    = cg_fsm.cp_states.get_coverage();
    fsm_trans_cov     = cg_fsm.cp_transitions.get_coverage();

    $display("");
    $display("##############################################################");
    $display("#             FUNCTIONAL & CROSS COVERAGE REPORT             #");
    $display("##############################################################");
    $display("#  Total Sampled Transactions: %0d", total_samples);
    $display("#------------------------------------------------------------#");
    $display("#  [COVERPOINTS]                                             #");
    $display("#    1. cp_mode              (ENCRYPT / DECRYPT)  : %6.2f %%   #", cp_mode_cov);
    $display("#    2. cp_key_type          (Zero/Ones/Pat/Rand) : %6.2f %%   #", cp_key_cov);
    $display("#    3. cp_iv_type           (Zero/Ones/Rand)     : %6.2f %%   #", cp_iv_cov);
    $display("#    4. cp_aad_length        (0, 1, 2..4, 5..8)   : %6.2f %%   #", cp_aad_cov);
    $display("#    5. cp_payload_length    (1, 2..4, 5..8, 9..12):%6.2f %%   #", cp_data_cov);
    $display("#    6. cp_verify_pass       (PASS=1, FAIL=0)     : %6.2f %%   #", cp_ver_cov);
    $display("#    7. cp_key_reuse         (New Key / Reused)   : %6.2f %%   #", cp_reuse_cov);
    $display("#------------------------------------------------------------#");
    $display("#  [CROSS COVERAGE]                                          #");
    $display("#    1. cross_mode_payload   (Mode x Payload Len) : %6.2f %%   #", cross_mp_cov);
    $display("#    2. cross_mode_aad       (Mode x AAD Len)     : %6.2f %%   #", cross_ma_cov);
    $display("#    3. cross_mode_key       (Mode x Key Type)    : %6.2f %%   #", cross_mk_cov);
    $display("#    4. cross_mode_verify    (Decrypt x Verify)   : %6.2f %%   #", cross_mv_cov);
    $display("#    5. cross_mode_key_reuse (Mode x Key Reuse)   : %6.2f %%   #", cross_mreuse_cov);
    $display("#------------------------------------------------------------#");
    $display("#  >>> OVERALL TRANSACTION COVERAGE SCORE         : %6.2f %%   #", total_cov);
    $display("##############################################################");
    $display("#             FSM STATE & TRANSITION COVERAGE REPORT         #");
    $display("##############################################################");
    $display("#  Total FSM State Transition Samples: %0d", total_fsm_samples);
    $display("#    1. FSM All 11 States    (IDLE..FINISH)       : %6.2f %%   #", fsm_states_cov);
    $display("#    2. FSM Transitions      (Branch Paths)       : %6.2f %%   #", fsm_trans_cov);
    $display("#  >>> OVERALL FSM COVERAGE SCORE                 : %6.2f %%   #", fsm_cov);
    $display("##############################################################");
    $display("");
  endfunction

endclass
