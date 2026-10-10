// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : monitor.sv
// Description : Passive monitor class observing interface bus signals
// ============================================================================

`define MON_IF vif.monitor_cb

class monitor;

  virtual data_if vif;
  mailbox mon2scb;

  function new(
    virtual data_if vif,
    mailbox mon2scb
  );
    this.vif     = vif;
    this.mon2scb = mon2scb;
  endfunction

  task run();
    forever begin
      transaction tr;
      bit tag_captured;
      tr = new();
      tag_captured = 1'b0;

      // Clear queues
      tr.aad_blocks.delete();
      tr.data_in_blocks.delete();
      tr.data_out_blocks.delete();

      // STEP 1 & 2: Wait for transaction start and capture KEY
      while (`MON_IF.load_key !== 1'b1)
        @(vif.monitor_cb);

      tr.mode = `MON_IF.mode;
      tr.cipher_key = `MON_IF.cipher_key;
      $display("[MONITOR] NEW TRANSACTION | MODE = %s", tr.mode ? "DECRYPT" : "ENCRYPT");
      $display("[MONITOR] Captured CIPHER_KEY = %032h", tr.cipher_key);

      // STEP 3: Capture IV
      while (`MON_IF.load_IV !== 1'b1)
        @(vif.monitor_cb);

      tr.IV = `MON_IF.IV;
      $display("[MONITOR] Captured IV = %024h", tr.IV);

      // STEP 4: In DECRYPT mode, capture TAG_REF
      if (tr.mode == 1'b1) begin
        while (`MON_IF.load_tag_ref !== 1'b1)
          @(vif.monitor_cb);

        tr.tag_ref = `MON_IF.tag_ref;
        $display("[MONITOR] Captured TAG_REF = %032h", tr.tag_ref);
      end else begin
        tr.tag_ref = 128'b0;
      end

      // STEP 5: Capture AAD Stream
      while (`MON_IF.no_AAD !== 1'b1 && `MON_IF.load_AAD !== 1'b1)
        @(vif.monitor_cb);

      if (`MON_IF.no_AAD === 1'b1) begin
        $display("[MONITOR] NO AAD");
      end else begin
        forever begin
          tr.aad_blocks.push_back(`MON_IF.AAD);
          $display("[MONITOR] AAD[%0d] = %032h | LAST=%0d",
                   tr.aad_blocks.size() - 1, `MON_IF.AAD, `MON_IF.AAD_last);

          if (`MON_IF.AAD_last === 1'b1)
            break;

          @(vif.monitor_cb);
          while (`MON_IF.load_AAD !== 1'b1)
            @(vif.monitor_cb);
        end
      end

      // STEP 6: Capture DATA IN Stream
      while (`MON_IF.load_data !== 1'b1)
        @(vif.monitor_cb);

      forever begin
        tr.data_in_blocks.push_back(`MON_IF.data_in);
        $display("[MONITOR] DATA_IN[%0d] = %032h | LAST=%0d",
                 tr.data_in_blocks.size() - 1, `MON_IF.data_in, `MON_IF.data_in_last);

        if (`MON_IF.data_in_last === 1'b1)
          break;

        @(vif.monitor_cb);
        while (`MON_IF.load_data !== 1'b1)
          @(vif.monitor_cb);
      end

      $display("[MONITOR] INPUT COMPLETE: AAD=%0d blocks, DATA=%0d blocks",
               tr.aad_blocks.size(), tr.data_in_blocks.size());

      // STEP 7: Capture Output Responses
      forever begin
        @(vif.monitor_cb);

        if (`MON_IF.data_valid === 1'b1) begin
          tr.data_out_blocks.push_back(`MON_IF.data_out);
          $display("[MONITOR] DATA_OUT[%0d] = %032h | LAST=%0d",
                   tr.data_out_blocks.size() - 1, `MON_IF.data_out, `MON_IF.data_out_last);
        end

        if (`MON_IF.tag_valid === 1'b1 && !tag_captured) begin
          tr.tag = `MON_IF.tag;
          tag_captured = 1'b1;
          $display("[MONITOR] TAG = %032h", tr.tag);
        end

        if (`MON_IF.verify_done === 1'b1) begin
          tr.verify_done = 1'b1;
          tr.verify_pass = `MON_IF.verify_pass;
          $display("[MONITOR] VERIFY_DONE = 1 | VERIFY_PASS = %0b", tr.verify_pass);
        end

        if (`MON_IF.CTR_counter_overflow === 1'b1) begin
          tr.CTR_counter_overflow = 1'b1;
          $display("[MONITOR] CTR_COUNTER_OVERFLOW = 1");
        end

        if (`MON_IF.finish === 1'b1) begin
          tr.finish = 1'b1;
          $display("[MONITOR] FINISH DETECTED");
          @(vif.monitor_cb);
          break;
        end
      end

      // STEP 8: Push complete transaction to Scoreboard
      mon2scb.put(tr);

      $display("");
      $display("============================================================");
      $display("[MONITOR] TRANSACTION COMPLETE");
      $display("============================================================");
      $display("[MONITOR] MODE            = %s", tr.mode ? "DECRYPT" : "ENCRYPT");
      $display("[MONITOR] KEY             = %032h", tr.cipher_key);
      $display("[MONITOR] IV              = %024h", tr.IV);
      if (tr.mode == 1'b1)
        $display("[MONITOR] TAG_REF         = %032h", tr.tag_ref);
      $display("[MONITOR] AAD BLOCKS      = %0d", tr.aad_blocks.size());
      $display("[MONITOR] DATA IN BLOCKS  = %0d", tr.data_in_blocks.size());
      $display("[MONITOR] DATA OUT BLOCKS = %0d", tr.data_out_blocks.size());
      $display("[MONITOR] TAG OUT         = %032h", tr.tag);
      $display("[MONITOR] VERIFY DONE     = %0b", tr.verify_done);
      $display("[MONITOR] VERIFY PASS     = %0b", tr.verify_pass);
      $display("[MONITOR] FINISH          = %0b", tr.finish);
      $display("============================================================");
    end
  endtask

endclass
