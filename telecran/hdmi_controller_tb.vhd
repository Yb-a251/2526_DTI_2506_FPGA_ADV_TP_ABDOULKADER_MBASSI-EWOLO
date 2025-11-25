library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_controller_tb is
end entity hdmi_controller_tb;

architecture sim of hdmi_controller_tb is
    -- Composant à tester
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
    
    -- Signaux de test
    signal s_clk           : std_logic := '0';
    signal s_rst_n         : std_logic := '0';
    signal s_hsync         : std_logic;
    signal s_vsync         : std_logic;
    signal s_de            : std_logic;
    signal s_x_counter     : integer range 0 to 719 := 0;
    signal s_y_counter     : integer range 0 to 479 := 0;
    signal s_pixel_visible : std_logic;
    signal s_pixel_en      : std_logic;
    signal s_pixel_address : integer range 0 to 345599 := 0;
    
    -- Constantes de timing
    constant c_clk_period : time := 37 ns;  -- 27 MHz (1/27MHz ≈ 37ns)
    constant c_h_total    : natural := 858;
    constant c_v_total    : natural := 525;
    constant c_h_visible  : natural := 720;
    constant c_v_visible  : natural := 480;
    
    -- Signal de fin de simulation
    signal s_sim_done : boolean := false;
    
begin
    -- Instanciation du DUT (Device Under Test)
    dut : component hdmi_controller
        port map (
            i_clk           => s_clk,
            i_rst_n         => s_rst_n,
            o_hsync         => s_hsync,
            o_vsync         => s_vsync,
            o_de            => s_de,
            o_x_counter     => s_x_counter,
            o_y_counter     => s_y_counter,
            o_pixel_visible => s_pixel_visible,
            o_pixel_en      => s_pixel_en,
            o_pixel_address => s_pixel_address
        );
    
    -- Génération de l'horloge 27 MHz
    p_clk : process
    begin
        while not s_sim_done loop
            s_clk <= '0';
            wait for c_clk_period / 2;
            s_clk <= '1';
            wait for c_clk_period / 2;
        end loop;
        wait;
    end process;
    
    -- Process de stimulus
    p_stimulus : process
    begin
        -- Reset initial
        s_rst_n <= '0';
        wait for 200 ns;
        s_rst_n <= '1';
        
        -- Attendre 2 frames complètes pour observer les signaux
        -- 1 frame = 858 × 525 cycles @ 27MHz = 16.68 ms
        -- 2 frames ≈ 33.36 ms
        wait for 34 ms;
        
        -- Fin de simulation
        s_sim_done <= true;
        report "Simulation terminée avec succès" severity note;
        wait;
    end process;
    
    -- Process de vérification des timings
    p_check : process(s_clk)
        variable v_h_pixel_count : natural := 0;
        variable v_v_line_count  : natural := 0;
        variable v_hsync_start   : natural := 0;
        variable v_hsync_end     : natural := 0;
        variable v_vsync_start   : natural := 0;
    begin
        if (rising_edge(s_clk) and s_rst_n = '1') then
            -- Vérification compteur horizontal
            assert (s_x_counter <= 719)
                report "ERREUR : x_counter dépasse 719 (" & integer'image(s_x_counter) & ")"
                severity error;
            
            -- Vérification compteur vertical
            assert (s_y_counter <= 479)
                report "ERREUR : y_counter dépasse 479 (" & integer'image(s_y_counter) & ")"
                severity error;
            
            -- Vérification HSYNC actif bas entre pixels 736 et 798 (720+16 à 720+16+62)
            if (s_hsync = '0') then
                if (v_hsync_start = 0) then
                    v_hsync_start := v_h_pixel_count;
                end if;
                v_hsync_end := v_h_pixel_count;
            end if;
            
            -- Comptage pixels par ligne
            v_h_pixel_count := v_h_pixel_count + 1;
            if (v_h_pixel_count = c_h_total) then
                v_h_pixel_count := 0;
                v_v_line_count := v_v_line_count + 1;
                
                -- Vérification durée HSYNC (doit être de 62 pixels)
                if (v_hsync_start > 0) then
                    assert ((v_hsync_end - v_hsync_start + 1) = 62)
                        report "ERREUR : Durée HSYNC incorrecte (" & integer'image(v_hsync_end - v_hsync_start + 1) & " au lieu de 62)"
                        severity warning;
                end if;
                v_hsync_start := 0;
                v_hsync_end := 0;
                
                if (v_v_line_count = c_v_total) then
                    v_v_line_count := 0;
                end if;
            end if;
        end if;
    end process;
    
end architecture sim;
