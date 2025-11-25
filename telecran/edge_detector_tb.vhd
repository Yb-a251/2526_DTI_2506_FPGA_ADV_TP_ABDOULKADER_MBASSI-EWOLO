library ieee;
use ieee.std_logic_1164.all;

-- Testbench simple pour vérifier le détecteur de fronts
entity edge_detector_tb is
end entity edge_detector_tb;

architecture sim of edge_detector_tb is
    signal s_clk : std_logic := '0';
    signal s_rst_n : std_logic := '0';
    signal s_a : std_logic := '0';
    
    signal s_a_ff1 : std_logic := '0';
    signal s_a_ff2 : std_logic := '0';
    signal s_rising : std_logic;
    
    constant c_clk_period : time := 20 ns;
    signal s_sim_end : boolean := false;
    
begin
    -- Génération horloge
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
    
    -- Premier étage
    p_ff1 : process(s_clk, s_rst_n)
    begin
        if (s_rst_n = '0') then
            s_a_ff1 <= '0';
        elsif (rising_edge(s_clk)) then
            s_a_ff1 <= s_a;
        end if;
    end process;
    
    -- Second étage
    p_ff2 : process(s_clk, s_rst_n)
    begin
        if (s_rst_n = '0') then
            s_a_ff2 <= '0';
        elsif (rising_edge(s_clk)) then
            s_a_ff2 <= s_a_ff1;
        end if;
    end process;
    
    -- Détection
    s_rising <= s_a_ff1 and not s_a_ff2;
    
    -- Stimulus
    p_test : process
    begin
        s_rst_n <= '0';
        s_a <= '0';
        wait for 100 ns;
        
        s_rst_n <= '1';
        wait for 100 ns;
        
        -- Test : front montant sur A
        report "Front montant sur A";
        s_a <= '1';
        wait for 200 ns;
        
        -- Test : front descendant sur A
        report "Front descendant sur A";
        s_a <= '0';
        wait for 200 ns;
        
        -- Test : série de fronts
        report "Serie de fronts";
        for i in 0 to 5 loop
            s_a <= '1';
            wait for 80 ns;
            s_a <= '0';
            wait for 80 ns;
        end loop;
        
        wait for 200 ns;
        report "Simulation terminée";
        s_sim_end <= true;
        wait;
    end process;
    
end architecture sim;
