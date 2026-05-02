`ifndef WAIT_TRANS_SV
`define WAIT_TRANS_SV

program wait_trans(intf_uart uart, intf_valid_ready intf_valid_ready);
  

class my_trans extends transaction;
    parameter DATA_WIDTH = 8;
    
    int cnt = 0;
    rand bit valid;
    rand bit ready;

    function void pre_randomize(); 
      valid.rand_mode(0); 
      ready.rand_mode(0);
      

    cnt++;
    endfunction


    function void post_randomize();

    //   $display("[TRANS] valid = %0b  | ready = %0b | cnt = %0d", 
    //             valid, ready, cnt-1);
    endfunction
    


  endclass
  environment env;
  my_trans my_tr; 
  
  initial begin
    env = new(uart, intf_valid_ready);
    my_tr = new();
    repeat(5) begin
    my_tr.randomize();

  end
    env.gen.repeat_count = 0;
    env.gen.trans = my_tr;
    
    env.run();
$display("\n[DEBUG] Afisare continut FIFO din testbench.dut:");
    

    $display("FIFO: %p", testbench.dut.fifo);
    $display("Current_state: %d", testbench.dut.current_state);
    

  end
endprogram

`endif