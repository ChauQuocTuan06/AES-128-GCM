// ============================================================================
// Project     : AES-128-GCM Verification Environment
// File        : test_pkg.sv
// Description : Package aggregating all test classes and inheriting env_pkg
// ============================================================================

package test_pkg;

  import env_pkg::*;

  `include "base_test.sv"
  `include "test_nist_kat.sv"
  `include "test_coverage_full.sv"
  `include "test_decryption_errors.sv"
  `include "test_x_propagation.sv"
  `include "test_reset.sv"
  `include "test_stress.sv"
  `include "test_all.sv"

endpackage : test_pkg
