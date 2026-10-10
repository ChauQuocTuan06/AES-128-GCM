# ==============================================================================
# QuestaSim / ModelSim Compilation Script
# Usage (inside QuestaSim console from sim/ directory):
#   do ../scripts/compile.do
# ==============================================================================

# Create work library if it does not exist
if [file exists work] {
    echo "Info: Using existing work library..."
} else {
    echo "Info: Creating work library..."
    vlib work
    vmap work work
}

echo "=========================================="
echo "Compiling RTL Files..."
echo "=========================================="
# Chế độ 1: Biên dịch từ 1 file duy nhất chứa toàn bộ lõi (Khuyến nghị)
vlog -sv -timescale "1ns/1ps" ../rtl/aes_128_gcm_all.sv

# Chế độ 2: Biên dịch từ danh sách 38 file rời (bỏ comment nếu muốn dùng filelist)
# vlog -sv -timescale "1ns/1ps" -f ../scripts/filelist_rtl.f

echo "=========================================="
echo "Compiling DV Files..."
echo "=========================================="
vlog -sv -timescale "1ns/1ps" -f ../scripts/filelist_dv.f

echo "=========================================="
echo "Compilation Finished Successfully!"
echo "=========================================="
