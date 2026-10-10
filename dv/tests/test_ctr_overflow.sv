// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_ctr_overflow.sv
// Description : CTR Counter Boundary & ALL_ONES_IV Corner-Case Verification
//               Validates that maximum IV (all 1s) is handled correctly by the
//               counter generation unit without premature overflow.
// ============================================================================

class test_ctr_overflow extends base_test;

  function new(string name = "test_ctr_overflow", virtual data_if vif, environment env_in = null);
    super.new(name, vif, env_in);
  endfunction

  virtual task do_stimulus();
    transaction tc_max_iv;

    // -------------------------------------------------------------------------
    // TEST 1: ALL-ONES IV (96'hFFFFFFFFFFFFFFFFFFFFFFFF)
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING ALL-ONES IV CORNER-CASE TEST...", test_name);
    tc_max_iv = new();
    tc_max_iv.mode = 1'b0; // Encrypt
    tc_max_iv.cipher_key = 128'hdeadbeefdeadbeefdeadbeefdeadbeef;
    tc_max_iv.IV = 96'hffffffffffffffffffffffff; // ALL-ONES IV
    tc_max_iv.aad_blocks.delete();
    tc_max_iv.aad_blocks.push_back(128'h0123456789abcdef0123456789abcdef);
    tc_max_iv.data_in_blocks.delete();
    tc_max_iv.data_in_blocks.push_back(128'hffff0000ffff0000ffff0000ffff0000);
    tc_max_iv.data_in_blocks.push_back(128'h0000ffff0000ffff0000ffff0000ffff);
    env.gen.send_directed(tc_max_iv);

    $display(">>> [%s] ALL-ONES IV TEST COMPLETED SUCCESSFULLY!", test_name);
  endtask

endclass
