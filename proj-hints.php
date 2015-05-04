<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
>

<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <? include("lib/prologue.html") ?>
    <style type="text/css" media="screen">
      @import url("lib/layout.css");
    </style>
  </head>

<body>

  <? include("lib/header.html") ?>
  

<!-- ************************************************************** -->
<!-- secondary navigation -->
<!-- ************************************************************** -->


<div id="contentbar"> 
  <h2>Project Hints and Corrections</h2>
</div>


<div id="primarycontarea">
  <div id="primarycontent">

<!--    
<h1>History of Changes</h1>

<ul>
  <li><font color="red"><b>03/18</b></font>:
    Fifth update</li>
  <li><font color="green"><b>03/17</b></font>:
    Fourth update</li>
  <li>03/15: Third update</li>
  <li>03/13: Second update</li>
  <li>03/11: Original version</li>
</ul>
-->

<!- **************************************************** -->
<h1>Estimating Optimality</h1>
<!- **************************************************** -->

<ul>
  <li>The optimality target is 500.  A good plan is to aim for an
  optimality of 600, so as to allow some slack for extra area and
  delay as you refine your implementation. An optimality of 500 means
  that your area is twice your clock speed. For example, you can
  achieve an optimality score of 500 with a clock speed of 200 MHz and
  area of 400 cells, or with a clock speed of 150 MHz and area of 300
  cells.
  </li>

  <li>A very efficient implementation of the circuitry outside of that
    drawn in the dataflow diagram can be done in approximately 150 cells.  
  </li>
</ul>  

<!- **************************************************** -->
<h1>Coding</h1>
<!- **************************************************** -->

<ul>

  <li>The inputs to the derivative calculations are a set of 8 pixels
  values from the convolution table.  It is usually simplest to use a
  set of 9 registers to hold the values of the current convolution
  table.  When a new pixel arrives, 6 values shift to the left and 3
  new values are read from memory.  It is possible to read all 8
  values from memory each time a pixel arrives, but the circuitry to
  do this is more complicated, and the complexity may cause the
  hardware to be larger and slower than the 3x3 table of registers.
  </li>
    
  <li><p>
      One of the more difficult parts of the project, and an area
  that is particularly susceptible to bugs, is the interaction between
  the row counter, column counter, memory indexing, and deciding
  whether to output a pixel or not (pixels are <b>not</b> output for
  the boundary).</p>

  <p>
  It is
  generally easiest to have your row and column counters point to
  the position of the <b>next</b> pixel that will enter the system.
  When the system starts, the first pixel is the next pixel, and it
  will have a position of (0,0).  When the first pixel arrives, the
  column counter can be incremented.
  </p>

  <p>Depending on implementation details, the row and column counters
  point to the position of either the current or the next pixel to
  enter the system.  In the 3x3 convolution table, this is the lower
  right pixel.  The output (edge and direction) is for the pixel in
  the <b>center</b> of the convolution table.  Recall that the system
  shall not output pixels on the perimeter (row or col is 0 or 255).
  You must translate this condition to the values of your row and
  column counters.  For example, if your row and column counters point
  to the position of the <b>next</b> pixel that will enter the system
  and you test whether you are on the perimeter <b>after</b>
  incrementing the counters for the current pixel, then the system
  shall not output a pixel when the column counter is 2.  </p>

  <p>The offset between the position that the output edge and
  direction represent and the current values of the row and column
  counters also complicates debugging.  Bugs are detected based upon
  the position of the output edge and direction, not the values of the
  row and column counters.  If there is a bug at position (i,j) in the
  output image, the corresponding point in the simulation run will be
  when your row counter is i+1 and column counter is either j+1 or
  j+2.
  </p>
    
  <p>If the total latency through your system is more than
  1/throughput, then you must pipeline your system.  If you increment
  your row and column counters when a pixel first enters the system,
  then a new pixel can enter the system and cause the counters to
  increment <b>before</b> the current pixel has exited.  This means
  that, depending on the number of bubbles between pixels, when a
  parcel exits the system, the row and column counters <b>might</b>
  have already been updated for the next pixel, or might not have been
  updated.  Thus, determining whether the current pixel is on the
  boundary must be done <b>before</b> the next parcel has a chance to
  affect the row and column counters.  This decision then must be
  propagated through the system to control the <tt>o_valid</tt> value
  for the current pixel.
  </p>

  <p>Your row and column counters are specified registers, and, for
  most implementations, these registers belong to the first stage of
  the pipeline.  Because hardware cannot be shared between stages, the
  only way that later stages can make use of the row and column
  counters is to copy their values to registers that belong to the
  later stages.  Because of the area cost and complexity of having
  duplicate copies of these registers, it is generally best to use the
  row and column counters only in the first stage.
  </p>
    
  </li>

  <li>Hardware is boring.  Datapath hardware is extremely boring.  For
    most implementations, the datapath can be completely ignorant of
    special cases, such as whether the current pixel is on the
    perimeter or whether the current pixel is in the first two rows of
    the image and so should not generate an output.  It almost always
    best just to let the datapath treat every pixel in exactly the
    same way, then simply turn off <tt>o_valid</tt> for pixels that
    should not generate outputs.  Similarly, the convolution table
    should be updated for each new pixel that arrives.  With just a
    bit of careful thought, even updating the table when
    row counter increments can be done without any special-case code.
  </li>
  
  <li>If your implementation grows beyond 450 lines of code: stop, do
      a serious design and code review.  The Kirsch equations were
      designed to be implemented efficiently in hardware.  Inside your
      ratatouille is a simple and elegant bowl of miso soup waiting to be
      discovered.
  </li>
