//-------------------------------------------------------------------------
//				www.verificationguide.com   testbench.sv
//-------------------------------------------------------------------------
//tbench_top or testbench top, this is the top most file, in which DUT(Design Under Test) and Verification environment are connected. 
//-------------------------------------------------------------------------

//including interfcae and testcase files
`include "interface.sv"
`include "intf_valid_ready"
`include "intf_uart"

//-------------------------[NOTE]---------------------------------
//Particular testcase can be run by uncommenting, and commenting the rest
//`include "random_test.sv"
//`include "wr_rd_test.sv"
`include "default_rd_test.sv"
//----------------------------------------------------------------


module testbench;
  
  //clock and reset signal declaration
  bit clk;
  bit reset;
  
  //clock generation
  always #5 clk = ~clk;
  
  //reset Generation
  initial begin
    reset = 1;
    #15 reset =0;
  end
  
  
  //creatinng instance of interface, inorder to connect DUT and testcase
  intf_uart intf_uart(clk,reset);
  intf_valid_ready intf_valid_ready(clk,reset);
  //Testcase instance, interface handle is passed to test as an argument
  test t1(intf_uart);
  test t2(intf_valid_ready);
  
  //DUT instance, interface signals are connected to the DUT ports

uart #(


)dut  #(
.DATA_WIDTH(),
.FIFO_DEPTH(),
.BOUD_RATE(),    // asta inseamna ca BOUD_RATE este 2^(20+3) 
.HAS_PARITY(),
.NO_BITS_STOP()  // 0 = 1 bit de stop, 1 = 1,5 biti de stop si 2 = 2 biti de stop
) dut(
.clk    (intf_valid_ready.clk),
  .rst_n  (intf_valid_ready.rst_n),

  .valid  (intf_valid_ready.valid),
  .ready  (intf_valid_ready.ready),
  .data_i (intf_valid_ready.data_i),

  .tx     ( intf_uart.tx)
               
);
  //enabling the wave dump
  initial begin 
    $dumpfile("dump.vcd"); $dumpvars;
  end
endmodule