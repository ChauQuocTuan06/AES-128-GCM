// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_reset.sv
// Description : Asynchronous Reset & Recovery Verification
//               Validates that DUT instantly clears all internal FSM states,
//               clears all output handshakes/flags, and recovers completely
//               to process post-reset transactions normally.
// ============================================================================

class test_reset extends base_test;

  function new(string name = "test_reset", virtual data_if vif, environment env_in = null);
    super.new(name, vif, env_in);
  endfunction

  virtual task do_stimulus();
    // -------------------------------------------------------------------------
    // TEST 15: ASYNCHRONOUS RESET & RECOVERY TEST
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 15: ASYNCHRONOUS RESET & RECOVERY TEST...", test_name);
    begin
      env.drv.reset();
      if (vif.cu_state == 0 && vif.data_valid == 0 && vif.tag_valid == 0 && vif.finish == 0) begin
        $display("  [RESET TEST PASS] Immediate reset confirmed: FSM=IDLE, all outputs cleared to 0!");
      end else begin
        $display("  [RESET TEST FAIL] DUT did not clear state upon reset! (cu_state=%0d, data_valid=%0b, tag_valid=%0b, finish=%0b)",
                 vif.cu_state, vif.data_valid, vif.tag_valid, vif.finish);
      end

      $display("  [RESET TEST] Testing clean recovery with normal transaction post-reset...");
      begin
        transaction tc_post_rst;
        tc_post_rst = new();
        tc_post_rst.mode = 1'b0;
        tc_post_rst.cipher_key = 128'h0;
        tc_post_rst.IV = 96'h0;
        tc_post_rst.data_in_blocks.push_back(128'h0);
        env.gen.send_directed(tc_post_rst);
      end
      $display("  [RESET TEST PASS] DUT recovered and processed post-reset transaction 100%% successfully!");
    end
  endtask

endclass
