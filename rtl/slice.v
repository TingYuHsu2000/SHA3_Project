// function: slice the input data to controller
// input : the all input (most 800 bytes)
// output:  part of input (1344 bit)
///

module slice(
  input            clk,
  input            rst,
  input  [   1:0]  mode_in,
  input  [6399:0]  data_in,
  input [12:0]     data_len,
  input            in_finish,
  output        [10:0] rate_out,
  output   reg  [1343:0]  part_data,
  output  reg [10:0]    part_data_len,
  output  [ 1:0]  mode_out_slice,
  output    reg   part_data_in_finish

);

integer idx;

reg [10:0] rate;
reg [2:0] input_counter;
reg eight_input_finish; 
reg input_8_flag;
reg [5823:0] input_data_buffer [7:0]; 
reg [12:0] input_data_len_s [7:0];    
reg [1:0]  input_mode_s [7:0]; 
reg [12:0] input_rate_s [7:0]; 
reg if_absorb_again_buffer [7:0]; 
wire [6399 : 0] current_all_data ; 
wire [10:0] current_rate;
wire [12:0] current_data_len;
wire [ 1:0] mode_buf = mode_in;

/*************************************************
*   Name :          rate_out
*   Description:    when eight messages are inputted 
*   the current rate is inputting one, if the eight datas all inputted,
*   get the rate stored in the buffer : input_rate_s[7] 
*************************************************/
assign rate_out = !eight_input_finish ? rate : input_rate_s[7];

/*************************************************
*   Name :          mode_out_slice
*   Description:    when eight messages are inputted 
*   the current mode is inputting one, if the eight datas all inputted,
*   get the mode stored in the buffer : input_mode_s[7] 
*************************************************/
assign mode_out_slice = !eight_input_finish ? mode_in : input_mode_s[7];

/*************************************************
*   Name :          current_all_data
*   Description:    when eight messages are inputted 
*   the current data is inputting one, if the eight datas all inputted,
*   get the data stored in the buffer : input_data_buffer[7] 
*************************************************/
assign current_all_data =  !eight_input_finish ?  data_in : input_data_buffer[7]; 

/*************************************************
*   Name :          current_rate
*   Description:    when eight messages are inputted 
*   the current rate is depend on the inputting one, if the eight datas all inputted,
*   get the rate stored in the buffer: input_rate_s[7] 
*************************************************/
assign current_rate = !eight_input_finish ? rate : input_rate_s[7];

/*************************************************
*   Name :          current_data_len
*   Description:    when eight messages are inputted 
*   the current data_len is the inputting one, if the eight datas all inputted,
*   get the data_len stored in the buffer: input_data_len_s[7] 
*************************************************/
assign current_data_len = !eight_input_finish ? data_len : input_data_len_s[7];

/*************************************************
*   Name :          part_data
*   Description:   If the length of the message is longer than rate,
*   the part data's lenhth is rate, otherwise, the length is the whole length 
*   of message.
*************************************************/
always @(*) begin
    if(current_data_len >= current_rate)
        part_data = current_all_data >> (current_data_len - current_rate);
    else 
        part_data  = current_all_data;
end

