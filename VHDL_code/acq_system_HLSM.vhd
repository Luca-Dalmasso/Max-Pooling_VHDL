----------------------------------------------------------------------------------
--module that is capable of:
--1) acquire 'n_samples' integers coming from external stimuli
--2) able to interact with an external memory (RAM type) in order to store all samples on the fly
--3) compute a Max-Pooling algorithm, with a Pooling window size, configurable by 'top_level' module. (m_x_m)

--OSS:
    --A: the result of the Pooling is dynamically computed and sended as stream of output signals on 16 bits,
    --   it is not stored!
    
    --B: everything is described as HLSM
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity acq_system_HLSM is
    generic(
        --address's bits
        addr_l: natural:=4;
        --data's bits
        data_l: natural:=16;
        --number of samples to be taken (must be <=2^addr_l)
        n_samples: natural:=16;
        --size of sqare matrix containig our samples
        nrows: natural:=40
    );
    port(
        clock:  in std_logic;
        reset:  in std_logic;
        start:  in std_logic;
        data_in:in std_logic_vector(data_l - 1 downto 0); --sample in
        data_from_memory: in std_logic_vector(data_l - 1 downto 0); --sample read from memory
        m_x_m: in std_logic_vector(3 downto 0); --size of sqare sub matrix where max poolinkg is applied    
        addr_out:out std_logic_vector(addr_l-1 downto 0); --RAM's address where to write
        data_out: out std_logic_vector(data_l-1 downto 0); --sample to be written in RAM  
        max_pool_sample: out std_logic_vector(data_l-1 downto 0); --result of current max-pooling
        pool_ready: out std_logic; --if = '1' --> result of current pooling is ready
        end_process: out std_logic; --every pooling on all sub-matrices has been done = end of process
        full: out std_logic; --write operation on RAM ended = all samples in have been captured and saved
        wr_en: out std_logic --write/read signal for RAM
    );
end acq_system_HLSM;

architecture HLSM of acq_system_HLSM is

--hlsm states register
type statetype is (INIT,CHECK,WR_SAMPLE,CHECK_I,CHECK_J,INIT_MAX,CHECK_K,CHECK_P,READ_SUB_VAL,STOP);
signal next_state,current_state: statetype;

--hlsm index counter
signal next_index,current_index: std_logic_vector(addr_l downto 0);

--i,j,k,p index registers
signal next_i,current_i: std_logic_vector(addr_l-1 downto 0);
signal next_j,current_j: std_logic_vector(addr_l-1 downto 0);
signal next_k,current_k: std_logic_vector(addr_l-1 downto 0);
signal next_p,current_p: std_logic_vector(addr_l-1 downto 0);

--max register
signal next_max,current_max: std_logic_vector(data_l-1 downto 0);


begin

    --hlsm regs,reset synch
    process(clock)
    begin
        if rising_edge(clock) then
            if reset='1' then
                current_state<=INIT;
                current_index<=(others=>'0');
                current_i<=(others=>'0');
                current_j<=(others=>'0');
                current_k<=(others=>'0');
                current_p<=(others=>'0');
                current_max<=(others=>'0');
            else
                current_state<=next_state;
                current_index<=next_index;
                current_i<=next_i;
                current_j<=next_j;
                current_k<=next_k;
                current_p<=next_p;
                current_max<=next_max;
            end if;
        end if;   
    end process;
    
    --hlsm control
    process(current_state,current_index,current_i,current_j,current_k,current_p,current_max,start,data_in,m_x_m,data_from_memory)
    variable address_memory: integer;
    begin
        --comb logic
        addr_out<=current_index(addr_l-1 downto 0);
        data_out<=(others=>'Z');
        wr_en<='Z';
        max_pool_sample<=(others=>'Z');
        end_process<='0';
        full<='1';
        pool_ready<='0';
        case current_state is
            when INIT=>
                --registers
                next_index<=(others=>'0');
                next_i<=(others=>'0');
                next_j<=(others=>'0');
                next_k<=(others=>'0');
                next_p<=(others=>'0');
                next_max<=(others=>'0');
                full<='0';
                if start='1' then
                    next_state<=CHECK;
                else
                    next_state<=INIT;
                end if;
                               
           when CHECK=>
                --have all samples been saved?
                full<='0';
                if to_integer(unsigned(current_index)) = (n_samples) then
                    next_state<=CHECK_I;
                    next_index<=(others=>'0');
                else
                    next_state<=WR_SAMPLE;
                end if;
           
           when WR_SAMPLE=>
                --on next clock cycle the data is written into memory
                next_index<=std_logic_vector(unsigned(current_index) + 1);
                wr_en<='1';
                data_out<=data_in;
                next_state<=CHECK;
                full<='0';
                
           when CHECK_I=>
                if to_integer(unsigned(current_i)) = (nrows) then
                    next_state<=STOP;
                else    
                    next_state<=CHECK_J;
                end if;
                next_j<=(others=>'0');
                
           when CHECK_J=>
                if to_integer(unsigned(current_j)) = (nrows) then
                    next_state<=CHECK_I;
                    next_i<=std_logic_vector(unsigned(current_i)+unsigned(m_x_m));
                else    
                    next_state<=INIT_MAX;
                end if;
                
           when INIT_MAX=>
                --read RAM for max init, i use an auxiliary variable to traslate 
                --a c,c++ like matrix (m[i][j]) into accesses to memory (array)
                --for example in a 2x2 matrix if i want to access element m[1][1] i just need i=1,j=1
                --i and j are translated into a single addres that is: addr=(i*2 + j); 
                address_memory:=to_integer(unsigned(current_i)) * nrows;
                addr_out<=std_logic_vector(to_unsigned(address_memory,addr_out'length) + unsigned(current_j));
                wr_en<='0';
                next_k<=current_i;
                next_state<=CHECK_K;
                next_max<=data_from_memory;
                
          when CHECK_K=>
                if (unsigned(current_k) = (unsigned(current_i)+unsigned(m_x_m))) then
                    max_pool_sample<=current_max;
                    next_j<=std_logic_vector(unsigned(current_j)+unsigned(m_x_m));
                    next_state<=CHECK_J;
                    pool_ready<='1';
                else
                    next_state<=CHECK_P;
                    next_p<=current_j;
                end if;
                
          when CHECK_P=>
                if (unsigned(current_p) = (unsigned(current_j)+unsigned(m_x_m))) then
                    next_k<=std_logic_vector(unsigned(current_k)+1);
                    next_state<=CHECK_K;                
                else
                    next_state<=READ_SUB_VAL;                   
                end if;
                
          when READ_SUB_VAL=>
                --read a value in submatrix and compare it to the current max value of same submatrix
                address_memory:=to_integer(unsigned(current_k)) * nrows;
                addr_out<=std_logic_vector(to_unsigned(address_memory,addr_out'length) + unsigned(current_p));
                wr_en<='0';
                next_p<=std_logic_vector(unsigned(current_p)+1);
                next_state<=CHECK_P;
                if  to_integer(unsigned(data_from_memory)) > to_integer(unsigned(current_max)) then
                    next_max<=data_from_memory;
                end if;

           when STOP=>
                --restart everything from scratch only with 'reset' signal
                end_process<='1';
                next_state<=STOP;
                
        end case;
    
    end process;

end HLSM;
