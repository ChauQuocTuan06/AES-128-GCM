// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_decryption_errors.sv
// Description : Negative test suite validating Decryption Integrity & Authentication
//               Checking that tampered Ciphertext, tampered AAD, or tampered Tag
//               strictly results in verify_pass = 0 and verify_done = 1.
// ============================================================================

class test_decryption_errors extends base_test;

  function new(string name = "test_decryption_errors", virtual data_if vif, environment env_in = null);
    super.new(name, vif, env_in);
  endfunction

  virtual task do_stimulus();
    // -------------------------------------------------------------------------
    // TEST 10: DECRYPTION NEGATIVE CASE 1 — TAMPERED CIPHERTEXT (Bản mã bị sửa đổi)
    // Ciphertext bị lệch 1 bit so với bản mã hợp lệ -> verify_pass phải là 0
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 10: DECRYPTION ERROR — TAMPERED CIPHERTEXT...", test_name);
    begin
      transaction tc_tamper_ct;
      tc_tamper_ct = new();
      tc_tamper_ct.mode = 1'b1; // Decrypt
      tc_tamper_ct.cipher_key = 128'h0;
      tc_tamper_ct.IV = 96'h0;
      tc_tamper_ct.aad_blocks.delete();
      tc_tamper_ct.data_in_blocks.delete();
      // Bản mã gốc: 0388dace60b6a392f328c2b971b2fe78 -> Làm sai bit cuối thành 79
      tc_tamper_ct.data_in_blocks.push_back(128'h0388dace60b6a392f328c2b971b2fe79);
      tc_tamper_ct.tag_ref = 128'h2c4fa7cbc8dcac66067fb1a42b88adc8; // Tag của bản gốc
      env.gen.send_directed(tc_tamper_ct);
    end

    // -------------------------------------------------------------------------
    // TEST 11: DECRYPTION NEGATIVE CASE 2 — TAMPERED AAD (Dữ liệu AAD bị sửa đổi)
    // AAD bị sửa đổi nhưng Tag Ref giữ nguyên -> verify_pass phải là 0
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 11: DECRYPTION ERROR — TAMPERED AAD...", test_name);
    begin
      transaction tc_tamper_aad;
      tc_tamper_aad = new();
      tc_tamper_aad.mode = 1'b1; // Decrypt
      tc_tamper_aad.cipher_key = 128'h00112233445566778899aabbccddeeff;
      tc_tamper_aad.IV = 96'h112233445566778899aabbcc;
      tc_tamper_aad.aad_blocks.delete();
      tc_tamper_aad.aad_blocks.push_back(128'hbad0bad0bad0bad0bad0bad0bad0bad0); // AAD sai
      tc_tamper_aad.data_in_blocks.delete();
      tc_tamper_aad.data_in_blocks.push_back(128'h0123456789abcdef0123456789abcdef);
      tc_tamper_aad.tag_ref = 128'h2c4fa7cbc8dcac66067fb1a42b88adc8; // Tag không khớp AAD
      env.gen.send_directed(tc_tamper_aad);
    end

    // -------------------------------------------------------------------------
    // TEST 12: DECRYPTION NEGATIVE CASE 3 — BOTH CIPHERTEXT & AAD TAMPERED
    // Cả bản mã và AAD đều bị hỏng -> verify_pass phải là 0
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 12: DECRYPTION ERROR — BOTH CIPHERTEXT & AAD TAMPERED...", test_name);
    begin
      transaction tc_tamper_both;
      tc_tamper_both = new();
      tc_tamper_both.mode = 1'b1; // Decrypt
      tc_tamper_both.cipher_key = 128'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
      tc_tamper_both.IV = 96'hfedcba9876543210deadbeef;
      tc_tamper_both.aad_blocks.delete();
      tc_tamper_both.aad_blocks.push_back(128'hdeaddeaddeaddeaddeaddeaddeaddead);
      tc_tamper_both.data_in_blocks.delete();
      tc_tamper_both.data_in_blocks.push_back(128'hbeefbeefbeefbeefbeefbeefbeefbeef);
      tc_tamper_both.tag_ref = 128'h112233445566778899aabbccddeeff00;
      env.gen.send_directed(tc_tamper_both);
    end
  endtask

endclass
