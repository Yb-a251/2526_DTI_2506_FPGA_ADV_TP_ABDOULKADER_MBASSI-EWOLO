library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pll;
use pll.all;

entity telecran is
    port (
        -- FPGA
        i_clk_50: in std_logic;

        -- HDMI
        io_hdmi_i2c_scl       : inout std_logic;
        io_hdmi_i2c_sda       : inout std_logic;
        o_hdmi_tx_clk        : out std_logic;
        o_hdmi_tx_d          : out std_logic_vector(23 downto 0);
        o_hdmi_tx_de         : out std_logic;
        o_hdmi_tx_hs         : out std_logic;
        i_hdmi_tx_int        : in std_logic;
        o_hdmi_tx_vs         : out std_logic;

        -- KEYs
        i_rst_n : in std_logic;
		  
		-- LEDs
		o_leds : out std_logic_vector(9 downto 0);
		o_de10_leds : out std_logic_vector(7 downto 0);

		-- Coder
		i_left_ch_a : in std_logic;
		i_left_ch_b : in std_logic;
		i_left_pb : in std_logic;
		i_right_ch_a : in std_logic;
		i_right_ch_b : in std_logic;
		i_right_pb : in std_logic
    );
end entity telecran;

architecture rtl of telecran is
	component I2C_HDMI_Config 
		port (
			iCLK : in std_logic;
			iRST_N : in std_logic;
			I2C_SCLK : out std_logic;
			I2C_SDAT : inout std_logic;
			HDMI_TX_INT  : in std_logic
		);
	 end component;
	 
	component pll 
		port (
			refclk : in std_logic;
			rst : in std_logic;
			outclk_0 : out std_logic;
			locked : out std_logic
		);
	end component;
	
	component encoder is
		generic (
			g_counter_width : natural := 10
		);
		port (
			i_clk      : in std_logic;
			i_rst_n    : in std_logic;
			i_ch_a     : in std_logic;
			i_ch_b     : in std_logic;
			o_position : out std_logic_vector(g_counter_width-1 downto 0)
		);
	end component;
	
	component hdmi_controller is
		port (
			i_clk           : in std_logic;
			i_rst_n         : in std_logic;
			o_hsync         : out std_logic;
			o_vsync         : out std_logic;
			o_de            : out std_logic;
			o_x_counter     : out integer range 0 to 719;
			o_y_counter     : out integer range 0 to 479;
			o_pixel_visible : out std_logic;
			o_pixel_en      : out std_logic;
			o_pixel_address : out integer range 0 to 345599
		);
	end component;
	
	component dpram is
		generic (
			mem_size   : natural := 720 * 480;
			data_width : natural := 8
		);
		port (
			i_clk_a  : in std_logic;
			i_clk_b  : in std_logic;
			i_data_a : in std_logic_vector(data_width-1 downto 0);
			i_data_b : in std_logic_vector(data_width-1 downto 0);
			i_addr_a : in natural range 0 to mem_size-1;
			i_addr_b : in natural range 0 to mem_size-1;
			i_we_a   : in std_logic := '1';
			i_we_b   : in std_logic := '1';
			o_q_a    : out std_logic_vector(data_width-1 downto 0);
			o_q_b    : out std_logic_vector(data_width-1 downto 0)
		);
	end component;

    constant h_res : natural := 720;
    constant v_res : natural := 480;

	signal s_clk_27 : std_logic;
	signal s_rst_n : std_logic;	-- holds reset as long as pll is not locked
	
	-- Signaux des encodeurs
	signal s_left_position  : std_logic_vector(9 downto 0);
	signal s_right_position : std_logic_vector(7 downto 0);
	
	-- Signaux du contrôleur HDMI
	signal s_x_counter     : integer range 0 to 719;
	signal s_y_counter     : integer range 0 to 479;
	signal s_pixel_visible : std_logic;
	
	-- Position du pixel à afficher (mise à l'échelle des encodeurs)
	signal s_x_pixel : integer range 0 to 719;
	signal s_y_pixel : integer range 0 to 479;
	
	-- Signaux Framebuffer
	signal s_ram_we_a      : std_logic;
	signal s_ram_addr_wr   : natural range 0 to 345599;
	signal s_ram_addr_rd   : natural range 0 to 345599;
	signal s_ram_data_in   : std_logic_vector(0 downto 0);
	signal s_ram_data_out  : std_logic_vector(0 downto 0);
	
	-- Machine à états effacement
	type t_clear_state is (IDLE, CLEARING, DONE);
	signal r_clear_state : t_clear_state := IDLE;
	signal r_clear_addr  : natural range 0 to 345599 := 0;
	signal r_clear_req   : std_logic := '0';
	
	-- Conversion position → one-hot pour affichage LED
	signal s_left_leds  : std_logic_vector(9 downto 0);
	signal s_right_leds : std_logic_vector(7 downto 0);
	
begin
	-- Conversion binaire → one-hot (1 seule LED allumée)
	process(s_left_position)
	begin
		s_left_leds <= (others => '0');
		case to_integer(unsigned(s_left_position)) is
			when 0 => s_left_leds(0) <= '1';
			when 1 => s_left_leds(1) <= '1';
			when 2 => s_left_leds(2) <= '1';
			when 3 => s_left_leds(3) <= '1';
			when 4 => s_left_leds(4) <= '1';
			when 5 => s_left_leds(5) <= '1';
			when 6 => s_left_leds(6) <= '1';
			when 7 => s_left_leds(7) <= '1';
			when 8 => s_left_leds(8) <= '1';
			when 9 => s_left_leds(9) <= '1';
			when others => s_left_leds <= (others => '0');
		end case;
	end process;
	
	process(s_right_position)
	begin
		s_right_leds <= (others => '0');
		case to_integer(unsigned(s_right_position)) is
			when 0 => s_right_leds(0) <= '1';
			when 1 => s_right_leds(1) <= '1';
			when 2 => s_right_leds(2) <= '1';
			when 3 => s_right_leds(3) <= '1';
			when 4 => s_right_leds(4) <= '1';
			when 5 => s_right_leds(5) <= '1';
			when 6 => s_right_leds(6) <= '1';
			when 7 => s_right_leds(7) <= '1';
			when others => s_right_leds <= (others => '0');
		end case;
	end process;
	
	-- Affichage positions encodeurs sur LEDs
	o_leds <= s_left_leds;           -- LEDs mezzanine : encodeur gauche
	o_de10_leds <= s_right_leds;     -- LEDs DE10-Nano : encodeur droit
	
	-- Frequency for HDMI is 27MHz generated by this PLL
	pll0 : component pll 
		port map (
			refclk => i_clk_50,
			rst => not(i_rst_n),
			outclk_0 => s_clk_27,
			locked => s_rst_n
		);

	-- Configures the ADV7513 for 480p
	I2C_HDMI_Config0 : component I2C_HDMI_Config 
		port map (
			iCLK => i_clk_50,
			iRST_N => i_rst_n,
			I2C_SCLK => io_hdmi_i2c_scl,
			I2C_SDAT => io_hdmi_i2c_sda,
			HDMI_TX_INT => i_hdmi_tx_int
	 );
	 
	-- Encodeur gauche : contrôle axe X (horizontal)
	encoder_left : component encoder
		generic map (
			g_counter_width => 10
		)
		port map (
			i_clk      => i_clk_50,
			i_rst_n    => i_rst_n,
			i_ch_a     => i_left_ch_a,
			i_ch_b     => i_left_ch_b,
			o_position => s_left_position
		);
	
	-- Encodeur droit : contrôle axe Y (vertical)
	encoder_right : component encoder
		generic map (
			g_counter_width => 8
		)
		port map (
			i_clk      => i_clk_50,
			i_rst_n    => i_rst_n,
			i_ch_a     => i_right_ch_a,
			i_ch_b     => i_right_ch_b,
			o_position => s_right_position
		);
	
	-- Contrôleur HDMI : génération des timings 720x480@60Hz
	hdmi_ctrl : component hdmi_controller
		port map (
			i_clk           => s_clk_27,      -- IMPORTANT : 27 MHz de la PLL
			i_rst_n         => s_rst_n,       -- Reset synchrone avec PLL
			o_hsync         => o_hdmi_tx_hs,
			o_vsync         => o_hdmi_tx_vs,
			o_de            => o_hdmi_tx_de,
			o_x_counter     => s_x_counter,
			o_y_counter     => s_y_counter,
			o_pixel_visible => s_pixel_visible,
			o_pixel_en      => open,          -- Non utilisé pour l'instant
			o_pixel_address => open           -- Non utilisé pour l'instant
		);
	
	-- Framebuffer : RAM dual-port 1-bit par pixel (720×480 = 345,600 pixels)
	framebuffer : component dpram
		generic map (
			mem_size   => 345600,
			data_width => 1
		)
		port map (
			-- Port A : Écriture (position encodeurs)
			i_clk_a  => s_clk_27,
			i_we_a   => s_ram_we_a,
			i_addr_a => s_ram_addr_wr,
			i_data_a => s_ram_data_in,
			o_q_a    => open,
			
			-- Port B : Lecture (scan HDMI)
			i_clk_b  => s_clk_27,
			i_we_b   => '0',                -- Port B lecture seule
			i_addr_b => s_ram_addr_rd,
			i_data_b => (others => '0'),
			o_q_b    => s_ram_data_out
		);
	
	-- Clock HDMI (copie de l'horloge pixel)
	o_hdmi_tx_clk <= s_clk_27;
	
	-- Mise à l'échelle : encodeurs → position pixel
	-- Encodeur gauche (10 bits : 0-1023) → X (0-719)
	-- Formule : x_pixel = (position_encoder * 720) / 1024
	s_x_pixel <= (to_integer(unsigned(s_left_position)) * 720) / 1024;
	
	-- Encodeur droit (8 bits : 0-255) → Y (0-479)  
	-- Formule : y_pixel = (position_encoder * 480) / 256
	s_y_pixel <= (to_integer(unsigned(s_right_position)) * 480) / 256;
	
	-- Adresse lecture RAM : scan HDMI synchrone
	s_ram_addr_rd <= s_y_counter * 720 + s_x_counter;
	
	-- Détection appui bouton LEFT_PB (anti-rebond)
	p_button_detect : process(s_clk_27, s_rst_n)
		variable v_btn_prev : std_logic := '1';
	begin
		if (s_rst_n = '0') then
			r_clear_req <= '0';
			v_btn_prev := '1';
		elsif (rising_edge(s_clk_27)) then
			-- Front descendant = appui (boutons actifs bas)
			if (v_btn_prev = '1' and i_left_pb = '0') then
				r_clear_req <= '1';
			elsif (r_clear_state = DONE) then
				r_clear_req <= '0';
			end if;
			v_btn_prev := i_left_pb;
		end if;
	end process;
	
	-- Machine à états effacement RAM
	p_clear_fsm : process(s_clk_27, s_rst_n)
	begin
		if (s_rst_n = '0') then
			r_clear_state <= IDLE;
			r_clear_addr <= 0;
		elsif (rising_edge(s_clk_27)) then
			case r_clear_state is
				when IDLE =>
					if (r_clear_req = '1') then
						r_clear_state <= CLEARING;
						r_clear_addr <= 0;
					end if;
				
				when CLEARING =>
					-- Parcourir toute la RAM et écrire '0'
					if (r_clear_addr < 345599) then
						r_clear_addr <= r_clear_addr + 1;
					else
						r_clear_state <= DONE;
					end if;
				
				when DONE =>
					r_clear_state <= IDLE;
			end case;
		end if;
	end process;
	
	-- Logique d'écriture RAM + affichage
	p_framebuffer : process(s_clk_27)
		variable v_dx : integer;
		variable v_dy : integer;
		variable v_is_cursor : boolean;
	begin
		if (rising_edge(s_clk_27)) then
			-- Calcul si pixel scanné fait partie du curseur (croix 11×11)
			v_dx := abs(s_x_counter - s_x_pixel);
			v_dy := abs(s_y_counter - s_y_pixel);
			v_is_cursor := ((v_dy <= 5) and (v_dx = 0)) or ((v_dx <= 5) and (v_dy = 0));
			
			-- MULTIPLEXAGE : Effacement prioritaire sur dessin
			if (r_clear_state = CLEARING) then
				-- Mode effacement : écrire '0' à adresse compteur
				s_ram_we_a      <= '1';
				s_ram_addr_wr   <= r_clear_addr;
				s_ram_data_in(0) <= '0';
			elsif (s_pixel_visible = '1') and v_is_cursor then
				-- Mode dessin : écrire '1' à position curseur
				s_ram_we_a      <= '1';
				s_ram_addr_wr   <= s_y_counter * 720 + s_x_counter;
				s_ram_data_in(0) <= '1';
			else
				s_ram_we_a <= '0';  -- Pas d'écriture
			end if;
			
			-- AFFICHAGE : Priorité curseur > RAM > fond
			if (s_pixel_visible = '1') then
				if v_is_cursor then
					o_hdmi_tx_d <= x"FFFFFF";  -- Curseur blanc (temps réel)
				elsif (s_ram_data_out(0) = '1') then
					o_hdmi_tx_d <= x"00FF00";  -- Tracé vert (mémorisé)
				else
					o_hdmi_tx_d <= x"000000";  -- Fond noir
				end if;
			else
				o_hdmi_tx_d <= (others => '0');  -- Noir hors zone visible
			end if;
		end if;
	end process;
		
end architecture rtl;
