`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////////////

program testBench(input logic clk_out,   
				  output logic reset, 
				  output logic [3:0] s_axis_tkeep, 
				  output logic s_axis_tvalid, 
				  output logic [31:0] s_axis_tdata,
				  output logic m_axis_tready,
				  output logic s_axis_tlast
				);
    
    initial begin
        (* ram_style = "block" *) logic [247:0] kmers [1023:0];
        $readmemb("mem_32b.mem",kmers);
        //data
        @(posedge clk_out) #1 reset=0; s_axis_tkeep=4'hf; s_axis_tvalid=1; m_axis_tready=1; s_axis_tlast=1;
		for(int i=0; i<1000000; i++)begin
			@(posedge clk_out) #1 reset=1; s_axis_tdata=kmers[i]; //es igual a kmers algo kmers[][], 
																 //st_data llega automaticamente a cada clk
		end			
    end
endprogram 

module simulation;

	logic clk_out;
    logic reset;
    logic [31:0] s_axis_tdata;
    logic [3:0] s_axis_tkeep;
    logic s_axis_tlast;
    logic s_axis_tvalid;
    logic m_axis_tready;
    
    reg s_axis_tready;
    reg [31:0] m_axis_tdata;
    reg [3:0] m_axis_tkeep;
    reg m_axis_tlast;
    
    reg m_axis_tvalid;
    
    //BRAM
	logic [9:0] address_w;
	logic [9:0] address_r;
	logic read_enable;
	logic write_enable;
	logic [31:0] data_in;
	logic [31:0] data_out;
	//
	logic start_gen; logic fin_archivo;

    logic [247:0] data; 
    logic start;
    
    
    logic [61:0] coded_kmer; logic coded_ready;
	logic [61:0]k_canon;  logic canon_ready;
    logic [63:0] hash_result;  logic hash_ready;
    
    
	logic [5:0]ldz;  logic ldz_ready;
	logic [31:0] sum_ldz;
    logic addr1023;
  // Instancia del módulo BlockRAM
	
	example_sv ex_sv(.*);
	
	BRAM bram(.*);
	
	generador_kmers gk(.*);
	
	encode_fsm f1(.*);
    canonic_fsm f2(.*);
    k_canon_to_hash_result_velocidad_3pasos f3(.*);
    ldz_position f4(.*);
	
    testBench tb(.*);
    
    initial begin
        clk_out = 1;
        repeat(1000000) #10 clk_out = ~clk_out;
        $finish;
    end
    initial begin
        //$monitor (" start=%b, address_w=%d, count_r=%d, state_gk=%d, data=%b, address_r=%d, data_out=%h, data_in=%h, read_enable=%b", 
		//		  start, address_w, gk.count_r, gk.state, data[247:200], address_r, data_out, data_in, read_enable);    
		$monitor (" adress_r=%d, start_gen=%b, adress_w=%d, data_in=%b, data_out=%b, state_reg=%d, read_enable=%b, state=%d, dataf=%d", 
				  address_r, start_gen, address_w, data_in, data_out, ex_sv.state_reg, read_enable, gk.state, data[247:240]);
    end
    
endmodule : simulation