</ul>

<!- **************************************************** -->
<h1>Clock Speed Optimizations</h1>
<!- **************************************************** -->

<ul>
  <li>If your critical path ends at <tt>o_edge</tt> or <tt>o_dir</tt>,
  you may be able to speed up your design by making these signals
  registers.  This is because the Quartus timing model puts a large
  load on the ouputs.  Making the outputs registers will add an extra
  clock cycle to your latency.
  </li>
</ul>

<!- **************************************************** -->
<h1>Simulation</h1>
<!- **************************************************** -->

    <li>When running simulation, there are several commands (in
    reality, just Tcl procedures) that have been
    added to modelsim:
      <table>
        <tr><th align="left">reload</th><td>Reloads the vhdl files</td></tr>
        <tr><th align="left">rerun</th><td>Reruns the simulation</td></tr>
        <tr><th align="left">rr</th><td>Reload and rerun</td></tr>
      </table>
    </li>

    <li>
      
      <p> In past years, some students have created <b>Excel
          spreadsheet reference models</b> of their
          implementations. The basic idea is to use the tabular format
          of the spreadsheet with signal names as labels on the rows
          and clock cycles as labels on the columns. You can then
          enter the equations for the signals as formulas in the
          cells. For the data input, you can import one of the .txt
          image files into a second sheet.</p>

      <p> To simplify implementation and debugging this year, we've
          created an
          <a href="https://ece.uwaterloo.ca/~ece327/proj/proj/refmodel.xls"
          >example reference model</a>.  </p>

      <p> You will need to change the signals and their equations to
       match your own implementation. The signals and equations that
       are given are just for illustrative purposes and do not reflect
       a particularly optimal design.</p>

      <p>After you have modified the spreadsheet to match the intended
      behaviour of your implementation, the debugging process is:

        <ol>
          <li> Run simulation</li>
          
          <li> use <tt>diff_ted</tt> to find the row and column of a
          buggy output</li>

          <li>
    type the row and column coordinates of the buggy output into the
    spreadsheet</li>

          <li> compare the values of the signals in the spreadsheet
    against the your implementation</li>

          <li>bugs in the reference model can be detected by comparing
        the derivative values in the upper right blue region against
        the signals below.</li>
            
        </ol>

      </p>

      <p>We've used image2 for the test image, because it has its
      first edge near the beginning of the picture.
      </p>

      
    </li>

    <li>If you are getting warnings about <b>metavalue detected</b>
        when running simulation, this indicates that you are getting
        <tt>'U'</tt> or <tt>'X'</tt> values in your simulation.  If
        these warnings occur before the first two rows of data are
        fully populated, then they may be safely ignored.  The
        memory arrays output <tt>'U'</tt> until they have been written
        to.  These <tt>'U'</tt> values will propagate safely through
        your circuit and then be ignored by setting <tt>o_valid</tt>
        to <tt>'0'</tt> while the first two rows of data are being
        filled.  If you are encouting metavalue warnings <b>after</b>
        the first two rows of memory have been filled, then this is
        often a sign of a bug in your system.
     </li>

  </ul>
  