/*************************************************
*   Name :          input_8_flag
*   Description:   the flag that  record the seventh message is inputted.
*************************************************/
always @(posedge clk or posedge rst) begin
    if(rst)
        input_8_flag <= 1'b0;
    else if (input_counter == 3'd6 && in_finish) 
        input_8_flag <= 1'b1;
        
end

/*************************************************
*   Name :          eight_input_finish
*   Description:   the flag that  record the whole ehught messages are inputted.
*************************************************/
always @(posedge clk or posedge rst) begin
    if(rst)
        eight_input_finish <= 1'b0;
    else if (!eight_input_finish && (input_counter == 3'd7) && input_8_flag) 
        eight_input_finish <= 1'b1;
        
end

/*************************************************
*   Name :          input_counter
*   Description:   the counter count zero to seven to check the eight 
*   messages are all inputted.
*************************************************/
always @(posedge clk or posedge rst) begin
    if(rst)
        input_counter <= 3'd7;
    else 
        input_counter <=  input_counter == 3'd7 ? 3'd0 : input_counter + 3'd1;//!
end

/*************************************************
*   Name :          rate
*   Description:   Depending the diffrent modes, assign the rate.
*   - sha3-256 ---> 1088 bits
*   - sha3-512 ---> 576 bits
*   - shake-128 ---> 1344 bits
*   - shake-256 ---> 1088 bits
*************************************************/
always @(*) begin
    if (mode_in == 2'd0) // sha3-256
        rate =  11'd1088;
    else if (mode_in == 2'd1) // sha3-512
        rate = 11'd576;
    else if (mode_in == 2'd2) // shake-128
        rate = 11'd1344;
    else if (mode_in == 2'd3) // shake-256
        rate = 11'd1088;
    else 
        rate = 11'b0;

end

/*************************************************
*   Name :          input_data_len_s
*   Description:   Store the current eight messages' data_len,
*   it will minus current_rate when output a part_data to next level.
*   If the length is less than rate, buffer will store zero.
*************************************************/
always @(posedge clk or posedge rst) begin
    if(rst)
        for (idx = 0 ; idx <8 ; idx = idx +1)begin
            input_data_len_s[idx] <=  13'b0;
        end
    else if( (!eight_input_finish) && (current_data_len >= current_rate)) begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
            input_data_len_s[idx+1] <=  input_data_len_s[idx];
        end
        input_data_len_s[0] <= current_data_len - current_rate;
    end
    else if (input_data_len_s[7] >= current_rate)  begin//if(!input_finish_buffer[7] 
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
                input_data_len_s[idx+1] <=  input_data_len_s[idx];
            end
        input_data_len_s[0] <=  input_data_len_s[7] - current_rate;
    end
    else begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
                input_data_len_s[idx+1] <=  input_data_len_s[idx];
            end
        input_data_len_s [0] <=  13'd0; 
    end
end

/*************************************************
*   Name :          stored_data
*   Description:   the remain data  should be stored 
*************************************************/
wire [5823:0]stored_data = data_in & ((1'b1<< (current_data_len - current_rate))  -1);

/*************************************************
*   Name :         input_data_buffer
*   Description:   If the inputted data is longer than the rate,
*   the remain data should be stored will store in the input_data_buffer.
*************************************************/
always @(posedge clk or posedge rst) begin
    if(rst)
        for (idx = 0 ; idx <8 ; idx = idx +1)begin
            input_data_buffer[idx] <=  5824'b0;
        end
    else if (!eight_input_finish && (current_data_len < current_rate))begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
                input_data_buffer[idx+1] <=  input_data_buffer[idx];
            end
        input_data_buffer[0] <= 5824'b0;
    end
    else if(!eight_input_finish) begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
            input_data_buffer[idx+1] <=  input_data_buffer[idx];
        end
        input_data_buffer[0] <= stored_data;//!
    end
    else begin//if(!input_finish_buffer[7] 
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
            input_data_buffer[idx+1] <=  input_data_buffer[idx];
        end
        input_data_buffer[0] <=  input_data_buffer[7] ;
    end

end

/*************************************************
*   Name :        input_mode_s
*   Description:   while the eight messages are inputted, 
*   store their modes in buffers: input_mode_s
*************************************************/
// reg [1:0]  input_mode_s [7:0];
always @(posedge clk or posedge rst) begin
    if(rst)
        for (idx = 0 ; idx <8 ; idx = idx +1)begin
            input_mode_s[idx] <=  2'b0;
        end
    else if(!eight_input_finish) begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
            input_mode_s[idx+1] <=  input_mode_s[idx];
        end
        input_mode_s[0] <= mode_buf;
    end
    else begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
            input_mode_s[idx+1] <=  input_mode_s[idx];
        end
        input_mode_s[0] <=  input_mode_s[7];
    end
end

/*************************************************
*   Name :         input_rate_s
*   Description:   while the eight messages are inputted, 
*   store their rates in buffers:  input_rate_s
*************************************************/
always @(posedge clk or posedge rst) begin
    if(rst)
        for (idx = 0 ; idx <8 ; idx = idx +1)begin
            input_rate_s[idx] <=  13'b0;
        end
    else if(!eight_input_finish) begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
            input_rate_s[idx+1] <=  input_rate_s[idx];
        end
      input_rate_s[0] <= rate;
    end
    else begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
            input_rate_s[idx+1] <=  input_rate_s[idx];
        end
        input_rate_s[0] <=  input_rate_s[7];
    end

end

/*************************************************
*   Name :         if_absorb_again_buffer
*   Description:   If the inputted message's length is 
*   the integer times of the rate, it should be absorbed once
*   the buffer  records if the extra absorbing one has exacuted.
*************************************************/
always @(posedge clk or posedge rst) begin
    if(rst)
        for (idx = 0 ; idx <8 ; idx = idx +1)begin
            if_absorb_again_buffer[idx] <=  1'b0;
        end
    else if  (current_data_len == current_rate ) begin //!
    for (idx = 0 ; idx <7 ; idx = idx +1)begin
            if_absorb_again_buffer[idx+1] <=  if_absorb_again_buffer[idx];
        end
        if_absorb_again_buffer[0] <= 1'b1;
    end
    else if (if_absorb_again_buffer[7])begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
            if_absorb_again_buffer[idx+1] <=  if_absorb_again_buffer[idx];
        end
        if_absorb_again_buffer[0] <= 1'b0;
    end
    else begin
        for (idx = 0 ; idx <7 ; idx = idx +1)begin
            if_absorb_again_buffer[idx+1] <=  if_absorb_again_buffer[idx];
        end
        if_absorb_again_buffer[0] <= if_absorb_again_buffer[7];
    end
end

/*************************************************
*   Name :         part_data_len
*   Description:   the cuurent part_data length 
*************************************************/
always @(*) begin
    if (current_data_len >= current_rate)begin
        part_data_len = current_rate;
    end
    else if (!current_data_len)begin
        part_data_len = 11'b0;
    end 
    else 
        part_data_len = current_data_len[10:0];
end

/*************************************************
*   Name :         part_data_in_finish
*   Description:   If the part_data_len is less than rate, 
*   the finish flag will rise when the final output,
*   And if the extra absorbing state ends, the finish flag rise,too.  
*************************************************/
always @(*) begin
    if (( !input_data_len_s[7] ) && if_absorb_again_buffer[7])begin
        part_data_in_finish = 1'b1;
    end
    else 
        part_data_in_finish = (current_data_len < current_rate);
end

endmodule