*///-------------------------------------------------------------------------
//						www.verificationguide.com
//-------------------------------------------------------------------------
interface interfata_valid_ready #(parameter DATA_WIDTH=8)
  ( input logic clk,
    input logic reset);
 logic [DATA_WIDTH-1:0] data_i;
 logic  valid_i; 
 logic ready_o;
  //semnalele din clocking block sunt sincrone cu frontul crescator de ceas
  //driver clocking block
  clocking driver_cb @(posedge clk);
    //semnalele de intrare sunt citite o unitate de timp inainte frontului de ceas, iar semnalele de iesire sunt citite o unitate de timp dupa frontul de ceas; astfel se elimina situatiile in care se fac scrieri sau citiri in acelasi timp
    default input #1 output #1;
    output [DATA_WIDTH-1:0] data_i;
	output valid_i;
	input ready_o;
  endclocking
  
  //monitor clocking block
  clocking monitor_cb @(posedge clk);
    default input #1 output #1;
	input [DATA_WIDTH-1:0] data_i;
	input valid_i; 
	input ready_o;
	  
  endclocking
  
  //driver modport
  modport DRIVER  (clocking driver_cb,input clk,reset);
  
  //monitor modport  
  modport MONITOR (clocking monitor_cb,input clk,reset);
  /* 1.daca valid_i(adica am date de trimis) a fost 1 si ready 0(inca nu pot primi),
  valid_i trebuie sa ramana tot 1*/
  property valid_stable;
    @(posedge clk) disable iff (reset==0)
    (valid_i && !ready_o) |=> valid_i;
  endproperty
 
 asertia_valid_stable: assert property (valid_stable) 
    else $error("A picat asertia asertia_valid_stable");
    VALID_STABLE_C: cover property (valid_stable);
  
  // 2.datele trebuie sa ramana stabile cat timp valid=1 si ready=0
  property data_stabila;
    @(posedge clk) disable iff (reset==0)
    (valid_i && !ready_o) |=> $stable(data_i);
  endproperty
  
  asertia_data_stabila: assert property (data_stabila) 
    else $error("A picat asertia asertia_data_stabila");
    DATA_STABILA_C: cover property (data_stabila);
  
  // 3.valid nu are voie sa fie x sau z, adica nedeterminate
   property valid_cunoscut;
    @(posedge clk) disable iff (reset==0)
    !$isunknown(valid_i);
  endproperty
  
  asertia_valid_cunoscut: assert property (valid_cunoscut) 
    else $error("A picat asertia asertia_valid_cunoscut");
    VALID_CUNOSCUT_C: cover property (valid_cunoscut);
	
	//4.ready nu are voie sa fie X sau Z (nedeterminat) niciodata
  property ready_cunoscut;
    @(posedge clk) disable iff (reset==0)
    !$isunknown(ready_o);
  endproperty

  asertia_ready_cunoscut: assert property (ready_cunoscut)
    else $error("A picat asertia asertia_ready_cunoscut");
	
	//5.data nu are voie sa fie X sau Z cat timp valid_i este 1
  property data_cunoscuta;
    @(posedge clk) disable iff (reset==0)
    valid_i |-> !$isunknown(data_i);
  endproperty

  asertia_data_cunoscuta: assert property (data_cunoscuta)
    else $error("A picat asertia asertia_data_cunoscuta");

  //6.dupa iesirea din reset, valid_i trebuie sa fie 0
  property valid_dupa_reset;
    @(posedge clk)
    $rose(reset) |-> !valid_i;
  endproperty
  
  asertia_valid_dupa_reset: assert property (valid_dupa_reset) 
    else $error("A picat asertia asertia_valid_dupa_reset");
    VALID_DUPA_RESET_C: cover property (valid_dupa_reset);
  
  //7.dupa iesirea din reset, ready_o trebuie sa fie 0
  property ready_dupa_reset;
    @(posedge clk)
    $rose(reset) |-> !ready_o;
  endproperty

  asertia_ready_dupa_reset: assert property (ready_dupa_reset)
    else $error("A picat asertia asertia_ready_dupa_reset");


    
  
endinterface