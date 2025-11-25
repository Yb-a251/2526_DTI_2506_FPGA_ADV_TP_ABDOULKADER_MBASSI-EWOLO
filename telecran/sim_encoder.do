# Script de simulation ModelSim pour encoder_tb
# Utilisation : vsim -do sim_encoder.do

# Nettoyage
quit -sim

# Création de la librairie de travail
vlib work

# Compilation des fichiers VHDL
vcom -2008 encoder.vhd
vcom -2008 encoder_tb.vhd

# Chargement du testbench
vsim -t 1ps work.encoder_tb

# Configuration de la fenêtre de forme d'onde
add wave -divider "Signaux de contrôle"
add wave -color yellow /encoder_tb/s_clk
add wave -color orange /encoder_tb/s_rst_n

add wave -divider "Entrées encodeur"
add wave -color cyan /encoder_tb/s_ch_a
add wave -color cyan /encoder_tb/s_ch_b

add wave -divider "Signaux internes - Voie A"
add wave -label "A_FF1 (D1)" -color green /encoder_tb/dut/r_a_ff1
add wave -label "A_FF2 (D2)" -color blue /encoder_tb/dut/r_a_ff2
add wave -color yellow /encoder_tb/dut/s_rising_a
add wave -color orange /encoder_tb/dut/s_falling_a

add wave -divider "Signaux internes - Voie B"
add wave -label "B_FF1 (D1)" -color green /encoder_tb/dut/r_b_ff1
add wave -label "B_FF2 (D2)" -color blue /encoder_tb/dut/r_b_ff2
add wave -color yellow /encoder_tb/dut/s_rising_b
add wave -color orange /encoder_tb/dut/s_falling_b

add wave -divider "Logique de comptage"
add wave -color green /encoder_tb/dut/s_increment
add wave -color red /encoder_tb/dut/s_decrement

add wave -divider "Sortie"
add wave -radix unsigned /encoder_tb/s_position

# Configuration de l'affichage
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# Lancement de la simulation
run -all

# Zoom pour voir toute la simulation
wave zoom full
