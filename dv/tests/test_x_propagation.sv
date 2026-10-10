// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_x_propagation.sv
// Description : X-Propagation Negative Test suite
//               Injects 4-state unknown 'X' on primary inputs (data_in, cipher_key)
//               and validates that DUT outputs (data_out, tag / GHASH) correctly
//               propagate 'X' without masking or corrupting states.
// ============================================================================

class test_x_propagation extends base_test;

  function new(string name = "test_x_propagation", virtual data_if vif, environment env_in = null);
    super.new(name, vif, env_in);
  endfunction

  virtual task do_stimulus();
    // -------------------------------------------------------------------------
    // TEST 13: X-PROPAGATION NEGATIVE TEST — DATA IN = ALL 'X'
    // Kỳ vọng: Khi data_in là toàn X, data_out phải lan truyền X và GHASH/TAG phải lan truyền X
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 13: X-PROPAGATION TEST — DATA IN = ALL 'X'...", test_name);
    begin
      transaction tc_x_data;
      tc_x_data = new();
      tc_x_data.is_x_test = 1'b1;
      tc_x_data.mode = 1'b0; // Encrypt
      tc_x_data.cipher_key = 128'h0123456789abcdef0123456789abcdef;
      tc_x_data.IV = 96'habcdef0123456789deadbeef;
      tc_x_data.aad_blocks.delete();
      tc_x_data.data_in_blocks.delete();
      tc_x_data.data_in_blocks.push_back('x); // 128-bit all 'X'
      env.gen.send_directed(tc_x_data);
    end

    // -------------------------------------------------------------------------
    // TEST 14: X-PROPAGATION NEGATIVE TEST — CIPHER KEY = ALL 'X'
    // Kỳ vọng: Khi cipher_key là toàn X, data_out phải lan truyền X và GHASH/TAG phải lan truyền X
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 14: X-PROPAGATION TEST — CIPHER KEY = ALL 'X'...", test_name);
    begin
      transaction tc_x_key;
      tc_x_key = new();
      tc_x_key.is_x_test = 1'b1;
      tc_x_key.mode = 1'b0; // Encrypt
      tc_x_key.cipher_key = 'x; // 128-bit all 'X' key
      tc_x_key.IV = 96'habcdef0123456789deadbeef;
      tc_x_key.aad_blocks.delete();
      tc_x_key.data_in_blocks.delete();
      tc_x_key.data_in_blocks.push_back(128'h0123456789abcdef0123456789abcdef);
      env.gen.send_directed(tc_x_key);
    end
  endtask

endclass
