///-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
interface intf_valid_ready #(
parameter DATA_WIDTH=8
)( input logic clk,
    input logic reset
    );
 logic [DATA_WIDTH-1:0] data_i;
 logic  valid; 
 logic ready;
  //semnalele din clocking block sunt sincrone cu frontul crescator de ceas
  //driver clocking block
  clocking driver_cb @(posedge clk);
    //semnalele de intrare sunt citite o unitate de timp inainte frontului de ceas, iar semnalele de iesire sunt citite o unitate de timp dupa frontul de ceas; astfel se elimina situatiile in care se fac scrieri sau citiri in acelasi timp
    default input #1 output #1;
    output  data_i;
	output valid;
	input ready;
  endclocking
  
  //monitor clocking block
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
	input  data_i;
	input valid; 
	input ready;
	  
  endclocking
  
  //driver modport
  modport DRIVER  (clocking driver_cb,input clk,reset);
  
  //monitor modport  
  modport MONITOR (clocking monitor_cb,input clk,reset);
    /*
        //asertii pe interfata
	//nu avem voie sa avem si read si write in acelai timp
   property rd_wr;
     @(posedge clk) disable iff (reset==0)//daca avem reset, nu se executa asertia
     !(wr_en && rd_en);
  endproperty
  
  asertia_rd_wr: assert property (rd_wr) 
    else $error("INTERFATA_INTRARE: a picat asertia asertia_rd_wr");
    RD_WR_C: cover property (rd_wr);//ne asiguram ca proprietatea a fost accesata macar o data
      
      
      
      	//daca wr_en a fost 1, in urmatorul tact de ceas va fi 0
   property wr_en_pulse;
     @(posedge clk) disable iff (reset==0)//daca avem reset, nu se executa asertia
     wr_en |=> !wr_en;
  endproperty
  
  asertia_wr_en_pulse: assert property (wr_en_pulse) 
    else $error("INTERFATA_INTRARE: a picat asertia asertia_rd_wr");
    WR_EN_pulse: cover property (wr_en_pulse);//ne asiguram ca proprietatea a fost accesata macar o data
     */ 
  
endinterface