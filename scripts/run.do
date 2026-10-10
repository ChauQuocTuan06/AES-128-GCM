# ==============================================================================
# QuestaSim / ModelSim Top-Level Run Script
# Usage (inside QuestaSim console from sim/ directory):
#   do ../scripts/run.do
# ==============================================================================

# 1. Compile
do ../scripts/compile.do

# 2. Elaborate & Load Simulation with DPI-C Golden Model and Coverage
# -sv_lib loads dv/dpi/aes_gcm_dpi.dll
# -coverage enables functional and code coverage collection
vsim -coverage -sv_lib ../dv/dpi/aes_gcm_dpi -voptargs="+acc" work.tb_top

# 3. Add Waves (only in GUI mode)
if {[batch_mode] == 0} {
    do ../scripts/wave.do
}

# 4. Run Simulation
run -all

# 5. Questa Coverage Report
coverage report -detail -cvg
