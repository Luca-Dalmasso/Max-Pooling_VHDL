--RAM MODULE

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM is
    generic(
        addr: natural:=4;--address' bits
        word: natural:=16;--word's bits
        size: natural:=16;--size of memory, must be <=(2^addr -1)
        t_acc: time:= 5 ns
    );
    port(
        clock:in std_logic;
        reset:in std_logic;
        data_in:in std_logic_vector(word-1 downto 0);
        addr_in:in std_logic_vector(addr-1 downto 0);
        wr_en:in std_logic;
        data_out:out std_logic_vector(word-1 downto 0) 
    );
end RAM;

architecture Behavioral of RAM is

--word subtype
subtype WORDT is std_logic_vector(word-1 downto 0);
--storage type
type STORAGE is array(0 to size-1) of WORDT;
--memory
signal MEM: STORAGE;

begin

    --write process
    process(clock)
    begin
        if rising_edge(clock) then
            if reset='1' then
                MEM<=(others=>(others=>'0'));
            else
                if wr_en='1' then
                    MEM(to_integer(unsigned(addr_in)))<=data_in;
                end if;
            end if;
        end if;
    end process;
    
    --read process
    process(addr_in,wr_en,MEM)
    begin
        if wr_en='0' then
            data_out<=MEM(to_integer(unsigned(addr_in))) after t_acc;
        else
            data_out<=(others=>'Z');
        end if; 
    end process;

end Behavioral;
