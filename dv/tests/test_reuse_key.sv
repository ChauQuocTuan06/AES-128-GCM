// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_reuse_key.sv
// Description : Key Reuse Verification (Skipping KEY_EXPANSION)
//               Validates FSM transitions IDLE -> WAIT_AAD (Encrypt)
//               and IDLE -> WAIT_TAG_REF (Decrypt) when H and round_key
//               are retained in hardware cache.
// ============================================================================

class test_reuse_key extends base_test;

  function new(string name = "test_reuse_key", virtual data_if vif, environment env_in = null);
    super.new(name, vif, env_in);
  endfunction

  virtual task do_stimulus();
    logic [127:0] master_key;
    transaction   tc1, tc2, tc3;

    master_key = 128'h00112233445566778899aabbccddeeff;

    // -------------------------------------------------------------------------
    // TRANSACTION 1: ENCRYPT with new key load (load_key = 1)
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] TRANS 1: Initial ENCRYPT with new Master Key...", test_name);
    tc1 = new();
    tc1.mode = 1'b0; // Encrypt
    tc1.cipher_key = master_key;
    tc1.IV = 96'h112233445566778899aabbcc;
    tc1.skip_key = 1'b0; // Load key into hardware
    tc1.aad_blocks.delete();
    tc1.aad_blocks.push_back(128'ha0b0c0d0e0f00112233445566778899a);
    tc1.data_in_blocks.delete();
    tc1.data_in_blocks.push_back(128'h0123456789abcdef0123456789abcdef);
    tc1.data_in_blocks.push_back(128'hfedcba9876543210fedcba9876543210);
    env.gen.send_directed(tc1);

    // -------------------------------------------------------------------------
    // TRANSACTION 2: ENCRYPT REUSING KEY (skip_key = 1, load_key = 0)
    // Triggers FSM branch IDLE -> WAIT_AAD directly!
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] TRANS 2: ENCRYPT REUSING CACHED KEY (IDLE -> WAIT_AAD)...", test_name);
    tc2 = new();
    tc2.mode = 1'b0; // Encrypt
    tc2.cipher_key = master_key;
    tc2.IV = 96'h99887766554433221100ffee; // New IV
    tc2.skip_key = 1'b1; // Skip load_key!
    tc2.aad_blocks.delete();
    tc2.aad_blocks.push_back(128'h123456789abcdef0123456789abcdef0);
    tc2.data_in_blocks.delete();
    tc2.data_in_blocks.push_back(128'haaaaaaaabbbbbbbbccccccccdddddddd);
    env.gen.send_directed(tc2);

    // -------------------------------------------------------------------------
    // TRANSACTION 3: DECRYPT REUSING KEY (skip_key = 1, load_key = 0)
    // Triggers FSM branch IDLE -> WAIT_TAG_REF directly!
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] TRANS 3: DECRYPT REUSING CACHED KEY (IDLE -> WAIT_TAG_REF)...", test_name);
    tc3 = new();
    tc3.mode = 1'b1; // Decrypt
    tc3.cipher_key = master_key;
    tc3.IV = 96'hcafebeeff00d123456789abc; // New IV
    tc3.skip_key = 1'b1; // Skip load_key!
    tc3.aad_blocks.delete();
    tc3.aad_blocks.push_back(128'hffff0000ffff0000ffff0000ffff0000);
    tc3.data_in_blocks.delete();
    tc3.data_in_blocks.push_back(128'h11111111222222223333333344444444);
    tc3.tag_ref = 128'h1234567890abcdef1234567890abcdef; // Test tag
    env.gen.send_directed(tc3);
  endtask

endclass
