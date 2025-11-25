# Script de simulation du contrôleur HDMI
# Pour lancer : vsim -do sim_hdmi_controller.do

# Créer la bibliothèque work si elle n'existe pas
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# Compiler les fichiers VHDL
vcom -2008 hdmi_controller.vhd
vcom -2008 hdmi_controller_tb.vhd

# Charger le testbench
vsim -t 1ns work.hdmi_controller_tb

# Configurer l'affichage des signaux
add wave -divider "Horloge et Reset"
add wave -format logic /hdmi_controller_tb/s_clk
add wave -format logic /hdmi_controller_tb/s_rst_n

add wave -divider "Signaux HDMI"
add wave -format logic /hdmi_controller_tb/s_hsync
add wave -format logic /hdmi_controller_tb/s_vsync
add wave -format logic /hdmi_controller_tb/s_de

add wave -divider "Compteurs"
add wave -format literal -radix unsigned /hdmi_controller_tb/s_x_counter
add wave -format literal -radix unsigned /hdmi_controller_tb/s_y_counter

add wave -divider "Compteurs internes DUT"
add wave -format literal -radix unsigned /hdmi_controller_tb/dut/r_h_counter
add wave -format literal -radix unsigned /hdmi_controller_tb/dut/r_v_counter

add wave -divider "Sorties pixel"
add wave -format logic /hdmi_controller_tb/s_pixel_visible
add wave -format literal -radix unsigned /hdmi_controller_tb/s_pixel_address

# Configurer le format de temps
configure wave -timelineunits us

# Lancer la simulation
run 40 ms

# Zoom sur une zone intéressante (première ligne)
wave zoom range 0us 35us

# Message de fin
echo "Simulation terminée. Vérifiez les signaux dans la fenêtre Wave."
echo "Points à vérifier :"
echo "  - HSYNC bas pendant 62 pixels (736-798)"
echo "  - VSYNC bas pendant 6 lignes (489-495)"
echo "  - r_h_counter : 0 à 857 (858 valeurs)"
echo "  - r_v_counter : 0 à 524 (525 valeurs)"
echo "  - pixel_visible actif uniquement quand x<720 ET y<480"
