# ==============================================================================
# QuestaSim / ModelSim Static Lint Script
# Usage (inside QuestaSim console from sim/ directory):
#   do ../scripts/lint.do
# ==============================================================================

if [file exists work] {
    echo "Info: Using work library..."
} else {
    vlib work
    vmap work work
}

echo "=========================================================="
echo " Running QuestaSim Built-in Lint on Monolithic RTL..."
echo "=========================================================="

# -lint: Bật kiểm tra lỗi thiết kế tĩnh (width mismatches, undriven nets, latches,...)
# -hazards: Bật kiểm tra race conditions / read-write hazards
vlog -sv -timescale "1ns/1ps" -lint -hazards ../rtl/aes_128_gcm_all.sv

echo "=========================================================="
echo " QuestaSim Lint Finished!"
echo "=========================================================="
