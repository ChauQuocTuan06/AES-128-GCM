// =============================================================================
// Project     : AES-128-GCM Hardware Accelerator
// File        : aes_128_gcm_all.sv
// Description : Complete Monolithic SystemVerilog RTL Implementation of AES-128-GCM.
//               Combines all 50 submodules in strict bottom-up dependency order.
//               All leaf modules and sub-blocks are defined prior to instantiation.
// Standard    : NIST SP 800-38D / FIPS 197 compliant
// Top Module  : AES_GCM
// =============================================================================

`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// [1/50] Module: AffineTransform
// Source   : rtl/AES-CTR/SBox/AffineTransform.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module AffineTransform (
    input logic [7:0] byte_in,

    output logic [7:0] byte_out
);
  assign byte_out[7] = byte_in[7] ^ byte_in[6] ^ byte_in[5] ^ byte_in[4] ^ byte_in[3];
  assign byte_out[6] = byte_in[6] ^ byte_in[5] ^ byte_in[4] ^ byte_in[3] ^ byte_in[2] ^ 1'b1;
  assign byte_out[5] = byte_in[5] ^ byte_in[4] ^ byte_in[3] ^ byte_in[2] ^ byte_in[1] ^ 1'b1;
  assign byte_out[4] = byte_in[4] ^ byte_in[3] ^ byte_in[2] ^ byte_in[1] ^ byte_in[0];
  assign byte_out[3] = byte_in[7] ^ byte_in[3] ^ byte_in[2] ^ byte_in[1] ^ byte_in[0];
  assign byte_out[2] = byte_in[7] ^ byte_in[6] ^ byte_in[2] ^ byte_in[1] ^ byte_in[0];
  assign byte_out[1] = byte_in[7] ^ byte_in[6] ^ byte_in[5] ^ byte_in[1] ^ byte_in[0] ^ 1'b1;
  assign byte_out[0] = byte_in[7] ^ byte_in[6] ^ byte_in[5] ^ byte_in[4] ^ byte_in[0] ^ 1'b1;
endmodule

// -----------------------------------------------------------------------------
// [2/50] Module: Imp
// Source   : rtl/AES-CTR/SBox/MultiplicativeInv.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module Imp (
    input logic [7:0] byte_in,

    output logic [7:0] byte_out
);
  assign byte_out[7] = byte_in[7] ^ byte_in[5];
  assign byte_out[6] = byte_in[7] ^ byte_in[6] ^ byte_in[4] ^ byte_in[3] ^ byte_in[2] ^ byte_in[1];
  assign byte_out[5] = byte_in[7] ^ byte_in[5] ^ byte_in[3] ^ byte_in[2];
  assign byte_out[4] = byte_in[7] ^ byte_in[5] ^ byte_in[3] ^ byte_in[2] ^ byte_in[1];
  assign byte_out[3] = byte_in[7] ^ byte_in[6] ^ byte_in[2] ^ byte_in[1];
  assign byte_out[2] = byte_in[7] ^ byte_in[4] ^ byte_in[3] ^ byte_in[2] ^ byte_in[1];
  assign byte_out[1] = byte_in[6] ^ byte_in[4] ^ byte_in[1];
  assign byte_out[0] = byte_in[6] ^ byte_in[1] ^ byte_in[0];
endmodule

// -----------------------------------------------------------------------------
// [3/50] Module: ImpInv
// Source   : rtl/AES-CTR/SBox/MultiplicativeInv.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module ImpInv (
    input logic [7:0] byte_in,

    output logic [7:0] byte_out
);
  assign byte_out[7] = byte_in[7] ^ byte_in[6] ^ byte_in[5] ^ byte_in[1];
  assign byte_out[6] = byte_in[6] ^ byte_in[2];
  assign byte_out[5] = byte_in[6] ^ byte_in[5] ^ byte_in[1];
  assign byte_out[4] = byte_in[6] ^ byte_in[5] ^ byte_in[4] ^ byte_in[2] ^ byte_in[1];
  assign byte_out[3] = byte_in[5] ^ byte_in[4] ^ byte_in[3] ^ byte_in[2] ^ byte_in[1];
  assign byte_out[2] = byte_in[7] ^ byte_in[4] ^ byte_in[3] ^ byte_in[2] ^ byte_in[1];
  assign byte_out[1] = byte_in[5] ^ byte_in[4];
  assign byte_out[0] = byte_in[6] ^ byte_in[5] ^ byte_in[4] ^ byte_in[2] ^ byte_in[0];
endmodule

// -----------------------------------------------------------------------------
// [4/50] Module: ModuleS
// Source   : rtl/AES-CTR/SBox/MultiplicativeInv.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module ModuleS (
    input logic [3:0] data_in,

    output logic [3:0] data_out
);
  assign data_out[3] = data_in[3];
  assign data_out[2] = data_in[3] ^ data_in[2];
  assign data_out[1] = data_in[2] ^ data_in[1];
  assign data_out[0] = data_in[3] ^ data_in[1] ^ data_in[0];
endmodule

// -----------------------------------------------------------------------------
// [5/50] Module: ModuleC
// Source   : rtl/AES-CTR/SBox/MultiplicativeInv.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module ModuleC (
    input logic [3:0] data_in,

    output logic [3:0] data_out
);
  assign data_out[3] = data_in[2] ^ data_in[0];
  assign data_out[2] = data_in[3] ^ data_in[2] ^ data_in[1] ^ data_in[0];
  assign data_out[1] = data_in[3];
  assign data_out[0] = data_in[2];
endmodule

// -----------------------------------------------------------------------------
// [6/50] Module: ModuleX
// Source   : rtl/AES-CTR/SBox/MultiplicativeInv.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module ModuleX (
    input logic [3:0] data_in1,
    input logic [3:0] data_in2,

    output logic [3:0] data_out
);
  assign data_out[3] = (data_in1[3] & data_in2[3]) 
                    ^ (data_in1[3] & data_in2[2]) ^ (data_in1[2] & data_in2[3])
                    ^ (data_in1[3] & data_in2[1]) ^ (data_in1[1] & data_in2[3])
                    ^ (data_in1[3] & data_in2[0]) ^ (data_in1[0] & data_in2[3])
                    ^ (data_in1[2] & data_in2[1]) ^ (data_in1[1] & data_in2[2]);
  assign data_out[2] = (data_in1[3] & data_in2[3]) ^ (data_in1[2] & data_in2[2])
                    ^ (data_in1[3] & data_in2[1]) ^ (data_in1[1] & data_in2[3])
                    ^ (data_in1[2] & data_in2[0]) ^ (data_in1[0] & data_in2[2]);
  assign data_out[1] = (data_in1[3] & data_in2[2]) ^ (data_in1[2] & data_in2[3])
                    ^ (data_in1[2] & data_in2[2]) ^ (data_in1[1] & data_in2[1])
                    ^ (data_in1[1] & data_in2[0]) ^ (data_in1[0] & data_in2[1]);
  assign data_out[0] = (data_in1[3] & data_in2[3]) ^ (data_in1[1] & data_in2[1]) ^ (data_in1[0] & data_in2[0])
                    ^ (data_in1[3] & data_in2[2]) ^ (data_in1[2] & data_in2[3]);
endmodule

// -----------------------------------------------------------------------------
// [7/50] Module: Inv
// Source   : rtl/AES-CTR/SBox/MultiplicativeInv.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module Inv (
    input logic [3:0] data_in,

    output logic [3:0] data_out
);
  always_comb begin : InvSelectorForDelta
    case (data_in)
      4'h0: data_out = 4'h0;
      4'h1: data_out = 4'h1;
      4'h2: data_out = 4'h3;
      4'h3: data_out = 4'h2;
      4'h4: data_out = 4'hf;
      4'h5: data_out = 4'hc;
      4'h6: data_out = 4'h9;
      4'h7: data_out = 4'hb;
      4'h8: data_out = 4'ha;
      4'h9: data_out = 4'h6;
      4'ha: data_out = 4'h8;
      4'hb: data_out = 4'h7;
      4'hc: data_out = 4'h5;
      4'hd: data_out = 4'he;
      4'he: data_out = 4'hd;
      4'hf: data_out = 4'h4;
      default: data_out = 4'h0;
    endcase
  end
endmodule

// -----------------------------------------------------------------------------
// [8/50] Module: MultiplicativeInv
// Source   : rtl/AES-CTR/SBox/MultiplicativeInv.sv
// Submodules: Imp, ImpInv, Inv, ModuleC, ModuleS, ModuleX
// -----------------------------------------------------------------------------
module MultiplicativeInv (
    input logic [7:0] byte_in,

    output logic [7:0] byte_out
);
  logic [7:0] byte_in_imp;
  logic [7:0] byte_in_inv;

  logic [3:0] byte_in_imp_S;
  logic [3:0] byte_in_imp_C;
  logic [3:0] XOR_byte_in_imp;
  logic [3:0] byte_in_imp_X;
  logic [3:0] XOR_to_Inv;
  logic [3:0] InvOut;

  assign XOR_byte_in_imp = byte_in_imp[7:4] ^ byte_in_imp[3:0];
  assign XOR_to_Inv = byte_in_imp_C ^ byte_in_imp_X;

  Imp imp1 (
      .byte_in (byte_in),
      .byte_out(byte_in_imp)
  );
  ModuleS s1 (
      .data_in (byte_in_imp[7:4]),
      .data_out(byte_in_imp_S)
  );
  ModuleC c1 (
      .data_in (byte_in_imp_S),
      .data_out(byte_in_imp_C)
  );
  ModuleX x1 (
      .data_in1(byte_in_imp[3:0]),
      .data_in2(XOR_byte_in_imp),
      .data_out(byte_in_imp_X)
  );
  Inv inv1 (
      .data_in (XOR_to_Inv),
      .data_out(InvOut)
  );
  ModuleX x2 (
      .data_in1(InvOut),
      .data_in2(byte_in_imp[7:4]),
      .data_out(byte_in_inv[7:4])
  );
  ModuleX x3 (
      .data_in1(InvOut),
      .data_in2(XOR_byte_in_imp),
      .data_out(byte_in_inv[3:0])
  );
  ImpInv impinv1 (
      .byte_in (byte_in_inv),
      .byte_out(byte_out)
  );
endmodule

// -----------------------------------------------------------------------------
// [9/50] Module: SBox
// Source   : rtl/AES-CTR/SBox/SBox.sv
// Submodules: AffineTransform, MultiplicativeInv
// -----------------------------------------------------------------------------
module SBox (
    input logic [7:0] byte_in,

    output logic [7:0] byte_out
);
  logic [7:0] after_mInv;

  MultiplicativeInv minv1 (
      .byte_in (byte_in),
      .byte_out(after_mInv)
  );
  AffineTransform aff1 (
      .byte_in (after_mInv),
      .byte_out(byte_out)
  );
endmodule

// -----------------------------------------------------------------------------
// [10/50] Module: AddRcon
// Source   : rtl/AES-CTR/Key_Expansion/GFunction/AddRcon.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module AddRcon (
    input logic [31:0] word_in,
    input logic [ 3:0] round_index,

    output logic [31:0] word_out
);
  logic [31:0] rcon;
  always_comb begin : RconSelector
    case (round_index)
      4'd0: rcon = 32'h01000000;
      4'd1: rcon = 32'h02000000;
      4'd2: rcon = 32'h04000000;
      4'd3: rcon = 32'h08000000;
      4'd4: rcon = 32'h10000000;
      4'd5: rcon = 32'h20000000;
      4'd6: rcon = 32'h40000000;
      4'd7: rcon = 32'h80000000;
      4'd8: rcon = 32'h1b000000;
      4'd9: rcon = 32'h36000000;
      default: rcon = 32'h01000000;
    endcase
  end

  assign word_out = word_in ^ rcon;
endmodule

// -----------------------------------------------------------------------------
// [11/50] Module: RotWord
// Source   : rtl/AES-CTR/Key_Expansion/GFunction/RotWord.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module RotWord (
    input logic [31:0] word_in,

    output logic [31:0] word_out
);
  assign word_out = {word_in[23:0], word_in[31:24]};
endmodule

// -----------------------------------------------------------------------------
// [12/50] Module: SubWord
// Source   : rtl/AES-CTR/Key_Expansion/GFunction/SubWord.sv
// Submodules: SBox
// -----------------------------------------------------------------------------
module SubWord (
    input logic [31:0] word_in,

    output logic [31:0] word_out
);
  SBox sb1 (
      .byte_in (word_in[31:24]),
      .byte_out(word_out[31:24])
  );
  SBox sb2 (
      .byte_in (word_in[23:16]),
      .byte_out(word_out[23:16])
  );
  SBox sb3 (
      .byte_in (word_in[15:8]),
      .byte_out(word_out[15:8])
  );
  SBox sb4 (
      .byte_in (word_in[7:0]),
      .byte_out(word_out[7:0])
  );
endmodule

// -----------------------------------------------------------------------------
// [13/50] Module: GFunction
// Source   : rtl/AES-CTR/Key_Expansion/GFunction/GFunction.sv
// Submodules: AddRcon, RotWord, SubWord
// -----------------------------------------------------------------------------
module GFunction (
    input logic [31:0] word_in,
    input logic [ 3:0] round_index,

    output logic [31:0] word_out
);
  logic [31:0] after_rotword;
  logic [31:0] after_subword;

  RotWord rw1 (
      .word_in (word_in),
      .word_out(after_rotword)
  );
  SubWord sw1 (
      .word_in (after_rotword),
      .word_out(after_subword)
  );
  AddRcon arc1 (
      .word_in(after_subword),
      .round_index(round_index),
      .word_out(word_out)
  );
endmodule

// -----------------------------------------------------------------------------
// [14/50] Module: Counter
// Source   : rtl/AES-CTR/Key_Expansion/Counter.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module Counter (
    input logic clk,
    input logic rst_n,
    input logic expansion_en,

    output logic first_rkey,
    output logic expansion_finish,
    output logic [3:0] round_index
);
  assign first_rkey = (round_index == 4'd0);

  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      round_index      <= 4'd0;
      expansion_finish <= 1'b0;
    end else if (expansion_finish) begin
      if (!expansion_en) begin
        expansion_finish <= 1'b0;
        round_index      <= 4'd0;
      end
    end else if (expansion_en) begin
      if (round_index == 4'd9) begin
        round_index      <= 4'd0;
        expansion_finish <= 1'b1;
      end else begin
        round_index <= round_index + 1'b1;
      end
    end
  end
endmodule

// -----------------------------------------------------------------------------
// [15/50] Module: KeyExpansion
// Source   : rtl/AES-CTR/Key_Expansion/KeyExpansion.sv
// Submodules: Counter, GFunction
// -----------------------------------------------------------------------------
module KeyExpansion (
    input logic clk,
    input logic rst_n,
    input logic expansion_en,
    input logic [127:0] cipher_key,

    output logic [127:0] round_key[0:10],
    output logic expansion_finish
);
  logic [3:0] round_index;
  logic [127:0] current_key;
  logic [127:0] next_key;
  logic [31:0] after_GFunction;
  logic first_rkey;

  always_ff @(posedge clk, negedge rst_n) begin : RoundKeyReg
    if (!rst_n) begin
      integer i;
      for (i = 0; i <= 10; i++) begin
        round_key[i] <= 128'h0;
      end
    end else if (expansion_en) begin
      if (first_rkey) begin
        round_key[0] <= cipher_key;
      end
      case (round_index)
        4'd0: round_key[1] <= next_key;
        4'd1: round_key[2] <= next_key;
        4'd2: round_key[3] <= next_key;
        4'd3: round_key[4] <= next_key;
        4'd4: round_key[5] <= next_key;
        4'd5: round_key[6] <= next_key;
        4'd6: round_key[7] <= next_key;
        4'd7: round_key[8] <= next_key;
        4'd8: round_key[9] <= next_key;
        4'd9: round_key[10] <= next_key;
        default: ;
      endcase
    end
  end
  always_comb begin : FirstRoundKeyMUX
    if (first_rkey) begin
      current_key = cipher_key;
    end else begin
      case (round_index)
        4'd0: current_key = round_key[0];
        4'd1: current_key = round_key[1];
        4'd2: current_key = round_key[2];
        4'd3: current_key = round_key[3];
        4'd4: current_key = round_key[4];
        4'd5: current_key = round_key[5];
        4'd6: current_key = round_key[6];
        4'd7: current_key = round_key[7];
        4'd8: current_key = round_key[8];
        4'd9: current_key = round_key[9];
        default: current_key = 128'h0;
      endcase
    end
  end

  assign next_key[127:96] = after_GFunction ^ current_key[127:96];
  assign next_key[95:64]  = next_key[127:96] ^ current_key[95:64];
  assign next_key[63:32]  = next_key[95:64] ^ current_key[63:32];
  assign next_key[31:0]   = next_key[63:32] ^ current_key[31:0];

  Counter cnt1 (
      .clk(clk),
      .rst_n(rst_n),
      .expansion_en(expansion_en),
      .round_index(round_index),
      .first_rkey(first_rkey),
      .expansion_finish(expansion_finish)
  );
  GFunction gfunc1 (
      .word_in(current_key[31:0]),
      .round_index(round_index),
      .word_out(after_GFunction)
  );
endmodule

// -----------------------------------------------------------------------------
// [16/50] Module: CTR_counter
// Source   : rtl/AES-CTR/counter_generator/CTR_counter.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module CTR_counter
(   input logic clk, finish_reset,
    input logic counter_en,
    output logic CTR_counter_overflow,
    output logic [31:0] CTR_counter
);
    
    always_ff @( posedge clk or posedge finish_reset) begin
        if(finish_reset)
            CTR_counter <= 32'b0;
        else begin
            if(!CTR_counter_overflow&&counter_en)
                CTR_counter <= CTR_counter+1;
        end
    end
    assign CTR_counter_overflow = (CTR_counter == 32'hff_ff_ff_ff);
endmodule

// -----------------------------------------------------------------------------
// [17/50] Module: IV_register
// Source   : rtl/AES-CTR/counter_generator/IV_register.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module IV_register(
    input logic clk, finish_reset,
    input logic load_IV,
    input logic [95:0] IV,
    output logic IV_loaded,
    output logic [95:0] IV_out
);

    always_ff @(posedge clk or posedge finish_reset) begin
        if(finish_reset) begin
            IV_loaded <= 1'b0;
            IV_out <= 96'b0;
        end
        else begin
            if(load_IV) begin
                IV_out <= IV;
                IV_loaded <= 1'b1;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// [18/50] Module: J0_register
// Source   : rtl/AES-CTR/counter_generator/J0_register.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module J0_register(
    input logic clk, finish_reset,
    input logic [31:0] CTR_counter,
    input logic [127:0] counter_block,
    output logic [127:0] J0);
    
    always @(posedge clk or posedge finish_reset) begin
        if(finish_reset)
            J0 <= 128'b0;
        else begin
            if(CTR_counter == 32'b0)
                J0 <= counter_block;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// [19/50] Module: counter_block_generator
// Source   : rtl/AES-CTR/counter_generator/counter_block_generator.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module counter_block_generator(
    input logic [31:0] CTR_counter,
    input logic [95:0] IV_out,
    output logic [127:0] counter_block);
    
    assign counter_block = {IV_out,CTR_counter+32'b1};
endmodule

// -----------------------------------------------------------------------------
// [20/50] Module: output_unit
// Source   : rtl/AES-CTR/counter_generator/output_unit.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module output_unit(
    input logic [1:0] data_type,
    input logic [127:0] counter_block,
    input logic [127:0] J0,
    output logic [127:0] data_out
    );
    
    always_comb begin
        case(data_type)
            2'b01: data_out = 128'b0;
            2'b10: data_out = counter_block;
            2'b11: data_out = J0;
            default: data_out = 128'b0;
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// [21/50] Module: type_generator
// Source   : rtl/AES-CTR/counter_generator/type_generator.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module type_generator(
    input logic clk, rst_n,
    input logic load_key,load_data,
    input logic gen_J0,
    output logic [1:0] data_type
    );
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            data_type<=  2'b0;
        else begin
            if(load_key)
                data_type <= 2'b01;
            else begin
                if(load_data)
                    data_type <= 2'b10;
                else begin
                    if(gen_J0)
                        data_type <= 2'b11;
                    else
                        data_type <= 2'b00;
                end
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// [22/50] Module: counter_generator
// Source   : rtl/AES-CTR/counter_generator/counter_generator.sv
// Submodules: CTR_counter, IV_register, J0_register, counter_block_generator, output_unit, type_generator
// -----------------------------------------------------------------------------
module counter_generator(
    input logic clk,rst_n,
    input logic finish_reset,
    input logic load_key, load_data, 
    input logic gen_J0, load_IV,
    input logic [95:0] IV,
    output logic CTR_counter_overflow, IV_loaded, 
    output logic [1:0] data_type,
    output logic [127:0] data_out
    );

    logic [31:0] CTR_counter;
    CTR_counter coun (.clk(clk),.finish_reset(finish_reset),.counter_en(load_data),
                        .CTR_counter_overflow(CTR_counter_overflow),.CTR_counter(CTR_counter));
    logic [95:0] IV_out;
    IV_register IV_reg (.clk(clk),.load_IV(load_IV),.finish_reset(finish_reset),
                        .IV(IV),.IV_loaded(IV_loaded),.IV_out(IV_out));
    logic [127:0] counter_block;
    counter_block_generator CBG (.CTR_counter(CTR_counter),.IV_out(IV_out),
                                .counter_block(counter_block));
    logic [127:0] J0;
    J0_register J0_reg (.clk(clk),.finish_reset(finish_reset),.counter_block(counter_block),
                        .CTR_counter(CTR_counter),.J0(J0));
    type_generator gentype (.clk(clk),.rst_n(rst_n),.load_key(load_key),.load_data(load_data),
                            .gen_J0(gen_J0),.data_type(data_type));
    output_unit ou (.data_type(data_type),.counter_block(counter_block),.J0(J0),
                    .data_out(data_out));
endmodule

// -----------------------------------------------------------------------------
// [23/50] Module: FIFO_memory
// Source   : rtl/AES-CTR/FIFO/FIFO_memory.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module FIFO_memory#(
    parameter int DATA_SIZE = 128,
    parameter int DEPTH =16,
    parameter int PTR_WIDTH = $clog2(DEPTH)
    )(input logic clk,
    input logic r_en, w_en,
    input logic [PTR_WIDTH-1:0] r_ptr, w_ptr,
    input logic [DATA_SIZE-1:0] data_in,
    output logic [DATA_SIZE-1:0] data_out);
    logic [DATA_SIZE-1:0] memory_array [0:DEPTH-1];
    always_ff @(posedge clk ) begin
        if (w_en)
            memory_array[w_ptr] <= data_in;
        if (r_en)
            data_out <= memory_array[r_ptr];
    end
endmodule

// -----------------------------------------------------------------------------
// [24/50] Module: Read_pointer
// Source   : rtl/AES-CTR/FIFO/Read_pointer.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module Read_pointer#(
    parameter int PTR_WIDTH = 4)
    (input logic clk, rst_n,r_en,
    output logic [PTR_WIDTH-1:0] r_ptr);
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) 
            r_ptr <= '0;
        else if(r_en)
            r_ptr <= r_ptr + 1'b1;
    end
endmodule

// -----------------------------------------------------------------------------
// [25/50] Module: Write_pointer
// Source   : rtl/AES-CTR/FIFO/Write_pointer.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module Write_pointer #(
    parameter int PTR_WIDTH = 4)
    (input logic clk, rst_n, w_en,
    output logic [PTR_WIDTH-1:0] w_ptr);
    
    always_ff @ (posedge clk or negedge rst_n) begin
        if(!rst_n)
            w_ptr <= '0;
        else if (w_en) 
            w_ptr <= w_ptr+1'b1;
    end
endmodule

// -----------------------------------------------------------------------------
// [26/50] Module: FIFO
// Source   : rtl/AES-CTR/FIFO/FIFO.sv
// Submodules: FIFO_memory, Read_pointer
// -----------------------------------------------------------------------------
module FIFO#(
    parameter int DATA_SIZE = 128,
    parameter int DEPTH = 16,
    parameter int PTR_WIDTH = $clog2(DEPTH)
    )(
    input logic clk, rst_n,
    input logic [DATA_SIZE-1:0] data_in,
    input logic r_en, w_en,
    output logic [DATA_SIZE-1 :0] data_out);
    
    logic [PTR_WIDTH-1:0] w_ptr, r_ptr;
    Write_pointer#(.PTR_WIDTH(PTR_WIDTH)) W_p
                    (.clk(clk),.rst_n(rst_n),.w_en(w_en),.w_ptr(w_ptr));
    Read_pointer #(.PTR_WIDTH(PTR_WIDTH)) R_p 
                    (.clk(clk),.rst_n(rst_n),.r_en(r_en),.r_ptr(r_ptr));
    FIFO_memory #(.DATA_SIZE(DATA_SIZE),.DEPTH(DEPTH),.PTR_WIDTH(PTR_WIDTH)) F_mem
                        (.clk(clk),.r_en(r_en),.w_en(w_en),
                        .r_ptr(r_ptr), .w_ptr(w_ptr), .data_in(data_in),.data_out(data_out));
endmodule

// -----------------------------------------------------------------------------
// [27/50] Module: MUL_MixColumns
// Source   : rtl/AES-CTR/AES_encryption/AES_round/MixColumns/MUL_MixColumns.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module MUL_MixColumns( 
    input logic [7:0] Byte,
    output logic[7:0] Byte_mul2 , Byte_mul3);
    logic [7:0] ByteSL;
    assign ByteSL = Byte << 1;
    assign Byte_mul2 = Byte[7] ? (ByteSL ^ 8'h1b) : ByteSL;
    assign Byte_mul3 = Byte_mul2 ^ Byte;
endmodule

// -----------------------------------------------------------------------------
// [28/50] Module: MixCol
// Source   : rtl/AES-CTR/AES_encryption/AES_round/MixColumns/MixCol.sv
// Submodules: MUL_MixColumns
// -----------------------------------------------------------------------------
module MixCol( 
    input logic [31:0] Col_in,
    output logic [31:0] Col_out);
    logic [7:0] Byte0_mul2, Byte0_mul3;
    logic [7:0] Byte1_mul2, Byte1_mul3;
    logic [7:0] Byte2_mul2, Byte2_mul3;
    logic [7:0] Byte3_mul2, Byte3_mul3;
    MUL_MixColumns mul0 (.Byte(Col_in[31:24]), .Byte_mul2(Byte0_mul2),.Byte_mul3(Byte0_mul3));
    MUL_MixColumns mul1 (.Byte(Col_in[23:16]), .Byte_mul2(Byte1_mul2),.Byte_mul3(Byte1_mul3));
    MUL_MixColumns mul2 (.Byte(Col_in[15:8]), .Byte_mul2(Byte2_mul2),.Byte_mul3(Byte2_mul3));
    MUL_MixColumns mul3 (.Byte(Col_in[7:0]), .Byte_mul2(Byte3_mul2),.Byte_mul3(Byte3_mul3));
    assign Col_out[31:24] = Byte0_mul2^Byte1_mul3^Col_in[15:8]^Col_in[7:0];
    assign Col_out[23:16] = Byte1_mul2^Byte2_mul3^Col_in[31:24]^Col_in[7:0];
    assign Col_out[15:8] = Byte2_mul2^Byte3_mul3^Col_in[31:24]^Col_in[23:16];
    assign Col_out[7:0] = Byte3_mul2^Byte0_mul3^Col_in[15:8]^Col_in[23:16];
endmodule

// -----------------------------------------------------------------------------
// [29/50] Module: MixColumns
// Source   : rtl/AES-CTR/AES_encryption/AES_round/MixColumns/MixColumns.sv
// Submodules: MixCol
// -----------------------------------------------------------------------------
module MixColumns(
    input logic [127:0] MixColumns_in,
    output logic [127:0] MixColumns_out);
    MixCol Col0 (.Col_in(MixColumns_in[127:96]), .Col_out(MixColumns_out[127:96]));
    MixCol Col1 (.Col_in(MixColumns_in[95:64]), .Col_out(MixColumns_out[95:64]));
    MixCol Col2 (.Col_in(MixColumns_in[63:32]), .Col_out(MixColumns_out[63:32]));
    MixCol Col3 (.Col_in(MixColumns_in[31:0]), .Col_out(MixColumns_out[31:0]));
endmodule

// -----------------------------------------------------------------------------
// [30/50] Module: AddRoundKeys
// Source   : rtl/AES-CTR/AES_encryption/AES_round/AddRoundKeys.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module AddRoundKeys(
    input logic  [127:0] RoundKey, AddRoundKeys_in,
    output logic [127:0] AddRoundKeys_out);
    assign AddRoundKeys_out = AddRoundKeys_in ^ RoundKey;
endmodule

// -----------------------------------------------------------------------------
// [31/50] Module: AES_register
// Source   : rtl/AES-CTR/AES_encryption/AES_round/AES_register.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module AES_register(
    input logic clk,rst_n,
    input logic [1:0] data_type_in,
    input logic [127:0] data_in,
    output logic [127:0] data_out,
    output logic [1:0] data_type_out,
    output logic valid);
    
    assign valid = (data_type_in!= 2'b0);
    
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_out <= 128'b0;
            data_type_out <= 2'b0;
        end    
        else begin
            data_type_out <= data_type_in;
            if (valid)
                data_out <= data_in;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// [32/50] Module: ShiftRows
// Source   : rtl/AES-CTR/AES_encryption/AES_round/ShiftRows.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module ShiftRows( 
    input logic [127:0] ShiftRows_in,
    output logic [127:0] ShiftRows_out);
    // row 0
    assign ShiftRows_out[127:120] = ShiftRows_in[127:120] ;
    assign ShiftRows_out[95:88] = ShiftRows_in[95:88] ;
    assign ShiftRows_out[63:56] = ShiftRows_in[63:56] ;
    assign ShiftRows_out[31:24] = ShiftRows_in[31:24] ;
    // row 1
    assign ShiftRows_out[119:112] = ShiftRows_in[87:80] ;
    assign ShiftRows_out[87:80] = ShiftRows_in[55:48] ;
    assign ShiftRows_out[55:48] = ShiftRows_in[23:16] ;
    assign ShiftRows_out[23:16] = ShiftRows_in[119:112] ;
    // row 2
    assign ShiftRows_out[111:104] = ShiftRows_in[47:40] ;
    assign ShiftRows_out[79:72] = ShiftRows_in[15:8] ;
    assign ShiftRows_out[47:40] = ShiftRows_in[111:104] ;
    assign ShiftRows_out[15:8] = ShiftRows_in[79:72] ;
    //row 3
    assign ShiftRows_out[103:96] = ShiftRows_in[7:0] ;
    assign ShiftRows_out[71:64] = ShiftRows_in[103:96] ;
    assign ShiftRows_out[39:32] = ShiftRows_in[71:64] ;
    assign ShiftRows_out[7:0] = ShiftRows_in[39:32] ;
endmodule

// -----------------------------------------------------------------------------
// [33/50] Module: SubBytes
// Source   : rtl/AES-CTR/AES_encryption/AES_round/SubBytes.sv
// Submodules: SBox
// -----------------------------------------------------------------------------
module SubBytes(
    input logic [127:0] SubBytes_in,
    output logic [127:0] SubBytes_out);
    SBox Sbyte0 (.byte_in(SubBytes_in[127:120]),.byte_out(SubBytes_out[127:120]));
    SBox Sbyte1 (.byte_in(SubBytes_in[119:112]),.byte_out(SubBytes_out[119:112]));
    SBox Sbyte2 (.byte_in(SubBytes_in[111:104]),.byte_out(SubBytes_out[111:104]));
    SBox Sbyte3 (.byte_in(SubBytes_in[103:96]),.byte_out(SubBytes_out[103:96]));
    SBox Sbyte4 (.byte_in(SubBytes_in[95:88]),.byte_out(SubBytes_out[95:88]));
    SBox Sbyte5 (.byte_in(SubBytes_in[87:80]),.byte_out(SubBytes_out[87:80]));
    SBox Sbyte6 (.byte_in(SubBytes_in[79:72]),.byte_out(SubBytes_out[79:72]));
    SBox Sbyte7 (.byte_in(SubBytes_in[71:64]),.byte_out(SubBytes_out[71:64]));
    SBox Sbyte8 (.byte_in(SubBytes_in[63:56]),.byte_out(SubBytes_out[63:56]));
    SBox Sbyte9 (.byte_in(SubBytes_in[55:48]),.byte_out(SubBytes_out[55:48]));
    SBox Sbyte10 (.byte_in(SubBytes_in[47:40]),.byte_out(SubBytes_out[47:40]));
    SBox Sbyte11 (.byte_in(SubBytes_in[39:32]),.byte_out(SubBytes_out[39:32]));
    SBox Sbyte12 (.byte_in(SubBytes_in[31:24]),.byte_out(SubBytes_out[31:24]));
    SBox Sbyte13 (.byte_in(SubBytes_in[23:16]),.byte_out(SubBytes_out[23:16]));
    SBox Sbyte14 (.byte_in(SubBytes_in[15:8]),.byte_out(SubBytes_out[15:8]));
    SBox Sbyte15 (.byte_in(SubBytes_in[7:0]),.byte_out(SubBytes_out[7:0]));
endmodule

// -----------------------------------------------------------------------------
// [34/50] Module: AES_first_round
// Source   : rtl/AES-CTR/AES_encryption/AES_first_round.sv
// Submodules: AES_register, AddRoundKeys
// -----------------------------------------------------------------------------
module AES_first_round(
    input logic clk,rst_n,
    input logic [1:0] data_type_in,
    input logic [127:0] data_in,
    input logic [127:0] round_key,
    output logic [127:0] data_out,
    output logic [1:0] data_type_out,
    output logic valid);
    
    logic [127:0] register_out;
    AES_register AES_reg (.clk(clk),.rst_n(rst_n),.data_type_in(data_type_in),.data_in(data_in),
                    .data_out(register_out),.data_type_out(data_type_out),.valid(valid));
    AddRoundKeys ARK (.RoundKey(round_key),.AddRoundKeys_in(register_out),
                    .AddRoundKeys_out(data_out));
endmodule

// -----------------------------------------------------------------------------
// [35/50] Module: AES_round
// Source   : rtl/AES-CTR/AES_encryption/AES_round.sv
// Submodules: AES_register, AddRoundKeys, MixColumns, ShiftRows, SubBytes
// -----------------------------------------------------------------------------
module AES_round(
    input logic clk,rst_n,
    input logic [1:0] data_type_in,
    input logic [127:0] data_in,
    input logic [127:0] round_key,
    output logic [127:0] data_out,
    output logic [1:0] data_type_out,
    output logic valid);
    
    logic [127:0] register_out;
    AES_register AES_reg (.clk(clk),.rst_n(rst_n),.data_type_in(data_type_in),.data_in(data_in),
                    .data_out(register_out),.data_type_out(data_type_out),.valid(valid));
    logic [127:0] subbyte_out;
    SubBytes SB (.SubBytes_in(register_out),.SubBytes_out(subbyte_out));
    logic [127:0] shiftrow_out;
    ShiftRows SR (.ShiftRows_in(subbyte_out),.ShiftRows_out(shiftrow_out));
    logic [127:0] mixcolumn_out;
    MixColumns MC (.MixColumns_in(shiftrow_out),.MixColumns_out(mixcolumn_out));
    AddRoundKeys ARK (.RoundKey(round_key),.AddRoundKeys_in(mixcolumn_out),
                    .AddRoundKeys_out(data_out));
endmodule

// -----------------------------------------------------------------------------
// [36/50] Module: AES_last_round
// Source   : rtl/AES-CTR/AES_encryption/AES_last_round.sv
// Submodules: AES_register, AddRoundKeys, ShiftRows, SubBytes
// -----------------------------------------------------------------------------
module AES_last_round(
    input logic clk,rst_n,
    input logic [1:0] data_type_in,
    input logic [127:0] data_in,
    input logic [127:0] round_key,
    output logic [127:0] data_out,
    output logic [1:0] data_type_out,
    output logic valid);

    logic [127:0] register_out;
    AES_register AES_reg (.clk(clk),.rst_n(rst_n),.data_type_in(data_type_in),.data_in(data_in),
                    .data_out(register_out),.data_type_out(data_type_out),.valid(valid));
    logic [127:0] subbyte_out;
    SubBytes SB (.SubBytes_in(register_out),.SubBytes_out(subbyte_out));
    logic [127:0] shiftrow_out;
    ShiftRows SR (.ShiftRows_in(subbyte_out),.ShiftRows_out(shiftrow_out));
    AddRoundKeys ARK (.RoundKey(round_key),.AddRoundKeys_in(shiftrow_out),
                    .AddRoundKeys_out(data_out));
endmodule

// -----------------------------------------------------------------------------
// [37/50] Module: AES_encryption
// Source   : rtl/AES-CTR/AES_encryption/AES_encryption.sv
// Submodules: AES_first_round, AES_last_round, AES_register, AES_round
// -----------------------------------------------------------------------------
module AES_encryption(
    input logic clk,rst_n,
    input logic [127:0] data_in,
    input logic [127:0] round_key [0:10],
    input logic [1:0] data_type_in,
    output logic [127:0] data_out,
    output logic [1:0] data_type_out,
    output logic data_req, AES_finish);
    
    logic [1:0] data_type [0:10];
    logic [127:0] data [0:10];
    logic valid [0:11];
    // first round
    AES_first_round first_round (.clk(clk),.rst_n(rst_n),.data_type_in(data_type_in),
                                .data_in(data_in),.round_key(round_key[0]),
                                .data_out(data[0]),.data_type_out(data_type[0]),
                                .valid(valid[0]));
    // AES rounds
    AES_round R1 (.clk(clk),.rst_n(rst_n),.data_type_in(data_type[0]),.data_in(data[0]),
                .round_key(round_key[1]),.data_out(data[1]),.data_type_out(data_type[1]),
                .valid(valid[1]));
    
    AES_round R2 (.clk(clk),.rst_n(rst_n),.data_type_in(data_type[1]),.data_in(data[1]),
                .round_key(round_key[2]),.data_out(data[2]),.data_type_out(data_type[2]),
                .valid(valid[2]));
    
    AES_round R3 (.clk(clk),.rst_n(rst_n),.data_type_in(data_type[2]),.data_in(data[2]),
                .round_key(round_key[3]),.data_out(data[3]),.data_type_out(data_type[3]),
                .valid(valid[3]));
    
    AES_round R4 (.clk(clk),.rst_n(rst_n),.data_type_in(data_type[3]),.data_in(data[3]),
                .round_key(round_key[4]),.data_out(data[4]),.data_type_out(data_type[4]),
                .valid(valid[4]));
    
    AES_round R5 (.clk(clk),.rst_n(rst_n),.data_type_in(data_type[4]),.data_in(data[4]),
                .round_key(round_key[5]),.data_out(data[5]),.data_type_out(data_type[5]),
                .valid(valid[5]));
    
    AES_round R6 (.clk(clk),.rst_n(rst_n),.data_type_in(data_type[5]),.data_in(data[5]),
                .round_key(round_key[6]),.data_out(data[6]),.data_type_out(data_type[6]),
                .valid(valid[6]));
    
    AES_round R7 (.clk(clk),.rst_n(rst_n),.data_type_in(data_type[6]),.data_in(data[6]),
                .round_key(round_key[7]),.data_out(data[7]),.data_type_out(data_type[7]),
                .valid(valid[7]));
    
    AES_round R8 (.clk(clk),.rst_n(rst_n),.data_type_in(data_type[7]),.data_in(data[7]),
                .round_key(round_key[8]),.data_out(data[8]),.data_type_out(data_type[8]),
                .valid(valid[8]));
    
    AES_round R9 (.clk(clk),.rst_n(rst_n),.data_type_in(data_type[8]),.data_in(data[8]),
                .round_key(round_key[9]),.data_out(data[9]),.data_type_out(data_type[9]),
                .valid(valid[9]));
    //last round
    AES_last_round last_round (.clk(clk),.rst_n(rst_n),.data_type_in(data_type[9]),
                            .data_in(data[9]),.round_key(round_key[10]),.data_out(data[10]),
                            .data_type_out(data_type[10]),.valid(valid[10]));
    // last register
    AES_register reg11 (.clk(clk),.rst_n(rst_n),.data_type_in(data_type[10]),
                        .data_in(data[10]),.data_out(data_out),.data_type_out(data_type_out),
                        .valid(valid[11]));
    assign AES_finish = ~(valid[0]|valid[1]|valid[2]|valid[3]|valid[4]|valid[5]|valid[6]
                        |valid[7]|valid[8]|valid[9]|valid[10]|valid[11]);
    assign data_req = (data_type[10] == 2'b10);
endmodule

// -----------------------------------------------------------------------------
// [38/50] Module: AES_CTR
// Source   : rtl/AES-CTR/AES_CTR.sv
// Submodules: AES_encryption, FIFO, KeyExpansion, counter_generator
// -----------------------------------------------------------------------------
module AES_CTR(
    input logic clk, rst_n, finish_reset,
    input logic load_key, load_data, load_IV,
    input logic [127:0] cipher_key, data_in,
    input logic [95:0] IV,
    input logic expansion_en, mode,
    input logic data_in_last,
    output logic AES_finish, CTR_counter_overflow,
    output logic IV_loaded, expansion_finish,
    output logic [127:0] H, E, data_out, CT,
    output logic data_out_last,
    output logic H_valid, E_valid, data_valid,
    output logic CT_last, CT_valid);
    
    logic gen_J0;
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            gen_J0 <= 1'b0;
        else begin
            gen_J0 <= data_in_last;
        end
    end
    
    logic data_req;
    logic [128:0] FIFO_data_in;
    logic [128:0] FIFO_data;
    assign FIFO_data_in = {data_in_last,data_in};
    FIFO #(.DATA_SIZE(129),.DEPTH(16)) fifo 
            (.clk(clk),.rst_n(rst_n),.data_in(FIFO_data_in),.w_en(load_data),.r_en(data_req),
            .data_out(FIFO_data));
    logic [127:0] round_key [0:10];
    KeyExpansion key_expan (.clk(clk),.rst_n(rst_n),.expansion_en(expansion_en),
                            .cipher_key(cipher_key),.round_key(round_key),
                            .expansion_finish(expansion_finish));
    logic [127:0] AES_data_in;
    logic [1:0] data_type_in;
    counter_generator count_gen (.clk(clk),.rst_n(rst_n),.finish_reset(finish_reset),
                                .gen_J0(gen_J0),.load_key(load_key),.load_data(load_data),
                                .load_IV(load_IV),.IV(IV),.data_type(data_type_in),
                                .data_out(AES_data_in),.IV_loaded(IV_loaded),
                                .CTR_counter_overflow(CTR_counter_overflow));
    logic [127:0] AES_data_out;
    logic [1:0] data_type_out;
    AES_encryption AES (.clk(clk),.rst_n(rst_n),.data_in(AES_data_in),.round_key(round_key),
                        .data_type_in(data_type_in),.data_out(AES_data_out),
                        .data_type_out(data_type_out),.data_req(data_req),
                        .AES_finish(AES_finish));
    logic [127:0] keystream;
    logic keystream_valid;
    always_comb begin
        H = 128'b0;
        E = 128'b0;
        keystream = 128'b0;
        H_valid = 1'b0;
        keystream_valid = 1'b0;
        E_valid = 1'b0;
        case(data_type_out)
            2'b01: begin
                H = AES_data_out;
                H_valid = 1'b1;
            end
            2'b10: begin
                keystream = AES_data_out;
                keystream_valid = 1'b1;
            end
            2'b11: begin
                E = AES_data_out;
                E_valid = 1'b1;
            end
            default: begin
                H                = 128'b0;
                E                = 128'b0;
                keystream        = 128'b0;
                H_valid          = 1'b0;
                keystream_valid  = 1'b0;
                E_valid          = 1'b0;
            end
        endcase
    end
    
    always_ff @(posedge clk or negedge rst_n) begin: outReg
        if(!rst_n) begin
            data_valid    <= 1'b0;
            data_out_last <= 1'b0;
            data_out      <= 128'b0;
        end
        else begin
            data_valid <= keystream_valid;
            data_out_last <= FIFO_data[128] & keystream_valid;
            if (keystream_valid)
                data_out <= FIFO_data[127:0] ^ keystream;
            else
                data_out <= 128'b0;
        end
    end

    assign CT = mode? FIFO_data : (FIFO_data [127:0] ^ keystream); 
    assign CT_valid = keystream_valid;
    assign CT_last  = keystream_valid & FIFO_data[128];
endmodule

// -----------------------------------------------------------------------------
// [39/50] Module: X8
// Source   : rtl/GCM-GHASH/GF128bitMultiply.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module X8 (
    input logic [7:0] data_in1,
    input logic [7:0] data_in2,

    output logic [15:0] data_out
);
  wire [15:0] product0 = {8'd0, data_in1} & {16{data_in2[0]}};
  wire [15:0] product1 = {7'd0, data_in1, 1'd0} & {16{data_in2[1]}};
  wire [15:0] product2 = {6'd0, data_in1, 2'd0} & {16{data_in2[2]}};
  wire [15:0] product3 = {5'd0, data_in1, 3'd0} & {16{data_in2[3]}};
  wire [15:0] product4 = {4'd0, data_in1, 4'd0} & {16{data_in2[4]}};
  wire [15:0] product5 = {3'd0, data_in1, 5'd0} & {16{data_in2[5]}};
  wire [15:0] product6 = {2'd0, data_in1, 6'd0} & {16{data_in2[6]}};
  wire [15:0] product7 = {1'd0, data_in1, 7'd0} & {16{data_in2[7]}};

  assign data_out = product0 ^ product1
                    ^ product2 ^ product3
                    ^ product4 ^ product5
                    ^ product6 ^ product7;
endmodule

// -----------------------------------------------------------------------------
// [40/50] Module: X16
// Source   : rtl/GCM-GHASH/GF128bitMultiply.sv
// Submodules: X8
// -----------------------------------------------------------------------------
module X16 (
    input logic [15:0] data_in1,
    input logic [15:0] data_in2,

    output logic [31:0] data_out
);
  logic [15:0] P0_result, P1_result, P2_result;
  wire [ 7:0] data_in1_P2 = data_in1[15:8] ^ data_in1[7:0];
  wire [ 7:0] data_in2_P2 = data_in2[15:8] ^ data_in2[7:0];
  wire [15:0] Pm = P0_result ^ P1_result ^ P2_result;

  X8 P1 (
      .data_in1(data_in1[15:8]),
      .data_in2(data_in2[15:8]),
      .data_out(P1_result)
  );
  X8 P0 (
      .data_in1(data_in1[7:0]),
      .data_in2(data_in2[7:0]),
      .data_out(P0_result)
  );
  X8 P2 (
      .data_in1(data_in1_P2),
      .data_in2(data_in2_P2),
      .data_out(P2_result)
  );

  assign data_out[31:24] = P1_result[15:8];
  assign data_out[23:16] = P1_result[7:0] ^ Pm[15:8];
  assign data_out[15:8]  = P0_result[15:8] ^ Pm[7:0];
  assign data_out[7:0]   = P0_result[7:0];
endmodule

// -----------------------------------------------------------------------------
// [41/50] Module: X32
// Source   : rtl/GCM-GHASH/GF128bitMultiply.sv
// Submodules: X16
// -----------------------------------------------------------------------------
module X32 (
    input logic [31:0] data_in1,
    input logic [31:0] data_in2,

    output logic [63:0] data_out
);
  logic [31:0] P0_result, P1_result, P2_result;
  wire [15:0] data_in1_P2 = data_in1[31:16] ^ data_in1[15:0];
  wire [15:0] data_in2_P2 = data_in2[31:16] ^ data_in2[15:0];
  wire [31:0] Pm = P0_result ^ P1_result ^ P2_result;

  X16 P1 (
      .data_in1(data_in1[31:16]),
      .data_in2(data_in2[31:16]),
      .data_out(P1_result)
  );
  X16 P0 (
      .data_in1(data_in1[15:0]),
      .data_in2(data_in2[15:0]),
      .data_out(P0_result)
  );
  X16 P2 (
      .data_in1(data_in1_P2),
      .data_in2(data_in2_P2),
      .data_out(P2_result)
  );

  assign data_out[63:48] = P1_result[31:16];
  assign data_out[47:32] = P1_result[15:0] ^ Pm[31:16];
  assign data_out[31:16] = P0_result[31:16] ^ Pm[15:0];
  assign data_out[15:0]  = P0_result[15:0];
endmodule

// -----------------------------------------------------------------------------
// [42/50] Module: X64
// Source   : rtl/GCM-GHASH/GF128bitMultiply.sv
// Submodules: X32
// -----------------------------------------------------------------------------
module X64 (
    input logic [63:0] data_in1,
    input logic [63:0] data_in2,

    output logic [127:0] data_out
);
  logic [63:0] P0_result, P1_result, P2_result;
  wire [31:0] data_in1_P2 = data_in1[63:32] ^ data_in1[31:0];
  wire [31:0] data_in2_P2 = data_in2[63:32] ^ data_in2[31:0];
  wire [63:0] Pm = P0_result ^ P1_result ^ P2_result;

  X32 P1 (
      .data_in1(data_in1[63:32]),
      .data_in2(data_in2[63:32]),
      .data_out(P1_result)
  );
  X32 P0 (
      .data_in1(data_in1[31:0]),
      .data_in2(data_in2[31:0]),
      .data_out(P0_result)
  );
  X32 P2 (
      .data_in1(data_in1_P2),
      .data_in2(data_in2_P2),
      .data_out(P2_result)
  );

  assign data_out[127:96] = P1_result[63:32];
  assign data_out[95:64]  = P1_result[31:0] ^ Pm[63:32];
  assign data_out[63:32]  = P0_result[63:32] ^ Pm[31:0];
  assign data_out[31:0]   = P0_result[31:0];
endmodule

// -----------------------------------------------------------------------------
// [43/50] Module: X128
// Source   : rtl/GCM-GHASH/GF128bitMultiply.sv
// Submodules: X64
// -----------------------------------------------------------------------------
module X128 (
    input logic [127:0] H_reg,
    input logic [127:0] data_in,

    output logic [255:0] data_out
);
  logic [127:0] P0_result, P1_result, P2_result;
  wire [ 63:0] data_in1_P2 = H_reg[127:64] ^ H_reg[63:0];
  wire [ 63:0] data_in2_P2 = data_in[127:64] ^ data_in[63:0];
  wire [127:0] Pm = P0_result ^ P1_result ^ P2_result;

  X64 P1 (
      .data_in1(H_reg[127:64]),
      .data_in2(data_in[127:64]),
      .data_out(P1_result)
  );
  X64 P0 (
      .data_in1(H_reg[63:0]),
      .data_in2(data_in[63:0]),
      .data_out(P0_result)
  );
  X64 P2 (
      .data_in1(data_in1_P2),
      .data_in2(data_in2_P2),
      .data_out(P2_result)
  );

  assign data_out[255:192] = P1_result[127:64];
  assign data_out[191:128] = P1_result[63:0] ^ Pm[127:64];
  assign data_out[127:64]  = P0_result[127:64] ^ Pm[63:0];
  assign data_out[63:0]    = P0_result[63:0];
endmodule

// -----------------------------------------------------------------------------
// [44/50] Module: ReductionBlock
// Source   : rtl/GCM-GHASH/GF128bitMultiply.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module ReductionBlock (
    input logic [255:0] data_in,

    output logic [127:0] data_out
);
  wire [134:0] xor_1 = {7'd0, data_in[127:0]}
                        ^ {7'd0, data_in[255:128]}
                        ^ {6'd0, data_in[255:128], 1'd0}
                        ^ {5'd0, data_in[255:128], 2'd0}
                        ^ {data_in[255:128], 7'd0};

  assign data_out = xor_1[127:0]
                    ^ {121'd0, xor_1[134:128]}
                    ^ {120'd0, xor_1[134:128], 1'd0}
                    ^ {119'd0, xor_1[134:128], 2'd0}
                    ^ {114'd0, xor_1[134:128], 7'd0};
endmodule

// -----------------------------------------------------------------------------
// [45/50] Module: GF128bitMultiply
// Source   : rtl/GCM-GHASH/GF128bitMultiply.sv
// Submodules: ReductionBlock, X128
// -----------------------------------------------------------------------------
module GF128bitMultiply (
    input logic [127:0] H_reg,
    input logic [127:0] data_in,

    output logic [127:0] data_out
);
  logic [255:0] X128_result;

  X128 Product (
      .H_reg(H_reg),
      .data_in(data_in),
      .data_out(X128_result)
  );

  ReductionBlock RB (
      .data_in (X128_result),
      .data_out(data_out)
  );
endmodule

// -----------------------------------------------------------------------------
// [46/50] Module: GHASH
// Source   : rtl/GCM-GHASH/GHASH.sv
// Submodules: GF128bitMultiply
// -----------------------------------------------------------------------------
module GHASH (
    input logic         clk,
    input logic         finish_reset,
    input logic         load_AAD,
    input logic         load_CT,
    input logic         length_block_valid,
    input logic [127:0] AAD,
    input logic [127:0] CT,
    input logic [127:0] length_block,
    input logic [127:0] H_reg,

    output logic         ghash_finish,
    output logic [127:0] ghash_out
);
  logic         ghash_en;
  logic [127:0] data_in;
  logic [127:0] multiply_in;
  logic [127:0] multiply_out;

  always_comb begin : DataInputMUX
    if (load_AAD) begin
      data_in = AAD;
    end else if (load_CT) begin
      data_in = CT;
    end else if (length_block_valid) begin
      data_in = length_block;
    end else begin
      data_in = 128'h0;
    end
  end

  assign ghash_en = (load_AAD ^ load_CT ^ length_block_valid) & !ghash_finish;
  assign multiply_in = ghash_out ^ data_in;

  GF128bitMultiply GFMultiply1 (
      .H_reg(H_reg),
      .data_in(multiply_in),
      .data_out(multiply_out)
  );

  always_ff @(posedge clk, posedge finish_reset) begin : GHASHReg
    if (finish_reset) begin
      ghash_out <= 128'h0;
    end else if (ghash_en) begin
      ghash_out <= multiply_out;
    end
  end

  always_ff @(posedge clk, posedge finish_reset) begin : GHASHfinishReg
    if (finish_reset) begin
      ghash_finish <= 1'b0;
    end else begin
      if (length_block_valid) begin
        ghash_finish <= 1'b1;
      end
    end
  end
endmodule

// -----------------------------------------------------------------------------
// [47/50] Module: LengthBlockCounter
// Source   : rtl/GCM-GHASH/LengthBlockCounter.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module LengthBlockCounter (
    input logic clk,
    input logic finish_reset,
    input logic load_AAD,
    input logic load_CT,
    input logic CT_last,

    output logic         length_block_valid,
    output logic [127:0] length_block
);
  logic [60:0] AAD_cnt;
  logic [60:0] CT_cnt;

  assign length_block = {AAD_cnt, 3'd0, CT_cnt, 3'd0};

  always_ff @(posedge clk, posedge finish_reset) begin : AADCounter
    if (finish_reset) begin
      AAD_cnt <= 61'd0;
    end else if (load_AAD) begin
      AAD_cnt <= AAD_cnt + 61'd16;
    end
  end

  always_ff @(posedge clk, posedge finish_reset) begin : CTCounter
    if (finish_reset) begin
      CT_cnt <= 61'd0;
    end else if (load_CT) begin
      CT_cnt <= CT_cnt + 61'd16;
    end
  end

  always_ff @(posedge clk, posedge finish_reset) begin : LengthBlockValidReg
    if (finish_reset) begin
      length_block_valid <= 1'b0;
    end else begin
      length_block_valid <= CT_last;
    end
  end
endmodule

// -----------------------------------------------------------------------------
// [48/50] Module: TagProcessing
// Source   : rtl/GCM-GHASH/TagProcessing.sv
// Submodules: GHASH, LengthBlockCounter
// -----------------------------------------------------------------------------
module TagProcessing (
    input logic         clk,
    input logic         rst_n,
    input logic         finish_reset,
    input logic         load_key,
    input logic         mode,
    input logic [127:0] AAD,
    input logic [127:0] CT,
    input logic [127:0] tag_ref,
    input logic [127:0] H,
    input logic [127:0] E,
    input logic         load_AAD,
    input logic         load_CT,
    input logic         H_valid,
    input logic         E_valid,
    input logic         load_tag_ref,
    input logic         CT_last,

    output logic         H_loaded,
    output logic         tag_ref_loaded,
    output logic [127:0] tag,
    output logic         tag_process_valid,
    output logic         verify_pass
);
  logic         H_reset;
  logic         length_block_valid;
  logic         E_loaded;
  logic         ghash_finish;
  logic [127:0] H_reg;
  logic [127:0] E_reg;
  logic [127:0] tag_ref_reg;
  logic [127:0] length_block;
  logic [127:0] ghash_out;

  assign H_reset = ~rst_n | load_key;
  assign verify_pass = mode && tag_process_valid && (tag == tag_ref_reg);

  always_ff @(posedge clk, posedge finish_reset) begin : TagReg
    if (finish_reset) begin
      tag <= 128'h0;
    end else begin
      if (ghash_finish && E_loaded) begin
        tag <= ghash_out ^ E_reg;
      end else begin
        tag <= 128'h0;
      end
    end
  end

  always_ff @(posedge clk, posedge finish_reset) begin : TagProcessValidReg
    if (finish_reset) begin
      tag_process_valid <= 1'b0;
    end else begin
      tag_process_valid <= ghash_finish & E_loaded;
    end
  end

  always_ff @(posedge clk, posedge H_reset) begin : HLoadedReg
    if (H_reset) begin
      H_loaded <= 1'b0;
    end else if (H_valid && !H_loaded) begin
      H_loaded <= 1'b1;
    end
  end

  always_ff @(posedge clk, posedge H_reset) begin : HKeyReg
    if (H_reset) begin
      H_reg <= 128'h0;
    end else if (H_valid && !H_loaded) begin
      H_reg <= H;
    end
  end

  always_ff @(posedge clk, posedge finish_reset) begin : ELoadedReg
    if (finish_reset) begin
      E_loaded <= 1'b0;
    end else if (E_valid && !E_loaded) begin
      E_loaded <= 1'b1;
    end
  end

  always_ff @(posedge clk, posedge finish_reset) begin : EKeyReg
    if (finish_reset) begin
      E_reg <= 128'h0;
    end else if (E_valid && !E_loaded) begin
      E_reg <= E;
    end
  end

  always_ff @(posedge clk, posedge finish_reset) begin : TagRefLoadedReg
    if (finish_reset) begin
      tag_ref_loaded <= 1'b0;
    end else if (load_tag_ref && !tag_ref_loaded) begin
      tag_ref_loaded <= 1'b1;
    end
  end

  always_ff @(posedge clk, posedge finish_reset) begin : TagReferenceReg
    if (finish_reset) begin
      tag_ref_reg <= 128'h0;
    end else if (load_tag_ref && !tag_ref_loaded) begin
      tag_ref_reg <= tag_ref;
    end
  end

  LengthBlockCounter LengthCounter (
      .clk               (clk),
      .finish_reset      (finish_reset),
      .load_AAD          (load_AAD),
      .load_CT           (load_CT),
      .CT_last           (CT_last),
      .length_block_valid(length_block_valid),
      .length_block      (length_block)
  );

  GHASH GHASHCore (
      .clk               (clk),
      .finish_reset      (finish_reset),
      .load_AAD          (load_AAD),
      .load_CT           (load_CT),
      .length_block_valid(length_block_valid),
      .AAD               (AAD),
      .CT                (CT),
      .length_block      (length_block),
      .H_reg             (H_reg),
      .ghash_finish      (ghash_finish),
      .ghash_out         (ghash_out)
  );
endmodule

// -----------------------------------------------------------------------------
// [49/50] Module: CU
// Source   : rtl/CU/CU.sv
// Submodules: None (Leaf module)
// -----------------------------------------------------------------------------
module CU(
    input logic clk, rst_n,
    input logic start, load_key,
    input logic expansion_finish,
    input logic H_loaded, IV_loaded,
    input logic tag_ref_loaded, mode,
    input logic load_AAD, no_AAD, AAD_last,
    input logic load_data, data_in_last,
    input logic process_finish, verify_checked,
    input logic CTR_counter_overflow,
    output logic expansion_en,
    output logic finish,
    output logic key_ready, IV_ready,
    output logic tag_ref_ready,
    output logic AAD_ready, data_ready,
    output logic verify_done
    );
    
    typedef enum logic [3:0] {
        IDLE,
        KEY_EXPANSION,
        WAIT_H_CAL,
        WAIT_TAG_REF,
        WAIT_AAD,
        LOAD_AAD,
        WAIT_DATA,
        LOAD_DATA,
        WAIT_PROCESS_FINISH,
        VERIFY_PASS,
        FINISH
        } state;
    state Current, Next;
    // state register
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n)
            Current <= IDLE;
        else
            Current <= Next;
    end
    // next-stage logic
    always_comb begin
        Next = Current;
        case(Current)
            IDLE: begin
                if(start) begin
                    if(load_key)
                        Next = KEY_EXPANSION;
                    else begin
                        if(mode) 
                            Next = WAIT_TAG_REF;
                        else 
                            Next = WAIT_AAD;
                    end
                end
            end
            KEY_EXPANSION: begin
                if(expansion_finish)
                    Next = WAIT_H_CAL;
            end
            WAIT_H_CAL: begin
                if(H_loaded && IV_loaded) begin
                    if(!tag_ref_loaded&&mode)
                        Next = WAIT_TAG_REF;
                    else
                        Next = WAIT_AAD;
                end
            end
            WAIT_TAG_REF: begin
                if(tag_ref_loaded)
                    Next = WAIT_AAD;
            end
            WAIT_AAD: begin
                if(no_AAD)
                    Next = WAIT_DATA;
                else begin
                    if(load_AAD) begin
                        if(AAD_last)
                            Next = WAIT_DATA;
                        else
                            Next = LOAD_AAD;
                    end
                end
            end
            LOAD_AAD: begin
                if(AAD_last)
                    Next = WAIT_DATA;
            end
            WAIT_DATA: begin
                if(load_data) begin
                    if(data_in_last)
                        Next = WAIT_PROCESS_FINISH;
                    else
                        Next = LOAD_DATA;
                end
            end
            LOAD_DATA: begin
                if(data_in_last)
                    Next = WAIT_PROCESS_FINISH;
            end
            WAIT_PROCESS_FINISH: begin
                if(process_finish) begin
                    if (mode) 
                        Next = VERIFY_PASS;
                    else
                        Next = FINISH;
                end
            end
            VERIFY_PASS: begin
                if(verify_checked)
                    Next = FINISH;
            end
            FINISH: begin
                Next = IDLE;
            end
            default: begin
                Next = IDLE;
            end
        endcase
    end
    // output logic stage
    always_comb begin
        expansion_en  = 1'b0;
        finish        = 1'b0;
        key_ready     = 1'b0;
        IV_ready      = 1'b0;
        tag_ref_ready = 1'b0;
        AAD_ready     = 1'b0;
        data_ready    = 1'b0;
        verify_done   = 1'b0;
        case(Current)
            IDLE: begin
                key_ready = 1'b1;
                if(H_loaded)
                    IV_ready = 1'b1;
            end
            KEY_EXPANSION: begin
                expansion_en = 1'b1;
                if(!IV_loaded)
                    IV_ready = 1'b1;
                if (!tag_ref_loaded&&mode)
                    tag_ref_ready = 1'b1;
            end
            WAIT_H_CAL: begin
                if(!IV_loaded)
                    IV_ready = 1'b1;
                if (!tag_ref_loaded&&mode)
                    tag_ref_ready = 1'b1;
            end
            WAIT_TAG_REF: begin
                if (!tag_ref_loaded&&mode)
                    tag_ref_ready = 1'b1;
            end
            WAIT_AAD: begin
                AAD_ready = 1'b1;
            end
            LOAD_AAD: begin
                AAD_ready = 1'b1;
            end
            WAIT_DATA: begin
                data_ready = 1'b1;
            end
            LOAD_DATA: begin
                if (!CTR_counter_overflow)
                    data_ready = 1'b1;
                else
                    data_ready = 1'b0;
            end
            VERIFY_PASS: begin
                verify_done = 1'b1;
            end
            FINISH: begin
                finish = 1'b1;
            end
            default: begin
                expansion_en  = 1'b0;
                finish        = 1'b0;
                key_ready     = 1'b0;
                IV_ready      = 1'b0;
                tag_ref_ready = 1'b0;
                AAD_ready     = 1'b0;
                data_ready    = 1'b0;
                verify_done   = 1'b0;
            end
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// [50/50] Module: AES_GCM
// Source   : rtl/AES_GCM.sv
// Submodules: AES_CTR, CU, TagProcessing
// -----------------------------------------------------------------------------
module AES_GCM(
    input logic clk, rst_n,
    input logic load_key, load_IV,
    input logic mode, load_tag_ref,
    input logic load_AAD, no_AAD, AAD_last,
    input logic load_data, data_in_last,
    input logic verify_checked,
    input logic [127:0] cipher_key, tag_ref,
    input logic [127:0] AAD, data_in,
    input logic [95:0] IV,
    output logic tag_valid, verify_pass, verify_done,
    output logic CTR_counter_overflow,
    output logic data_valid, data_out_last,
    output logic finish, tag_ref_ready,
    output logic key_ready, IV_ready,
    output logic AAD_ready, data_ready,
    output logic [127:0] tag, data_out
    );

    logic start, finish_reset;
    assign start = load_key | load_IV;
    assign finish_reset = (~rst_n) | finish;
    
    logic expansion_en, expansion_finish;
    logic AES_finish, IV_loaded;
    logic [127:0] H, E, CT;
    logic H_valid, E_valid, CT_valid;
    logic CT_last;
    
    AES_CTR AES (.clk(clk),.rst_n(rst_n),.finish_reset(finish_reset),.load_key(load_key),
                .load_IV(load_IV),.load_data(load_data),.cipher_key(cipher_key),
                .data_in(data_in),.IV(IV),.expansion_en(expansion_en),.mode(mode),
                .data_in_last(data_in_last),.AES_finish(AES_finish),.IV_loaded(IV_loaded),
                .CTR_counter_overflow(CTR_counter_overflow),.expansion_finish(expansion_finish),
                .H(H),.E(E),.data_out(data_out),.CT(CT),.data_out_last(data_out_last),
                .H_valid(H_valid),.E_valid(E_valid),.data_valid(data_valid),.CT_valid(CT_valid),
                .CT_last(CT_last));
    
    logic H_loaded, tag_ref_loaded, tag_process_finish;
    
    TagProcessing tag_pro (.clk(clk),.rst_n(rst_n),.finish_reset(finish_reset),
                            .load_key(load_key),.mode(mode),.AAD(AAD),.CT(CT),
                            .tag_ref(tag_ref),.H(H),.E(E),.load_AAD(load_AAD),
                            .load_CT(CT_valid),.H_valid(H_valid),.E_valid(E_valid),
                            .load_tag_ref(load_tag_ref),.CT_last(CT_last),.H_loaded(H_loaded),
                            .tag_ref_loaded(tag_ref_loaded),.tag(tag),
                            .tag_process_valid(tag_process_finish),.verify_pass(verify_pass));
    
    logic process_finish;
    assign process_finish = AES_finish & tag_process_finish;
    CU cu (.clk(clk),.rst_n(rst_n),.start(start),.load_key(load_key),
            .expansion_finish(expansion_finish),.H_loaded(H_loaded),.IV_loaded(IV_loaded),
            .tag_ref_loaded(tag_ref_loaded),.mode(mode),.load_AAD(load_AAD),.no_AAD(no_AAD),
            .AAD_last(AAD_last),.load_data(load_data),.data_in_last(data_in_last),
            .process_finish(process_finish),.expansion_en(expansion_en),.finish(finish),
            .key_ready(key_ready),.IV_ready(IV_ready),.tag_ref_ready(tag_ref_ready),
            .AAD_ready(AAD_ready),.data_ready(data_ready),
            .CTR_counter_overflow(CTR_counter_overflow),
            .verify_checked(verify_checked),.verify_done(verify_done));

    
    assign tag_valid = (~mode) & tag_process_finish;
endmodule

