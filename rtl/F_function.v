`include "../rtl/f_sub.v"
module F_function(
    input [1599:0] F_input,
    input clk,
    input rst,
    output [1599:0] F_output
);
//region reg wire
reg [1599:0] f_buffer [7:0];

/*************************************************
*   Name :          f_wire
*   Description:    assign 1 round f_sub output to f_wire
*************************************************/

wire [1599:0] f1_wire;
wire [1599:0] f2_wire;
wire [1599:0] f3_wire;
wire [1599:0] f4_wire [6:0];
wire [1599:0] f5_wire [6:0];
wire [1599:0] f6_wire [6:0];

/*************************************************
*   Name :          F_output
*   Description:    assign 24 rounds f_sub output to F_output
*************************************************/

assign F_output = f_buffer[7];

wire [7:0] const [23:0];

/*************************************************
*   Name :          const
*   Description:    assign 24 rounds 8 bits constant to const
*************************************************/

assign const[0]=8'h01;
assign const[1]=8'h32;
assign const[2]=8'hba;
assign const[3]=8'he0;
assign const[4]=8'h3b;
assign const[5]=8'h41;
assign const[6]=8'hf1;
assign const[7]=8'ha9;
assign const[8]=8'h1a;
assign const[9]=8'h18;
assign const[10]=8'h69;
assign const[11]=8'h4a;
assign const[12]=8'h7b;
assign const[13]=8'h9b;
assign const[14]=8'hb9;
assign const[15]=8'ha3;
assign const[16]=8'ha2;
assign const[17]=8'h90;
assign const[18]=8'h2a;
assign const[19]=8'hca;
assign const[20]=8'hf1;
assign const[21]=8'hb0;
assign const[22]=8'h41;
assign const[23]=8'he8;



//endregion
integer i1;

/*************************************************
*   Name :          f_buffer
*   Description:    assign 3 rounds f_sub output to f_buffer
*************************************************/

always@(posedge rst or posedge clk) begin
    if (rst)begin
        for(i1=0; i1<8; i1=i1+1)begin
            f_buffer[i1] <= 1600'b0;
        end
    end
    else begin
        f_buffer[0] <= f3_wire;
        for(i1=1; i1<8; i1=i1+1)begin
            f_buffer[i1] <= f6_wire[i1-1];
        end
    end
end
f_sub fsub1(	
    .absorb_outcome			(F_input),
    .rc                     (const[0]),
    .s_out					(f1_wire)
);
f_sub fsub2(	
    .absorb_outcome			(f1_wire),
    .rc                     (const[1]),
    .s_out					(f2_wire)
);
f_sub fsub3(
    .absorb_outcome			(f2_wire),
    .rc                     (const[2]),
    .s_out					(f3_wire)
);
genvar i;
generate
	for(i=3; i<=21; i=i+3)begin : generate_block_f_function
			f_sub fsub4(	
			.absorb_outcome			(f_buffer[(i-3)/3]),
			.rc                     (const[i]),
            .s_out					(f4_wire[(i-3)/3])
			);
            f_sub fsub5(	
            .absorb_outcome			(f4_wire[(i-3)/3]),
            .rc                     (const[i+1]),
            .s_out					(f5_wire[(i-3)/3])
            );
            f_sub fsub6(
            .absorb_outcome			(f5_wire[(i-3)/3]),
            .rc                     (const[i+2]),
            .s_out					(f6_wire[(i-3)/3])
            );
	end 
endgenerate

endmodule