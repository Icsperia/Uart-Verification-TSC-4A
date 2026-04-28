//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------

//in mediul de verificare se instantiaza toate componentele de verificare
//`include "transaction.sv"
//`include "generator.sv"
//`include "driver_valid_ready.sv"
//`include "monitor_uart.sv"
//`include "monitor_valid_ready.sv"
// `include "coverage.sv"
// `include "scoreboard.sv"
`ifndef ENVIRONMENT_SV 
`define ENVIRONMENT_SV
class environment;
  
  //componentele de verificare sunt declarate
  //generator and driver instance
  generator  gen;
  driver_valid_ready    driv_valid_ready;
  mon_valid_ready    mon_valid_ready;
  mon_uart   mon_uart;
  coverage cov;
  
  //mailbox handle's
  mailbox gen2driv;
  mailbox mon2scb;
  mailbox mon2cov;
  //event for synchronization between generator and test
  event gen_ended;
  
  //virtual interface
  virtual intf_uart vintf_uart;
  virtual intf_valid_ready vintf_valid_ready;
  
  //constructor
  function new(virtual intf_uart vintf_uart, virtual intf_valid_ready vintf_valid_ready);
    //get the interface from test
    this.vintf_uart = vintf_uart;
    this.vintf_valid_ready = vintf_valid_ready;
    //creating the mailbox (Same handle will be shared across generator and driver)
    gen2driv = new();
    mon2scb  = new();

    cov = new( );
    //componentele de verificare sunt create
    //creating generator and driver
    gen  = new(gen2driv,gen_ended);
    driv_valid_ready = new(vintf_valid_ready,gen2driv);
    mon_valid_ready  = new(vintf_valid_ready,mon2scb);
    mon_uart = new(vintf_uart,mon2scb);
    // scb  = new(mon2scb);
  endfunction
  
  //
  task pre_test();            
   driv_valid_ready.reset();
  endtask
  
  task test();
    fork 
    gen.main();
    driv_valid_ready.main();
    mon_valid_ready.main();
    mon_uart.main();    
 
    join_any
  endtask
  
  task post_test();
    wait(gen_ended.triggered);
    //se urmareste ca toate datele generate sa fie transmise la DUT si sa ajunga si la scoreboard
    wait(gen.repeat_count ==driv_valid_ready.no_transactions);
    // wait(gen.repeat_count == scb.no_transactions);
  endtask  
  
  // function report();
  //   scb.colector_coverage.print_coverage();
  // endfunction
  
  //run task
  task run;
    pre_test();
    test();
    post_test();
    //report();
    //linia de mai jos este necesara pentru ca simularea sa sa termine
    $finish;
  endtask
  
endclass

`endif