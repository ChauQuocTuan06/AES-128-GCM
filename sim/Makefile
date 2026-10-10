# ==============================================================================
# Makefile for QuestaSim / ModelSim Simulation
# Run from inside the sim/ directory:
#   make compile   -> Compile RTL and TB
#   make run       -> Run simulation in CLI/batch mode
#   make gui       -> Run simulation with QuestaSim GUI and wave
#   make clean     -> Clean generated simulation files
# ==============================================================================

VSIM      ?= vsim
VLIB      ?= vlib
VMAP      ?= vmap
VLOG      ?= vlog

TB_TOP    ?= tb_top
VSIM_OPT  ?= -voptargs="+acc"

.PHONY: all build compile run gui lint clean

all: run

lint:
	@echo "--- Running static lint check ---"
	$(VSIM) -c -do "do ../scripts/lint.do; quit -f"


build compile:
	@echo "--- Compiling design and testbench ---"
	$(VSIM) -c -do "do ../scripts/compile.do; quit -f"

run:
	@echo "--- Running simulation in batch mode ---"
	$(VSIM) -c -do "do ../scripts/run.do; quit -f"

gui:
	@echo "--- Running simulation in GUI mode ---"
	$(VSIM) -gui -do "do ../scripts/run.do"

clean:
	@echo "--- Cleaning simulation artifacts ---"
	rm -rf work transcript *.wlf *.log *.vstf covhtmlreport modelsim.ini vsim.dbg
