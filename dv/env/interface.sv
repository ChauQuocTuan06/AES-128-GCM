// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : interface.sv
// Description : SystemVerilog Interface for AES-128-GCM IP Core
// ============================================================================

interface data_if(input logic clk);
  logic rst_n;
  logic [3:0] cu_state; // FSM state observation
  
  // =========================================================
  // 1. Tín hiệu Input (Chiều từ Testbench vào DUT)
  // =========================================================

  logic [127:0] cipher_key, tag_ref, AAD, data_in;
  logic [95:0]  IV;
  logic         load_key, load_IV, load_tag_ref, load_AAD, load_data;
  logic         mode, no_AAD, AAD_last, data_in_last;
  logic         verify_checked; // Bắt tay xác nhận kết quả verify từ CPU/TB

  // =========================================================
  // 2. Tín hiệu Output (Chiều từ DUT ra Testbench)
  // =========================================================
  logic [127:0] tag, data_out;
  logic         tag_valid, verify_pass, verify_done, CTR_counter_overflow;
  logic         data_valid, data_out_last, finish;
  logic         key_ready, IV_ready, tag_ref_ready, AAD_ready, data_ready;

  // =========================================================
  // 3. Driver Clocking Block (Đồng bộ hóa tín hiệu kích thích)
  // =========================================================
  clocking driver_cb @(posedge clk);
    default input #1 output #1;
    
    // Tín hiệu Driver xuất vào DUT
    output cipher_key, tag_ref, AAD, data_in;
    output IV;
    output load_key, load_IV, load_tag_ref, load_AAD, load_data;
    output mode, no_AAD, AAD_last, data_in_last;
    output verify_checked;
    
    // Tín hiệu Driver đọc phản hồi từ DUT
    input  tag, data_out;
    input  tag_valid, verify_pass, verify_done, CTR_counter_overflow;
    input  data_valid, data_out_last, finish;
    input  key_ready, IV_ready, tag_ref_ready, AAD_ready, data_ready;
  endclocking

  // =========================================================
  // 4. Monitor Clocking Block (Đồng bộ hóa tín hiệu quan sát)
  // =========================================================
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
    
    // Monitor thụ động quan sát toàn bộ tín hiệu
    input cipher_key, tag_ref, AAD, data_in;
    input IV;
    input load_key, load_IV, load_tag_ref, load_AAD, load_data;
    input mode, no_AAD, AAD_last, data_in_last;
    input verify_checked;
    
    input tag, data_out;
    input tag_valid, verify_pass, verify_done, CTR_counter_overflow;
    input data_valid, data_out_last, finish;
    input key_ready, IV_ready, tag_ref_ready, AAD_ready, data_ready;
  endclocking

  // =========================================================
  // 5. Modports
  // =========================================================
  modport DRIVER  (clocking driver_cb, input clk, rst_n);
  modport MONITOR (clocking monitor_cb, input clk, rst_n);
  
endinterface
