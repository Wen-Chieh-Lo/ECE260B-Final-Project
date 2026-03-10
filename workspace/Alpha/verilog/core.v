// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module core (clk, reset, set_mode, mode_in, start, 
			mem_in, inst_ext,
			sum_in, sum_out, 
            out, status);

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+4;
parameter sfp_out_shift = 7;
parameter pr = 8;
localparam VEC_LEN      = 4'd8;


input  [bw_psum+3:0] sum_in;
output [bw_psum+3:0] sum_out;
output [bw_psum*col-1:0] out;

input  [pr*bw-1:0] mem_in;
input  [5:0]       inst_ext;
input  clk;
input  reset;
input        start;
output [2:0] status;  // {busy, qmem_locked, kmem_locked} from controller
input 		set_mode;
input [2:0] 	mode_in;



// ########################################### //
//               Wires & Regs                  //
// ########################################### //
// ######  Memories  ###########
reg   					kmem_rd; 
reg   					kmem_wr; 
reg   [3:0] 	  		kmem_add;
reg   [pr*bw-1:0] 		kmem_in;
wire  [pr*bw-1:0] 		kmem_out;
reg   					qmem_rd; 
reg   					qmem_wr; 
reg   [3:0] 	  		qmem_add;
reg   [pr*bw-1:0] 		qmem_in;
wire  [pr*bw-1:0] 		qmem_out;
reg  					pmem_rd; 
reg  					pmem_wr;       
reg   [3:0] 			pmem_add;
reg   [bw_psum*col-1:0] pmem_in;
wire  [bw_psum*col-1:0] pmem_out;

// #####  MAC & OFIFO #############
wire  [1:0]				mac_inst;
wire  [pr*bw-1:0]  		mac_in;
wire  [bw_psum*col-1:0] array_out;
wire 					fifo_valid;
reg 					fifo_rd;
wire  [col-1:0] 		fifo_wr;
wire  [bw_psum*col-1:0] fifo_out;

// #####   Controller   ###########
wire [2:0] mem_ext_ctrl_sel;
wire [7:0] inst_ctrl;
reg  [2:0]	mode; // {op_mode, sfp_write_to_kmem, sfp_write_to_pmem}, default QK+norm, sfp->kmem only


// ######    SFP    ###############
wire  [bw*col-1:0] 	sfp_out;
wire  [bw_psum*col-1:0] sfp_out_BW_extended;
reg   [4:0]			sfp_counter, sfp_counter_nxt;
wire   save_done;
wire sfp_acc;                         // SFP accumulating for normalization
wire sfp_div;                         // SFP dividing for normalization
wire sfp_fifo_ext_rd;                 // SFP start to output FIFO -> sfp_sum_out -> other core, not used in single core
wire [bw_psum+3:0] sfp_sum_in;        // SFP sum input, is always 0 in single port
wire [bw_psum+3:0] sfp_sum_out;       // SFP sum output, float in single core
reg  result_wr;
reg  [3:0] result_addr, result_addr_nxt;


// #####   Unconcatenate  ###########
assign   mac_inst = {mac_exec, mac_load};

wire     kmem_ext_wr_sel, qmem_ext_wr_sel, pmem_ext_rd_sel;
assign   kmem_ext_wr_sel = mem_ext_ctrl_sel[2];
assign   qmem_ext_wr_sel = mem_ext_ctrl_sel[1];
assign   pmem_ext_rd_sel = mem_ext_ctrl_sel[0];

wire 	 mac_load, mac_exec, qmem_rd_ctrler, kmem_rd_ctrler;
wire  [3:0] qkmem_add_ctrler;
assign qmem_rd_ctrler   = inst_ctrl[7];
assign kmem_rd_ctrler   = inst_ctrl[6];
assign qkmem_add_ctrler = inst_ctrl[5:2];
assign mac_exec  		= inst_ctrl[1];
assign mac_load  		= inst_ctrl[0];

wire op_mode, sfp_write_to_kmem, sfp_write_to_pmem;
assign op_mode     			 = mode[2];
assign sfp_write_to_kmem     = mode[1];
assign sfp_write_to_pmem     = mode[0];

wire  [1:0]        mem_cmd_ext;
wire  [3:0]        addr_ext;
assign addr_ext    = inst_ext[5:2];
assign mem_cmd_ext = inst_ext[1:0];

