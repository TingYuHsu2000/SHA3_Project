module controller(
	input          clk,
  	input          rst,
    input    [1:0] mode_in,//!can be omitted(use Rate to get mode)
    input [1343:0] data_in,
    input [10:0] data_len,
    input   [12:0] length,
    input          in_finish,
    input   [10:0]     rate_in,
    output reg [1599:0] data,
    output   [1:0]  mode_out_controller,
    output  reg       out_valid,
    output  reg       finish,
    output  reg [10:0] out_length,
    output         absorb_or_squeeze, 
    output         zero_or_fout  
);


integer idx,j;
wire [12:0] length_buffer = length;
wire if_sqeeze_enough; 
reg [3:0] input_buffer;
reg [12:0] out_length_buffer [7:0];
reg [7:0] in_finish_buffer ; 
reg [1343:0] data_in_reverse;
reg [1087 :0 ] PaddingRate_sha256 ;
reg [575 :0 ] PaddingRate_sha512 ;
reg [1343 :0 ] PaddingRate_shake128 ;
reg [1087 :0 ] PaddingRate_shake256 ;

/*************************************************
*   Name :          if_sqeeze_enough
*   Description:    While a data squeezes end, throwing out all the things about data (massage)
*************************************************/
assign if_sqeeze_enough = (out_length_buffer[7] <= rate_in);

/*************************************************
*   Name :          sqeeze_enough
*   Description:    Determine the f function's input is from absorb data or squeeze result
*                   1 -> f_out , 0 -> data ^ s_in
*************************************************/
assign absorb_or_squeeze = in_finish_buffer[7] && (out_length_buffer[7] > rate_in) ;

/*************************************************
*   Name :          zero_or_fout
*   Description:    Determine data_in is {xor 0} or {xor f_out}
*                   -1st absorb or squeeze -> xor 0     -> f_Function_in = data_in
*                   -other absorb          -> xor f_out -> f_Function_in = data_in ^ f_out
*************************************************/
assign zero_or_fout = (!in_finish_buffer[7]); 

/*************************************************
*   Name :          mode_out_controller
*   Description:    Same as mode_in
*************************************************/
assign mode_out_controller =  mode_in;

/*************************************************
*   Name :          data_in_reverse
*   Description:    Padding Step0 -> reverse data_in
*                   -byte unit
*************************************************/
always @(*) begin
    for (j = 0 ; j < 1344 ; j = j + 8)begin
            data_in_reverse[(1343-j) -: 4] =  data_in[(j+4) +: 4];
            data_in_reverse[(1343-j-4) -: 4] =  data_in[j +: 4];
        end 
end

/*************************************************
*   Name :          PaddingRate_sha256
*   Description:    Padding Step1(sha256) -> padding Block size(r)
*************************************************/
wire [1343:0] Pad1=(8'h80 << 1080) | (8'h06 << data_len) | (data_in_reverse >> (1344-data_len));
wire [1343:0] Pad2=(data_in_reverse >> (1344-data_len));
always @(*) begin
    if (mode_in == 2'd0 && data_len < 11'd1088)
        PaddingRate_sha256 = Pad1[1087:0];  
    else 
        PaddingRate_sha256 = Pad2[1087:0];
end
/*************************************************
*   Name :          PaddingRate_sha512
*   Description:    Padding Step1(sha512) -> padding Block size(r)
*************************************************/
wire [1343:0] Pad3=(8'h80 << 568) | (8'h06 << data_len) | (data_in_reverse >> (1344-data_len));
wire [1343:0] Pad4=(data_in_reverse >> (1344-data_len));
always @(*) begin
    if (mode_in == 2'd1 && data_len < 11'd576)
        PaddingRate_sha512 = Pad3[575:0]; 
    else 
        PaddingRate_sha512 = Pad4[575:0];
end
/*************************************************
*   Name :          PaddingRate_shake128
*   Description:    Padding Step1(shake128) -> padding Block size(r)
*************************************************/
always @(*) begin
    if (mode_in == 2'd2 && data_len < 11'd1344)
        PaddingRate_shake128 = (8'h80 << 1336) | (8'h1F << data_len) | (data_in_reverse >> (1344-data_len));
    else 
        PaddingRate_shake128 = (data_in_reverse >> (1344-data_len));
end
/*************************************************
*   Name :          PaddingRate_shake256
*   Description:    Padding Step1(shake256) -> padding Block size(r)
*************************************************/
wire [1343:0] Pad5=(8'h80 << 1080) | (8'h1F << data_len) | (data_in_reverse >> (1344-data_len)) ;
wire [1343:0] Pad6=(data_in_reverse >> (1344-data_len));
always @(*) begin
    if (mode_in == 2'd3 && data_len <  11'd1088)
        PaddingRate_shake256 = Pad5[1087:0] ;
    else 
        PaddingRate_shake256 = Pad6[1087:0] ;
