//-------------------------------------------------------------------------
//            www.verificationguide.com
//-------------------------------------------------------------------------

class generator;
  // Obiectele de tip tranzactie care vor fi populate cu date aleatorii.
  // 'trans' este obiectul principal, iar 'tr' este copia trimisa spre driver.
  rand transaction trans, tr;
  
  // Variabila care determina cate pachete de date vor fi create in timpul testului.
  int repeat_count;
  
  // Mailbox-ul este canalul de comunicare  intre Generator si Driver.
  // Se foloseste pentru a trimite tranzactiile generate catre Driver.
  mailbox gen2driv;
  
  // Eveniment utilizat pentru a anunta restul mediului de verificare 
  // ca generatorul a terminat de creat toate tranzactiile solicitate.
  event gen_ended;
  
  // Constructorul clasei: initializeaza conexiunile si obiectul de tranzactie.
  function new(mailbox gen2driv, event gen_ended);
    // Primeste handle-ul  catre mailbox si eveniment din clasa Environment.
    this.gen2driv = gen2driv;
    this.gen_ended = gen_ended;
    // Creeaza instanta obiectului de tranzactie care va fi randomizat.
    trans = new();
  endfunction
  
  // Task-ul principal care executa logica de generare.
  task main();
    // Repeta procesul de 'repeat_count' ori.
    repeat(repeat_count) begin
      
      // Aleatorizeaza variabilele marcate cu 'rand' din clasa transaction.
      // Daca randomizarea esueaza, simularea se opreste cu o eroare fatala.
      if( !trans.randomize() ) 
          $fatal("Gen:: trans randomization failed");      
      
      // Se face o copie a obiectului randomizat pentru a evita modificarea datelor
      // de catre generator in timp ce driverul inca le proceseaza.
      tr = trans.do_copy();
      
      // Pune copia tranzactiei in mailbox pentru a fi preluata de Driver.
      // Operatia 'put' este blocanta daca mailbox-ul este plin.
      gen2driv.put(tr);
    end
    
    // Dupa ce s-au generat toate tranzactiile, se declanseaza evenimentul
    // pentru a semnaliza sfarsitul activitatii generatorului.
    ->gen_ended; 
  endtask
  
endclass