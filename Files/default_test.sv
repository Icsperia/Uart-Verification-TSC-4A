//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------

//testele contin unul sau mai multe scenarii de verificarel testele instantiaza mediul de verificare (a se vedea linia 28); testele sunt pornite din testbench
`ifndef DEFAULT_TEST_SV
`define DEFAULT_TEST_SV

`include "enviroment.sv"

program test(intf_uart intf_uart, intf_valid_ready intf_valid_ready);

  class my_trans extends transaction;
    function void post_randomize();
      valid = 1;
    endfunction
  endclass

  environment env;
  my_trans tr;

  initial begin
    env = new(intf_uart, intf_valid_ready);
    tr = new();
    
    env.gen.repeat_count = 10;
    env.gen.trans = tr;
    
    env.run();
  end
endprogram

`endif