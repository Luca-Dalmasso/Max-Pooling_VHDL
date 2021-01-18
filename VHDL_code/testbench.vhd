

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;

entity testbench is
--  Port ( );
end testbench;

architecture tb of testbench is

component top_level is
    port(
        sample_in: in std_logic_vector(15 downto 0);
        clock,reset,start: in std_logic;
        select_window: in std_logic_vector(2 downto 0);
        pool_output: out std_logic_vector(15 downto 0);
        pooling_end: out std_logic;
        pool_is_ready: out std_logic
    );
end component;

signal clk,rst,start: std_logic;
signal data_in: std_logic_vector(15 downto 0);
signal sel: std_logic_vector(2 downto 0);
signal ready: std_logic;
signal pool_output:std_logic_vector(15 downto 0);
signal stop:std_logic ;

signal test: std_logic_vector(15 downto 0);
constant period:time:= 20 ns;

file VECTOR_SAMPLE : text;
file VECTOR_VV: text;

begin

uut:top_level port map(data_in,clk,rst,start,sel,pool_output,stop,ready); 

    --CLOCK GENERATION PROCESS
    process
    begin
        clk<='0';
        wait for period/2;
        clk<='1';
        wait for period/2;    
    end process;
    
    --INPUT STREAM GENERATION PROCESS
    process
    variable v_ILINE : line;
    variable v_TERM: integer;
    begin
        file_open(VECTOR_SAMPLE, "samples.mem",  read_mode);
        rst<='1';
        wait for period/2;
        wait for 5 ns;
        rst<='0';
        sel<="010";
        start<='1';
        wait for period;
        wait for period;
        while not endfile(VECTOR_SAMPLE) loop
            readline(VECTOR_SAMPLE, v_ILINE);
            read(v_ILINE, v_TERM);
            data_in<=std_logic_vector(to_unsigned(v_TERM,data_in'length));
            wait for period;
            wait for period;
        end loop;
        file_close(VECTOR_SAMPLE); 
        wait;
    end process;
    
    --TEST OF CORRECTNESS PROCESS
    --read the ouput stream of datas, which are the results of Max-Pooling.
    --compare, on the fly, the data captured with a predefined sequence.
    process(ready,stop,pool_output)
    type array_to_test is  array(0 to 1600) of integer;
    variable x: array_to_test;
    variable i: integer;
    variable term: integer:=0;
    variable v_ILINE : line;
    variable v_TERM: integer;
    begin
        if stop='0' then
            --write process
            if ready='1' then
                x(i):=to_integer(unsigned(pool_output));
                i:=i+1;
            end if;
        else
            --v & v process
            if term=0 then
                i:=0;
                file_open(VECTOR_VV, "pooling.mem",  read_mode);
                while not endfile(VECTOR_VV) loop
                    readline(VECTOR_VV, v_ILINE);
                    read(v_ILINE, v_TERM);
                    assert v_TERM /= x(i) report "System failure!" severity error;
                    assert v_TERM  = x(i) report "OK" severity note;
                    i:=i+1;
                    end loop;
                file_close(VECTOR_SAMPLE);
                term:=1;
            end if;
        end if;
    
    end process;
end tb;
