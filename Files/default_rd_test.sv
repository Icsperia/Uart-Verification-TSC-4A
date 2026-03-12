//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------

//testele contin unul sau mai multe scenarii de verificarel testele instantiaza mediul de verificare (a se vedea linia 28); testele sunt pornite din testbench

`include "environment.sv"


constraint transaction::wdata_c {soft wdata %4 == 0;}

program test(mem_intf intf);
  
  class my_trans extends transaction;
    
    bit [1:0] count;
    
    //in cadrul acestui test, se doreste ca sa nu primeasca valori aleatorii campurile wr_en, rd_en, si addr (astfel, putem zice ca avem de-a face cu un text directionat spre a testa DUT-ul doar in modul de citire)
    function void pre_randomize();
      wr_en.rand_mode(0);
      rd_en.rand_mode(0);
      addr.rand_mode(0);
        wr_en = 0;
        rd_en = 1;
        addr  = cnt;
      cnt++;
    endfunction
    
  endclass
    
  //declaring environment instance
  environment env;
  my_trans my_tr;
  
  initial begin
    //creating environment
    env = new(intf);
    
    my_tr = new();
    
    //setting the repeat count of generator as 4, means to generate 4 packets
    env.gen.repeat_count = 4;
    
    env.gen.trans = my_tr;
    
    //calling run of env, it interns calls generator and driver main tasks.
    env.run();
  end
endprogram