
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

  signal received_pixels : unsigned(15 downto 0);
  signal matrix_col, matrix_row : unsigned(7 downto 0);
  signal mem_wren : std_logic_vector(2 downto 0);
  subtype vec is unsigned(7 downto 0);
  type vec_vec is array (2 downto 0) of vec;
  signal mem_q : vec_vec;

  signal row1_pixel, row2_pixel : unsigned(7 downto 0);  

  signal a, b, c, d, e, f, g, h, i : unsigned(9 downto 0);

  signal stage1_v, stage2_v : std_logic_vector(3 downto 0); 

 
  function "rol" (a : std_logic_vector; n : natural)
    return std_logic_vector
  is
  begin
    return std_logic_vector(unsigned(a) rol n);
  end function;

  function "sll" (a : std_logic_vector; n : natural)
    return std_logic_vector
  is
  begin
    return std_logic_vector(unsigned(a) sll n);
  end function;
begin  
  memory_generate: for i in 0 to 2 generate
    mem: entity work.mem(main)
    port map (
      address => std_logic_vector(matrix_col),
      clock => i_clock,
      data => i_pixel,
      wren => mem_wren(i),
      unsigned(q) => mem_q(i)
    );
  end generate memory_generate;



  memory_writing : process begin
    wait until rising_edge(i_clock);
    
    if (i_reset = '1') then
      received_pixels <= X"0000";
      mem_wren <= "001";
    elsif (i_valid = '1') then
      received_pixels <= received_pixels + 1; 

      if (matrix_col = 255) then
        mem_wren <= "rol"(mem_wren, 1);
      end if;
    end if;
  end process;
  matrix_col <= received_pixels (7 downto 0);
  matrix_row <= received_pixels (15 downto 8);
  o_row <= std_logic_vector(matrix_row);



  system_mode : process begin
    wait until rising_edge(i_clock);

    if (i_reset = '1') then
      mode <= "01";
    elsif (i_valid = '1') then
      mode <= "11";
    elsif ((stage2_v(3) = '1') and ((matrix_row = 255) and (matrix_col = 255))) then
      mode <= "10";
    else
      mode <= "00";
    end if; 
  end process;
  o_mode <= mode;



  get_pixel_from_memory : process(mem_q, mem_wren) begin
    case mem_wren is
      when "001" =>
        row1_pixel <= mem_q(1);
        row2_pixel <= mem_q(2);
      when "010" =>
        row1_pixel <= mem_q(2);
        row2_pixel <= mem_q(0);
      when "100" =>
        row1_pixel <= mem_q(0);
        row2_pixel <= mem_q(1);
      when others =>
        row1_pixel <= X"00";
        row2_pixel <= X"00"; 
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

      c <= "00" & row1_pixel;
      f <= "00" & row2_pixel;
      i <= "00" & unsigned(i_pixel);
    end if;
  end process;



  stage1 : process begin
    wait until rising_edge(i_clock);
    
    if (i_reset = '1') then
      stage1_v <= "0000";
    else
      stage1_v <= "sll"(stage1_v, 1);
      
      if ((i_valid = '1') and ((matrix_row > 1) and (matrix_col > 1)))  then
        stage1_v(0) <= '1';
      end if;

      if (stage1_v(0) = '1') then

      elsif (stage1_v(1) = '1') then

      elsif (stage1_v(2) = '1') then

      elsif (stage1_v(3) = '1') then

      end if;
    end if;
  end process;



  stage2 : process begin
    wait until rising_edge(i_clock);
    
    if (i_reset = '1') then
      stage2_v <= "0000";
    else
      stage2_v <= "sll"(stage2_v, 1);

      stage2_v(0) <= stage1_v(0);

      if (stage2_v(0) = '1') then
         
      elsif (stage2_v(1) = '1') then

      elsif (stage2_v(2) = '1') then

      elsif (stage2_v(3) = '1') then

      end if;
    end if;
  end process;



  stage3 : process begin
    wait until rising_edge(i_clock);

    valid = '0';
    if (i_reset = '1') then
      stage3_v <= "00";
    else
      stave3_v <= "sll"(stage3_v, 1);

      stage3_v(0) <= stage2_v(3);
      
      if (stage3_v(0) = '1') then

      elsif (stage3_v(1) = '1') then
        valid = '1';
        edge_exists = '0';
        dir = "000";
      end if;
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
