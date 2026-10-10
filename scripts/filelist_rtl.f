# ==============================================================================
# RTL Filelist for AES-128-GCM
# Relative to execution directory (sim/)
# ==============================================================================

# SBox
../rtl/AES-CTR/SBox/AffineTransform.sv
../rtl/AES-CTR/SBox/MultiplicativeInv.sv
../rtl/AES-CTR/SBox/SBox.sv

# Key Expansion
../rtl/AES-CTR/Key_Expansion/GFunction/AddRcon.sv
../rtl/AES-CTR/Key_Expansion/GFunction/RotWord.sv
../rtl/AES-CTR/Key_Expansion/GFunction/SubWord.sv
../rtl/AES-CTR/Key_Expansion/GFunction/GFunction.sv
../rtl/AES-CTR/Key_Expansion/Counter.sv
../rtl/AES-CTR/Key_Expansion/KeyExpansion.sv

# Counter Generator
../rtl/AES-CTR/counter_generator/CTR_counter.sv
../rtl/AES-CTR/counter_generator/IV_register.sv
../rtl/AES-CTR/counter_generator/J0_register.sv
../rtl/AES-CTR/counter_generator/counter_block_generator.sv
../rtl/AES-CTR/counter_generator/output_unit.sv
../rtl/AES-CTR/counter_generator/type_generator.sv
../rtl/AES-CTR/counter_generator/counter_generator.sv

# FIFO
../rtl/AES-CTR/FIFO/FIFO_memory.sv
../rtl/AES-CTR/FIFO/Read_pointer.sv
../rtl/AES-CTR/FIFO/Write_pointer.sv
../rtl/AES-CTR/FIFO/FIFO.sv

# AES Core & Encryption Rounds
../rtl/AES-CTR/AES_encryption/AES_round/MixColumns/MUL_MixColumns.sv
../rtl/AES-CTR/AES_encryption/AES_round/MixColumns/MixCol.sv
../rtl/AES-CTR/AES_encryption/AES_round/MixColumns/MixColumns.sv
../rtl/AES-CTR/AES_encryption/AES_round/AddRoundKeys.sv
../rtl/AES-CTR/AES_encryption/AES_round/AES_register.sv
../rtl/AES-CTR/AES_encryption/AES_round/ShiftRows.sv
../rtl/AES-CTR/AES_encryption/AES_round/SubBytes.sv
../rtl/AES-CTR/AES_encryption/AES_first_round.sv
../rtl/AES-CTR/AES_encryption/AES_round.sv
../rtl/AES-CTR/AES_encryption/AES_last_round.sv
../rtl/AES-CTR/AES_encryption/AES_encryption.sv

# AES-CTR Top
../rtl/AES-CTR/AES_CTR.sv

# GCM & GHASH
../rtl/GCM-GHASH/GF128bitMultiply.sv
../rtl/GCM-GHASH/GHASH.sv
../rtl/GCM-GHASH/LengthBlockCounter.sv
../rtl/GCM-GHASH/TagProcessing.sv

# Control Unit
../rtl/CU/CU.sv

# AES-128-GCM Top-Level Module
../rtl/AES_GCM.sv
