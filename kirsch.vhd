
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
  signal mode : std_logic_vector(1 downto 0);
  signal dir : std_logic_vector(2 downto 0);
  signal edge_exists : std_logic;
  signal valid : std_logic;
  signal busy : std_logic;

  signal mem_wren : std_logic_vector(2 downto 0);

  subtype vec is unsigned(7 downto 0);
  type vec_vec is array (2 downto 0) of vec;
  signal mem_q : vec_vec;

  signal matrix_col, matrix_row : unsigned(7 downto 0);
  signal receivedNumbers : unsigned(15 downto 0);

  signal row1pixel, row2pixel : unsigned(7 downto 0);  

  signal a, b, c, d, e, f, g, h, i : unsigned(9 downto 0);

  
  function "rol" (a : std_logic_vector; n : natural)
    return std_logic_vector
  is
  begin
    return std_logic_vector(unsigned(a) rol n);
  end function;
begin  
  memory: for i in 0 to 2 generate
    mem: entity work.mem(main)
    port map (
      address => std_logic_vector(matrix_col),
      clock => i_clock,
      data => i_pixel,
      wren => mem_wren(i),
      unsigned(q) => mem_q(i)
    );
  end generate;

  memory_writing: process begin
    wait until rising_edge(i_clock);
    
    if (i_reset = '1') then
      receivedNumbers <= X"0000";
      mem_wren <= "001";
      busy <= '0';
    elsif (i_valid = '1') then
      receivedNumbers <= receivedNumbers + 1; 
      busy <= '1'; 

      if (matrix_col = 255) then
        mem_wren <= "rol"(mem_wren, 1);
        
        if (matrix_row = 255) then
          busy <= '0';
        end if;
      end if;
    end if;
  end process;
  matrix_col <= receivedNumbers (7 downto 0);
  matrix_row <= receivedNumbers (15 downto 8);
  o_row <= std_logic_vector(matrix_row);


  get_pixel_from_memory : process(mem_q, mem_wren) begin
    case mem_wren is
      when "001" =>
        row1pixel <= mem_q(1);
        row2pixel <= mem_q(2);
      when "010" =>
        row1pixel <= mem_q(2);
        row2pixel <= mem_q(0);
      when "100" =>
        row1pixel <= mem_q(0);
        row2pixel <= mem_q(1);
      when others =>
        row1pixel <= X"00";
        row2pixel <= X"00"; 
    end case;
  end process;



  convolution_table : process begin
    wait until rising_edge(i_clock);
  
    if (i_valid = '1') then
      a <= b;
      b <= c;
      d <= e;
      e <= f;
      g <= h;
      h <= i;

      --add new stuff to the convulution table
      c <= "00" & row1pixel;
      f <= "00" & row2pixel;
      i <= "00" & unsigned(i_pixel);
    end if;
  end process;



  system_mode : process begin
    wait until rising_edge(i_clock);
 
    if (i_reset = '1') then 
      mode <= "01";
    elsif (busy = '1') then
      mode <= "11";
    else
      mode <= "10";
    end if;
  end process;
  o_mode <= mode;


  computation : process begin
    wait until rising_edge(i_clock);
    
    if (i_reset = '1') then
      valid <= '0';
    else

    end if;
  end process;
  o_edge <= edge_exists;
  o_dir <= dir;
  o_valid <= valid;

  debug_num_5 <= X"E";
  debug_num_4 <= X"C";
  debug_num_3 <= X"E";
  debug_num_2 <= X"3";
  debug_num_1 <= X"2";
  debug_num_0 <= X"7";

  debug_led_red <= (others => '0');
  debug_led_grn <= (others => '0');
  
end architecture;
