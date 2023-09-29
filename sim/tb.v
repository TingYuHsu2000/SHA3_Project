`timescale 1ns/10ps
`define CYCLE 6.0
`define END_CYCLE 100
// all pattern is in len
`define SDFFILE "../syn/top_syn.sdf"

`ifdef syn
  `include "../syn/top_syn.v"
`else
  `include "../rtl/top.v"
`endif

module tb;
`ifdef PIPE
	`define PAT        "./dat/pipeline/pipe_testpattern.txt"    
	`define GOLDEN     "./dat/pipeline/pipe_golden.txt"  
	`define OUTLEN       "./dat/pipeline/pipe_outlen.txt"  
	`define INLEN     "./dat/pipeline/pipe_inlen.txt" 
	`define MODE       "./dat/pipeline/pipe_mode.txt"  
	`define IN_FIS     "./dat/pipeline/pipe_in_finish.txt" 
`elsif SHAKE128
	`define PAT        "./dat/shake_128/shake128_testpattern.txt"    
	`define INLEN       "./dat/shake_128/shake128_inlen.txt"  
	`define OUTLEN       "./dat/shake_128/shake128_outlen.txt"  
	`define GOLDEN     "./dat/shake_128/shake128_golden.txt"  
	`define MODE       "./dat/shake_128/mode.txt"  
	`define IN_FIS     "./dat/shake_128/in_finish.txt" 
`elsif SHAKE256
	`define PAT        "./dat/shake_256/shake256_testpattern.txt"    
	`define GOLDEN     "./dat/shake_256/shake256_golden.txt"  
	`define OUTLEN       "./dat/shake_256/shake256_outlen.txt"  
	`define INLEN     "./dat/shake_256/shake256_inlen.txt"   
	`define MODE       "./dat/shake_256/mode.txt"  
	`define IN_FIS     "./dat/shake_256/in_finish.txt" 
`elsif SHA256
	`define PAT        "./dat/sha_256/sha256_testpattern.txt"    
	`define GOLDEN     "./dat/sha_256/sha256_golden.txt"  
	`define OUTLEN       "./dat/sha_256/sha256_outlen.txt"  
	`define INLEN     "./dat/sha_256/sha256_inlen.txt"
	`define MODE       "./dat/sha_256/mode.txt"  
	`define IN_FIS     "./dat/sha_256/in_finish.txt" 
`elsif SHA512
	`define PAT        "./dat/sha_512/sha512_testpattern.txt"    
	`define GOLDEN     "./dat/sha_512/sha512_golden.txt"  
	`define OUTLEN       "./dat/sha_512/sha512_outlen.txt"  
	`define INLEN     "./dat/sha_512/sha512_inlen.txt" 
	`define MODE       "./dat/sha_512/mode.txt"  
	`define IN_FIS     "./dat/sha_512/in_finish.txt" 
`else//default SHA512
	`define PAT        "sha512_testpattern.txt"    
	`define GOLDEN     "sha512_golden.txt"  
	`define OUTLEN       "sha512_outlen.txt"  
	`define INLEN     "sha512_inlen.txt" 
	`define MODE       "mode.txt"  
	`define IN_FIS     "in_finish.txt" 
`endif

parameter  SHAKE128_RATE= 8'd168, SHAKE256_RATE= 8'd136 ,SHA256_RATE= 8'd136, SHA512_RATE= 8'd72; //bytes
reg clk, rst,in_finish;
reg [10:0] in_len;
reg [6399:0] data_in;
reg [12:0] data_len;
reg [12:0] length;
reg [1:0]mode_in;

wire [1343:0] data_out;
wire finish,valid,in_ready;
wire [1:0] mode_out;
wire [10:0] out_length;

//---------------the correct answer--------------------
reg [6399:0]in_buf[0:47]; //!modify with the input
reg [10:0]in_len_buf[0:47];
reg [12:0]out_len_buf[0:7];
reg [1343:0]golden_buf[0:47];
reg [3:0]in_finish_buf[0:47];
reg [1:0]mode_buf[0:47];

reg [22:0] cycle=0;
reg [5:0]counter_buf,counter_round,counter_golden;
reg [3:0]counter8_in,counter8_out;
integer n;

top top(.clk(clk),
		  .rst(rst),
		  .mode_in(mode_in),
		  .data_in(data_in),
		  .data_len(data_len),
		  .length(length),
          .in_finish(in_finish),
		  // .in_ready(in_ready),
		  .data_out(data_out),
		  .mode_out(mode_out),
		  .out_valid(valid),
		  .out_length(out_length),
          .finish(finish));


always begin #(`CYCLE/2) clk = ~clk ; end

initial begin
	clk = 0; 
	rst = 0;
	@(posedge clk) #(`CYCLE/2) rst = 1;
	#(`CYCLE*1) rst = 0;
end

`ifdef SDF
    initial $sdf_annotate(`SDFFILE, top);
