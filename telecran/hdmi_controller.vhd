library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity hdmi_controller is
    port (
        i_clk           : in std_logic;  -- 27 MHz depuis PLL
        i_rst_n         : in std_logic;  -- Reset actif bas
        
        -- Sorties vers ADV7513
        o_hsync         : out std_logic;
        o_vsync         : out std_logic;
        o_de            : out std_logic;  -- Data Enable
        
        -- Informations pixel pour logique externe
        o_x_counter     : out integer range 0 to 719;
        o_y_counter     : out integer range 0 to 479;
        o_pixel_visible : out std_logic;   -- '1' dans zone visible
        o_pixel_en      : out std_logic;   -- Pulse à chaque pixel visible
        o_pixel_address : out integer range 0 to 345599  -- Adresse linéaire (y*720+x)
    );
end entity hdmi_controller;

architecture rtl of hdmi_controller is
    -- Compteurs
    signal r_h_counter : integer range 0 to 857 := 0;
    signal r_v_counter : integer range 0 to 524 := 0;
    
    -- Timings Horizontaux (720x480 @ 60Hz)
    constant c_h_visible : natural := 720;  -- Zone visible
    constant c_h_fp      : natural := 16;   -- Front porch
    constant c_h_sync    : natural := 62;   -- Sync pulse
    constant c_h_bp      : natural := 60;   -- Back porch
    constant c_h_total   : natural := 858;  -- Total (720+16+62+60)
    
    -- Timings Verticaux
    constant c_v_visible : natural := 480;  -- Zone visible
    constant c_v_fp      : natural := 9;    -- Front porch
    constant c_v_sync    : natural := 6;    -- Sync pulse
    constant c_v_bp      : natural := 30;   -- Back porch
    constant c_v_total   : natural := 525;  -- Total (480+9+6+30)
    
    -- Signaux internes
    signal s_h_visible : std_logic;
    signal s_v_visible : std_logic;
    signal s_pixel_visible : std_logic;
    
begin
    -- Process de comptage Horizontal et Vertical
    p_counters : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_h_counter <= 0;
            r_v_counter <= 0;
        elsif (rising_edge(i_clk)) then
            -- Compteur horizontal
            if (r_h_counter = c_h_total - 1) then
                r_h_counter <= 0;
                
                -- Compteur vertical (incrémenté en fin de ligne)
                if (r_v_counter = c_v_total - 1) then
                    r_v_counter <= 0;
                else
                    r_v_counter <= r_v_counter + 1;
                end if;
            else
                r_h_counter <= r_h_counter + 1;
            end if;
        end if;
    end process;
    
    -- Détection zone visible horizontale
    s_h_visible <= '1' when (r_h_counter < c_h_visible) else '0';
    
    -- Détection zone visible verticale
    s_v_visible <= '1' when (r_v_counter < c_v_visible) else '0';
    
    -- Pixel visible : intersection des deux zones
    s_pixel_visible <= s_h_visible and s_v_visible;
    
    -- Génération HSYNC (actif bas)
    -- HSYNC bas pendant la durée du pulse de sync
    o_hsync <= '0' when (r_h_counter >= c_h_visible + c_h_fp) and 
                        (r_h_counter < c_h_visible + c_h_fp + c_h_sync)
               else '1';
    
    -- Génération VSYNC (actif bas)
    -- VSYNC bas pendant la durée du pulse de sync
    o_vsync <= '0' when (r_v_counter >= c_v_visible + c_v_fp) and 
                        (r_v_counter < c_v_visible + c_v_fp + c_v_sync)
               else '1';
    
    -- Data Enable : actif uniquement dans zone visible
    o_de <= s_pixel_visible;
    
    -- Sorties position (uniquement dans zone visible)
    o_x_counter     <= r_h_counter when s_h_visible = '1' else 0;
    o_y_counter     <= r_v_counter when s_v_visible = '1' else 0;
    o_pixel_visible <= s_pixel_visible;
    o_pixel_en      <= s_pixel_visible;
    
    -- Adresse linéaire du pixel : addr = y * 720 + x
    o_pixel_address <= (r_v_counter * 720 + r_h_counter) when s_pixel_visible = '1' else 0;
    
end architecture rtl;
