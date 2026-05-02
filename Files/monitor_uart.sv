//-------------------------------------------------------------------------
//            www.verificationguide.com
//-------------------------------------------------------------------------
// Monitorul urmareste traficul de pe interfetele DUT-ului, preia datele brute si 
// recompune tranzactiile pentru a fi trimise catre scoreboard pentru verificare.
`include "coverage_uart.sv"

// Definim un macro pentru a accesa semnalul TX prin Clocking Block-ul monitorului.
// Esantionarea prin Clocking Block asigura stabilitatea datelor fata de ceas.
`define MON_IF uart_vif.MONITOR.monitor_cb 

class mon_uart;
  // Interfata virtuala pentru accesarea semnalelor fizice (tx, clk).
  virtual intf_uart uart_vif; 
  
  // Parametru: lungimea cadrului (ex: 8 biti date + 1 paritate).
  parameter DATA_LENGTH = 9;
  
  // Variabila temporara pentru bitii colectati serial.
  bit [DATA_LENGTH-1:0] uart_data;
  
  int i;           
  bit has_parity;
  
  // Instanta pentru colectarea statisticilor de acoperire (coverage).
  coverage_uart cov;
  
  // Mailbox pentru comunicarea cu Scoreboard-ul.
  mailbox mon2scb;
  
  // Constructor: conecteaza componentele din mediu (environment).
  function new(virtual intf_uart uart_vif, mailbox mon2scb, bit has_parity = 0, coverage_uart cov);
    this.uart_vif    = uart_vif;
    this.mon2scb     = mon2scb;
    this.has_parity  = has_parity;
    this.cov         = cov;
  endfunction
  



  task main;
    forever begin 
        // Instantierea unui nou obiect de tip tranzactie pentru fiecare cadru detectat
        transaction trans; 
        trans = new();

        // 1. Detectarea starii de IDLE si masurarea pauzei (delay) intre cadre
        // Esantionare IDLE: Monitorul verifica TX la fiecare front de ceas pana cand linia scade in '0'
        while(uart_vif.MONITOR.monitor_cb.tx) begin
          @(posedge uart_vif.MONITOR.clk); // <--- PUNCT DE ESANTIONARE (IDLE)
          trans.delay++; 
        end
        
        // Inregistreaza tranzactia in coverage pentru activitatea liniei TX
        cov.sample_tx_function(trans);

        // 2. Sincronizarea dupa START BIT
        // UART incepe cand TX trece in '0'. Asteptam un ceas pentru a trece de bitul de start.
        @(posedge uart_vif.MONITOR.clk); // <--- PUNCT DE ESANTIONARE (START BIT)

        // 3. Colectarea bitilor de DATE (Esantionarea bit cu bit)
        // Se parcurge lungimea definita si se citeste valoarea TX pentru reconstructia octetului
        for (i = DATA_LENGTH-1; i >= 0; i--) begin
          @(posedge uart_vif.MONITOR.clk); // <--- PUNCT DE ESANTIONARE (DATA BITS)
          uart_data[i] = `MON_IF.tx; 
        end
    
        // 4. Gestionarea bitului de PARITATE (Daca este activat)
        if(has_parity == 1) begin
             @(posedge uart_vif.MONITOR.clk); // <--- PUNCT DE ESANTIONARE (PARITY)
        end
    
        // 5. Finalizarea cadrului prin STOP BIT
        // Asteptam revenirea liniei in '1' pentru a marca finalul transmisiei
        @(posedge uart_vif.MONITOR.clk); // <--- PUNCT DE ESANTIONARE (STOP BIT)
  
        // 6. Finalizarea tranzactiei si raportarea rezultatelor
        trans.data_i = uart_data;
        cov.sample_function(trans);
        
        trans.tx = `MON_IF.tx;          
        cov.sample_tx_function(trans);  
        
        // Trimite tranzactia completa catre scoreboard prin mailbox
        mon2scb.put(trans);
    end 
  endtask
  
endclass