`endif

`ifdef FSDB
	initial begin
		$fsdbDumpfile("SHA.fsdb");
		$fsdbDumpvars();
		$fsdbDumpMDA;
	end
`endif

initial begin
    $display("----------------------");
    $display("-- Simulation Start --");
    $display("----------------------");
    @(posedge clk); #1; rst = 1'b1; 
    #(`CYCLE*2);  
    @(posedge clk); #1;   rst = 1'b0;
end

initial begin	 
     $readmemh(`PAT, in_buf);
	 $readmemh(`OUTLEN, out_len_buf);
	 $readmemh(`GOLDEN, golden_buf);
	 $readmemh(`IN_FIS, in_finish_buf);
	 $readmemb(`MODE, mode_buf);
	 $readmemh(`INLEN, in_len_buf);
	//  $readmemh(`INLEN, in_finish_buf,0,1);
	//  $readmemh(`INLEN, mode_buf,2,3);
	//  for(n=0;n<8;n=n+1)
	//  	$display("indata is %h", in_buf[n]) ;
	//  $display("--------------------------------------------------");
	//  for(n=0;n<10;n=n+1)
	//  	$display("in len is %d", in_len_buf[n]) ;
	//  $display("--------------------------------------------------");
	//  for(n=0;n<10;n=n+1)
	// 	$display("OUT len is %d", out_len_buf[n]) ;
	// for(n=0;n<8;n=n+1)
	// 	$display("in_finish_buf is %d", in_finish_buf[n]) ;
	// $display("--------------------------------------------------");
	//  for(n=0;n<20;n=n+1)
	// 	$display("golden_buf is %d \n", golden_buf[n]) ;
end

always @(posedge clk ) begin
	if(rst)begin 		
		data_in=0;
		data_len=0;
		length=0;
		in_len=0;
		mode_in=0;
		in_finish=0;
		counter_buf=0;
	end
	else begin //always RATE>in_len_buf[counter_buf]
		// $display("pattern %d", counter_buf) ;
		data_in=in_buf[counter_buf];
		data_len=in_len_buf[counter_buf]*8;
		length=out_len_buf[counter_buf]*8;
		mode_in=mode_buf[counter_buf];
		in_finish=in_finish_buf[counter_buf];
		
		// $display("the inlen is %d",in_len_buf[counter_buf]) ;
		// $display("the mode_in is %h", mode_buf[counter_buf]) ;
		// $display("the in_finish_buf is %h", in_finish_buf[counter_buf]) ;
		end	
end

always @(posedge clk ) begin
	if(rst)begin 		

		counter_buf=0;

	end
	//else if(finish) begin //always RATE>in_len_buf[counter_buf]
		// $display("pattern %d", counter_buf) ;
		//counter_buf<=counter_buf;
		// $display("the inlen is %d",in_len_buf[counter_buf]) ;
		// $display("the mode_in is %h", mode_buf[counter_buf]) ;
		// $display("the in_finish_buf is %h", in_finish_buf[counter_buf]) ;
		//end
	else 	
		counter_buf<=counter_buf+1;
end


integer score=0,err=0; // the success and failed amount
integer allpass=1;
reg [3:0]counter_finish;
always @(posedge clk) begin
	if(rst)begin
		counter_golden=0;
		counter_finish=0;
	end
	else if(valid && counter_finish<=8)begin
		counter_golden<=counter_golden+1;
		if(data_out==golden_buf[counter_golden])begin //?data_out[out_length:0]
			score=score+1;
			$display("===========================================") ;
			$display("pattern %d is correct", counter_golden) ;
			$display("                               ") ;
			$display("expect %h in hex", golden_buf[counter_golden]) ;
			$display("                               ") ;
			$display("get    %h in hex", data_out) ;
		end
		else begin
			allpass=0;
			err=err+1;
			$display("============================================") ;
			$display("pattern %d is wrong", counter_golden) ;
			$display("                               ") ;
			$display("expect %h in hex", golden_buf[counter_golden]) ;
			$display("                               ") ;
			$display("get    %h in hex", data_out) ;
		end
		if(finish ) begin 
			counter_finish=counter_finish+1;
		end
	end
end

// end simulation
always @(posedge clk) begin
    cycle=cycle+1;
    if (cycle > `END_CYCLE) begin
        $display("--------------------------------------------------");
        $display("-- Failed waiting valid signal, Simulation STOP --");
        $display("--------------------------------------------------");
        $finish;
    end
	else if(counter_finish==8)begin //modify with your pattern amount
		if(allpass == 1 && score >1)begin
			$display("----------------------------------");
			$display("-- Simulation finish, ALL PASS  --");
			$display("----------------------------------");
			$finish;
			end
		else begin
			$display("----------------------------------");
			$display("-- Simulation finish            --");
			$display("-- error =%3d , Score =%3d       --",err, score);
			$display("----------------------------------");
			$finish;
		end
	end
end


endmodule