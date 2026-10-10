// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : transaction.sv
// Description : Transaction class defining stimulus and DUT response (4-state logic)
// ============================================================================

class transaction;

  // =========================================================
  // 1. STIMULUS (Đầu vào tạo ngẫu nhiên hoặc có chủ đích - 4-state logic)
  // =========================================================
  rand logic [127:0] cipher_key;
  rand logic [95:0]  IV;
  rand bit           mode; // 0: Encrypt, 1: Decrypt

  // Luồng khối AAD (Additional Authenticated Data)
  rand logic [127:0] aad_blocks[$];

  // Luồng khối Payload (Plaintext nếu Encrypt, Ciphertext nếu Decrypt)
  rand logic [127:0] data_in_blocks[$];

  // Tag tham chiếu phục vụ chế độ giải mã (Decrypt Mode)
  rand logic [127:0] tag_ref;

  // Cờ báo hiệu testcase tiêm giá trị X (X-Propagation Test)
  bit is_x_test    = 1'b0;
  // Cờ báo hiệu tái sử dụng Key (không phát xung load_key)
  bit skip_key     = 1'b0;
  // Cờ báo hiệu giả lập backpressure / delay khi nạp dữ liệu
  bit inject_delay = 1'b0;

  // =========================================================
  // 2. DUT RESPONSE (Phản hồi thu thập từ Monitor)
  // =========================================================
  logic [127:0] data_out_blocks[$];
  logic [127:0] tag;
  bit           verify_pass;
  bit           verify_done;
  bit           CTR_counter_overflow;
  bit           finish;

  // =========================================================
  // 3. CONSTRAINTS
  // =========================================================
  constraint c_block_sizes {
    aad_blocks.size() inside {[0:8]};
    data_in_blocks.size() inside {[1:12]};
  }

  // =========================================================
  // 4. COPY
  // =========================================================
  function void copy(transaction tr);
    this.cipher_key           = tr.cipher_key;
    this.IV                   = tr.IV;
    this.mode                 = tr.mode;
    this.tag_ref              = tr.tag_ref;
    this.aad_blocks           = tr.aad_blocks;
    this.data_in_blocks       = tr.data_in_blocks;
    this.data_out_blocks      = tr.data_out_blocks;
    this.tag                  = tr.tag;
    this.verify_pass          = tr.verify_pass;
    this.verify_done          = tr.verify_done;
    this.CTR_counter_overflow = tr.CTR_counter_overflow;
    this.finish               = tr.finish;
    this.is_x_test            = tr.is_x_test;
    this.skip_key             = tr.skip_key;
    this.inject_delay         = tr.inject_delay;
  endfunction

  // =========================================================
  // 5. DISPLAY
  // =========================================================
  function void display(string name = "Transaction");
    $display("==================================================");
    $display("[%s]", name);
    $display("Mode        : %s", mode ? "DECRYPT" : "ENCRYPT");
    $display("Cipher Key  : %032h", cipher_key);
    $display("IV          : %024h", IV);
    $display("AAD Size    : %0d blocks", aad_blocks.size());
    foreach (aad_blocks[i])
      $display("  AAD[%0d]   : %032h", i, aad_blocks[i]);
    $display("Data In Size: %0d blocks", data_in_blocks.size());
    foreach (data_in_blocks[i])
      $display("  DATA[%0d]  : %032h", i, data_in_blocks[i]);
    if (mode == 1'b1)
      $display("Tag Ref     : %032h", tag_ref);
    $display("Data Out Sz : %0d blocks", data_out_blocks.size());
    foreach (data_out_blocks[i])
      $display("  DOUT[%0d] : %032h", i, data_out_blocks[i]);
    $display("Tag Out     : %032h", tag);
    $display("Verify Pass : %0b", verify_pass);
    $display("Verify Done : %0b", verify_done);
    $display("CTR Overflow: %0b", CTR_counter_overflow);
    $display("Finish      : %0b", finish);
    $display("Is X Test   : %0b", is_x_test);
    $display("==================================================");
  endfunction

endclass
