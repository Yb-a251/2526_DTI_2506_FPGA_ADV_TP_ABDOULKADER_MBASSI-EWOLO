library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encoder is
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
end entity encoder;

architecture rtl of encoder is
    -- Échantillonnage à 1 kHz
    constant c_sample_period : natural := 50000;
    signal r_sample_cnt : natural range 0 to c_sample_period-1 := 0;
    signal s_sample : std_logic := '0';
    
    -- État encodeur (Gray code)
    signal r_state : std_logic_vector(1 downto 0) := "00";
    signal r_state_prev : std_logic_vector(1 downto 0) := "00";
    
    -- Compteur interne avec 2 bits supplémentaires (résolution x4)
    signal r_position : unsigned(g_counter_width+1 downto 0) := (others => '0');
    
begin
    -- Générateur de tick d'échantillonnage
    p_sample : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_sample_cnt <= 0;
            s_sample <= '0';
        elsif (rising_edge(i_clk)) then
            if (r_sample_cnt = c_sample_period-1) then
                r_sample_cnt <= 0;
                s_sample <= '1';
            else
                r_sample_cnt <= r_sample_cnt + 1;
                s_sample <= '0';
            end if;
        end if;
    end process p_sample;
    
    -- Décodeur Gray code
    p_decode : process(i_clk, i_rst_n)
        variable v_transition : std_logic_vector(3 downto 0);
    begin
        if (i_rst_n = '0') then
            r_state <= "00";
            r_state_prev <= "00";
            r_position <= (others => '0');
            
        elsif (rising_edge(i_clk)) then
            if (s_sample = '1') then
                -- Échantillonnage de l'état actuel
                r_state <= i_ch_a & i_ch_b;
                
                -- Calcul de la transition : état_précédent & état_actuel
                v_transition := r_state_prev & r_state;
                
                -- Décodage Gray code (1 seul changement = 1 incrément)
                -- Rotation horaire : 00→01, 01→11, 11→10, 10→00
                -- Rotation anti-horaire : inverse
                case v_transition is
                    -- Transitions horaires (+1)
                    when "0001" =>  -- 00 → 01
                        r_position <= r_position + 1;
                    when "0111" =>  -- 01 → 11
                        r_position <= r_position + 1;
                    when "1110" =>  -- 11 → 10
                        r_position <= r_position + 1;
                    when "1000" =>  -- 10 → 00
                        r_position <= r_position + 1;
                    
                    -- Transitions anti-horaires (-1)
                    when "0010" =>  -- 00 → 10
                        r_position <= r_position - 1;
                    when "1011" =>  -- 10 → 11
                        r_position <= r_position - 1;
                    when "1101" =>  -- 11 → 01
                        r_position <= r_position - 1;
                    when "0100" =>  -- 01 → 00
                        r_position <= r_position - 1;
                    
                    -- Pas de changement ou changement invalide
                    when others =>
                        null;
                end case;
                
                r_state_prev <= r_state;
            end if;
        end if;
    end process p_decode;
    
    -- Sortie : division par 4 pour avoir 1 incrément visible par cran
    o_position <= std_logic_vector(r_position(g_counter_width+1 downto 2));
    
end architecture rtl;
