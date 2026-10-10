// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : tb_top.sv
// Description : Top-level Testbench connecting DUT, Interface, and invoking
//               modular test classes via test_pkg.
//               Architecture aligned with EDA Playground OOP methodology.
// ============================================================================

`timescale 1ns/1ps

import env_pkg::*;
import test_pkg::*;

module tb_top;

  // 1. Clock & Reset Generator
  logic clk;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100 MHz (10ns period)
  end

  // Watchdog timeout (1ms = 100,000 clock cycles)
  initial begin
    #1000000;
    $display("[TB] *** TIMEOUT REACHED (1ms) ***");
    $finish;
  end

  // 2. Physical Interface Instantiation
  data_if vif (
    .clk (clk)
  );

  // 3. DUT Instantiation (AES-128-GCM Top-Level)
  AES_GCM u_dut (
    .clk                  (clk),
    .rst_n                (vif.rst_n),
    
    // Inputs
    .cipher_key           (vif.cipher_key),
    .load_key             (vif.load_key),
    .IV                   (vif.IV),
    .load_IV              (vif.load_IV),
    .mode                 (vif.mode),
    .tag_ref              (vif.tag_ref),
    .load_tag_ref         (vif.load_tag_ref),
    .AAD                  (vif.AAD),
    .load_AAD             (vif.load_AAD),
    .no_AAD               (vif.no_AAD),
    .AAD_last             (vif.AAD_last),
    .data_in              (vif.data_in),
    .load_data            (vif.load_data),
    .data_in_last         (vif.data_in_last),
    .verify_checked       (vif.verify_checked),

    // Outputs
    .tag                  (vif.tag),
    .tag_valid            (vif.tag_valid),
    .verify_pass          (vif.verify_pass),
    .verify_done          (vif.verify_done),
    .CTR_counter_overflow (vif.CTR_counter_overflow),
    .data_out             (vif.data_out),
    .data_valid           (vif.data_valid),
    .data_out_last        (vif.data_out_last),
    .finish               (vif.finish),
    .key_ready            (vif.key_ready),
    .IV_ready             (vif.IV_ready),
    .tag_ref_ready        (vif.tag_ref_ready),
    .AAD_ready            (vif.AAD_ready),
    .data_ready           (vif.data_ready)
  );

  // Hook internal state to interface for test observability
  assign vif.cu_state = u_dut.cu.Current;

  // Debug monitor CU FSM transitions
  always @(u_dut.cu.Current) begin
    $display("[FSM TRACE @ %0t ps] CU Current=%s (%0d), Next=%0d | start=%0b, H_loaded=%0b, IV_loaded=%0b, no_AAD=%0b, AAD_ready=%0b, data_ready=%0b",
             $time, u_dut.cu.Current.name(), u_dut.cu.Current, u_dut.cu.Next, u_dut.cu.start, u_dut.cu.H_loaded, u_dut.cu.IV_loaded, u_dut.cu.no_AAD, u_dut.cu.AAD_ready, u_dut.cu.data_ready);
  end

  // 4. SystemVerilog Assertions (SVA) Module Instantiation
  aes_gcm_assertions u_sva (
    .clk          (clk),
    .rst_n        (vif.rst_n),
    .load_key     (vif.load_key),
    .key_ready    (vif.key_ready),
    .load_IV      (vif.load_IV),
    .IV_ready     (vif.IV_ready),
    .load_tag_ref (vif.load_tag_ref),
    .tag_ref_ready(vif.tag_ref_ready),
    .load_AAD     (vif.load_AAD),
    .AAD_ready    (vif.AAD_ready),
    .load_data    (vif.load_data),
    .data_ready   (vif.data_ready),
    .mode         (vif.mode),
    .finish       (vif.finish),
    .tag_valid    (vif.tag_valid),
    .verify_done  (vif.verify_done),
    .verify_pass  (vif.verify_pass),
    .data_valid   (vif.data_valid),
    .cu_state     (vif.cu_state)
  );

  // 5. Test Execution Block (Dynamic Test Selection via +TESTNAME)
  initial begin : test_runner
    string                 testname;
    base_test              t;
    test_nist_kat          t_kat;
    test_coverage_full     t_cov;
    test_reuse_key         t_reuse;
    test_enc_dec_chain     t_chain;
    test_backpressure      t_bp;
    test_ctr_overflow      t_max_iv;
    test_decryption_errors t_dec;
    test_x_propagation     t_x;
    test_reset             t_rst;
    test_stress            t_str;
    test_all               t_all;

    testname = "test_all";
    void'($value$plusargs("TESTNAME=%s", testname));

    $display("==================================================================");
    $display("  STARTING AES-128-GCM SYSTEMVERILOG VERIFICATION ENVIRONMENT    ");
    $display("  Selected Test: %s", testname);
    $display("==================================================================");

    case (testname)
      "test_nist_kat": begin
        t_kat = new("test_nist_kat", vif);
        t = t_kat;
      end
      "test_coverage_full": begin
        t_cov = new("test_coverage_full", vif);
        t = t_cov;
      end
      "test_reuse_key": begin
        t_reuse = new("test_reuse_key", vif);
        t = t_reuse;
      end
      "test_enc_dec_chain": begin
        t_chain = new("test_enc_dec_chain", vif);
        t = t_chain;
      end
      "test_backpressure": begin
        t_bp = new("test_backpressure", vif);
        t = t_bp;
      end
      "test_ctr_overflow": begin
        t_max_iv = new("test_ctr_overflow", vif);
        t = t_max_iv;
      end
      "test_decryption_errors": begin
        t_dec = new("test_decryption_errors", vif);
        t = t_dec;
      end
      "test_x_propagation": begin
        t_x = new("test_x_propagation", vif);
        t = t_x;
      end
      "test_reset": begin
        t_rst = new("test_reset", vif);
        t = t_rst;
      end
      "test_stress": begin
        t_str = new("test_stress", vif);
        t = t_str;
      end
      "test_all": begin
        t_all = new("test_all", vif);
        t = t_all;
      end
      default: begin
        $display("[TB_TOP] Unknown TESTNAME '%s', falling back to 'test_all'", testname);
        t_all = new("test_all", vif);
        t = t_all;
      end
    endcase

    t.run();

    $display("==================================================================");
    $display("  SIMULATION COMPLETE                                             ");
    $display("==================================================================");
    $finish;
  end

endmodule
