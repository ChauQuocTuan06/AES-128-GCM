// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : coverage.sv
// Description : Functional Coverage and Cross Coverage Collector for AES-128-GCM
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

  int total_samples;

  // =========================================================================
  // Covergroup Definition
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

    // 3. Phân loại Vector Khởi tạo IV
    cp_iv_type: coverpoint cov_iv {
      bins ZERO_IV         = {96'h0};
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

    // =======================================================================
    // Cross Coverage
    // =======================================================================
    // Cross 1: Mode x Payload Length (Bảo đảm kiểm tra đủ các cỡ payload ở cả 2 mode)
    cross_mode_payload: cross cp_mode, cp_payload_length;

    // Cross 2: Mode x AAD Length (Bảo đảm kiểm tra có/không có AAD ở cả 2 mode)
    cross_mode_aad: cross cp_mode, cp_aad_length;

    // Cross 3: Mode x Key Type (Bảo đảm cả khóa 0 và khóa ngẫu nhiên cho cả 2 mode)
    cross_mode_key: cross cp_mode, cp_key_type;

    // Cross 4: Mode x Verify Pass (Chỉ có ý nghĩa khi Mode = DECRYPT)
    cross_mode_verify: cross cp_mode, cp_verify_pass {
      ignore_bins enc_bins = binsof(cp_mode) intersect {1'b0};
    }

  endgroup

  // =========================================================================
  // Constructor
  // =========================================================================
  function new();
    cg_aes_gcm = new();
    total_samples = 0;
  endfunction

  // =========================================================================
  // Sample Task
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

    cg_aes_gcm.sample();
    total_samples++;
  endfunction

  // =========================================================================
  // Report Function
  // =========================================================================
  function void report();
    real total_cov;
    real cp_mode_cov, cp_key_cov, cp_iv_cov, cp_aad_cov, cp_data_cov, cp_ver_cov;
    real cross_mp_cov, cross_ma_cov, cross_mk_cov, cross_mv_cov;

    total_cov    = cg_aes_gcm.get_coverage();
    cp_mode_cov  = cg_aes_gcm.cp_mode.get_coverage();
    cp_key_cov   = cg_aes_gcm.cp_key_type.get_coverage();
    cp_iv_cov    = cg_aes_gcm.cp_iv_type.get_coverage();
    cp_aad_cov   = cg_aes_gcm.cp_aad_length.get_coverage();
    cp_data_cov  = cg_aes_gcm.cp_payload_length.get_coverage();
    cp_ver_cov   = cg_aes_gcm.cp_verify_pass.get_coverage();

    cross_mp_cov = cg_aes_gcm.cross_mode_payload.get_coverage();
    cross_ma_cov = cg_aes_gcm.cross_mode_aad.get_coverage();
    cross_mk_cov = cg_aes_gcm.cross_mode_key.get_coverage();
    cross_mv_cov = cg_aes_gcm.cross_mode_verify.get_coverage();

    $display("");
    $display("##############################################################");
    $display("#             FUNCTIONAL & CROSS COVERAGE REPORT             #");
    $display("##############################################################");
    $display("#  Total Sampled Transactions: %0d", total_samples);
    $display("#------------------------------------------------------------#");
    $display("#  [COVERPOINTS]                                             #");
    $display("#    1. cp_mode              (ENCRYPT / DECRYPT)  : %6.2f %%   #", cp_mode_cov);
    $display("#    2. cp_key_type          (Zero / Random)      : %6.2f %%   #", cp_key_cov);
    $display("#    3. cp_iv_type           (Zero / Random)      : %6.2f %%   #", cp_iv_cov);
    $display("#    4. cp_aad_length        (0, 1, 2..4, 5..8)   : %6.2f %%   #", cp_aad_cov);
    $display("#    5. cp_payload_length    (1, 2..4, 5..8, 9..12):%6.2f %%   #", cp_data_cov);
    $display("#    6. cp_verify_pass       (PASS=1, FAIL=0)     : %6.2f %%   #", cp_ver_cov);
    $display("#------------------------------------------------------------#");
    $display("#  [CROSS COVERAGE]                                          #");
    $display("#    1. cross_mode_payload   (Mode x Payload Len) : %6.2f %%   #", cross_mp_cov);
    $display("#    2. cross_mode_aad       (Mode x AAD Len)     : %6.2f %%   #", cross_ma_cov);
    $display("#    3. cross_mode_key       (Mode x Key Type)    : %6.2f %%   #", cross_mk_cov);
    $display("#    4. cross_mode_verify    (Decrypt x Verify)   : %6.2f %%   #", cross_mv_cov);
    $display("#------------------------------------------------------------#");
    $display("#  >>> OVERALL FUNCTIONAL COVERAGE SCORE          : %6.2f %%   #", total_cov);
    $display("##############################################################");
    $display("");
  endfunction

endclass
