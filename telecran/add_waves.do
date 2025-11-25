# Script pour ajouter manuellement les signaux dans une simulation déjà ouverte
# Dans ModelSim, tapez : do add_waves.do

# Supprime les anciennes vagues
delete wave *

# Ajoute les signaux avec couleurs distinctes
add wave -divider "Contrôle"
add wave -height 30 -color yellow /encoder_tb/s_clk
add wave -height 30 -color orange /encoder_tb/s_rst_n

add wave -divider "Entrées"
add wave -height 30 /encoder_tb/s_ch_a
add wave -height 30 /encoder_tb/s_ch_b

add wave -divider "Voie A - ATTENTION AUX COULEURS"
add wave -height 30 -color "#00FF00" -label "A_FF1_VERT" /encoder_tb/dut/r_a_ff1
add wave -height 30 -color "#0000FF" -label "A_FF2_BLEU" /encoder_tb/dut/r_a_ff2
add wave -height 30 -color red /encoder_tb/dut/s_rising_a

add wave -divider "Sortie"
add wave -height 30 -radix unsigned /encoder_tb/s_position

# Rafraîchit
wave zoom full
