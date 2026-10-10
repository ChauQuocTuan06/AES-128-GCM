// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_enc_dec_chain.sv
// Description : Chained End-to-End Encrypt -> Decrypt Verification
//               Validates that Ciphertext and Tag produced during Encryption
//               can be fed into Decryption to cleanly recover the original
//               Plaintext with verify_pass = 1.
// ============================================================================

class test_enc_dec_chain extends base_test;

  function new(string name = "test_enc_dec_chain", virtual data_if vif, environment env_in = null);
    super.new(name, vif, env_in);
  endfunction

  virtual task do_stimulus();
    transaction   tc_enc, tc_dec;
    byte unsigned c_key[16], c_iv[12], c_aad[256], c_pt[256], c_ct[256], c_tag[16];
    logic [127:0] key_val;
    logic [95:0]  iv_val;
    logic [127:0] aad_val;
    logic [127:0] pt_val0, pt_val1;
    logic [127:0] ct_val0, ct_val1;
    logic [127:0] tag_val;
    int           aad_len, pt_len;

    key_val = 128'h0123456789abcdef0123456789abcdef;
    iv_val  = 96'habcdef0123456789deadbeef;
    aad_val = 128'hfeedfacecafebeefdeadbeef12345678;
    pt_val0 = 128'h112233445566778899aabbccddeeff00;
    pt_val1 = 128'haabbccddeeff00112233445566778899;

    // Pack into bytes for Golden Model calculation
    for (int i = 0; i < 16; i++) begin
      c_key[i]  = key_val[127 - 8*i -: 8];
      c_aad[i]  = aad_val[127 - 8*i -: 8];
      c_pt[i]   = pt_val0[127 - 8*i -: 8];
      c_pt[16+i]= pt_val1[127 - 8*i -: 8];
    end
    for (int i = 0; i < 12; i++) begin
      c_iv[i] = iv_val[95 - 8*i -: 8];
    end
    aad_len = 16;
    pt_len  = 32;

    // Call Golden Model to get expected CT and Tag
    c_aes128_gcm_encrypt(c_key, c_iv, c_aad, aad_len, c_pt, pt_len, c_ct, c_tag, 1);

    for (int i = 0; i < 16; i++) begin
      ct_val0[127 - 8*i -: 8] = c_ct[i];
      ct_val1[127 - 8*i -: 8] = c_ct[16+i];
      tag_val[127 - 8*i -: 8] = c_tag[i];
    end

    // -------------------------------------------------------------------------
    // STEP 1: ENCRYPT PLAINTEXT
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] STEP 1: ENCRYPTING ORIGINAL PLAINTEXT...", test_name);
    tc_enc = new();
    tc_enc.mode = 1'b0; // Encrypt
    tc_enc.cipher_key = key_val;
    tc_enc.IV = iv_val;
    tc_enc.aad_blocks.push_back(aad_val);
    tc_enc.data_in_blocks.push_back(pt_val0);
    tc_enc.data_in_blocks.push_back(pt_val1);
    env.gen.send_directed(tc_enc);

    // -------------------------------------------------------------------------
    // STEP 2: DECRYPT RESULTING CIPHERTEXT & TAG
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] STEP 2: DECRYPTING CIPHERTEXT & VALIDATING RECOVERED PLAINTEXT...", test_name);
    tc_dec = new();
    tc_dec.mode = 1'b1; // Decrypt
    tc_dec.cipher_key = key_val;
    tc_dec.IV = iv_val;
    tc_dec.aad_blocks.push_back(aad_val);
    tc_dec.data_in_blocks.push_back(ct_val0);
    tc_dec.data_in_blocks.push_back(ct_val1);
    tc_dec.tag_ref = tag_val; // Use Tag produced by Encryption
    env.gen.send_directed(tc_dec);

    $display(">>> [%s] CHAINED ENCRYPT-DECRYPT VERIFICATION COMPLETED!", test_name);
  endtask

endclass
