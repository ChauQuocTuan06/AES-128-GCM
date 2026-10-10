// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_backpressure.sv
// Description : Flow-Control & Upstream Stall (Backpressure) Verification
//               Validates that DUT handshakes (AAD_ready, data_ready) handle
//               intermittent multi-cycle stalls without dropping or corrupting data.
// ============================================================================

class test_backpressure extends base_test;

  function new(string name = "test_backpressure", virtual data_if vif, environment env_in = null);
    super.new(name, vif, env_in);
  endfunction

  virtual task do_stimulus();
    transaction tc_bp_enc, tc_bp_dec;

    // -------------------------------------------------------------------------
    // TEST 1: ENCRYPT with multi-cycle stalls between blocks
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING ENCRYPT WITH INTERMITTENT INPUT DELAYS...", test_name);
    tc_bp_enc = new();
    tc_bp_enc.mode = 1'b0; // Encrypt
    tc_bp_enc.inject_delay = 1'b1; // Trigger driver stall simulation
    tc_bp_enc.cipher_key = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    tc_bp_enc.IV = 96'hf0f1f2f3f4f5f6f7f8f9fafb;
    tc_bp_enc.aad_blocks.delete();
    tc_bp_enc.aad_blocks.push_back(128'h000102030405060708090a0b0c0d0e0f);
    tc_bp_enc.aad_blocks.push_back(128'h101112131415161718191a1b1c1d1e1f);
    tc_bp_enc.data_in_blocks.delete();
    tc_bp_enc.data_in_blocks.push_back(128'h202122232425262728292a2b2c2d2e2f);
    tc_bp_enc.data_in_blocks.push_back(128'h303132333435363738393a3b3c3d3e3f);
    tc_bp_enc.data_in_blocks.push_back(128'h404142434445464748494a4b4c4d4e4f);
    env.gen.send_directed(tc_bp_enc);

    // -------------------------------------------------------------------------
    // TEST 2: DECRYPT with multi-cycle stalls between blocks
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING DECRYPT WITH INTERMITTENT INPUT DELAYS...", test_name);
    tc_bp_dec = new();
    tc_bp_dec.mode = 1'b1; // Decrypt
    tc_bp_dec.inject_delay = 1'b1;
    tc_bp_dec.cipher_key = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    tc_bp_dec.IV = 96'hf0f1f2f3f4f5f6f7f8f9fafb;
    tc_bp_dec.aad_blocks.delete();
    tc_bp_dec.aad_blocks.push_back(128'h000102030405060708090a0b0c0d0e0f);
    tc_bp_dec.data_in_blocks.delete();
    tc_bp_dec.data_in_blocks.push_back(128'h505152535455565758595a5b5c5d5e5f);
    tc_bp_dec.data_in_blocks.push_back(128'h606162636465666768696a6b6c6d6e6f);
    tc_bp_dec.tag_ref = 128'h112233445566778899aabbccddeeff00;
    env.gen.send_directed(tc_bp_dec);
  endtask

endclass
