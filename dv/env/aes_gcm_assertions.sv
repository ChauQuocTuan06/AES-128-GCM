// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : aes_gcm_assertions.sv
// Description : SystemVerilog Assertions (SVA) checking protocol handshakes,
//               FSM state invariants, and output signal integrity
// ============================================================================

module aes_gcm_assertions (
  input logic       clk,
  input logic       rst_n,
  
  // Handshake and control inputs
  input logic       load_key,
  input logic       key_ready,
  input logic       load_IV,
  input logic       IV_ready,
  input logic       load_tag_ref,
  input logic       tag_ref_ready,
  input logic       load_AAD,
  input logic       AAD_ready,
  input logic       load_data,
  input logic       data_ready,
  input logic       mode,
  
  // Outputs
  input logic       finish,
  input logic       tag_valid,
  input logic       verify_done,
  input logic       verify_pass,
  input logic       data_valid,
  input logic [3:0] cu_state
);

  // =========================================================================
  // 1. Handshake Protocol Assertions
  // =========================================================================
  property p_load_key_handshake;
    @(posedge clk) disable iff (!rst_n)
    load_key |-> key_ready;
  endproperty
  a_load_key: assert property (p_load_key_handshake)
    else $error("[SVA ERROR @ %0t] load_key asserted when key_ready is 0!", $time);

  property p_load_IV_handshake;
    @(posedge clk) disable iff (!rst_n)
    load_IV |-> IV_ready;
  endproperty
  a_load_IV: assert property (p_load_IV_handshake)
    else $error("[SVA ERROR @ %0t] load_IV asserted when IV_ready is 0!", $time);

  property p_load_tag_ref_handshake;
    @(posedge clk) disable iff (!rst_n)
    load_tag_ref |-> tag_ref_ready;
  endproperty
  a_load_tag_ref: assert property (p_load_tag_ref_handshake)
    else $error("[SVA ERROR @ %0t] load_tag_ref asserted when tag_ref_ready is 0!", $time);

  property p_load_AAD_handshake;
    @(posedge clk) disable iff (!rst_n)
    load_AAD |-> AAD_ready;
  endproperty
  a_load_AAD: assert property (p_load_AAD_handshake)
    else $error("[SVA ERROR @ %0t] load_AAD asserted when AAD_ready is 0!", $time);

  property p_load_data_handshake;
    @(posedge clk) disable iff (!rst_n)
    load_data |-> data_ready;
  endproperty
  a_load_data: assert property (p_load_data_handshake)
    else $error("[SVA ERROR @ %0t] load_data asserted when data_ready is 0!", $time);

  // =========================================================================
  // 2. Pulse Width & Protocol Mode Assertions
  // =========================================================================
  property p_finish_pulse;
    @(posedge clk) disable iff (!rst_n)
    $rose(finish) |=> !finish;
  endproperty
  a_finish_pulse: assert property (p_finish_pulse)
    else $error("[SVA ERROR @ %0t] finish held high for more than 1 cycle!", $time);

  property p_verify_only_in_decrypt;
    @(posedge clk) disable iff (!rst_n)
    verify_done |-> mode;
  endproperty
  a_verify_only_decrypt: assert property (p_verify_only_in_decrypt)
    else $error("[SVA ERROR @ %0t] verify_done asserted in ENCRYPT mode!", $time);

  property p_tag_valid_only_in_encrypt;
    @(posedge clk) disable iff (!rst_n)
    tag_valid |-> !mode;
  endproperty
  a_tag_valid_only_encrypt: assert property (p_tag_valid_only_in_encrypt)
    else $error("[SVA ERROR @ %0t] tag_valid asserted in DECRYPT mode!", $time);

  // =========================================================================
  // 3. FSM State Invariant Assertions
  // =========================================================================
  property p_finish_to_idle;
    @(posedge clk) disable iff (!rst_n)
    $rose(finish) |=> (cu_state == 4'd0);
  endproperty
  a_finish_to_idle: assert property (p_finish_to_idle)
    else $error("[SVA ERROR @ %0t] FSM did not return to IDLE after finish!", $time);

  property p_idle_outputs;
    @(posedge clk) disable iff (!rst_n)
    (cu_state == 4'd0) |-> (!data_valid && !tag_valid && !finish);
  endproperty
  a_idle_outputs: assert property (p_idle_outputs)
    else $error("[SVA ERROR @ %0t] Unexpected active outputs in IDLE state!", $time);

endmodule
