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
    -- Générateur d'enable à 1 kHz (anti-rebond)
    constant c_enable_divider : natural := 50000; -- 50 MHz / 1 kHz
    signal r_enable_counter   : natural range 0 to c_enable_divider-1 := 0;
    signal s_enable           : std_logic := '0';
    
    signal r_a_ff1 : std_logic := '0';
    signal r_b_ff1 : std_logic := '0';
    signal r_a_ff2 : std_logic := '0';
    signal r_b_ff2 : std_logic := '0';
    
    signal s_rising_a  : std_logic;
    signal s_falling_a : std_logic;
    signal s_rising_b  : std_logic;
    signal s_falling_b : std_logic;
    
    signal r_position  : unsigned(g_counter_width-1 downto 0) := (others => '0');
    signal s_increment : std_logic;
    signal s_decrement : std_logic;
    
begin
    -- Générateur d'enable à 1 kHz pour anti-rebond
    p_enable_gen : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_enable_counter <= 0;
            s_enable <= '0';
        elsif (rising_edge(i_clk)) then
            if (r_enable_counter = c_enable_divider-1) then
                r_enable_counter <= 0;
                s_enable <= '1';
            else
                r_enable_counter <= r_enable_counter + 1;
                s_enable <= '0';
            end if;
        end if;
    end process p_enable_gen;
    
    -- Synchronisation double étage (FF1 puis FF2)
    p_sync_stage1 : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_a_ff1 <= '0';
            r_b_ff1 <= '0';
        elsif (rising_edge(i_clk)) then
            if (s_enable = '1') then
                r_a_ff1 <= i_ch_a;
                r_b_ff1 <= i_ch_b;
            end if;
        end if;
    end process p_sync_stage1;
    
    p_sync_stage2 : process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_a_ff2 <= '0';
            r_b_ff2 <= '0';
        elsif (rising_edge(i_clk)) then
            if (s_enable = '1') then
                r_a_ff2 <= r_a_ff1;
                r_b_ff2 <= r_b_ff1;
            end if;
        end if;
    end process p_sync_stage2;
    
    -- Détection de fronts montants uniquement
    s_rising_a <= r_a_ff1 and not r_a_ff2;
    
    -- Logique d'incrément/décrément (1 clic = 1 incrément)
    -- Rotation horaire : front montant A avec B=0
    -- Rotation anti-horaire : front montant A avec B=1
    s_increment <= s_rising_a and not r_b_ff1;
    s_decrement <= s_rising_a and r_b_ff1;
    
    -- Compteur de position (synchronisé avec enable)
    process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_position <= (others => '0');
        elsif (rising_edge(i_clk)) then
            if (s_enable = '1') then
                if (s_increment = '1') then
                    r_position <= r_position + 1;
                elsif (s_decrement = '1') then
                    r_position <= r_position - 1;
                end if;
            end if;
        end if;
    end process;
    
    o_position <= std_logic_vector(r_position);
    
end architecture rtl;
