`ifndef ENVIRONMENT_SV 
`define ENVIRONMENT_SV

class environment;
  
  // --- Componentele de verificare (clasele care executa testarea) ---
  
  generator           gen;              // Creeaza tranzactiile (datele de test)
  driver_valid_ready  driv_valid_ready; // Trimite datele create de generator catre interfata DUT-ului
  mon_valid_ready     mon_valid_ready;  // Monitorizeaza interfata de intrare (Valid/Ready) si colecteaza datele
  mon_uart            mon_uart;         // Monitorizeaza interfata de iesire UART (firul TX)
  coverage_uart       cov_uart;         // Calculeaza cat de mult din protocolul UART a fost testat
  coverage_valid_ready cov_valid_ready; // Calculeaza acoperirea pentru handshake-ul Valid/Ready
  
  // --- Canale de comunicare (Mailbox-uri) ---
  
  mailbox gen2driv; // "Cutia postala" prin care Generatorul trimite tranzactii catre Driver
  mailbox mon2scb;  // Trimite datele capturate de monitoare catre Scoreboard (pentru verificare)
  mailbox mon2cov;  // (Optional) Trimite date catre unitatile de coverage
  
  // --- Sincronizare ---
  event gen_ended;  // Semnal care anunta restul mediului ca Generatorul a terminat de creat toate datele
  
  // --- Interfete Virtuale (Legatura cu hardware-ul) ---
  virtual intf_uart vintf_uart;              // Conexiunea virtuala la semnalele UART
  virtual intf_valid_ready vintf_valid_ready; // Conexiunea virtuala la semnalele de intrare Valid/Ready
  
  // --- Constructor (Initializarea mediului) ---
  function new(virtual intf_uart vintf_uart, virtual intf_valid_ready vintf_valid_ready);
    // Primeste interfetele fizice de la testbench si le mapeaza la cele virtuale
    this.vintf_uart = vintf_uart;
    this.vintf_valid_ready = vintf_valid_ready;
    
    // Aloca memorie pentru mailbox-uri (canalele de comunicare)
    gen2driv = new();
    mon2scb  = new();

    // Initializeaza obiectele de coverage
    cov_uart = new();
    cov_valid_ready = new();
    
    // Instantiaza componentele si le conecteaza intre ele (injectare de dependinte)
    gen              = new(gen2driv, gen_ended);
    driv_valid_ready = new(vintf_valid_ready, gen2driv);
    mon_valid_ready  = new(vintf_valid_ready, mon2scb, 0, cov_valid_ready);
    mon_uart         = new(vintf_uart, mon2scb, 0, cov_uart);
  endfunction
  
  // --- Task: Pregatirea testului ---
  task pre_test();            
    driv_valid_ready.reset(); // Apeleaza secventa de reset pentru a pune DUT-ul intr-o stare cunoscuta
  endtask
  
  // --- Task: Executia principala ---
  task test();
    fork 
      gen.main();              // Porneste generarea datelor
      driv_valid_ready.main(); // Porneste trimiterea datelor catre DUT
      mon_valid_ready.main();  // Porneste monitorizarea intrarii
      mon_uart.main();         // Porneste monitorizarea iesirii UART
    join_any // Continua cand prima componenta (de obicei generatorul) termina
  endtask
  
  // --- Task: Curatenia si asteptarea finalizarii ---
  task post_test();
    wait(gen_ended.triggered); // Asteapta pana cand generatorul spune "gata"
    
    // Se asigura ca numarul de date generate este egal cu numarul de date trimise fizic
    wait(gen.repeat_count == driv_valid_ready.no_transactions);
  endtask  
  
  // --- Functie: Raportarea rezultatelor ---
  function report();
    // Afiseaza in consola statisticile de coverage (cat de bine am testat design-ul)
    mon_valid_ready.cov.print_coverage();
    mon_uart.cov.print_coverage();
  endfunction
  
  // --- Task-ul principal: Executa tot fluxul de verificare ---
  task run;
    pre_test();  // 1. Reset
    test();      // 2. Simulare efectiva
    post_test(); // 3. Asteptare final
    report();    // 4. Afisare rezultate
    $finish;     // 5. Inchide simulatorul
  endtask
  
endclass

`endif