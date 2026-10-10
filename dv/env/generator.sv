// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : generator.sv
// Description : Generator class for random and directed stimulus generation
// ============================================================================

class generator;
  transaction trans;
  int loop = 1;
  event drv_done;
  mailbox gen2drv;
  
  function new(mailbox gen2drv, event drv_done);
    this.gen2drv  = gen2drv;
    this.drv_done = drv_done;
    trans         = new();
  endfunction
  
  // Random test generation task
  task run();
    for (int i = 0; i < loop; i++) begin
      transaction tr;
      if (!trans.randomize()) begin
        $fatal(1, "[GENERATOR] Transaction randomization failed!");
      end
      tr = new();
      tr.copy(trans);
      $display("[GENERATOR] Generated transaction #%0d (Mode: %s, Data blocks: %0d)",
               i + 1, tr.mode ? "DECRYPT" : "ENCRYPT", tr.data_in_blocks.size());
      gen2drv.put(tr);
      @(drv_done);
    end
  endtask

  // Helper task to send custom/directed transaction (e.g. NIST Known Answer Test)
  task send_directed(transaction tr_in);
    transaction tr;
    tr = new();
    tr.copy(tr_in);
    $display("[GENERATOR] Sending directed transaction (Mode: %s)",
             tr.mode ? "DECRYPT" : "ENCRYPT");
    gen2drv.put(tr);
    @(drv_done);
  endtask

endclass
