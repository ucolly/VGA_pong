library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_rst_mgmt is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           locked : in STD_LOGIC;
           rst : out STD_LOGIC);
end clk_rst_mgmt;

architecture rtl of clk_rst_mgmt is
    SIGNAL rst_sync : STD_LOGIC_VECTOR(1 DOWNTO 0);
begin
    SyncProc : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            rst_sync(0) <= reset;
            rst_sync(1) <= rst_sync(0);
            
            IF rst_sync(1) = '1' OR locked = '0' THEN
                rst <= '1';
            ELSE
                rst <= '0';    
            END IF;
        END IF;
    END PROCESS SyncProc;
end rtl;
