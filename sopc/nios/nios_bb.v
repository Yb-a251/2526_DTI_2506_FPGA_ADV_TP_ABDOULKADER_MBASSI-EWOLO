
module nios (
	clk_clk,
	pio_0_external_connection_export,
	reset_reset_n,
	i2c_0_i2c_serial_sda_in,
	i2c_0_i2c_serial_scl_in,
	i2c_0_i2c_serial_sda_oe,
	i2c_0_i2c_serial_scl_oe);	

	input		clk_clk;
	output	[9:0]	pio_0_external_connection_export;
	input		reset_reset_n;
	input		i2c_0_i2c_serial_sda_in;
	input		i2c_0_i2c_serial_scl_in;
	output		i2c_0_i2c_serial_sda_oe;
	output		i2c_0_i2c_serial_scl_oe;
endmodule
