//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//driverul preia datele de la generator, la nivel abstract, si le trimite DUT-ului conform protocolului de comunicatie pe interfata respectiva
//gets the packet from generator and drive the transaction paket items into interface (interface is connected to DUT, so the items driven into interface signal will get driven in to DUT) 


//ceva de clocking block
//se declara macro-ul DRIV_IF care va reprezenta interfata pe care driverul va trimite date DUT-ului
`define DRIV_IF virtual_intf_valid_ready.driver_cb
class driver_valid_ready;
  
  //used to count the number of transactions
  int no_transactions;
  
  //creating virtual interface handle
  virtual intf_valid_ready virtual_intf_valid_ready;
  
  //se creaza portul prin care driverul primeste datele la nivel abstract de la DUT
  //creating mailbox handle
  mailbox gen2driv;
  
  //constructor
  function new(virtual intf_valid_ready virtual_intf_valid_ready,mailbox gen2driv);
    //cand se creaza driverul, interfata pe care acesta trimite datele este conectata la interfata reala a DUT-ului
    //getting the interface
    this.virtual_intf_valid_ready = virtual_intf_valid_ready;
    //getting the mailbox handles from  environment 
    this.gen2driv = gen2driv;
  endfunction
  
  //Reset task, Reset the Interface signals to default/initial values
  task reset;
    wait(!virtual_intf_valid_ready.reset);
    $display("--------- [DRIVER] Reset Started ---------");
    `DRIV_IF.valid <= 0;
    `DRIV_IF.data_i <= 0;
    wait( virtual_intf_valid_ready.reset);
    $display("--------- [DRIVER] Reset Ended ---------");
  endtask
  
  //drives the transaction items to interface signals
  task drive;
      transaction trans;
      
    //se asteapta ca modulul sa iasa din reset
     wait(virtual_intf_valid_ready.reset);//linie valabila daca resetul este activ in 0
    //wait(!virtual_intf_valid_ready.reset);//linie valabila daca resetul este activ in 1
    
    //daca nu are date de la generator, driverul ramane cu executia la linia de mai jos, pana cand primeste respectivele date
      gen2driv.get(trans);
      repeat(trans.delay) @(posedge virtual_intf_valid_ready.DRIVER.clk);
      $display("--------- [DRIVER-TRANSFER: %0d] ---------",no_transactions);
      @(posedge virtual_intf_valid_ready.DRIVER.clk);

        `DRIV_IF.valid <= trans.valid;
        `DRIV_IF.data_i<=trans.data_i;
  
        $display("\tvalid = %0h, \tdata_i = %0h ",trans.valid, trans.data_i);
        do begin
      @(posedge virtual_intf_valid_ready.DRIVER.clk);
        end while (`DRIV_IF.ready !==1'b1);
        `DRIV_IF.valid <=1'b0;
  
  
      $display("--------- [TRANSFER FINALIZAT CU SUCCES] ---------");
      $display("-----------------------------------------");
      no_transactions++;
  endtask
  
    
  //Cele doua fire de executie de mai jos ruleaza in paralel. Dupa ce primul dintre ele se termina al doilea este intrerupt automat. Daca se activeaza reset-ul, nu se mai transmit date. 
  task main;
    forever begin
      fork
        //Thread-1: Waiting for reset
        begin
          wait(!virtual_intf_valid_ready.reset);//linie valabila daca resetul este activ in 0
          //wait(virtual_intf_valid_ready.reset);//linie valabila daca resetul este activ in 1
        end
        //Thread-2: Calling drive task
        begin
          //transmiterea datelor se face permanent, dar este conditionta de primirea datelor de la monitor.
          forever
            drive();
        end
      join_any
      disable fork;
      reset();
    end
  endtask
        
endclass