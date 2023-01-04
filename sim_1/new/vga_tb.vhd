library ieee;
use ieee.std_logic_1164.all;

entity tb_vga is
end tb_vga;

architecture tb of tb_vga is

    component vga
        port (clk_vga  : in std_logic;
              rst_vga  : in std_logic;
              vga_data : in std_logic_vector (11 downto 0);
              addr_x   : out std_logic_vector (10 downto 0);
              addr_y   : out std_logic_vector (10 downto 0);
              vsync    : out std_logic;
              hsync    : out std_logic;
              rgb      : out std_logic_vector (11 downto 0));
    end component;

    signal clk_vga  : std_logic;
    signal rst_vga  : std_logic;
    signal vga_data : std_logic_vector (11 downto 0);
    signal addr_x   : std_logic_vector (10 downto 0);
    signal addr_y   : std_logic_vector (10 downto 0);
    signal vsync    : std_logic;
    signal hsync    : std_logic;
    signal rgb      : std_logic_vector (11 downto 0);

    constant TbPeriod : time := 6.734 ns; -- EDIT Put right period here
    signal TbClock : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : vga
    port map (clk_vga  => clk_vga,
              rst_vga  => rst_vga,
              vga_data => vga_data,
              addr_x   => addr_x,
              addr_y   => addr_y,
              vsync    => vsync,
              hsync    => hsync,
              rgb      => rgb);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';

    -- EDIT: Check that clk_vga is really your main clock signal
    clk_vga <= TbClock;

    stimuli : process
    begin
        -- EDIT Adapt initialization as needed
        vga_data <= (others => '0');

        -- Reset generation
        -- EDIT: Check that rst_vga is really your reset signal
        rst_vga <= '1';
        wait for 100 ns;
        rst_vga <= '0';
        wait for 100 ns;

        -- EDIT Add stimuli here
        wait for 100000000 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;