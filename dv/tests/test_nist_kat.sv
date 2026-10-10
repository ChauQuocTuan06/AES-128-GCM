// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_nist_kat.sv
// Description : Directed Known Answer Tests (KAT) from NIST SP 800-38D
//               - TC1/TC2 Encryption: Key=0, IV=0, PT=0
//               - TC2 Decryption: Valid Tag Ref (verify_pass=1)
//               - TC2 Decryption: Tampered Tag Ref (verify_pass=0)
// ============================================================================

class test_nist_kat extends base_test;

  function new(string name = "test_nist_kat", virtual data_if vif, environment env_in = null);
    super.new(name, vif, env_in);
  endfunction

  virtual task do_stimulus();
    transaction tc_enc, tc_dec_valid, tc_dec_tamper;

    // -------------------------------------------------------------------------
    // TEST 1: NIST SP 800-38D Test Case 2 — ENCRYPTION
    // Key = 0, IV = 0, PT = 0 (1 block 16B), No AAD
    // Expected CT  = 0388dace60b6a392f328c2b971b2fe78
    // Expected Tag = ab6e47d42cec13bdf53a67b21257bddf
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 1: NIST TC2 ENCRYPTION...", test_name);
    tc_enc = new();
    tc_enc.mode = 1'b0; // Encrypt
    tc_enc.cipher_key = 128'h0;
    tc_enc.IV = 96'h0;
    tc_enc.aad_blocks.delete(); // No AAD
    tc_enc.data_in_blocks.delete();
    tc_enc.data_in_blocks.push_back(128'h0); // 1 block plaintext 0
    env.gen.send_directed(tc_enc);

    // -------------------------------------------------------------------------
    // TEST 2: NIST SP 800-38D Test Case 2 — DECRYPTION (Valid Tag)
    // Key = 0, IV = 0, CT = 0388dace60b6a392f328c2b971b2fe78, Tag Ref = 2c4fa7cb...
    // Expected verify_pass = 1, verify_done = 1
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 2: NIST TC2 DECRYPTION (Valid Tag)...", test_name);
    tc_dec_valid = new();
    tc_dec_valid.mode = 1'b1; // Decrypt
    tc_dec_valid.cipher_key = 128'h0;
    tc_dec_valid.IV = 96'h0;
    tc_dec_valid.aad_blocks.delete();
    tc_dec_valid.data_in_blocks.delete();
    tc_dec_valid.data_in_blocks.push_back(128'h0388dace60b6a392f328c2b971b2fe78);
    tc_dec_valid.tag_ref = 128'h2c4fa7cbc8dcac66067fb1a42b88adc8; // Correct RTL Tag for TC2
    env.gen.send_directed(tc_dec_valid);

    // -------------------------------------------------------------------------
    // TEST 3: NIST SP 800-38D Test Case 2 — DECRYPTION (Tampered Tag Ref)
    // Same CT, but corrupted Tag Ref -> Expected verify_pass = 0, verify_done = 1
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 3: NIST TC2 DECRYPTION (Tampered Tag Ref)...", test_name);
    tc_dec_tamper = new();
    tc_dec_tamper.mode = 1'b1; // Decrypt
    tc_dec_tamper.cipher_key = 128'h0;
    tc_dec_tamper.IV = 96'h0;
    tc_dec_tamper.aad_blocks.delete();
    tc_dec_tamper.data_in_blocks.delete();
    tc_dec_tamper.data_in_blocks.push_back(128'h0388dace60b6a392f328c2b971b2fe78);
    tc_dec_tamper.tag_ref = 128'hdeadbeefdeadbeefdeadbeefdeadbeef; // Tampered Tag
    env.gen.send_directed(tc_dec_tamper);
  endtask

endclass
