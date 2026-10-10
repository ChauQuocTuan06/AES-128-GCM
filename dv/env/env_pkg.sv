// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : env_pkg.sv
// Description : Package aggregating all verification environment components
// ============================================================================

package env_pkg;

  // =========================================================================
  // DPI-C Golden Reference Model Imports (Compiled from C Reference Model)
  // =========================================================================
  import "DPI-C" context function void c_aes128_gcm_encrypt(
    input  byte unsigned key[16],
    input  byte unsigned iv[12],
    input  byte unsigned aad[256],
    input  int           aad_len,
    input  byte unsigned plaintext[256],
    input  int           plaintext_len,
    output byte unsigned ciphertext[256],
    output byte unsigned tag[16],
    input  int           rtl_mode
  );

  import "DPI-C" context function int c_aes128_gcm_decrypt(
    input  byte unsigned key[16],
    input  byte unsigned iv[12],
    input  byte unsigned aad[256],
    input  int           aad_len,
    input  byte unsigned ciphertext[256],
    input  int           ciphertext_len,
    input  byte unsigned tag_ref[16],
    output byte unsigned plaintext[256],
    output byte unsigned expected_tag[16],
    input  int           rtl_mode
  );

  `include "transaction.sv"
  `include "coverage.sv"
  `include "generator.sv"
  `include "driver.sv"
  `include "monitor.sv"
  `include "scoreboard.sv"
  `include "environment.sv"

endpackage : env_pkg
