//-------------------------------------------------------------------------
//            www.verificationguide.com
//-------------------------------------------------------------------------
// Monitorul urmareste traficul de pe interfetele DUT-ului, preia datele brute si 
// recompune tranzactiile pentru a fi trimise catre scoreboard pentru verificare.
`include "coverage_uart.sv"

// Definirea unui macro pentru accesul rapid la semnalele esantionate prin clocking block-ul monitorului
`define MON_IF uart_vif.MONITOR.monitor_cb 

class mon_uart;
  // Interfata virtuala folosita pentru a accesa semnalele fizice UART (tx, clk)
  virtual intf_uart uart_vif; 
  
  // Parametru care defineste numarul de biti de date esantionati (ex: 8 biti date + 1 paritate)
  parameter DATA_LENGTH = 9;
  
  // Variabila pentru stocarea temporara a bitilor colectati de pe linia seriala
  bit [DATA_LENGTH-1:0] uart_data;
  
  // Contor folosit in bucla de colectare a bitilor
  int                   i;           
  
  // Indicator pentru prezenta bitului de paritate in fluxul de date
  bit                   has_parity;
  
  // Obiectul de coverage pentru inregistrarea statisticilor de testare ale interfetei UART
  coverage_uart cov;
  
  // Mailbox-ul prin care monitorul trimite tranzactiile recompuse catre scoreboard
  mailbox mon2scb;
  
  // Constructor: asociaza interfata virtuala, mailbox-ul si obiectul de coverage primite din environment
  function new(virtual intf_uart uart_vif, mailbox mon2scb, bit has_parity = 0, coverage_uart cov);
    this.uart_vif    = uart_vif;
    this.mon2scb     = mon2scb;
    this.has_parity  = has_parity;
    this.cov         = cov;
  endfunction
  
  // Task-ul principal care ruleaza continuu pentru a "asculta" linia TX a UART-ului
  task main;
    forever begin 
        // Instantierea unui nou obiect de tip tranzactie pentru fiecare cadru detectat
        transaction trans; 
        trans = new();

        // 1. Detectarea starii de IDLE si masurarea pauzei (delay) intre cadre
        // Atat timp cat linia TX este in '1' (stare idle), monitorul asteapta si numara ciclii de ceas
        while(uart_vif.MONITOR.monitor_cb.tx) begin
          @(posedge uart_vif.MONITOR.clk);
          trans.delay++; // Incrementeaza timpul de asteptare pana la urmatoarea transmisie
        end
        
        // Inregistreaza tranzactia pentru a monitoriza activitatea liniei TX in coverage
        cov.sample_tx_function(trans);

        // 2. Sincronizarea dupa detectarea START BIT-ului
        // Protocolul UART incepe cand TX trece in '0'. Asteptam un ciclu de ceas pentru a trece de bitul de start.
        @(posedge uart_vif.MONITOR.clk);

        // 3. Colectarea bitilor de DATE
        // Se parcurge lungimea definita (DATA_LENGTH) si se esantioneaza valoarea TX la fiecare front de ceas
        for (i = DATA_LENGTH-1; i >= 0; i--) begin
          @(posedge uart_vif.MONITOR.clk);
          uart_data[i] = `MON_IF.tx; // Recompunerea vectorului de date din fluxul serial
        end
    
        // 4. Gestionarea bitului de PARITATE (optional)
        if(has_parity == 1) begin
             @(posedge uart_vif.MONITOR.clk);
             // Aici bitul de paritate a fost parcurs
        end
    
        // 5. Finalizarea cadrului prin STOP BIT
        // UART termina transmisia cu bitul de stop (revenirea in '1'). Asteptam finalizarea acestuia.
        @(posedge uart_vif.MONITOR.clk);
  
        // 6. Finalizarea tranzactiei si raportarea rezultatelor
        trans.data_i = uart_data;       // Salveaza datele recompuse in obiectul tranzactie
        cov.sample_function(trans);     // Colecteaza coverage pe datele efective primite
        
        trans.tx = `MON_IF.tx;          // Actualizeaza starea curenta a TX in tranzactie
        cov.sample_tx_function(trans);  // Inregistreaza starea finala a liniei pentru coverage
        
        // Trimite tranzactia completa catre scoreboard prin mailbox pentru validarea finala
        mon2scb.put(trans);
    end
  endtask
  
endclass