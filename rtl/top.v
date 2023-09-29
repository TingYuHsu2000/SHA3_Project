`include "../rtl/controller.v"
`include "../rtl/F_function.v"
`include "../rtl/slice.v"


module top(
  input            clk,
  input            rst,
  input  [   1:0]  mode_in,
  input  [6399:0]  data_in,
  input [12:0]     data_len,
  input  [  12:0]  length,
  input            in_finish,
  output wire [1343:0]  data_out,
  output wire [   1:0]  mode_out,
  output wire          out_valid,
  output wire [  10:0]  out_length,
  output wire      finish
);

//wire,reg

wire [1343:0] part_data;
wire [10:0] part_data_len;
wire [1:0] mode_out_slice;
wire part_data_in_finish;
wire [10:0] rate_out;
slice slice(
    .clk        (clk),
    .rst        (rst),
    .mode_in    (mode_in),
    .data_in    (data_in),
    .data_len    (data_len),
    .in_finish  (in_finish),
    .rate_out    (rate_out),
    .part_data       (part_data),
    .part_data_len  (part_data_len),
    .mode_out_slice     (mode_out_slice),
    .part_data_in_finish (part_data_in_finish)
);


wire [1599:0] F_in_wire;
wire [1599:0] F_out_wire;
wire [1599:0] s_in;
wire [1599:0] data;
wire sabsorb_or_squeeze;
wire zero_or_fout;

controller controller(
    .clk        (clk),
    .rst        (rst),
    .mode_in    (mode_out_slice),
    .data_in    (part_data),
    .data_len    (part_data_len),
    .length     (length),
    .in_finish  ( part_data_in_finish),
    .rate_in    (rate_out),
    .data       (data),
    .mode_out_controller   (mode_out),
    .out_valid  (out_valid),
    .finish     (finish),
    .out_length (out_length),
    .absorb_or_squeeze (absorb_or_squeeze),
    .zero_or_fout(zero_or_fout) // s_out selector(xor zero or f_out) 0: zero, 1:f_out
);
/*
sig absorb_or_squeeze
1: absorb
0: squeeze
*/
integer j;
reg [1343:0] data_out_temp;
assign data_out = data_out_temp >> (1344 - out_length);


// data_out
always @(*) begin
    for (j = 0 ; j < 1344 ; j = j + 8)begin
            data_out_temp[(1343-j) -: 4] =  F_out_wire[(j+4) +: 4];
            data_out_temp[(1343-j-4) -: 4] =  F_out_wire[j +: 4];
        end 
end


assign s_in = zero_or_fout ?  F_out_wire :  1600'd0;
//assign F_in_wire = squeeze_enough ? data^s_in : F_out_wire ;

assign F_in_wire = absorb_or_squeeze ? F_out_wire:  data ^ s_in ;
F_function F_function(
    .clk(clk),
    .rst(rst),
    .F_input(F_in_wire),
    .F_output(F_out_wire)
);

endmodule