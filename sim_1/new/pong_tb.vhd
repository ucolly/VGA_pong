library ieee;
use ieee.std_logic_1164.all;

entity tb_pong_design_wrapper is
end tb_pong_design_wrapper;

architecture tb of tb_pong_design_wrapper is

    component pong_design_wrapper
        port (clk     : in std_logic;
              hsync   : out std_logic;
              reset   : in std_logic;
              rgb     : out std_logic_vector (11 downto 0 );
              rl_down : in std_logic;
              rl_up   : in std_logic;
              rr_down : in std_logic;
              rr_up   : in std_logic;
              vsync   : out std_logic);
    end component;

    signal clk     : std_logic;
    signal hsync   : std_logic;
    signal reset   : std_logic;
    signal rgb     : std_logic_vector (11 downto 0 );
    signal rl_down : std_logic;
    signal rl_up   : std_logic;
    signal rr_down : std_logic;
    signal rr_up   : std_logic;
    signal vsync   : std_logic;

    constant TbPeriod : time := 10 ns; 
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : pong_design_wrapper
    port map (clk     => clk,
              hsync   => hsync,
              reset   => reset,
              rgb     => rgb,
              rl_down => rl_down,
              rl_up   => rl_up,
              rr_down => rr_down,
              rr_up   => rr_up,
              vsync   => vsync);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk is really your main clock signal
    clk <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        rl_down <= '0';
        rl_up <= '0';
        rr_down <= '0';
        rr_up <= '0';

        -- Reset generation
        -- EDIT: Check that reset is really your reset signal
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- EDIT Add stimuli here
        wait for 100 MS;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;