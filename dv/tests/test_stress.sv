// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_stress.sv
// Description : Stress Test suite
//               Executes a heavy burst of 8 back-to-back randomized transactions
//               with constrained random keys, IVs, AAD blocks, and payloads
//               to stress DUT pipelines, FIFO buffers, and GHASH multipliers.
// ============================================================================

class test_stress extends base_test;

  function new(string name = "test_stress", virtual data_if vif, environment env_in = null);
    super.new(name, vif, env_in);
  endfunction

  virtual task do_stimulus();
    // -------------------------------------------------------------------------
    // TEST 16: STRESS TEST (BURST OF BACK-TO-BACK CONSTRAINED RANDOM TRANSACTIONS)
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 16: STRESS TEST (BURST OF 8 BACK-TO-BACK TRANSACTIONS)...", test_name);
    env.gen.loop = 8;
    env.gen.run();
  endtask

endclass
