// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : driver.sv
// Description : Driver class converting transactions to pin-level interface signals
// ============================================================================

`define drv_if vif.driver_cb

class driver;

  virtual data_if vif;
  mailbox gen2drv;
  event drv_done;

  function new(
    virtual data_if vif,
    mailbox gen2drv,
    event drv_done
  );
    this.vif      = vif;
    this.gen2drv  = gen2drv;
    this.drv_done = drv_done;
  endfunction

  // ================================================================
  // RESET
  // ================================================================
  task reset();
    $display("");
    $display("========================================================");
    $display("[DRIVER] RESET STARTED");
    $display("========================================================");

    vif.rst_n <= 1'b0;

    // Đưa toàn bộ input về trạng thái an toàn
    `drv_if.cipher_key     <= 128'b0;
    `drv_if.tag_ref        <= 128'b0;
    `drv_if.AAD            <= 128'b0;
    `drv_if.data_in        <= 128'b0;
    `drv_if.IV             <= 96'b0;

    `drv_if.load_key       <= 1'b0;
    `drv_if.load_IV        <= 1'b0;
    `drv_if.load_tag_ref   <= 1'b0;
    `drv_if.load_AAD       <= 1'b0;
    `drv_if.load_data      <= 1'b0;

    `drv_if.mode           <= 1'b0;
    `drv_if.no_AAD         <= 1'b0;
    `drv_if.AAD_last       <= 1'b0;
    `drv_if.data_in_last   <= 1'b0;
    `drv_if.verify_checked <= 1'b0;

    // Giữ reset 2 clock
    repeat (2) @(vif.driver_cb);

    // Release reset
    vif.rst_n <= 1'b1;
    @(vif.driver_cb);

    $display("========================================================");
    $display("[DRIVER] RESET COMPLETED");
    $display("========================================================");
  endtask

  // ================================================================
  // LOAD KEY
  // ================================================================
  task drive_key(transaction tr);
    $display("[DRIVER] Waiting KEY_READY...");

    while (`drv_if.key_ready !== 1'b1)
      @(vif.driver_cb);

    `drv_if.cipher_key <= tr.cipher_key;
    `drv_if.load_key   <= 1'b1;

    $display("[DRIVER] LOAD_KEY = %032h", tr.cipher_key);

    @(vif.driver_cb);

    `drv_if.load_key   <= 1'b0;
  endtask

  // ================================================================
  // LOAD IV
  // ================================================================
  task drive_IV(transaction tr);
    $display("[DRIVER] Waiting IV_READY...");

    while (`drv_if.IV_ready !== 1'b1)
      @(vif.driver_cb);

    `drv_if.IV      <= tr.IV;
    `drv_if.load_IV <= 1'b1;

    $display("[DRIVER] LOAD_IV = %024h", tr.IV);

    @(vif.driver_cb);

    `drv_if.load_IV <= 1'b0;
    `drv_if.IV      <= 96'b0;
  endtask

  // ================================================================
  // LOAD TAG REF (Decrypt Mode Only)
  // ================================================================
  task drive_tag_ref(transaction tr);
    if (tr.mode == 1'b0)
      return;

    $display("[DRIVER] Waiting TAG_REF_READY...");

    while (`drv_if.tag_ref_ready !== 1'b1)
      @(vif.driver_cb);

    `drv_if.tag_ref      <= tr.tag_ref;
    `drv_if.load_tag_ref <= 1'b1;

    $display("[DRIVER] LOAD_TAG_REF = %032h", tr.tag_ref);

    @(vif.driver_cb);

    `drv_if.load_tag_ref <= 1'b0;
    `drv_if.tag_ref      <= 128'b0;
  endtask

  // ================================================================
  // LOAD AAD STREAM
  // ================================================================
  task drive_AAD(transaction tr);
    $display("[DRIVER] Waiting AAD_READY...");

    while (`drv_if.AAD_ready !== 1'b1)
      @(vif.driver_cb);

    if (tr.aad_blocks.size() == 0) begin
      `drv_if.no_AAD   <= 1'b1;
      `drv_if.load_AAD <= 1'b0;
      `drv_if.AAD      <= 128'b0;
      `drv_if.AAD_last <= 1'b0;
      $display("[DRIVER] NO AAD (no_AAD = 1)");
      @(vif.driver_cb);
      return;
    end

    `drv_if.no_AAD   <= 1'b0;
    `drv_if.load_AAD <= 1'b0;
    `drv_if.AAD      <= 128'b0;
    `drv_if.AAD_last <= 1'b0;

    for (int i = 0; i < tr.aad_blocks.size(); i++) begin
      while (`drv_if.AAD_ready !== 1'b1)
        @(vif.driver_cb);

      `drv_if.AAD <= tr.aad_blocks[i];
      `drv_if.load_AAD <= 1'b1;
      if (i == tr.aad_blocks.size() - 1)
        `drv_if.AAD_last <= 1'b1;
      else
        `drv_if.AAD_last <= 1'b0;

      $display("[DRIVER] AAD[%0d] = %032h | LAST=%0d",
               i, tr.aad_blocks[i], (i == tr.aad_blocks.size() - 1));

      @(vif.driver_cb);

      if (i == tr.aad_blocks.size() - 1)
        break;

      if (`drv_if.AAD_ready !== 1'b1) begin
        `drv_if.load_AAD <= 1'b0;
        `drv_if.AAD      <= 128'b0;
        `drv_if.AAD_last <= 1'b0;
        $display("[DRIVER] AAD_READY = 0, waiting for next AAD block");
      end
    end

    `drv_if.load_AAD <= 1'b0;
    `drv_if.AAD      <= 128'b0;
    `drv_if.AAD_last <= 1'b0;
  endtask

  // ================================================================
  // LOAD DATA STREAM (Plaintext / Ciphertext)
  // ================================================================
  task drive_data(transaction tr);
    $display("[DRIVER] Waiting DATA_READY...");

    while (`drv_if.data_ready !== 1'b1)
      @(vif.driver_cb);

    `drv_if.no_AAD <= 1'b0;

    for (int i = 0; i < tr.data_in_blocks.size(); i++) begin
      `drv_if.data_in <= tr.data_in_blocks[i];

      while (`drv_if.data_ready !== 1'b1)
        @(vif.driver_cb);

      `drv_if.load_data <= 1'b1;
      if (i == tr.data_in_blocks.size() - 1)
        `drv_if.data_in_last <= 1'b1;
      else
        `drv_if.data_in_last <= 1'b0;

      $display("[DRIVER] DATA[%0d] = %032h | LAST=%0d",
               i, tr.data_in_blocks[i], (i == tr.data_in_blocks.size() - 1));

      @(vif.driver_cb);

      if (i == tr.data_in_blocks.size() - 1)
        break;

      if (`drv_if.data_ready !== 1'b1) begin
        `drv_if.load_data    <= 1'b0;
        `drv_if.data_in      <= 128'b0;
        `drv_if.data_in_last <= 1'b0;
        $display("[DRIVER] DATA_READY = 0, waiting for next DATA block");
      end
    end

    `drv_if.load_data    <= 1'b0;
    `drv_if.data_in      <= 128'b0;
    `drv_if.data_in_last <= 1'b0;
  endtask

  // ================================================================
  // MAIN RUN
  // ================================================================
  virtual task run();
    forever begin
      transaction tr;
      gen2drv.get(tr);

      $display("");
      $display("========================================================");
      $display("[DRIVER] NEW AES-GCM TRANSACTION (Mode: %s)", tr.mode ? "DECRYPT" : "ENCRYPT");
      $display("========================================================");
      tr.display("DRIVER");

      `drv_if.mode <= tr.mode;
      drive_key(tr);
      drive_IV(tr);
      if (tr.mode == 1'b1) begin
        drive_tag_ref(tr);
      end
      drive_AAD(tr);
      drive_data(tr);

      // Handshake cho chế độ Decrypt: chờ verify_done từ DUT và phản hồi verify_checked
      if (tr.mode == 1'b1) begin
        $display("[DRIVER] Waiting VERIFY_DONE from DUT...");
        while (`drv_if.verify_done !== 1'b1)
          @(vif.driver_cb);

        $display("[DRIVER] VERIFY_DONE detected! (verify_pass=%0b). Asserting VERIFY_CHECKED pulse.",
                 `drv_if.verify_pass);
        `drv_if.verify_checked <= 1'b1;
        @(vif.driver_cb);
        `drv_if.verify_checked <= 1'b0;
      end

      $display("[DRIVER] Waiting FINISH from DUT...");
      while (`drv_if.finish !== 1'b1)
        @(vif.driver_cb);

      $display("[DRIVER] FINISH detected!");

      -> drv_done;

      $display("========================================================");
      $display("[DRIVER] TRANSACTION COMPLETED");
      $display("========================================================");
    end
  endtask

endclass
