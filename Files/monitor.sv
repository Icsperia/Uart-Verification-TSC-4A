//-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
//monitorul urmareste traficul de pe interfetele DUT-ului, preia datele verificate si recompune tranzactiile (folosind obiecte ale clasei transaction); in implementarea de fata, datele preluate de pe interfete sunt trimise scoreboardului pentru verificare
//Samples the interface signals, captures into transaction packet and send the packet to scoreboard.

//in macro-ul MON_IF se retine blocul de semnale de unde monitorul extrage datele
`define MON_IF mem_vif.MONITOR.monitor_cb
class monitor;
  
  //creating virtual interface handle
  virtual mem_intf mem_vif;
  
  //se creaza portul prin care monitorul trimite scoreboardului datele colectate de pe interfata DUT-ului sub forma de tranzactii 
  //creating mailbox handle
  mailbox mon2scb;
  
  //cand se creaza obiectul de tip monitor (in fisierul environment.sv), interfata de pe care acesta colecteaza date este conectata la interfata reala a DUT-ului
  //constructor
  function new(virtual mem_intf mem_vif,mailbox mon2scb);
    //getting the interface
    this.mem_vif = mem_vif;
    //getting the mailbox handles from  environment 
    this.mon2scb = mon2scb;
  endfunction
  
  //Samples the interface signal and send the sample packet to scoreboard
  task main;
    forever begin
      //se declara si se creaza obiectul de tip tranzactie care va contine datele preluate de pe interfata
      transaction trans;
      trans = new();

      //datele sunt citite pe frontul de ceas, informatiile preluate de pe semnale fiind retinute in oboiectul de tip tranzactie
      @(posedge mem_vif.MONITOR.clk);
      wait(`MON_IF.rd_en || `MON_IF.wr_en);//ready == 1
        trans.addr  = `MON_IF.addr;//legare datedin interfata
        trans.wr_en = `MON_IF.wr_en;
        trans.wdata = `MON_IF.wdata;
        if(`MON_IF.rd_en) begin
          trans.rd_en = `MON_IF.rd_en;
          @(posedge mem_vif.MONITOR.clk);
          @(posedge mem_vif.MONITOR.clk);
          trans.rdata = `MON_IF.rdata;
        end    
      // dupa ce s-au retinut informatiile referitoare la o tranzactie, continutul obiectului trans se trimite catre scoreboard
        mon2scb.put(trans);
    end
  endtask
  
endclass