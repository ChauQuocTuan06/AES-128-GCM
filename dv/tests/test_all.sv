// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_all.sv
// Description : Full Regression Master Test Suite
//               Executes all specialized test suites sequentially in a single run:
//               1. NIST KAT (Encrypt & Decrypt)
//               2. Directed 100% Coverage Suite
//               3. Decryption Integrity Negative Errors
//               4. X-Propagation Negative Tests
//               5. Asynchronous Reset & Recovery Test
//               6. Constrained Random Stress Test
// ============================================================================

class test_all extends base_test;

  function new(string name = "test_all", virtual data_if vif);
    super.new(name, vif);
  endfunction

  virtual task do_stimulus();
    test_nist_kat          t_kat;
    test_coverage_full     t_cov;
    test_decryption_errors t_dec;
    test_x_propagation     t_x;
    test_reset             t_rst;
    test_stress            t_str;

    $display("\n==============================================================");
    $display("  STARTING FULL REGRESSION TEST SUITE (ALL TESTS 1 TO 16)     ");
    $display("==============================================================");

    // 1. NIST Known Answer Tests (Tests 1, 2, 3)
    t_kat = new("test_nist_kat", vif);
    t_kat.env = this.env;
    t_kat.do_stimulus();

    // 2. Full Functional & Cross Coverage Tests (Tests 4 to 9)
    t_cov = new("test_coverage_full", vif);
    t_cov.env = this.env;
    t_cov.do_stimulus();

    // 3. Decryption Error Negative Tests (Tests 10, 11, 12)
    t_dec = new("test_decryption_errors", vif);
    t_dec.env = this.env;
    t_dec.do_stimulus();

    // 4. X-Propagation Negative Tests (Tests 13, 14)
    t_x = new("test_x_propagation", vif);
    t_x.env = this.env;
    t_x.do_stimulus();

    // 5. Asynchronous Reset & Recovery Test (Test 15)
    t_rst = new("test_reset", vif);
    t_rst.env = this.env;
    t_rst.do_stimulus();

    // 6. Constrained Random Stress Test Burst (Test 16)
    t_str = new("test_stress", vif);
    t_str.env = this.env;
    t_str.do_stimulus();
  endtask

endclass
