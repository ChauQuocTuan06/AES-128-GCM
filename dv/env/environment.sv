// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : environment.sv
// Description : Top-level verification environment integrating all components
// ============================================================================

class environment;

  // Components
  generator  gen;
  driver     drv;
  monitor    mon;
  scoreboard scb;
  coverage   cov;

  // Communication channels
  mailbox gen2drv;
  mailbox mon2scb;
  event   drv_done;

  // Virtual Interface
  virtual data_if vif;

  function new(virtual data_if vif);
    this.vif = vif;

    gen2drv = new();
    mon2scb = new();
    cov     = new();

    gen = new(gen2drv, drv_done);
    drv = new(vif, gen2drv, drv_done);
    mon = new(vif, mon2scb);
    scb = new(mon2scb, cov);
  endfunction

  // Giai đoạn tiền mô phỏng: Thiết lập Reset hệ thống
  task pre_test();
    $display("[ENV] Running Pre-Test Phase: System Reset...");
    drv.reset();
  endtask

  // Tiến trình nền giám sát và thu thập FSM Coverage
  task run_fsm_cov();
    forever @(vif.cu_state) begin
      cov.sample_fsm(vif.cu_state);
    end
  endtask

  // Giai đoạn chạy mô phỏng chính: Chạy song song Generator, Driver, Monitor, Scoreboard
  task test();
    $display("[ENV] Running Test Phase...");
    fork
      gen.run();
      drv.run();
      mon.run();
      scb.run();
    join_any
  endtask

  // Giai đoạn hậu mô phỏng: Chờ tất cả transaction được kiểm tra và xuất báo cáo
  task post_test();
    $display("[ENV] Running Post-Test Phase...");
    // Chờ số lượng transaction trong scoreboard bằng số lượng yêu cầu của generator
    wait(scb.total_trans == gen.loop);
    #100;
    scb.report();
    cov.report();
  endtask

  // Task điều phối toàn bộ vòng đời môi trường kiểm thử
  task run();
    pre_test();
    test();
    post_test();
    $display("[ENV] Environment execution completed successfully!");
  endtask

endclass
