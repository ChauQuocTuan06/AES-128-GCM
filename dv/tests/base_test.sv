// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : base_test.sv
// Description : Base test class providing common test initialization, execution,
//               and reporting routines.
// ============================================================================

class base_test;

  virtual data_if vif;
  environment     env;
  string          test_name;

  function new(string name = "base_test", virtual data_if vif);
    this.test_name = name;
    this.vif       = vif;
    this.env       = new(vif);
  endfunction

  // Pre-test execution: System Reset and start background tasks
  virtual task pre_run();
    $display("");
    $display("==================================================================");
    $display("  [TEST START] %s", test_name);
    $display("==================================================================");
    env.pre_test();
    fork
      env.drv.run();
      env.mon.run();
      env.scb.run();
    join_none
  endtask

  // Stimulus task to be overridden by child test classes
  virtual task do_stimulus();
    // Default base test does nothing
  endtask

  // Post-test execution: wait for scoreboard drain, report results & coverage
  virtual task post_run();
    #300;
    env.scb.report();
    env.cov.report();
    $display("");
    $display("==================================================================");
    $display("  [TEST FINISH] %s Completed!", test_name);
    $display("==================================================================");
  endtask

  // Main run task orchestrating test lifecycle
  virtual task run();
    pre_run();
    do_stimulus();
    post_run();
  endtask

endclass
