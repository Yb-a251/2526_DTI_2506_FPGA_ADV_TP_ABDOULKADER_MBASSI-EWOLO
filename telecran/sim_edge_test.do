# Script pour tester uniquement le détecteur de fronts
vlib work
vcom -2008 edge_detector_tb.vhd
vsim -t 1ps work.edge_detector_tb

add wave -divider "Contrôle"
add wave -color yellow /edge_detector_tb/s_clk
add wave -color orange /edge_detector_tb/s_rst_n

add wave -divider "Entrée et synchronisation"
add wave -color cyan /edge_detector_tb/s_a
add wave -color green -label "FF1 (D1)" /edge_detector_tb/s_a_ff1
add wave -color blue -label "FF2 (D2)" /edge_detector_tb/s_a_ff2

add wave -divider "Détection"
add wave -color red /edge_detector_tb/s_rising

configure wave -namecolwidth 200
configure wave -valuecolwidth 100

run -all
wave zoom full
