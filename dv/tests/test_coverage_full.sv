// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_coverage_full.sv
// Description : Directed test suite specifically crafted to achieve 100%
//               Functional & Cross Coverage across all operational modes,
//               key types, AAD length bins, payload length bins, and verify bins.
// ============================================================================

class test_coverage_full extends base_test;

  function new(string name = "test_coverage_full", virtual data_if vif);
    super.new(name, vif);
  endfunction

  virtual task do_stimulus();
    // -------------------------------------------------------------------------
    // TEST 4: PATTERN KEY & MULTI-BLOCK LOW AAD/PAYLOAD — ENCRYPTION
    // Pattern key 0xAAAA..., Multi-block LOW AAD (2 blocks), Short Payload (3 blocks)
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 4: PATTERN KEY & MULTI-BLOCK AAD/PAYLOAD ENCRYPTION...", test_name);
    begin
      transaction tc_pat;
      tc_pat = new();
      tc_pat.mode = 1'b0; // Encrypt
      tc_pat.cipher_key = 128'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
      tc_pat.IV = 96'hcafebeeff00d123456789abc;
      tc_pat.aad_blocks.delete();
      tc_pat.aad_blocks.push_back(128'h11112222333344445555666677778888);
      tc_pat.aad_blocks.push_back(128'h9999aaaabbbbccccddddeeeeffff0000);
      tc_pat.data_in_blocks.delete();
      tc_pat.data_in_blocks.push_back(128'h0123456789abcdef0123456789abcdef);
      tc_pat.data_in_blocks.push_back(128'hfedcba9876543210fedcba9876543210);
      tc_pat.data_in_blocks.push_back(128'h5555555555555555aaaaaaaaaaaaaaaa);
      env.gen.send_directed(tc_pat);
    end

    // -------------------------------------------------------------------------
    // TEST 5: ALL-ONES KEY & MULTI-BLOCK HI AAD & LONG PAYLOAD — ENCRYPTION
    // Key 0xFFFF..., Multi-block HI AAD (5 blocks), Long Payload (9 blocks)
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 5: ALL-ONES KEY & LONG PAYLOAD ENCRYPTION...", test_name);
    begin
      transaction tc_ones;
      tc_ones = new();
      tc_ones.mode = 1'b0; // Encrypt
      tc_ones.cipher_key = 128'hffffffffffffffffffffffffffffffff;
      tc_ones.IV = 96'habcdef0123456789deadbeef;
      tc_ones.aad_blocks.delete();
      for (int a = 0; a < 5; a++) begin
        tc_ones.aad_blocks.push_back({32'(a+1), 32'(a+2), 32'(a+3), 32'(a+4)});
      end
      tc_ones.data_in_blocks.delete();
      for (int p = 0; p < 9; p++) begin
        tc_ones.data_in_blocks.push_back({32'(p*10), 32'(p*10+1), 32'(p*10+2), 32'(p*10+3)});
      end
      env.gen.send_directed(tc_ones);
    end

    // -------------------------------------------------------------------------
    // TEST 6: SINGLE-BLOCK AAD & MEDIUM PAYLOAD — DECRYPTION
    // Random Key, Single AAD (1 block), Medium Payload (5 blocks)
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 6: SINGLE-BLOCK AAD & MEDIUM PAYLOAD DECRYPTION...", test_name);
    begin
      transaction tc_sb_aad;
      tc_sb_aad = new();
      tc_sb_aad.mode = 1'b1; // Decrypt
      tc_sb_aad.cipher_key = 128'h00112233445566778899aabbccddeeff;
      tc_sb_aad.IV = 96'h112233445566778899aabbcc;
      tc_sb_aad.aad_blocks.delete();
      tc_sb_aad.aad_blocks.push_back(128'haabbccddeeff00112233445566778899);
      tc_sb_aad.data_in_blocks.delete();
      for (int p = 0; p < 5; p++) begin
        tc_sb_aad.data_in_blocks.push_back({32'(p), 32'(p+1), 32'(p+2), 32'(p+3)});
      end
      tc_sb_aad.tag_ref = 128'h0123456789abcdef0123456789abcdef;
      env.gen.send_directed(tc_sb_aad);
    end

    // -------------------------------------------------------------------------
    // TEST 7: PATTERN KEY & MULTI-BLOCK AAD — DECRYPTION
    // Pattern Key 0xAAAA..., Multi-block LOW AAD (3 blocks), Short Payload (2 blocks)
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 7: PATTERN KEY & MULTI-BLOCK AAD DECRYPTION...", test_name);
    begin
      transaction tc_pat_dec;
      tc_pat_dec = new();
      tc_pat_dec.mode = 1'b1; // Decrypt
      tc_pat_dec.cipher_key = 128'haaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa;
      tc_pat_dec.IV = 96'hfedcba9876543210deadbeef;
      tc_pat_dec.aad_blocks.delete();
      for (int a = 0; a < 3; a++) begin
        tc_pat_dec.aad_blocks.push_back({32'(a+10), 32'(a+20), 32'(a+30), 32'(a+40)});
      end
      tc_pat_dec.data_in_blocks.delete();
      tc_pat_dec.data_in_blocks.push_back(128'h0123456789abcdef0123456789abcdef);
      tc_pat_dec.data_in_blocks.push_back(128'hfedcba9876543210fedcba9876543210);
      tc_pat_dec.tag_ref = 128'h112233445566778899aabbccddeeff00;
      env.gen.send_directed(tc_pat_dec);
    end

    // -------------------------------------------------------------------------
    // TEST 8: ALL-ONES KEY & MULTI-BLOCK HI AAD & LONG PAYLOAD — DECRYPTION
    // Key 0xFFFF..., Multi-block HI AAD (6 blocks), Long Payload (10 blocks)
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 8: ALL-ONES KEY & LONG PAYLOAD DECRYPTION...", test_name);
    begin
      transaction tc_ones_dec;
      tc_ones_dec = new();
      tc_ones_dec.mode = 1'b1; // Decrypt
      tc_ones_dec.cipher_key = 128'hffffffffffffffffffffffffffffffff;
      tc_ones_dec.IV = 96'h9876543210fedcbacafebeef;
      tc_ones_dec.aad_blocks.delete();
      for (int a = 0; a < 6; a++) begin
        tc_ones_dec.aad_blocks.push_back({32'(a*2), 32'(a*2+1), 32'(a*2+2), 32'(a*2+3)});
      end
      tc_ones_dec.data_in_blocks.delete();
      for (int p = 0; p < 10; p++) begin
        tc_ones_dec.data_in_blocks.push_back({32'(p*5), 32'(p*5+1), 32'(p*5+2), 32'(p*5+3)});
      end
      tc_ones_dec.tag_ref = 128'hffeeddccbbaa99887766554433221100;
      env.gen.send_directed(tc_ones_dec);
    end

    // -------------------------------------------------------------------------
    // TEST 9: SINGLE-BLOCK AAD & SHORT PAYLOAD — ENCRYPTION
    // (Bổ sung bin cuối cùng: <ENCRYPT, SINGLE_BLOCK AAD> để đạt 100% COVERAGE)
    // -------------------------------------------------------------------------
    $display("\n>>> [%s] RUNNING TEST 9: SINGLE-BLOCK AAD & SHORT PAYLOAD ENCRYPTION (100%% COVERAGE TARGET)...", test_name);
    begin
      transaction tc_sb_enc;
      tc_sb_enc = new();
      tc_sb_enc.mode = 1'b0; // Encrypt
      tc_sb_enc.cipher_key = 128'h1234567890abcdef1234567890abcdef;
      tc_sb_enc.IV = 96'h9876543210fedcba98765432;
      tc_sb_enc.aad_blocks.delete();
      tc_sb_enc.aad_blocks.push_back(128'h0f1e2d3c4b5a69788796a5b4c3d2e1f0); // 1 block AAD!
      tc_sb_enc.data_in_blocks.delete();
      tc_sb_enc.data_in_blocks.push_back(128'ha0b1c2d3e4f5061728394a5b6c7d8e9f);
      tc_sb_enc.data_in_blocks.push_back(128'hf0e1d2c3b4a5968778695a4b3c2d1e0f);
      tc_sb_enc.data_in_blocks.push_back(128'h00112233445566778899aabbccddeeff);
      env.gen.send_directed(tc_sb_enc);
    end
  endtask

endclass
