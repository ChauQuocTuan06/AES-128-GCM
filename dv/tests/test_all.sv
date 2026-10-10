// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_all.sv
// Description : Full Regression Master Test Suite
//               Executes all specialized test suites sequentially in a single run:
//               1. NIST KAT (Encrypt & Decrypt)
//               2. Directed 100% Coverage Suite
//               3. Key Reuse (Skipping KEY_EXPANSION)
//               4. Chained End-to-End Encrypt -> Decrypt
//               5. Backpressure / Handshake Stalls
//               6. ALL_ONES_IV & Counter Boundary
//               7. Decryption Integrity Negative Errors
//               8. X-Propagation Negative Tests
//               9. Asynchronous Reset & Recovery Test
//               10. Constrained Random Stress Test Burst
// ============================================================================

class test_all extends base_test;

  function new(string name = "test_all", virtual data_if vif);
    super.new(name, vif);
  endfunction

  virtual task do_stimulus();
    test_nist_kat          t_kat;
    test_coverage_full     t_cov;
    test_reuse_key         t_reuse;
    test_enc_dec_chain     t_chain;
    test_backpressure      t_bp;
    test_ctr_overflow      t_max_iv;
    test_decryption_errors t_dec;
    test_x_propagation     t_x;
    test_reset             t_rst;
    test_stress            t_str;

    $display("\n==============================================================");
    $display("  STARTING FULL REGRESSION TEST SUITE (COMPREHENSIVE RUN)      ");
    $display("==============================================================");

    // 1. NIST Known Answer Tests
    t_kat = new("test_nist_kat", vif, this.env);
    t_kat.do_stimulus();

    // 2. Full Functional & Cross Coverage Tests
    t_cov = new("test_coverage_full", vif, this.env);
    t_cov.do_stimulus();

    // 3. Key Reuse Verification (IDLE -> WAIT_AAD & IDLE -> WAIT_TAG_REF)
    t_reuse = new("test_reuse_key", vif, this.env);
    t_reuse.do_stimulus();

    // 4. Chained End-to-End Encrypt -> Decrypt
    t_chain = new("test_enc_dec_chain", vif, this.env);
    t_chain.do_stimulus();

    // 5. Backpressure / Handshake Stalls
    t_bp = new("test_backpressure", vif, this.env);
    t_bp.do_stimulus();

    // 6. ALL_ONES_IV & Counter Boundary
    t_max_iv = new("test_ctr_overflow", vif, this.env);
    t_max_iv.do_stimulus();

    // 7. Decryption Error Negative Tests
    t_dec = new("test_decryption_errors", vif, this.env);
    t_dec.do_stimulus();

    // 8. X-Propagation Negative Tests
    t_x = new("test_x_propagation", vif, this.env);
    t_x.do_stimulus();

    // 9. Asynchronous Reset & Recovery Test
    t_rst = new("test_reset", vif, this.env);
    t_rst.do_stimulus();

    // 10. Constrained Random Stress Test Burst
    t_str = new("test_stress", vif, this.env);
    t_str.do_stimulus();
  endtask

endclass
