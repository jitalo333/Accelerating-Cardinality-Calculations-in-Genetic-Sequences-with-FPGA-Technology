
module BRAM(

  input logic clk_out,
  input logic [9:0] address_w,
  input logic [9:0] address_r,
  input logic read_enable,
  input logic write_enable,
  input logic [31:0] data_in,
  output logic [31:0] data_out
);

  reg [31:0] memory [0:1023];
  //reg [31:0] memory [0:10];
  
  always @(posedge clk_out) begin
    if (write_enable)
      memory[address_w] <= data_in;
    if (read_enable)
      data_out <= memory[address_r];
  end
  
endmodule

module example_sv(
    input clk_out,
    input reset,
    input [31:0] s_axis_tdata,
    input [3:0] s_axis_tkeep,
    input s_axis_tlast,
    input s_axis_tvalid,
    input m_axis_tready,
    
    output reg s_axis_tready,
    output reg [31:0] m_axis_tdata,
    output reg [3:0] m_axis_tkeep,
    output reg m_axis_tlast,
    
    output reg m_axis_tvalid,
    
    //BRAM
	output logic [9:0] address_w,
	input logic [9:0] address_r,
	input logic read_enable,
	output logic write_enable,
	output logic [31:0] data_in,
	input logic [31:0] data_out,
	//
	output logic start_gen,
	input logic [247:0] data,
	input logic enviar_dato,
	input logic addr1023,
	input logic fin_archivo,
	//solo simulacion
	output logic sim_feed
    );
    
    reg [3:0] state_reg;
    reg [31:0] tdata;
    reg tlast;
    
    parameter init               = 3'd0;
    parameter SetSlaveTready     = 3'd1;
    parameter Save 		         = 3'd2;
    parameter Espera             = 3'd3;
    parameter ProcessTdata       = 3'd4;
    parameter CheckTlast         = 3'd5;
    
    always @ (posedge clk_out)
        begin
			// Default outputs            
			m_axis_tvalid <= 1'b0;
            
            if (reset == 1'b0)
                begin
                    tlast <= 1'b0;
                    tdata[31:0] <= 32'd0;
                    s_axis_tready <= 1'b0;
                    m_axis_tdata[31:0] <= 32'd0;
                    m_axis_tkeep <= 4'h0;
                    m_axis_tlast <= 1'b0;
                    state_reg <= init;
                    //BRAM
                    address_w<=0;
                    write_enable<=0;
			        data_in<=0;
			        
			        //
			        start_gen<=0;
                end
            else
                begin
                
                    case(state_reg) 
                        init : // 0 
                            begin
                                tlast <= 1'b0;
                                tdata[31:0] <= 32'd0;
                                s_axis_tready <= 1'b0;
                                m_axis_tdata[31:0] <= 32'd0;
                                m_axis_tkeep <= 4'h0;
                                m_axis_tlast <= 1'b0;
                                state_reg <= SetSlaveTready;
                            end 
                            
                        SetSlaveTready : // 1
                            begin
                                s_axis_tready <= 1'b1;
                                state_reg <= Save;
                                //solo simulacion
								sim_feed<=1;
                            end 
                            
                        Save: // 2
                            begin
														
								if(address_w==1023) begin
									state_reg<=Espera;
									address_w<=0;
									s_axis_tready <= 1'b0;
									write_enable<=0;
									
								end
								else begin
									if (s_axis_tkeep == 4'hf && s_axis_tvalid == 1'b1)
										begin
										    //solo simulacion
									        sim_feed<=0;
											state_reg <= SetSlaveTready;
											s_axis_tready <= 1'b0;
											tlast <= s_axis_tlast;
											//BRAM
											address_w<=address_w+1;
											write_enable<=1;
											data_in[31:0] <= s_axis_tdata[31:0];
										end
									else
										begin 
										    state_reg <= Save;
											data_in[31:0] <= 32'd0;
											write_enable<= 0;
										end 
								end
                            end //Save

							
						Espera: 
							begin
							    if(fin_archivo) begin
							        start_gen<=0;
							        if(enviar_dato) begin
									   state_reg<=ProcessTdata;
									end
								end
								else if(addr1023) begin
									//state_reg<= SetSlaveTready;
									state_reg<=ProcessTdata;
									
								end
								
								else begin
								    start_gen<=1;	
								end
							end//espera
                        
						
						
                        ProcessTdata : // 3
                            begin 
                                start_gen<=0;
                                m_axis_tkeep <= 4'hf;
                                m_axis_tlast <= tlast;
                                //m_axis_tlast <= 0;
                                m_axis_tvalid <= 1'b1;
                                //BRAM
                                m_axis_tdata[31:0] <= 222;
                                
                                if (m_axis_tready == 1'b1)
                                    begin 
                                        state_reg <= CheckTlast;
                                    end 
                                else
                                    begin 
                                        state_reg <= ProcessTdata;
                                    end 
                            end
                            
                        CheckTlast : // 4
                            begin 
                                if (m_axis_tlast == 1'b1)
                                    begin				
                                        state_reg <= init;
                                    end
                                else if (m_axis_tready == 1'b1)
                                    begin
                                        state_reg <= SetSlaveTready;
                                    end
                                else 
                                    begin 
                                        state_reg <= CheckTlast;
                                    end 
                            end 
                            
                    endcase 
                end
        end
    
endmodule

module generador_kmers(input logic clk_out, input logic ldz_ready, input logic start_gen, input logic [9:0] address_w, input logic [31:0] data_out, input logic reset,
					output logic [9:0] address_r, output logic  start, read_enable, output logic [247:0] data, output logic fin_archivo, addr1023);
	
	logic [1:0] state;
	logic [1:0] count_r;

	always @(posedge clk_out) begin
	
		if(reset == 0) begin
			state<=0;
			address_r<=0;
			start<=0;
			data<=0;
			read_enable<=0;
			count_r<=0;
			fin_archivo<=0;
			addr1023<=0;
		end
		
		else begin
		  if(start_gen) begin
              case(state)
                        0: begin
                            if((data[7:0]!=8'b0) && (data[247:240]!=8'b0)) begin 
                                state<=1; //comienza transmisión
                                start<=1; 
                            end
                            else begin
                            //////////////////////////////
                                    read_enable<=1; 
                                    count_r<=count_r+1;
                                    if(count_r==3) begin
                                        address_r<= address_r+1;
                                    end
                                    case(count_r) 
                                        0: begin
                                         data[247:8]<=data[239:0];
                                         data[7:0]<=data_out[7:0];
                                        end
                                        1: begin
                                         data[247:8]<=data[239:0];
                                         data[7:0]<=data_out[15:8];
                                        end
                                        2: begin
                                         data[247:8]<=data[239:0];
                                         data[7:0]<=data_out[23:16];
                                        end
                                        3: begin
                                         data[247:8]<=data[239:0];
                                         data[7:0]<=data_out[31:24];
                                        end
                                    endcase
                            ///////////////////////////////
                            end
                        end //case 0
                        1: begin
                           
                            if(data[7:0]==8'b0) begin
                                state<=2; //se borra data y se espera para comenzar llenado
                            end
                            else if(address_r==1023) begin
                                addr1023<=1;
                                address_r<=0;
                                state<=2;
                            end
                            else begin
                                if(ldz_ready) begin
                                    //////////////////////////////////////////////////
                                        read_enable<=1; 
                                        count_r<=count_r+1;
                                        if(count_r==3) begin
                                            address_r<= address_r+1;
                                        end
                                        case(count_r) 
                                            0: begin
                                             data[247:8]<=data[239:0];
                                             data[7:0]<=data_out[7:0];
                                            end
                                            1: begin
                                             data[247:8]<=data[239:0];
                                             data[7:0]<=data_out[15:8];
                                            end
                                            2: begin
                                             data[247:8]<=data[239:0];
                                             data[7:0]<=data_out[23:16];
                                            end
                                            3: begin
                                             data[247:8]<=data[239:0];
                                             data[7:0]<=data_out[31:24];
                                            end
                                        endcase
                                    /////////////////////////////////////////////////
                                    start<= 1;
                                end
                                else begin
                                    start<=0;
                                end
                            end
                        end //case 1
                        2: begin 
                            state<=0; //comienza llenado
                            data<=0;	
                            fin_archivo<=1;
                            address_r<=0;
                            addr1023<=0;
                        end //case 2
                    endcase	
		  end//else start_gen		
		end //else reset
	end
endmodule: generador_kmers


//Dato calculado listo
module prueba_dcl(input logic clk_out,  reset, st_keep, st_valid, input logic [31:0] st_data,
					output logic [9:0] address_r, input logic [247:0] data, 
					output logic [9:0] address_w, 
                    output logic write_enable, st_ready, start_gen,
					output logic [31:0] data_in );
	logic [2:0]state;
	
    always @(posedge clk_out) begin
        //reset
        if(reset) begin            
            address_w<=1000;	
            address_r<=0;
			write_enable<=0;
			state<=1;
			st_ready<=0;
			data_in<=0;
        end
        //Cuerpo
        else begin
            case(state) 
                //set
                1: begin
                   st_ready<=1;  
                   state<=2;   
                end //1
                2: begin
                    if(address_w==1023) begin
                        state<=3;
                    end
                    else begin
                        if(st_keep && st_valid) begin
                            state<=1;
                            st_ready<=0;
                            address_w<=address_w+1;
                            write_enable<=1;
                            data_in<=st_data;
                        end
                        else begin
                            data_in<=0;
                            write_enable<=0;
                        end//else2
                    end//else1
                end//2
                3: begin
                    if(address_r==1023) begin
                        state<=1;
                        start_gen<=0;
                        address_r<=0;
                    end
                    else if(data[7:0]==0) begin
                        state<=4;   
                    end
                    address_r<=address_r+1;
                    start_gen<=1;
                end
            
            endcase
        end //else
		
    end//always_   	
	
endmodule:prueba_dcl

module encode_fsm(input logic [247:0] data, input logic clk_out, start, output logic [61:0] coded_kmer, output logic coded_ready);

    always_ff @(posedge clk_out) begin
        if(start) begin ///ESTADO 0
            coded_kmer[ 0 ]<=data[ 1 ]^data[ 2 ];
            coded_kmer[ 2 ]<=data[ 9 ]^data[ 10 ];
            coded_kmer[ 4 ]<=data[ 17 ]^data[ 18 ];
            coded_kmer[ 6 ]<=data[ 25 ]^data[ 26 ];
            coded_kmer[ 8 ]<=data[ 33 ]^data[ 34 ];
            coded_kmer[ 10 ]<=data[ 41 ]^data[ 42 ];
            coded_kmer[ 12 ]<=data[ 49 ]^data[ 50 ];
            coded_kmer[ 14 ]<=data[ 57 ]^data[ 58 ];
            coded_kmer[ 16 ]<=data[ 65 ]^data[ 66 ];
            coded_kmer[ 18 ]<=data[ 73 ]^data[ 74 ];
            coded_kmer[ 20 ]<=data[ 81 ]^data[ 82 ];
            coded_kmer[ 22 ]<=data[ 89 ]^data[ 90 ];
            coded_kmer[ 24 ]<=data[ 97 ]^data[ 98 ];
            coded_kmer[ 26 ]<=data[ 105 ]^data[ 106 ];
            coded_kmer[ 28 ]<=data[ 113 ]^data[ 114 ];
            coded_kmer[ 30 ]<=data[ 121 ]^data[ 122 ];
            coded_kmer[ 32 ]<=data[ 129 ]^data[ 130 ];
            coded_kmer[ 34 ]<=data[ 137 ]^data[ 138 ];
            coded_kmer[ 36 ]<=data[ 145 ]^data[ 146 ];
            coded_kmer[ 38 ]<=data[ 153 ]^data[ 154 ];
            coded_kmer[ 40 ]<=data[ 161 ]^data[ 162 ];
            coded_kmer[ 42 ]<=data[ 169 ]^data[ 170 ];
            coded_kmer[ 44 ]<=data[ 177 ]^data[ 178 ];
            coded_kmer[ 46 ]<=data[ 185 ]^data[ 186 ];
            coded_kmer[ 48 ]<=data[ 193 ]^data[ 194 ];
            coded_kmer[ 50 ]<=data[ 201 ]^data[ 202 ];
            coded_kmer[ 52 ]<=data[ 209 ]^data[ 210 ];
            coded_kmer[ 54 ]<=data[ 217 ]^data[ 218 ];
            coded_kmer[ 56 ]<=data[ 225 ]^data[ 226 ];
            coded_kmer[ 58 ]<=data[ 233 ]^data[ 234 ];
            coded_kmer[ 60 ]<=data[ 241 ]^data[ 242 ];

            coded_kmer[ 1 ]<=data[ 2 ];
            coded_kmer[ 3 ]<=data[ 10 ];
            coded_kmer[ 5 ]<=data[ 18 ];
            coded_kmer[ 7 ]<=data[ 26 ];
            coded_kmer[ 9 ]<=data[ 34 ];
            coded_kmer[ 11 ]<=data[ 42 ];
            coded_kmer[ 13 ]<=data[ 50 ];
            coded_kmer[ 15 ]<=data[ 58 ];
            coded_kmer[ 17 ]<=data[ 66 ];
            coded_kmer[ 19 ]<=data[ 74 ];
            coded_kmer[ 21 ]<=data[ 82 ];
            coded_kmer[ 23 ]<=data[ 90 ];
            coded_kmer[ 25 ]<=data[ 98 ];
            coded_kmer[ 27 ]<=data[ 106 ];
            coded_kmer[ 29 ]<=data[ 114 ];
            coded_kmer[ 31 ]<=data[ 122 ];
            coded_kmer[ 33 ]<=data[ 130 ];
            coded_kmer[ 35 ]<=data[ 138 ];
            coded_kmer[ 37 ]<=data[ 146 ];
            coded_kmer[ 39 ]<=data[ 154 ];
            coded_kmer[ 41 ]<=data[ 162 ];
            coded_kmer[ 43 ]<=data[ 170 ];
            coded_kmer[ 45 ]<=data[ 178 ];
            coded_kmer[ 47 ]<=data[ 186 ];
            coded_kmer[ 49 ]<=data[ 194 ];
            coded_kmer[ 51 ]<=data[ 202 ];
            coded_kmer[ 53 ]<=data[ 210 ];
            coded_kmer[ 55 ]<=data[ 218 ];
            coded_kmer[ 57 ]<=data[ 226 ];
            coded_kmer[ 59 ]<=data[ 234 ];
            coded_kmer[ 61 ]<=data[ 242 ];
             
            coded_ready<=1;
        end
        else if(coded_ready) begin ///ESTADO 1
            coded_ready<=0;      
        end
    end
    
endmodule
//FSM
module canonic_fsm(input logic clk_out, coded_ready, input logic [61:0]coded_kmer, 
					  output logic [61:0]k_canon, output logic canon_ready);  
    
	logic [61:0]k;    
	//Registros de estado
	logic state; //sA=0, sB=1
	
		//Transición
	always_ff @(posedge clk_out) begin

		if(coded_ready) begin
			state<=1;
		end
		else if(canon_ready) begin
			state<=0;	
		end	
		
	end

    always_comb begin
        if(state) begin
			k[ 1 : 0 ]=~coded_kmer[ 61 : 60 ];
			k[ 3 : 2 ]=~coded_kmer[ 59 : 58 ];
			k[ 5 : 4 ]=~coded_kmer[ 57 : 56 ];
			k[ 7 : 6 ]=~coded_kmer[ 55 : 54 ];
			k[ 9 : 8 ]=~coded_kmer[ 53 : 52 ];
			k[ 11 : 10 ]=~coded_kmer[ 51 : 50 ];
			k[ 13 : 12 ]=~coded_kmer[ 49 : 48 ];
			k[ 15 : 14 ]=~coded_kmer[ 47 : 46 ];
			k[ 17 : 16 ]=~coded_kmer[ 45 : 44 ];
			k[ 19 : 18 ]=~coded_kmer[ 43 : 42 ];
			k[ 21 : 20 ]=~coded_kmer[ 41 : 40 ];
			k[ 23 : 22 ]=~coded_kmer[ 39 : 38 ];
			k[ 25 : 24 ]=~coded_kmer[ 37 : 36 ];
			k[ 27 : 26 ]=~coded_kmer[ 35 : 34 ];
			k[ 29 : 28 ]=~coded_kmer[ 33 : 32 ];
			k[ 31 : 30 ]=~coded_kmer[ 31 : 30 ];
			k[ 33 : 32 ]=~coded_kmer[ 29 : 28 ];
			k[ 35 : 34 ]=~coded_kmer[ 27 : 26 ];
			k[ 37 : 36 ]=~coded_kmer[ 25 : 24 ];
			k[ 39 : 38 ]=~coded_kmer[ 23 : 22 ];
			k[ 41 : 40 ]=~coded_kmer[ 21 : 20 ];
			k[ 43 : 42 ]=~coded_kmer[ 19 : 18 ];
			k[ 45 : 44 ]=~coded_kmer[ 17 : 16 ];
			k[ 47 : 46 ]=~coded_kmer[ 15 : 14 ];
			k[ 49 : 48 ]=~coded_kmer[ 13 : 12 ];
			k[ 51 : 50 ]=~coded_kmer[ 11 : 10 ];
			k[ 53 : 52 ]=~coded_kmer[ 9 : 8 ];
			k[ 55 : 54 ]=~coded_kmer[ 7 : 6 ];
			k[ 57 : 56 ]=~coded_kmer[ 5 : 4 ];
			k[ 59 : 58 ]=~coded_kmer[ 3 : 2 ];
			k[ 61 : 60 ]=~coded_kmer[ 1 : 0 ];
			
			if(k<coded_kmer) begin
				k_canon=k;
			end
			else begin
				k_canon=coded_kmer;  
			end
			
			//Levantamos flag
			canon_ready=1;
		end
		else begin
			//bajamos flag
			canon_ready=0;
		end
    end                                                     
endmodule

module k_canon_to_hash_result_velocidad_3pasos(input logic clk_out, canon_ready, input logic [61:0]k_canon,  
							  output logic [63:0] hash_result, output logic hash_ready);
    
    logic [63:0] k0, k1, k2, k3, k4, k5, k6;
	logic [8:0] state, nextstate; //poner bus numero de estados
	logic [31:0] x0, x1, x2, x3, x4, x5,x6, x7, x8, x9, 
	             x0_, x1_, x2_, x3_, x4_, x5_,x6_, x7_, x8_, x9_;
	logic [18:0] y0, y1, y2, w0, w1, w2, n0, 
				 y0_, y1_, y2_, w0_, w1_, w2_, n0_;
	
	//Transición
	//assign nextstate= state + 1;
	
	//Transición
	always_ff @(posedge clk_out) begin

		if(canon_ready) begin
			state<=1;
		end //state0
		
		else if(state==0) begin
			hash_ready=0; ////////////////////////
		end	//state0
		
		else if(state==1) begin
			state<=2;
		end //state1
		
		else if(state==2) begin
			state<=3;
		end //state2
		
		else if(state==3) begin
			state<=4;
		end //state3
		
		else if(state==4) begin
			state<=5;
		end //state4
		
		else if(state==5) begin
			state<=6;
		end //state5
		
		else if(state==6) begin
			state<=7;
		end //state6
		
		else if(state==7) begin
			state<=8;		
		end //state7
			
		else if(state==8) begin
			state<=9;
		end //state8
		
		else if(state==9) begin
			state<=10;
		end //state9
		
		else if(state==10) begin
			state<=11;
		end //state11
		
		else if(state==11) begin
			state<=12;
		end //state12
		else if(state==12) begin
			state<=13;
		end //state12
		else if(state==13) begin
			state<=14;
		end //state13
		
		else if(state==14) begin
			state<=0;
			hash_ready<=1;
		end //state18
		
	end //Alwaysff1


	//Cálculos
	always_ff @(posedge clk_out) begin
	
	case(state)
		
		1: k0 <= k_canon>>33;
		2: k1 <= k0^k_canon;
		//k2=k1*constante
		3: begin
			x0<=k1[15:0]*'b1000110011001101;
			x1<=k1[31:16]*'b1000110011001101;
			x2<=k1[15:0]*'b1110110101010101;
			x3<=k1[15:0]*'b1010111111010111;
			x4<=k1[31:16]*'b1110110101010101;
			x5<=k1[47:32]*'b1000110011001101;
			x6<=k1[15:0]*'b1111111101010001;
			x7<=k1[31:16]*'b1010111111010111;
			x8<=k1[47:32]*'b1110110101010101;
			x9<=k1[63:48]*'b1000110011001101;
		end
		4: begin
			y0<= x3[31:16]  + x4[31:16]  + x5[31:16];
			y1<= x6[15:0] + x7[15:0] + x8[15:0];

			w0<= x1[31:16] + x2[31:16] + x3[15:0];
			w1<= x4[15:0] + x5[15:0];

			n0<= x0[31:16] + x2[15:0] + x1[15:0];

			k2[15:0]<= x0[15:0];
		end
		5: begin
			y2<= y0 + y1 + x9[15:0];

			w2<= w0 + w1 + n0[17:16];

			k2[31:16]<=n0;
		end
		6: begin
			k2[63:48]<= y2 + w2[18:16];
			k2[47:32]<= w2;		
		end
		7: k3 <= k2>>33;
		8: k4 <= k3^k2;
		9: begin
			x0_<=k4[15:0]*'b1110110001010011;
			x1_<=k4[31:16]*'b1110110001010011;
			x2_<=k4[15:0]*'b0001101010000101;
			x3_<=k4[15:0]*'b1011100111111110;
			x4_<=k4[31:16]*'b0001101010000101;
			x5_<=k4[47:32]*'b1110110001010011;
			x6_<=k4[15:0]*'b1100010011001110;
			x7_<=k4[31:16]*'b1011100111111110;
			x8_<=k4[47:32]*'b0001101010000101;
			x9_<=k4[63:48]*'b1110110001010011;
		end
		10: begin
            y0_<= x3_[31:16]  + x4_[31:16]  + x5_[31:16];
			y1_<= x6_[15:0] + x7_[15:0] + x8_[15:0];

			w0_<= x1_[31:16] + x2_[31:16] + x3_[15:0];
			w1_<= x4_[15:0] + x5_[15:0];

			n0_<= x0_[31:16] + x2_[15:0] + x1_[15:0];

			k5[15:0]<= x0_[15:0];
		end
		11: begin
			y2_<= y0_ + y1_ + x9_[15:0];

			w2_<= w0_ + w1_ + n0_[17:16];

			k5[31:16]<=n0_;
        end
		12: begin
			k5[63:48]<= y2_ + w2_[18:16];
			k5[47:32]<= w2_;
		end
		13: k6 <= k5>>33;
		14: hash_result <= k6^k5;
		
	endcase
	
	end
	
endmodule: k_canon_to_hash_result_velocidad_3pasos

module ldz_position(input logic reset, clk_out, hash_ready, input logic [63:0]hash_result, input logic start,  
output logic [5:0]ldz, output logic ldz_ready, output logic [31:0] sum_ldz);
	//Registros de estado
	logic state; //sA=0, sB=1
 
    //Variables combinacionales:
	logic [63:0]Ms;
    logic [31:0] bits32;
    logic [15:0] bits16;
    logic [8:0] bits8;
    logic [3:0] bits4;
    logic [1:0] bits2; 
    logic bits[31:0];
	
	//Transición
	always_ff @(posedge clk_out) begin
	    //reset
	    if(reset==0) begin
            ldz_ready<= 0;
            //suma de ldz
            sum_ldz<=0;
        end
        //comienzo calculo
		if(hash_ready) begin
			state<=1;
		end
		else begin
			state<=0;	
		end	
        //LDZ ///////////////////////////////cambio 2
        if(state) begin
            ldz_ready<=1;
            //suma de ldz
            sum_ldz<=sum_ldz+ldz;
        end
        else begin
            ldz_ready<=0;
        end
		
	end//end ff

    always_comb begin
        if(state==1) begin
			Ms[13:0]=14'b10000000000000;
			Ms[63:14]=hash_result[63:14];
			
			ldz[5]=(Ms[63:32]==0); //si ldz es 1, no hay uno en Msb, y nos vamos a la derecha
			
			if(ldz[5])
				bits32= Ms[31:0];
			else
				bits32[31:0]= Ms[63:32];  
			//4   
			ldz[4]= (bits32[31:16]==0);  
			 if(ldz[4])
				bits16=bits32[15:0]; 
			 else             
				bits16=bits32[31:16];  
			 //3  
			 ldz[3]=(bits16[15:8]==0);  
			 if(ldz[3])
				bits8=bits16[7:0];
			 else
				bits8=bits16[15:8];
			 //2   
			 ldz[2]=(bits8[7:4]==0);
			 if(ldz[2])
				bits4=bits8[3:0];  
			 else
				bits4=bits8[7:4];
			 //1   
			 ldz[1]=(bits4[3:2]==0); 
			 if(ldz[1])
				bits2=bits4[1:0];            
			 else
				bits2=bits4[3:2];			 
			 //0   
			 ldz[0]=(bits2[1]==0); 
		end
    end
    
endmodule: ldz_position


module BRAM_Sketch(

  input logic clk_out, reset,
  input logic [14:0] address_w2,
  input logic [14:0] address_r2,
  input logic read_enable2,
  input logic write_enable2,
  input logic [31:0] data_in2,
  output logic [31:0] data_out2
);

  reg [5:0] memory [0:16384];
  //reg [31:0] memory [0:10];
  
  always @(posedge clk_out) begin
    if(reset) begin
        data_out2<=0;
    end
    else begin
        if (write_enable2)
          memory[address_w2] <= data_in2;
        if (read_enable2)
          data_out2 <= memory[address_r2];
    end
  end
  
endmodule

module suma_armonica(input logic clk_out, reset, ldz_ready, input logic [5:0]ldz, input logic [31:0] data_out2, 
                      input logic fin_archivo,
                      input logic [63:0] hash_result,
                      output logic [14:0] address_w2,
                      output logic [14:0] address_r2,
                      output logic read_enable2,
                      output logic write_enable2,
                      output logic [31:0] data_in2,
                      output logic [31:0] suma_arm,
                      output logic [15:0] nz,
                      output logic enviar_dato);

    logic [2:0] state;
    logic [14:0] count;
    
    always_ff @(posedge clk_out) begin
        //almacenamiento
        if(reset==0) begin
            state<=0;
            address_w2<=0;
            write_enable2<=0;
            count<=0;
            enviar_dato<=0;
            suma_arm<=0;
            nz<=0;
        end
        else begin
            case(state)
                0: begin 
                        if(fin_archivo) begin
                            state<=1;
                        end
                        else if(ldz_ready) begin
                            address_w2<=hash_result[14:0];   
                            address_r2<=hash_result[14:0]; 
                            write_enable2<= 1;
                            read_enable2<= 1;
                            if(ldz>data_out2) begin
                                data_in2<=ldz;
                            end
                        end//else
                    end //0  
                1:  begin
                        address_r2<=0;
                        address_w2<=0;
                        state<=2;
                    end //1
                2:  begin
                        if(address_r2==16384) begin
                            enviar_dato<=1;
                            count<=0;
                        end  
                        else begin
                            address_r2<=address_r2+1;
                            read_enable2<=1;
                            state<=3;
                            if(data_out2==0) begin
                                nz<=nz+1;
                                suma_arm<= suma_arm + (22'b0000000001000000000000 >> data_out2);
                            end   
                        end //else                  
                    end//2
                 3: begin
                        state<=2;
                        address_w2<=address_r2;
                        write_enable2<=1;
                        data_in2<=0;
                    end
            endcase
        end
    end
    
endmodule: suma_armonica