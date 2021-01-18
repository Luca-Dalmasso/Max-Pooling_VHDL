----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 17.01.2021 13:04:10
-- Design Name: 
-- Module Name: top_level - struct
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top_level is
    port(
        sample_in: in std_logic_vector(15 downto 0);
        clock,reset,start: in std_logic;
        select_window: in std_logic_vector(2 downto 0);
        pool_output: out std_logic_vector(15 downto 0);
        pooling_end: out std_logic;
        pool_is_ready: out std_logic
    );
end top_level;

architecture struct of top_level is

component acq_system_HLSM is
    generic(
        addr_l: natural:=4;
        data_l: natural:=16;
        n_samples: natural:=16;
        nrows: natural:=40
    );
    port(
        clock:  in std_logic;
        reset:  in std_logic;
        start:  in std_logic;
        data_in:in std_logic_vector(data_l - 1 downto 0);
        data_from_memory: in std_logic_vector(data_l - 1 downto 0);
        m_x_m: in std_logic_vector(3 downto 0);     
        addr_out:out std_logic_vector(addr_l-1 downto 0);
        data_out: out std_logic_vector(data_l-1 downto 0);      
        max_pool_sample: out std_logic_vector(data_l-1 downto 0);
        pool_ready: out std_logic;
        end_process: out std_logic;
        full: out std_logic;
        wr_en: out std_logic
    );
end component;

signal data_out_acq: std_logic_vector(15 downto 0);
signal addr_out_acq: std_logic_vector(3 downto 0);
signal end_save: std_logic;
signal wr_enable: std_logic;
signal m: std_logic_vector(3 downto 0);
signal ready: std_logic;
signal pool_out:std_logic_vector(15 downto 0);
signal max_pooling_end: std_logic;

component RAM is
    generic(
        addr: natural:=4;
        word: natural:=16;
        size: natural:=16;
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
end component;

signal data_out_mem: std_logic_vector(15 downto 0);

begin

system: acq_system_HLSM generic map(4,16,16,4) port map(clock,reset,start,sample_in,data_out_mem,m,addr_out_acq,data_out_acq,pool_out,ready,max_pooling_end,end_save,wr_enable);
memory: RAM generic map(4,16,16,5 ns) port map(clock,reset,data_out_acq,addr_out_acq,wr_enable,data_out_mem);

with select_window select m<="0001" when "001",
                             "0010" when "010",
                             "0100" when "100",
                             "1000" when "101",
                             "1010" when others;

pool_output<=pool_out;
pooling_end<=max_pooling_end;
pool_is_ready<=ready;
end struct;
