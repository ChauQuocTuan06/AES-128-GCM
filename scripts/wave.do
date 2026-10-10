# ==============================================================================
# QuestaSim / ModelSim Waveform Configuration for AES_GCM Environment
# ==============================================================================

onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -divider {GLOBAL CLOCK & RESET}
add wave -noupdate -radix hexadecimal /tb_top/vif/clk
add wave -noupdate -radix hexadecimal /tb_top/vif/rst_n

add wave -noupdate -divider {CONTROL & MODES}
add wave -noupdate -radix hexadecimal /tb_top/vif/mode
add wave -noupdate -radix ascii       /tb_top/u_dut/cu/Current
add wave -noupdate -radix hexadecimal /tb_top/vif/finish

add wave -noupdate -divider {KEY & IV HANDSHAKES}
add wave -noupdate -radix hexadecimal /tb_top/vif/key_ready
add wave -noupdate -radix hexadecimal /tb_top/vif/load_key
add wave -noupdate -radix hexadecimal /tb_top/vif/cipher_key
add wave -noupdate -radix hexadecimal /tb_top/vif/IV_ready
add wave -noupdate -radix hexadecimal /tb_top/vif/load_IV
add wave -noupdate -radix hexadecimal /tb_top/vif/IV

add wave -noupdate -divider {AAD HANDSHAKE & STREAM}
add wave -noupdate -radix hexadecimal /tb_top/vif/AAD_ready
add wave -noupdate -radix hexadecimal /tb_top/vif/load_AAD
add wave -noupdate -radix hexadecimal /tb_top/vif/no_AAD
add wave -noupdate -radix hexadecimal /tb_top/vif/AAD_last
add wave -noupdate -radix hexadecimal /tb_top/vif/AAD

add wave -noupdate -divider {DATA INPUT (PAYLOAD)}
add wave -noupdate -radix hexadecimal /tb_top/vif/data_ready
add wave -noupdate -radix hexadecimal /tb_top/vif/load_data
add wave -noupdate -radix hexadecimal /tb_top/vif/data_in_last
add wave -noupdate -radix hexadecimal /tb_top/vif/data_in

add wave -noupdate -divider {DATA OUTPUT}
add wave -noupdate -radix hexadecimal /tb_top/vif/data_valid
add wave -noupdate -radix hexadecimal /tb_top/vif/data_out_last
add wave -noupdate -radix hexadecimal /tb_top/vif/data_out

add wave -noupdate -divider {TAG & DECRYPTION VERIFICATION}
add wave -noupdate -radix hexadecimal /tb_top/vif/tag_ref_ready
add wave -noupdate -radix hexadecimal /tb_top/vif/load_tag_ref
add wave -noupdate -radix hexadecimal /tb_top/vif/tag_ref
add wave -noupdate -radix hexadecimal /tb_top/vif/tag_valid
add wave -noupdate -radix hexadecimal /tb_top/vif/tag
add wave -noupdate -radix hexadecimal /tb_top/vif/verify_done
add wave -noupdate -radix hexadecimal /tb_top/vif/verify_checked
add wave -noupdate -radix hexadecimal /tb_top/vif/verify_pass

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 220
configure wave -valuecolwidth 140
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