genvar i;
generate
	for(i=0; i<col; i=i+1)begin
		assign sfp_out_BW_extended[i*bw_psum +: bw_psum] = {{(bw_psum-bw){1'b0}}, sfp_out[i*bw +: bw]};
	end
endgenerate





// ########################################### //
//       External Mem Command Decode           //
// ########################################### //
localparam EXT_CMD_NO_OP   = 2'b00;
localparam EXT_CMD_KMEM_WR = 2'b01;
localparam EXT_CMD_QMEM_WR = 2'b10;
localparam EXT_CMD_PMEM_RD = 2'b11;

wire kmem_wr_ext, qmem_wr_ext, pmem_rd_ext;
assign kmem_wr_ext = (mem_cmd_ext==EXT_CMD_KMEM_WR);
assign qmem_wr_ext = (mem_cmd_ext==EXT_CMD_QMEM_WR);
assign pmem_rd_ext = (mem_cmd_ext==EXT_CMD_PMEM_RD);

localparam OP_MODE_MULT_NORM = 1'b0;
localparam OP_MODE_MULT		 = 1'b1;


// ########################################### //
//             Memory Control Logic            //
// ########################################### //
// KMEM write: external or by SFP 
//      read : when mac load
always @(*) begin
	if(kmem_ext_wr_sel)begin
		kmem_wr  = kmem_wr_ext;
		kmem_rd  = 1'b0;
		kmem_add = addr_ext;
		kmem_in  = mem_in;
	end
	else if(kmem_rd_ctrler)begin
		kmem_wr  = 1'b0;
		kmem_rd  = 1'b1;
		kmem_add = qkmem_add_ctrler;
		kmem_in  = mem_in;             //Don't care
	end
	else if(op_mode==OP_MODE_MULT_NORM && sfp_write_to_kmem && result_wr) begin //SFP write
		kmem_wr  = 1'b1;
		kmem_rd  = 1'b0;
		kmem_add = result_addr;
		kmem_in  = sfp_out;
	end
	else begin
		kmem_wr  = 1'b0;
		kmem_rd  = 1'b0;
		kmem_add = qkmem_add_ctrler;  //Don't care
		kmem_in  = mem_in;            //Don't care
	end
end
// QMEM write: external
//      read : when mac exec
always @(*) begin
	qmem_in  = mem_in;
	if(qmem_ext_wr_sel)begin
		qmem_wr  = qmem_wr_ext;
		qmem_rd  = 1'b0;
		qmem_add = addr_ext;
	end
	else if(qmem_rd_ctrler)begin 
		qmem_wr  = 1'b0;
		qmem_rd  = 1'b1;
		qmem_add = qkmem_add_ctrler;
	end
	else begin 
		qmem_wr  = 1'b0;
		qmem_rd  = 1'b0;
		qmem_add = addr_ext;        //Don't care
	end
end
// PMEM write: sfp / fifo
//      read : external
always @(*) begin
	if(pmem_ext_rd_sel)begin
		pmem_rd  = pmem_rd_ext;
		pmem_wr  = 1'b0;
		pmem_add = addr_ext;
		pmem_in  = fifo_out; 		//Don't Care
	end
	else if (op_mode==OP_MODE_MULT && result_wr) begin
		pmem_rd  = 1'b0;
		pmem_wr  = 1'b1;
		pmem_add = result_addr;
		pmem_in  = fifo_out;
	end
	else if(op_mode==OP_MODE_MULT_NORM && sfp_write_to_pmem && result_wr)begin
		pmem_rd  = 1'b0;
		pmem_wr  = 1'b1;
		pmem_add = result_addr;
		pmem_in  = sfp_out_BW_extended;


	end
	else begin     
		pmem_rd  = 1'b0;
		pmem_wr  = 1'b0;
		pmem_add = result_addr;  //Don't care
		pmem_in  = fifo_out;     //Don't care
	end
end

// ########################################### //
//         Mem Out Data flow                   //
// ########################################### //
assign mac_in  = mac_load_D1 ? kmem_out : 
				 mac_exec_D1 ? qmem_out : {(pr*bw-1){1'b0}};
assign out     = pmem_out;


// ########################################### //
//          SFP & result save logic            //
// ########################################### //
assign save_done = (result_addr==VEC_LEN);
always @(*) begin
	// fifo_rd:   pop the current fifo_out @next clk edge
	// result_wr: write the current fifo_out to memory
	if(op_mode==OP_MODE_MULT)begin
		result_wr = fifo_valid;
		fifo_rd = fifo_valid;
	end
	else begin //OP_MODE_MULT_NORM
		result_wr = sfp_out_valid;
		fifo_rd = sfp_out_valid;
	end
end

always @(*) begin
	if(result_wr)begin
		result_addr_nxt = result_addr + 4'd1;
	end
	else begin
		result_addr_nxt = result_addr;
	end
end


 // Min interval that doesn't result in data/ctrl hazard
`ifdef SFP_LONGDIV
	localparam SFP_IN_INTERVAL = 5'd14;
`elsif VANILLA
	localparam SFP_IN_INTERVAL = 5'd7;
`endif

always @(*) begin
	if(!fifo_valid || sfp_counter == SFP_IN_INTERVAL)begin
		sfp_counter_nxt = 5'd0;
	end
	else begin
		sfp_counter_nxt = sfp_counter + 5'd1;
	end
end

assign sfp_fifo_ext_rd = 1'b0;    // unused in single core
assign sfp_sum_in = {bw_psum+4{1'b0}}; // unused in single core
assign sfp_acc = (sfp_counter==5'd1) || (sfp_counter==5'd2);
assign sfp_div = (sfp_counter==5'd5) || (sfp_counter==5'd6);



always @(posedge clk ) begin
	if(reset)begin
		mode <= 3'b100; //pure matrix mult, output to pmem
	end	
	else if(set_mode)begin
		mode <= mode_in;
	end
	else begin
		mode <= mode;
	end
end




controller controller_instance (
	.clk(clk),
	.reset(reset),
	.start(start),
	.mode_from_reg_map(mode),
	.status_to_reg_map(status),
	.save_done(save_done),
	.inst_ctrl(inst_ctrl),
    .mem_ext_ctrl_sel(mem_ext_ctrl_sel)
);

mac_array #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) mac_array_instance (
        .in(mac_in), 
        .clk(clk), 
        .reset(reset), 
        .inst(mac_inst),     
        .fifo_wr(fifo_wr),     
		.out(array_out)
);

ofifo #(.bw(bw_psum), .col(col))  ofifo_inst (
        .reset(reset),
        .clk(clk),
        .in(array_out),
        .wr(fifo_wr),
        .rd(fifo_rd),
        .o_valid(fifo_valid),
        .out(fifo_out)
);


sram_w16 #(.sram_bit(pr*bw)) qmem_instance (
        .CLK(clk),
        .D(mem_in),
        .Q(qmem_out),
        .CEN(!(qmem_rd||qmem_wr)),
        .WEN(!qmem_wr), 
        .A(qmem_add)
);

sram_w16 #(.sram_bit(pr*bw)) kmem_instance (
        .CLK(clk),
        .D(kmem_in),
        .Q(kmem_out),
        .CEN(!(kmem_rd||kmem_wr)),
        .WEN(!kmem_wr), 
        .A(kmem_add)
);

sram_w16 #(.sram_bit(col*bw_psum)) psum_mem_instance (
        .CLK(clk),
        .D(pmem_in),
        .Q(pmem_out),
        .CEN(!(pmem_rd||pmem_wr)),
        .WEN(!pmem_wr), 
        .A(pmem_add)
);


sfp_row #(.col(col), .bw(bw), .bw_psum(bw_psum), .out_shift(sfp_out_shift)) sfp_instance (
	.clk(clk),
	.reset(reset),
	.acc(sfp_acc),
	.div(sfp_div),
	.fifo_ext_rd(sfp_fifo_ext_rd),
	.sum_in(sfp_sum_in),
	.sum_out(sfp_sum_out),
	.sfp_in(fifo_out),
	.sfp_out(sfp_out),
	.sfp_out_valid(sfp_out_valid)
);



//   //////////// For printing purpose ////////////
//   always @(posedge clk) begin
//       if(pmem_wr)
//          $display("Memory write to PSUM mem add %x %x ", pmem_add, pmem_in); 
//   end

  ////////// For printing purpose ////////////
//   always @(posedge clk) begin
//       if(result_wr && sfp_write_to_kmem)
// 		 $display("Write to kmem: %7d %7d %7d %7d %7d %7d %7d %7d",
// 		 	kmem_in[7*bw +: bw], kmem_in[6*bw +: bw], 
// 			kmem_in[5*bw +: bw], kmem_in[4*bw +: bw], 
// 			kmem_in[3*bw +: bw], kmem_in[2*bw +: bw], 
// 			kmem_in[1*bw +: bw], kmem_in[0*bw +: bw]
// 		 ); 
		 
//   end

	reg mac_load_D1, mac_exec_D1;
	always @(posedge clk ) begin
		mac_load_D1 <= mac_load;
		mac_exec_D1 <= mac_exec;
	end


	
  always @(posedge clk ) begin
	if(reset)begin
		result_addr <= 4'd0;
		sfp_counter <= 4'd0;
	end
	else begin
		result_addr <= result_addr_nxt;
		sfp_counter <= sfp_counter_nxt;
	end
  end

endmodule
