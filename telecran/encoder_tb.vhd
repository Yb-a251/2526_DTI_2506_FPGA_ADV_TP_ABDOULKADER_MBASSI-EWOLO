library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encoder_tb is
end entity encoder_tb;

architecture sim of encoder_tb is
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
    
    -- Signaux de test
    signal s_clk      : std_logic := '0';
    signal s_rst_n    : std_logic := '0';
    signal s_ch_a     : std_logic := '0';
    signal s_ch_b     : std_logic := '0';
    signal s_position : std_logic_vector(9 downto 0);
    
    -- Période d'horloge
    constant c_clk_period : time := 20 ns; -- 50 MHz
    
    -- Contrôle de la simulation
    signal s_sim_end : boolean := false;
    
begin
    -- Instanciation du DUT
    dut : component encoder
        generic map (
            g_counter_width => 10
        )
        port map (
            i_clk      => s_clk,
            i_rst_n    => s_rst_n,
            i_ch_a     => s_ch_a,
            i_ch_b     => s_ch_b,
            o_position => s_position
        );
    
    -- Génération de l'horloge
    p_clk : process
    begin
        while not s_sim_end loop
            s_clk <= '0';
            wait for c_clk_period/2;
            s_clk <= '1';
            wait for c_clk_period/2;
        end loop;
        wait;
    end process;
    
    -- Process de test
    p_test : process
    begin
        -- Reset initial
        s_rst_n <= '0';
        s_ch_a <= '0';
        s_ch_b <= '0';
        wait for 100 ns;
        
        s_rst_n <= '1';
        wait for 200 ns;
        
        -- Test 1 : Rotation horaire (incrément) - 5 pas
        report "Test 1 : Rotation horaire (5 pas)";
        for i in 0 to 4 loop
            -- État 00
            s_ch_a <= '0'; s_ch_b <= '0'; wait for 100 us;
            -- État 10 (A monte en premier)
            s_ch_a <= '1'; s_ch_b <= '0'; wait for 100 us;
            -- État 11
            s_ch_a <= '1'; s_ch_b <= '1'; wait for 100 us;
            -- État 01
            s_ch_a <= '0'; s_ch_b <= '1'; wait for 100 us;
        end loop;
        s_ch_a <= '0'; s_ch_b <= '0'; wait for 500 us;
        
        -- Test 2 : Rotation anti-horaire (décrément) - 3 pas
        report "Test 2 : Rotation anti-horaire (3 pas)";
        for i in 0 to 2 loop
            -- État 00
            s_ch_a <= '0'; s_ch_b <= '0'; wait for 100 us;
            -- État 01 (B monte en premier)
            s_ch_a <= '0'; s_ch_b <= '1'; wait for 100 us;
            -- État 11
            s_ch_a <= '1'; s_ch_b <= '1'; wait for 100 us;
            -- État 10
            s_ch_a <= '1'; s_ch_b <= '0'; wait for 100 us;
        end loop;
        s_ch_a <= '0'; s_ch_b <= '0'; wait for 500 us;
        
        -- Test 3 : Rotation horaire rapide (10 pas)
        report "Test 3 : Rotation horaire rapide (10 pas)";
        for i in 0 to 9 loop
            s_ch_a <= '0'; s_ch_b <= '0'; wait for 100 us;
            s_ch_a <= '1'; s_ch_b <= '0'; wait for 100 us;
            s_ch_a <= '1'; s_ch_b <= '1'; wait for 100 us;
            s_ch_a <= '0'; s_ch_b <= '1'; wait for 100 us;
        end loop;
        s_ch_a <= '0'; s_ch_b <= '0'; wait for 500 us;
        
        -- Test 4 : Reset pendant rotation
        report "Test 4 : Reset pendant rotation";
        s_ch_a <= '0'; s_ch_b <= '0'; wait for 100 us;
        s_ch_a <= '1'; wait for 50 us;
        s_rst_n <= '0'; wait for 100 ns;
        s_rst_n <= '1';
        s_ch_a <= '0'; wait for 500 us;
        
        -- Fin de simulation
        report "Simulation terminée";
        s_sim_end <= true;
        wait;
    end process;
    
end architecture sim;
