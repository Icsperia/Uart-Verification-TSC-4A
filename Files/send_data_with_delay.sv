`ifndef SEND_DATA_WITH_DELAY_SV
`define SEND_DATA_WITH_DELAY_SV

//cu delay mare
program send_data_with_delay(intf_uart uart, intf_valid_ready intf_valid_ready);

  class my_trans extends transaction;
    parameter DATA_WIDTH = 8;
    
//de verificat bitul de paritate
    rand bit [1:0] stop_type;
    

    bit start = 1'b0;
    bit paritate;
    bit [1:0] stop_bits_val;
    bit [11:0] uart_frame;   
    int cnt = 0;
// constraint c_delay_mediu{
//     delay inside {[25 : 75]}; 
//   }



constraint c_delay_mare{
    delay inside {[100 : 1000]}; 
  }



//     constraint c_stop {
//       stop_type inside {1, 2, 3};
//       stop_type dist {1 := 25, 2 := 25, 3:=50};
//     }

//     function void post_randomize();
//       paritate = ^data_i; 
      
   
//    if (stop_type == 1) begin
//       stop_bits_val = 2'b01; 
//     end else if (stop_type == 2) begin
//       stop_bits_val = 2'b11;
//     end else if (stop_type == 3) begin
//       stop_bits_val = 2'b10; 
//     end
        
  
    //  uart_frame = {stop_bits_val, paritate, data_i, start};

    // $display("[TRANS] valid = %0b  | ready = %0b | cnt = %0d", 
    //              valid, ready, cnt-1);
  //  endfunction
  endclass

  environment env;
  my_trans my_tr; 
  
  initial begin
    env = new(uart, intf_valid_ready);
    my_tr = new();
    

    env.gen.repeat_count = 1000; 
    env.gen.trans = my_tr;
        env.run();
    $display("\n--- Generare Cadre UART (Debug Mode) ---");
    
repeat(100) @(posedge uart.clk);
    repeat(1000) begin
     @(posedge uart.clk);
      if (!my_tr.randomize()) $error("Randomization failed!");
      $display(" Data: %h | Stop Type: %0d bits |Current_state: %d |Next_state: %d", 
                 my_tr.data_i, my_tr.stop_type,testbench.dut.current_state, testbench.dut.next_state );
      //  $display("Delay value", my_tr.delay);
    end


  end
endprogram

`endif

//test de baudrate

//pentru delay mic si valori multe generate, coverage 100
//pentru delay mare si valiri mari coverage de 33 - 66