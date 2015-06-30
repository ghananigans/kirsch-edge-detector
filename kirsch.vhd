
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity kirsch is
  port(
    ------------------------------------------
    -- main inputs and outputs
    i_clock    : in  std_logic;                      
    i_reset    : in  std_logic;                      
    i_valid    : in  std_logic;                 
    i_pixel    : in  std_logic_vector(7 downto 0);
    o_valid    : out std_logic;                 
    o_edge     : out std_logic;	                     
    o_dir      : out std_logic_vector(2 downto 0);                      
    o_mode     : out std_logic_vector(1 downto 0);
    o_row      : out std_logic_vector(7 downto 0);
    ------------------------------------------
    -- debugging inputs and outputs
    debug_key      : in  std_logic_vector( 3 downto 1) ; 
    debug_switch   : in  std_logic_vector(17 downto 0) ; 
    debug_led_red  : out std_logic_vector(17 downto 0) ; 
    debug_led_grn  : out std_logic_vector(5  downto 0) ; 
    debug_num_0    : out std_logic_vector(3 downto 0) ; 
    debug_num_1    : out std_logic_vector(3 downto 0) ; 
    debug_num_2    : out std_logic_vector(3 downto 0) ; 
    debug_num_3    : out std_logic_vector(3 downto 0) ; 
    debug_num_4    : out std_logic_vector(3 downto 0) ;
    debug_num_5    : out std_logic_vector(3 downto 0) 
    ------------------------------------------
  );  
end entity;


architecture main of kirsch is
  signal index : unsigned (15 downto 0);
  signal receivedNumbers : unsigned (15 downto 0);

  signal pixel : std_logic_vector(7 downto 0);

  subtype vec_unsigned_8 is unsigned(7 downto 0);
  type vec_vec_unsigned_8 is array (2 downto 0) of vec_unsigned_8;
  signal memq : vec_vec_unsigned_8;

  signal memwren : std_logic_vector (2 downto 0);

  signal memRow, memRow2 :unsigned (1 downto 0);
  signal memCol : unsigned (7 downto 0);

  signal matrixRow, matrixCol : unsigned (7 downto 0);
begin 

  memory : for i in 0 to 2 generate
    memBlock : entity work.mem(main)
    port map (
      clock => i_clock,
      address => std_logic_vector(memCol),
      wren => memwren(i),
      unsigned(q) => memq(i),
      data => std_logic_vector(pixel)
   );
  end generate memory;

 
  pixel_receive_buffer : process begin
    wait until rising_edge(i_clock);

    if (i_valid = '1') then
      pixel <= i_pixel;
    end if;
  end process;


  write_to_mem : process begin
    wait until rising_edge(i_clock);

    if (i_reset = '1') then
      --reset
      index <= X"FFFF";
      memRow <= "10";
      memRow2 <= "00";
      memwren <= "000";
    elsif (i_valid = '1') then
      memwren(to_integer(memRow2)) <= '1';
      index <= receivedNumbers;

      if (memCol = 255) then
        if (memRow = 2) then
          memRow <= "00";
        else
          memRow <= memRow + 1;
        end if;
      end if;

      if (memCol = 254) then
        if (memRow2 = 2) then
          memRow2 <= "00";
        else
          memRow2 <= memRow2 + 1;
        end if;
      end if;
    else
      memwren <= "000";
    end if;
  end process;

  receivedNumbers <= index + 1;
  
  matrixCol <= index (7 downto 0);
  matrixRow <= index (15 downto 8);

  memCol <= index (7 downto 0);

  debug_num_5 <= X"E";
  debug_num_4 <= X"C";
  debug_num_3 <= X"E";
  debug_num_2 <= X"3";
  debug_num_1 <= X"2";
  debug_num_0 <= X"7";

  debug_led_red <= (others => '0');
  debug_led_grn <= (others => '0');
  
end architecture;
