
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
  signal received_pixels : unsigned(15 downto 0);
  signal mem_wren : std_logic_vector(2 downto 0);
  subtype vec is unsigned(7 downto 0);
  type vec_vec is array (2 downto 0) of vec;
  signal mem_q : vec_vec;

  signal busy : std_logic;

  signal row1_pixel, row2_pixel : unsigned(7 downto 0);  

  signal a, b, c, d, e, f, g, h, i : unsigned(7 downto 0);

  signal stage1_v, stage2_v, stage3_v : std_logic_vector(3 downto 0); 
  signal stage4_v : std_logic_vector(2 downto 0);

  signal stage1_max : unsigned (7 downto 0);
  signal stage1_max_dir : std_logic_vector (2 downto 0);
  signal stage1_sum : unsigned(8 downto 0);

  signal stage2_max : unsigned (9 downto 0);
  signal stage2_max_dir : std_logic_vector (2 downto 0);
  signal stage2_sum : unsigned(10 downto 0);

  signal stage3_max : unsigned (9 downto 0);
  signal stage3_max_dir : std_logic_vector (2 downto 0);
 
  signal stage4_max : unsigned (12 downto 0);
  signal stage4_max_dir : std_logic_vector (2 downto 0);

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
      address => std_logic_vector(received_pixels(7 downto 0)),
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
      o_row <= "00000000";
    elsif (i_valid = '1') then
      received_pixels <= received_pixels + 1; 

      if (received_pixels(7 downto 0) = 255) then
        mem_wren <= "rol"(mem_wren, 1);
      end if;
    
      o_row <= std_logic_vector(received_pixels(15 downto 8));
    end if;
  end process;



  system_mode : process begin
    wait until rising_edge(i_clock);

    if (i_reset = '1') then
      o_mode <= "01";
      busy <= '0';
    elsif (i_valid = '1') then
      busy <= '1';
      o_mode <= "11";
    elsif (((stage3_v = "0000") and(stage4_v(1) = '1')) and (received_pixels = 0)) then
      o_mode <= "10";
      busy <= '0';
    elsif (busy = '1') then
      o_mode <= "11";
    else
      o_mode <= "10";
    end if; 
  end process;



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

      c <= row1_pixel;
      f <= row2_pixel;
      i <= unsigned(i_pixel);
    end if;
  end process;



  stage1 : process begin
    wait until rising_edge(i_clock);
    
    if (i_reset = '1') then
      stage1_v <= "0000";
    else
      stage1_v <= "sll"(stage1_v, 1);
      
      if ((i_valid = '1') and ((received_pixels(7 downto 1) /= "0000000") and (received_pixels(15 downto 9) /= "0000000")))  then
        stage1_v(0) <= '1';
      end if;

      case stage1_v is
        when "0001" =>
          if (b > g) then
            stage1_max <= b;
            stage1_max_dir <= "100";
          else
            stage1_max <= g;
            stage1_max_dir <= "001";
          end if;
          stage1_sum <= ('0' & d) + ('0' & a);
     
        when "0010" =>
          if (f > a) then
            stage1_max <= f;
            stage1_max_dir <= "110";
          else
            stage1_max <= a;
            stage1_max_dir <= "010";
          end if;
          stage1_sum <= ('0' & c) + ('0' & b);
         
        when "0100" =>
          if (h > c) then
            stage1_max <= h;
            stage1_max_dir <= "101";
          else
            stage1_max <= c;
            stage1_max_dir <= "000";
          end if;
          stage1_sum <= ('0' & f) + ('0' & i);

        when "1000" =>
          if (d > i) then
            stage1_max <= d;
            stage1_max_dir <= "111";
          else
            stage1_max <= i;
            stage1_max_dir <= "011";
          end if;
          stage1_sum <= ('0' & g) + ('0' & h);

        when others =>
      end case;
    end if;
  end process;



  stage2 : process begin
    wait until rising_edge(i_clock);
    
    if (i_reset = '1') then
      stage2_v <= "0000";
    else
      stage2_v <= "sll"(stage2_v, 1);
      if (stage1_v(0) = '1') then
        stage2_v(0) <= '1';
      end if;

      stage2_max <= ("00" & stage1_max) + ('0' & stage1_sum);
      stage2_max_dir <= stage1_max_dir;

      if (stage2_v(0) = '1') then
        stage2_sum <= "00" & stage1_sum; 
      else
       stage2_sum <= stage2_sum + ("00" & stage1_sum);
      end if;
    end if;
  end process;



  stage3 : process begin
    wait until rising_edge(i_clock);

    if (i_reset = '1') then
      stage3_v <= "0000";
    else
      stage3_v <= "sll"(stage3_v, 1);
      if (stage2_v(0) = '1') then
        stage3_v(0) <= '1';
      end if;

      if (stage3_v(0) = '1') then
        stage3_max <= stage2_max;
        stage3_max_dir <= stage2_max_dir;
      else
        if(stage2_max > stage3_max) then
          stage3_max <= stage2_max;
          stage3_max_dir <= stage2_max_dir;
      	end if;
      end if;
    end if;
  end process;



  stage4 : process begin
    wait until rising_edge(i_clock);

    o_valid <= '0';
    if (i_reset = '1') then
      stage4_v <= "000";
    else
      stage4_v <= "sll"(stage4_v, 1);
      if (stage2_v(3) = '1') then
        stage4_v(0) <= '1';
      end if;
 
      case stage4_v is
        when "001" =>
           stage4_max <= ('0' & stage2_sum & '0') + ("00" & stage2_sum);

        when "010" =>
          stage4_max <= (stage3_max & "000") - stage4_max;
          stage4_max_dir <= stage3_max_dir;
          o_valid <= '1';
        when "100" =>
          --o_valid <= '1';

          --if (stage4_max > 383) then
            --o_edge <= '1';
            --o_dir <= stage4_max_dir;
          --else
	    --o_edge <= '0';	
	    --o_dir <= "000";
          --end if;

        when others =>
      end case;
    end if;
  end process;

  o_edge <= '1' when stage4_max > 383 else '0';
  o_dir <= stage4_max_dir when stage4_max > 383 else "000";

  debug_num_5 <= X"E";
  debug_num_4 <= X"C";
  debug_num_3 <= X"E";
  debug_num_2 <= X"3";
  debug_num_1 <= X"2";
  debug_num_0 <= X"7";

  debug_led_red <= (others => '0');
  debug_led_grn <= (others => '0');
  
end architecture;