<!- **************************************************** -->
<h1>Debugging</h1>
<!- **************************************************** -->

  <ul>
    <li>When debugging, add a clock-cycle signal to your
    implementation that counts the number of clock cycles that have
    elapsed since <tt>i_valid</tt> was <tt>'1'</tt>.  This will make
    it easier to match the waveforms in Modelsim against your dataflow
    diagram and Excel reference model (if you use the Excel model).
    </li>      
      
    <li>When first debugging, set the <tt>bubbles</tt> generic in
    <tt>kirsch_tb.vhd</tt> to be greater than your latency.  For
    example, if your latency is 8, then set <tt>bubbles</tt> to be
    10.   This will ensure that there is at most one parcel in your
    system at a time.  After your system works correctly in this
    "unpipelined" mode, then set <tt>bubbles</tt> to be 3 and debug
    any problems that are then discovered.
    </li>
  </ul>
    
<!- **************************************************** -->
<h1>Warning Messages from PrecisionRTL (uw-synth)</h1>
<!- **************************************************** -->

<ul>

  <!-- ****************************************** -->

  <li>
  <p><b><code>Warning, <i>signal</i> is not always assigned. Storage may be
  needed..</code></b></p>

  <p>This is <b>bad</b> <i>signal</i> will be turned into a latch.
  Check to make sure that you are covering all possible cases in your
  assignmemts, and use a fall-through "others" or "else".  </p>

  </li>

  <!-- ****************************************** -->
  
  <li><p><b><code>Warning, <i>signal</i> should be declared on the
  sensitivity list of the process</code></b></p>

  <p> If this is in a combinational process, then this is <b>bad</b>,
  because you will get a latch rather than combinational circuitry.
  If this is in a clocked process, then it is safe to ignore the
  warning.</p>

  </li>

  <!-- ****************************************** -->
  <li>
  <p><b>Warning, Multiple drivers on <i>signal</i>; also line
  <i>line</i></b></p>

  <p>This is <b>bad</b> *the probable cause is that more than one
   process is writing to <i>signal</i>.</p>

   <p>Here's a sample situation with multiple drivers, and an
    explanation of how to fix the problem:</p>

  <pre>
do_red:
  process (state) begin
    if ( state = RED ) then
      next_state <= ....
    end if;
  end process;

do_green:
  process (state) begin
    if ( state = GREEN ) then
      next_state <= ....
    end if;
  end process;
</pre>

    <p> The goal here was to organize the design so that each process
    handles one situation, analogous to procedures in software.
    However, both "do_red" and "do_green" assign values to next_state.
    For hardware, decompose your design into processes based upon the
    signals that are assigned to, not based on different situations.
    </p>

    <p> For example, with a traffic light system, have one process for
    the north-south light and one for the east-west light, rather than
    having one process for when north-south is green and another
    process for when east-west is green.  </p>

    <p> The correct way to think about the organization of your code
    is for each process to be responsible for a signal, or a set of
    closely related signals.  This would then give: </p>

<pre>
  process (state) begin
    if ( state = GREEN ) then
      next_state <= ...
    elseif ( state = GREEN ) then
      next_state <= ...
    else ... [ other cases ] ...
    end if;
  end process;
 </pre>

 
  </li>
</ul>
  
  <!-- ****************************************** -->

<!- **************************************************** -->
<h1>Error messages</h1>
<!- **************************************************** -->

  <ul>
  
    <!-- ****************************************** -->
    
    <li><p><b><code>Component <i>comp</i> has no visible entity
    binding.</code></b></p>

    <p>In your VHDL file, you have a component named <i>comp</i>, but
     you have not compiled an entity to put in for the component.
    </p>

    </li>

  </ul>
  
    <!-- ****************************************** -->
    
  

<!- ************************************************************** -->
<!- ************************************************************** -->
    
</div>

  <? include("lib/epilogue.html") ?>
</body>
</html>
