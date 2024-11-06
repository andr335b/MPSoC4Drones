library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity data_copier is
    Port (
        clk         : in  STD_LOGIC;
        rst         : in  STD_LOGIC;
        
        -- BRAM0 interface (read)
        bram0_din   : in  STD_LOGIC_VECTOR(31 downto 0);
        bram0_addr  : out STD_LOGIC_VECTOR(31 downto 0);
        bram0_en    : out STD_LOGIC;
        bram0_wen   : out STD_LOGIC_VECTOR(3 downto 0);
        
        -- BRAM1 interface (write)
        bram1_dout  : out STD_LOGIC_VECTOR(31 downto 0);
        bram1_addr  : out STD_LOGIC_VECTOR(31 downto 0);
        bram1_wen   : out STD_LOGIC_VECTOR(3 downto 0);
        bram1_en    : out STD_LOGIC
    );
end data_copier;

architecture Behavioral of data_copier is
    signal addr_counter : UNSIGNED(31 downto 0) := (others => '0');  -- 32-bit address counter
    signal read_data    : STD_LOGIC_VECTOR(31 downto 0);
    signal modified_data : STD_LOGIC_VECTOR(31 downto 0);
begin

    process(clk, rst)
    begin
        if rst = '1' then
            addr_counter <= (others => '0');
            bram0_en <= '0';
            bram1_en <= '0';
            bram1_wen <= (others => '0');
        elsif rising_edge(clk) then
            -- Enable both BRAMs for operation
            bram0_en <= '1';
            bram1_en <= '1';

            -- Set BRAM addresses using the 32-bit counter
            bram0_addr <= std_logic_vector(addr_counter);
            bram1_addr <= std_logic_vector(addr_counter);

            -- Read data from BRAM0
            read_data <= bram0_din;

            -- Modify read_data by setting the MSB to 200 (0xC8)
            modified_data <= x"C8" & read_data(23 downto 0);

            -- Write modified data to BRAM1
            bram1_dout <= modified_data;
            bram1_wen <= "1111";  -- Enable writing all bytes in BRAM1

            -- Increment the address counter
            if addr_counter = 808 then
                addr_counter <= (others => '0');  -- Reset the counter after reaching 200
            else
                addr_counter <= addr_counter + 4;
            end if;
        end if;
    end process;

    -- Set BRAM0 write enable to 0 (read-only)
    bram0_wen <= "0000";
end Behavioral;

