# Contraintes de broches pour le projet Télécran
# À utiliser dans Quartus Pin Planner

# Horloge et Reset
set_location_assignment PIN_AF14 -to i_clk_50
set_location_assignment PIN_AH17 -to i_rst_n

# Encodeur gauche (LEFT)
set_location_assignment PIN_AF27 -to i_left_ch_a
set_location_assignment PIN_AF28 -to i_left_ch_b
set_location_assignment PIN_AH27 -to i_left_pb

# Encodeur droit (RIGHT)
set_location_assignment PIN_AA26 -to i_right_ch_a
set_location_assignment PIN_AA13 -to i_right_ch_b
set_location_assignment PIN_AA11 -to i_right_pb

# LEDs Mezzanine (10 LEDs)
set_location_assignment PIN_AG28 -to o_leds[0]
set_location_assignment PIN_AE25 -to o_leds[1]
set_location_assignment PIN_AG26 -to o_leds[2]
set_location_assignment PIN_AG25 -to o_leds[3]
set_location_assignment PIN_AG23 -to o_leds[4]
set_location_assignment PIN_AH21 -to o_leds[5]
set_location_assignment PIN_AF22 -to o_leds[6]
set_location_assignment PIN_AG20 -to o_leds[7]
set_location_assignment PIN_AG18 -to o_leds[8]
set_location_assignment PIN_AG15 -to o_leds[9]

# LEDs DE10-Nano (8 LEDs)
set_location_assignment PIN_W15 -to o_de10_leds[0]
set_location_assignment PIN_AA24 -to o_de10_leds[1]
set_location_assignment PIN_V16 -to o_de10_leds[2]
set_location_assignment PIN_V15 -to o_de10_leds[3]
set_location_assignment PIN_AF26 -to o_de10_leds[4]
set_location_assignment PIN_AE26 -to o_de10_leds[5]
set_location_assignment PIN_Y16 -to o_de10_leds[6]
set_location_assignment PIN_AA23 -to o_de10_leds[7]

# Standards d'entrée/sortie
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to i_clk_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to i_rst_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to i_left_*
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to i_right_*
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to o_leds[*]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to o_de10_leds[*]
