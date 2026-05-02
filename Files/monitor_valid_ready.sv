//-------------------------------------------------------------------------
//            www.verificationguide.com
//-------------------------------------------------------------------------
// Monitorul urmareste traficul de pe interfetele DUT-ului, preia datele verificate 
// si recompune tranzactiile; datele sunt apoi trimise catre scoreboard pentru validare.

`include "coverage_valid_ready.sv"

// Macro pentru accesarea rapida a semnalelor prin Clocking Block-ul de monitorizare
`define MON_IF valid_ready_vif.MONITOR.monitor_cb

class mon_valid_ready;
  
  // Interfata virtuala pentru accesarea semnalelor fizice de Valid/Ready
  virtual intf_valid_ready valid_ready_vif;
  
  // Mailbox pentru trimiterea tranzactiilor colectate catre Scoreboard
  mailbox mon2scb;
  
  // Contor intern pentru masurarea decalajului (delay) in cicluri de ceas
  int cnt_dly;
  
  // Obiectul de coverage pentru monitorizarea handshake-ului si a datelor
  coverage_valid_ready cov;

  // Constructor: conecteaza interfata virtuala, mailbox-ul si obiectul de coverage
  function new(virtual intf_valid_ready valid_ready_vif, mailbox mon2scb, int cnt_dly=0, coverage_valid_ready cov);
    this.valid_ready_vif = valid_ready_vif;
    this.mon2scb = mon2scb;
    this.cnt_dly = cnt_dly;
    this.cov = cov;
  endfunction
  
  // Task-ul principal: extrage datele de pe interfata si le trimite catre scoreboard
  task main;
    forever begin // Bucla infinita pentru monitorizarea continua a interfetei
      // Crearea unui nou obiect tranzactie pentru fiecare transfer detectat
      transaction trans;
      trans = new();
      
      // Resetarea contorului de delay la inceputul fiecarei cautari de transfer
      cnt_dly = 0;

      // Sincronizare pe frontul crescator al ceasului de monitorizare
      @(posedge valid_ready_vif.MONITOR.clk);

      // Asteapta conditia de transfer: atat VALID cat si READY trebuie sa fie '1' simultan
      wait(`MON_IF.valid && `MON_IF.ready);
      
      // Capturarea valorilor semnalelor in obiectul tranzactie
      trans.valid  = `MON_IF.valid;
      trans.ready  = `MON_IF.ready;
      trans.data_i = `MON_IF.data_i;
      
      // Salvarea numarului de cicluri de ceas scurse pana la transfer
      trans.delay  = cnt_dly;

      // Trimiterea tranzactiei catre scoreboard prin mailbox
      mon2scb.put(trans);
      
      // Colectarea statisticilor de coverage pentru tranzactia curenta
      cov.sample_function(trans);
    end
  endtask

  // Task pentru numararea cicliilor de ceas; ajuta la masurarea timpului intre evenimente
  task delay_cnt();
    forever begin
      @(posedge valid_ready_vif.MONITOR.clk);
      cnt_dly++; // Incrementeaza contorul la fiecare front de ceas
    end
  endtask 
  
endclass