end
/*************************************************
*   Name :          data
*   Description:    Padding Step2(finish) -> padding zero to reach 1600bits and output 
*************************************************/
always @(*) begin
    if (mode_in == 2'd0 )
        data = {512'b0, PaddingRate_sha256};
    else if (mode_in == 2'd1 )
        data = {1024'b0, PaddingRate_sha512};
    else if (mode_in == 2'd2)
        data =  {256'b0, PaddingRate_shake128}; 
    else if (mode_in == 2'd3)
        data = {512'b0, PaddingRate_shake256}; 
    else 
        data= 1600'b0;
end

/*************************************************
*   Name :          input_buffer
*   Description:    To distinguish the stage of first absorb by counting 8 cycles
*                   15 0 1 2 3 4 5 6 7 8 8 8 8 8 ...  
*************************************************/
always @(posedge clk or posedge rst) begin
    if(rst)
        input_buffer <= 4'd15;
    else if(input_buffer != 4'd8)
        input_buffer <= input_buffer + 4'd1;
end
/*************************************************
*   Name :          in_finish_buffer (7bits)
*   Description:    To buffer in_finish 8 cycles
*                   -If all slices of this message is inputed, in_finish will be 0//?include current input
*************************************************/
always @(posedge clk or posedge rst) begin
    if(rst)
        in_finish_buffer <= 8'b11111111;
    else if(input_buffer == 4'd8 && out_valid && if_sqeeze_enough)
        in_finish_buffer <= {in_finish_buffer[6:0],1'b1};
    else if(input_buffer < 4'd8 || (out_valid && if_sqeeze_enough) || (!in_finish_buffer[7]))
        in_finish_buffer <= {in_finish_buffer[6:0],in_finish};
    else if((out_valid && (!if_sqeeze_enough) || in_finish_buffer[7]))
        in_finish_buffer <= {in_finish_buffer[6:0],in_finish_buffer[7]};
end
/*************************************************
*   Name :          out_length_buffer (13bits * 8)
*   Description:    To buffer out_length 8 cycles
*                   -If all slices of this message is inputed, out_length will be 0//?exclude current input
*                   -out_length_buffer[7]=1 -> output data is meaningful        
*************************************************/
always @(posedge clk or posedge rst) begin
    if(rst)
        for (idx = 0 ; idx <8 ; idx = idx +1)begin
            out_length_buffer[idx] <=  13'b0;
        end
    else if(input_buffer == 4'd8 && (out_valid && if_sqeeze_enough)) begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
            out_length_buffer[idx+1] <=  out_length_buffer[idx];
        end
        out_length_buffer[0] <= 13'b0; 
    end
    else if(input_buffer != 4'd8 || (out_valid && if_sqeeze_enough)) begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
            out_length_buffer[idx+1] <=  out_length_buffer[idx];
        end
        out_length_buffer[0] <= length_buffer;
    end
    else if(out_valid && (!if_sqeeze_enough)  )begin
        for (idx =0 ; idx <7 ; idx = idx +1)begin
            out_length_buffer[idx+1] <=  out_length_buffer[idx];
        end
        out_length_buffer[0] <= out_length_buffer[7] - rate_in;
    end
    else begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
            out_length_buffer[idx+1] <=  out_length_buffer[idx];
        end
        out_length_buffer[0] <=  out_length_buffer[7];
    end
end
/*************************************************
*   Name :          out_valid
*   Description:    current slice is squeezed completely and output is valid 
*                   -in_finish_buffer[7]=1 -> current stage is squeeze 
*                   -out_length_buffer[7]=1 -> output data is meaningful     
*************************************************/
always @(*) begin
        out_valid = in_finish_buffer[7] && out_length_buffer[7] && input_buffer == 4'd8;
end
/*************************************************
*   Name :          finish
*   Description:    final slice is squeezed completely and output is valid
*                   -if_sqeeze_enough=1     -> out_length <= Rate 
*                   -in_finish_buffer[7]=1  -> current stage is squeeze 
*                   -out_length_buffer[7]=1 -> output data is meaningful     
*************************************************/
always @(*) begin
    if(input_buffer == 4'd8)
        finish = if_sqeeze_enough &&  in_finish_buffer[7] && out_length_buffer[7];//&& input_buffer == 4'd8
    else 
        finish = 1'b0;
end

/*************************************************
*   Name :          out_length
*   Description:    Decide out_length according to mode
*                   -mode0(sha256) -> 256
*                   -mode1(sha512) -> 256
*                   -mode2(shake256) -> out_length_buffer[7]
*                   -mode3(shake512) -> out_length_buffer[7]  
*************************************************/
always @(*) begin
    if(if_sqeeze_enough && (mode_in== 2'd2 || mode_in== 2'd3))
        out_length = out_length_buffer[7][10:0];
    else if (mode_in == 2'd0)
        out_length =  11'd256;
    else if (mode_in == 2'd1)
        out_length = 11'd512;
    else 
        out_length = rate_in;
end

endmodule
