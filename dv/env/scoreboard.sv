// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : scoreboard.sv
// Description : Scoreboard utilizing C Golden Reference Model via DPI-C,
//               sampling coverage, and verifying X-Propagation Negative Tests
// ============================================================================

class scoreboard;

  mailbox  mon2scb;
  coverage cov;

  int match_count = 0;
  int error_count = 0;
  int total_trans = 0;

  // =========================================================================
  // Constructor
  // =========================================================================
  function new(mailbox mon2scb, coverage cov = null);
    this.mon2scb = mon2scb;
    this.cov     = cov;
  endfunction

  // =========================================================================
  // Helper Conversion Functions (Big-Endian Packing / Unpacking)
  // =========================================================================
  function automatic void bit128_to_bytes(input logic [127:0] val, output byte unsigned b[16]);
    for (int i = 0; i < 16; i++) begin
      b[i] = val[127 - 8*i -: 8];
    end
  endfunction

  function automatic logic [127:0] bytes_to_bit128(input byte unsigned b[16]);
    logic [127:0] val = '0;
    for (int i = 0; i < 16; i++) begin
      val[127 - 8*i -: 8] = b[i];
    end
    return val;
  endfunction

  function automatic void bit96_to_bytes(input logic [95:0] val, output byte unsigned b[12]);
    for (int i = 0; i < 12; i++) begin
      b[i] = val[95 - 8*i -: 8];
    end
  endfunction

  function automatic void queue_to_bytes(input logic [127:0] q[$], output byte unsigned buf_out[256], output int num_bytes);
    num_bytes = q.size() * 16;
    for (int i = 0; i < 256; i++) buf_out[i] = 8'h00;
    for (int blk = 0; blk < q.size(); blk++) begin
      for (int i = 0; i < 16; i++) begin
        buf_out[blk*16 + i] = q[blk][127 - 8*i -: 8];
      end
    end
  endfunction

  function automatic void bytes_to_queue(input byte unsigned buf_in[256], input int num_bytes, output logic [127:0] q[$]);
    int num_blocks = (num_bytes + 15) / 16;
    q.delete();
    for (int blk = 0; blk < num_blocks; blk++) begin
      logic [127:0] val = '0;
      for (int i = 0; i < 16; i++) begin
        if (blk*16 + i < num_bytes)
          val[127 - 8*i -: 8] = buf_in[blk*16 + i];
      end
      q.push_back(val);
    end
  endfunction

  // =========================================================================
  // Main Scoreboard Run Task
  // =========================================================================
  task run();
    forever begin
      transaction tr;
      logic [127:0] exp_data_out[$];
      logic [127:0] exp_tag;
      bit           exp_verify_pass;
      bit           item_passed = 1'b1;

      byte unsigned c_key[16];
      byte unsigned c_iv[12];
      byte unsigned c_aad[256];
      byte unsigned c_pt[256];
      byte unsigned c_ct[256];
      byte unsigned c_tag_ref[16];
      byte unsigned c_tag_out[16];
      byte unsigned c_nist_tag[16];
      byte unsigned c_nist_ct[256];
      int aad_len, data_len;
      int c_match;

      mon2scb.get(tr);
      total_trans++;

      // =====================================================================
      // 1. KIỂM TRA LAN TRUYỀN 'X' (X-PROPAGATION NEGATIVE TEST)
      // =====================================================================
      if (tr.is_x_test || $isunknown(tr.cipher_key) || (tr.data_in_blocks.size() > 0 && $isunknown(tr.data_in_blocks[0]))) begin
        bit x_pass = 1'b1;
        $display("");
        $display("==============================================================");
        $display("[SCOREBOARD] Evaluating X-PROPAGATION Negative Test #%0d", total_trans);
        $display("  Stimulus check: Key is unknown = %0b, Data In is unknown = %0b",
                 $isunknown(tr.cipher_key), (tr.data_in_blocks.size() > 0) ? $isunknown(tr.data_in_blocks[0]) : 1'b0);

        // Kiểm tra DATA_OUT phải lan truyền X
        if (tr.data_out_blocks.size() > 0) begin
          if ($isunknown(tr.data_out_blocks[0])) begin
            $display("  [PASS] DATA_OUT correctly propagated 'X' as expected! (data_out[0] = %h)", tr.data_out_blocks[0]);
          end else begin
            $display("  [FAIL] DATA_OUT did NOT propagate 'X'! (data_out[0] = %h)", tr.data_out_blocks[0]);
            x_pass = 1'b0;
          end
        end

        // Kiểm tra TAG (kết quả GHASH) phải lan truyền X
        if ($isunknown(tr.tag)) begin
          $display("  [PASS] TAG (GHASH result) correctly propagated 'X' as expected! (tag = %h)", tr.tag);
        end else begin
          $display("  [FAIL] TAG did NOT propagate 'X'! (tag = %h)", tr.tag);
          x_pass = 1'b0;
        end

        if (x_pass) begin
          match_count++;
          $display("[SCOREBOARD] *** X-PROPAGATION TEST #%0d PASSED ***", total_trans);
        end else begin
          error_count++;
          $display("[SCOREBOARD] *** X-PROPAGATION TEST #%0d FAILED ***", total_trans);
        end
        $display("==============================================================");
        continue; // Bỏ qua C Golden Model và Coverage cho trường hợp X-test
      end

      // =====================================================================
      // 2. KIỂM TRA CHỨC NĂNG CHUẨN QUA C GOLDEN MODEL
      // =====================================================================
      $display("");
      $display("==============================================================");
      $display("[SCOREBOARD] Evaluating Transaction #%0d via DPI-C C Golden Model", total_trans);
      $display("  Mode           : %s", (tr.mode == 1'b0) ? "ENCRYPTION" : "DECRYPTION");
      $display("  Cipher Key     : %032h", tr.cipher_key);
      $display("  IV (96-bit)    : %024h", tr.IV);
      $display("  AAD Blocks     : %0d", tr.aad_blocks.size());
      $display("  Data In Blocks : %0d", tr.data_in_blocks.size());

      // Chuyển đổi dữ liệu sang định dạng C buffer
      bit128_to_bytes(tr.cipher_key, c_key);
      bit96_to_bytes(tr.IV, c_iv);
      queue_to_bytes(tr.aad_blocks, c_aad, aad_len);
      queue_to_bytes(tr.data_in_blocks, c_pt, data_len);
      bit128_to_bytes(tr.tag_ref, c_tag_ref);

      if (tr.mode == 1'b0) begin
        // Mode ENCRYPT:
        c_aes128_gcm_encrypt(c_key, c_iv, c_aad, aad_len, c_pt, data_len, c_ct, c_tag_out, 1);
        bytes_to_queue(c_ct, data_len, exp_data_out);
        exp_tag = bytes_to_bit128(c_tag_out);

        // Đối chiếu thêm chế độ chuẩn NIST SP 800-38D
        c_aes128_gcm_encrypt(c_key, c_iv, c_aad, aad_len, c_pt, data_len, c_nist_ct, c_nist_tag, 0);

        $display("  [C Golden Reference Analysis]");
        $display("    NIST SP 800-38D Std Tag : %032h", bytes_to_bit128(c_nist_tag));
        $display("    RTL Polynomial Expected : %032h", exp_tag);
      end else begin
        // Mode DECRYPT:
        queue_to_bytes(tr.data_in_blocks, c_ct, data_len);
        c_match = c_aes128_gcm_decrypt(c_key, c_iv, c_aad, aad_len, c_ct, data_len, c_tag_ref, c_pt, c_tag_out, 1);
        bytes_to_queue(c_pt, data_len, exp_data_out);
        exp_tag = bytes_to_bit128(c_tag_out);
        exp_verify_pass = (c_match == 1);

        $display("  [C Golden Decrypt Analysis]");
        $display("    C Golden Match Result   : %0d", c_match);
        $display("    C Golden Computed Tag   : %032h", exp_tag);
      end

      // So sánh dữ liệu Payload Data Out
      if (tr.data_out_blocks.size() != exp_data_out.size()) begin
        $display("  [FAIL] Payload block count mismatch! DUT: %0d, EXP: %0d",
                 tr.data_out_blocks.size(), exp_data_out.size());
        item_passed = 1'b0;
      end else begin
        for (int k = 0; k < exp_data_out.size(); k++) begin
          if (tr.data_out_blocks[k] !== exp_data_out[k]) begin
            $display("  [FAIL] DATA_OUT[%0d] mismatch!", k);
            $display("         DUT : %032h", tr.data_out_blocks[k]);
            $display("         EXP : %032h", exp_data_out[k]);
            item_passed = 1'b0;
          end
        end
        if (item_passed) begin
          $display("  [PASS] All %0d Payload blocks matched Golden Model!", exp_data_out.size());
        end
      end

      // So sánh Tag / Kết quả xác thực
      if (tr.mode == 1'b0) begin
        if (tr.tag !== exp_tag) begin
          $display("  [FAIL] TAG Mismatch!");
          $display("         DUT : %032h", tr.tag);
          $display("         EXP : %032h", exp_tag);
          item_passed = 1'b0;
        end else begin
          $display("  [PASS] TAG MATCHED WITH C MODEL: %032h", tr.tag);
        end
      end else begin
        if (tr.verify_done !== 1'b1) begin
          $display("  [FAIL] VERIFY_DONE was not asserted in DECRYPT mode!");
          item_passed = 1'b0;
        end
        if (tr.verify_pass !== exp_verify_pass) begin
          $display("  [FAIL] VERIFY_PASS mismatch!");
          $display("         DUT VERIFY_PASS : %0b", tr.verify_pass);
          $display("         EXP VERIFY_PASS : %0b", exp_verify_pass);
          item_passed = 1'b0;
        end else begin
          $display("  [PASS] VERIFY_PASS MATCHED: %0b (exp_pass=%0b, verify_done=%0b)",
                   tr.verify_pass, exp_verify_pass, tr.verify_done);
        end
      end

      // Thu thập mẫu Functional Coverage & Cross Coverage
      if (cov != null) begin
        cov.sample(tr);
      end

      // Tổng kết Transaction
      if (item_passed) begin
        match_count++;
        $display("[SCOREBOARD] *** TRANSACTION #%0d PASSED (VERIFIED BY C MODEL) ***", total_trans);
      end else begin
        error_count++;
        $display("[SCOREBOARD] *** TRANSACTION #%0d FAILED ***", total_trans);
      end
      $display("==============================================================");
    end
  endtask

  // =========================================================================
  // Report Function
  // =========================================================================
  function void report();
    $display("");
    $display("##############################################################");
    $display("       FINAL SCOREBOARD REPORT (DPI-C C GOLDEN MODEL)         ");
    $display("##############################################################");
    $display(" Total Transactions Tested : %0d", total_trans);
    $display(" Passed Transactions       : %0d", match_count);
    $display(" Failed Transactions       : %0d", error_count);
    if (error_count == 0 && total_trans > 0)
      $display(" RESULT: ALL TESTS PASSED SUCCESSFULLY! (100%% MATCH WITH C)");
    else if (total_trans == 0)
      $display(" RESULT: NO TRANSACTIONS EXECUTED!");
    else
      $display(" RESULT: SIMULATION COMPLETED WITH ERRORS!");
    $display("##############################################################");
  endfunction

endclass
