//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//scoreboardul preia datele de la monitor si verifica acuratetea acestora; pentru a se face aceasta verificare, in scoreboard este implementata functionalitatea DUT-ului; intrarile pe care le primeste DUT-ul sunt preluate de catre monitor si transmise scoreboardului; comparandu-se iesirile monitorului si ale scoreboardului se poate determina daca acestea functioneaza corect

//the scoreboard gets the packet from monitor, generates the expected result and compares with the //actual result recived from Monitor

class scoreboard;
   
  //se declara portul prin care scoreboardul primeste date de la monitor; daca sunt mai multe monitoare, se pot declara mai multe porturi de acest tip
  //creating mailbox handle
  mailbox mon2scb;
  
  //used to count the number of transactions
  int no_transactions;
  
  //array to use as local memory
  bit [7:0] mem[4];
   
  //se declara si se creaza colectorul de coverage
  coverage colector_coverage;

  //constructor
  function new(mailbox mon2scb);
    //getting the mailbox handles from  environment 
    this.mon2scb = mon2scb;
    foreach(mem[i]) mem[i] = 8'hFF;
    colector_coverage = new();
  endfunction
  
  //stores wdata and compare rdata with stored data
  task main;
    transaction trans;
    forever begin
      #50;
      //se preiau datele de la monitor
      mon2scb.get(trans);
      //mai jos se gaseste implementarea unui checker
      if(trans.rd_en) begin
        if(mem[trans.addr] != trans.rdata) 
          $error("[SCB-FAIL] Addr = %0h,\n \t   Data :: Expected = %0h Actual = %0h",trans.addr,mem[trans.addr],trans.rdata);
        else 
          begin
          $display("[SCB-PASS] Addr = %0h,\n \t   Data :: Expected = %0h Actual = %0h",trans.addr,mem[trans.addr],trans.rdata);
          //daca tranzactia s-a executat cu succes, se colecteaza coverage-ul
            colector_coverage.sample(trans);
          end
      end
      //cele doua lini de mai jos reprezinta functionalitatea DUT-ului, care este implementata si in cadrul scoreboard-ului
      else if(trans.wr_en)
        begin
          mem[trans.addr] = trans.wdata;
          //colectez coverage-ul si pentru tranzactiile de tip scriere la memorie
          colector_coverage.sample(trans);
        end

      no_transactions++;
    end
  endtask
  
endclass