// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module core (clk, reset, set_mode, mode_in, start, 
			mem_in, inst_ext,
			sum_in, sum_in_valid, sum_out, 
            out, status);

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+4;
parameter sfp_out_shift = 7;
parameter pr = 8;
localparam VEC_LEN      = 4'd8;


input  [bw_psum+3:0] sum_in;
input                sum_in_valid;
output [bw_psum+3:0] sum_out;
output [bw_psum*col-1:0] out;

input  [pr*bw-1:0] mem_in;
input  [5:0]       inst_ext;
input  clk;
input  reset;
input        start;
output [3:0] status;  // {busy, qmem_locked, kmem_locked, pmem_locked} from controller
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
wire 					ofifo_valid;
wire  [col-1:0] 		fifo_wr;
wire  [bw_psum*col-1:0] fifo_out;

// #####   Controller   ###########
wire [2:0] mem_ext_ctrl_sel;
wire [7:0] inst_ctrl;
reg  [2:0]	mode; // {op_mode, sfp_write_to_kmem, sfp_write_to_pmem}, default QK+norm, sfp->kmem only
wire 		busy;
assign 		busy = status[3];
wire  save_done;

// ######    SFP    ###############
wire acc_start, div_start;
wire acc_done, div_done, div_busy;
wire  [bw_psum+3:0] sfp_sum_in;
wire  [bw_psum+3:0] sfp_sum_out;
wire  [col*bw_psum-1:0] sfp_in;
wire  [bw*col-1:0] 	sfp_div_out;
wire  [bw_psum*col-1:0] sfp_out_BW_extended;

reg  [3:0] acc_done_cnt, div_done_cnt;
reg        acc_all_done;
reg        div_all_done;
reg  [3:0] result_addr, result_addr_nxt;

reg  [1:0] sfp_div_state, sfp_div_state_nxt; // for controlling PMEM rd/wr when SFP is involved. PMEM has 1 cyc read latency.
localparam [1:0] S_PMEM_read_bubble = 2'b00; //Initial State
localparam [1:0] S_divident_ready = 2'b01;
localparam [1:0] S_wait_div_done = 2'b10;


assign acc_start = (op_mode==OP_MODE_MULT_NORM) && !acc_all_done && ofifo_valid; // start acc when the first valid data comes in, and we haven't finished all acc
assign div_start = !div_all_done && acc_all_done && !div_busy &&(sfp_div_state==S_divident_ready) && sum_in_valid;
assign sum_out = sfp_sum_out;
assign sfp_in = pmem_out;
// start div when all acc are done, and we haven't finished all div


// #####   Unconcatenate  ###########

wire     kmem_ext_wr_sel, qmem_ext_wr_sel, pmem_ext_rd_sel;
assign   kmem_ext_wr_sel = mem_ext_ctrl_sel[2];
assign   qmem_ext_wr_sel = mem_ext_ctrl_sel[1];
assign   pmem_ext_rd_sel = mem_ext_ctrl_sel[0];

wire 	 mac_load, mac_exec, qmem_rd_ctrler, kmem_rd_ctrler;
reg 	 mac_load_D1, mac_exec_D1;
assign   mac_inst = {mac_exec, mac_load};
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
		assign sfp_out_BW_extended[i*bw_psum +: bw_psum] = {{(bw_psum-bw){1'b0}}, sfp_div_out[i*bw +: bw]};
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
	else if(op_mode==OP_MODE_MULT_NORM && sfp_write_to_kmem && div_done) begin //SFP div write if sfp_write_to_kmem is set, only for norm mode and when we have valid result to write
		kmem_wr  = 1'b1;
		kmem_rd  = 1'b0;
		kmem_add = result_addr;
		kmem_in  = sfp_div_out;
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
// PMEM write: ofifo / sfp_div
//      read : external / sfp_div
always @(*) begin
	if(pmem_ext_rd_sel)begin
		pmem_rd  = pmem_rd_ext;
		pmem_wr  = 1'b0;
		pmem_add = addr_ext;
		pmem_in  = fifo_out; //Don't Care
	end else if(!acc_all_done) begin // Mac result always goes to PMEM first, whether it's for norm or not. For norm, we will read it back and feed to SFP later.
		pmem_rd  = 1'b0;
		pmem_wr  = ofifo_valid;
		pmem_add = result_addr; // increment address when we have valid data from ofifo
		pmem_in  = fifo_out;
	end else begin // acc_all_done implies OP_Mode_MULT_NORM, and we are in div phase.
		// read PMEM when !div_done, write to PMEM when div_done (if only sfp_write_to_pmem is set)
		if(div_all_done)begin 
			pmem_rd  = 1'b0;
			pmem_wr  = 1'b0;
			pmem_add = result_addr; //Don't care
			pmem_in  = fifo_out;    //Don't care
		end else if(!div_done)begin
			pmem_rd  = 1'b1;
			pmem_wr  = 1'b0;
			pmem_add = result_addr; // increment address when div_done
			pmem_in  = fifo_out;    //Don't care
		end else begin
			pmem_rd  = 1'b0;
			pmem_wr  = sfp_write_to_pmem && div_done;
			pmem_add = result_addr; // increment address when div_done
			pmem_in  = sfp_out_BW_extended;
		end
	end
end

// ########################################### //
//         Mem Out Data flow                   //
// ########################################### //
assign mac_in  = mac_load_D1 ? kmem_out : 
				 mac_exec_D1 ? qmem_out : {(pr*bw-1){1'b0}};
assign out     = pmem_out;


// ########################################### //
// 	SFP related acc_done & div_done conuter    //
// ########################################### //
always @(posedge clk) begin
	if(reset || op_mode==OP_MODE_MULT) begin
		acc_done_cnt <= 0;
		acc_all_done <= 1'b0;
	end else begin
		if(acc_done) begin
			acc_done_cnt <= acc_done_cnt + 1;
			if(acc_done_cnt==VEC_LEN-1) begin
				acc_all_done <= 1'b1;
			end else begin
				acc_all_done <= acc_all_done;
			end
		end else begin
			acc_done_cnt <= acc_done_cnt;
			acc_all_done <= acc_all_done;
		end

	end

	if(reset) begin
		div_done_cnt <= 0;
		div_all_done <= 1'b0;
	end else begin
		if(div_done) begin
			div_done_cnt <= div_done_cnt + 1;
			if(div_done_cnt==VEC_LEN-1) begin
				div_all_done <= 1'b1;
			end else begin
				div_all_done <= div_all_done;
			end
		end else begin
			div_done_cnt <= div_done_cnt;
			div_all_done <= div_all_done;
		end
	end
end


always @(*) begin
	if(!acc_all_done)begin
		sfp_div_state_nxt = S_PMEM_read_bubble; // stay in bubble state until all acc are done
	end
	else begin // acc_all_done. Start div and wait for div to be done
		case(sfp_div_state)
			S_PMEM_read_bubble: begin
				sfp_div_state_nxt = S_divident_ready; // after one cycle bubble, we can start div
			end
			S_divident_ready: begin
				if(div_start && div_done)begin
					sfp_div_state_nxt = S_PMEM_read_bubble; // if div is done in the same cycle as start, we can jump to next bubble
				end
				else if(div_start && !div_done)begin
					sfp_div_state_nxt = S_wait_div_done; // if div is not done in the same cycle as start, we need to wait for div to be done before starting next div, which means we need to insert bubble cycles in between
				end
				else begin
					sfp_div_state_nxt = S_divident_ready; // if div is not started, stay in this state and wait for div to start
				end
			end
			S_wait_div_done: begin
				if(div_done)begin
					sfp_div_state_nxt = S_PMEM_read_bubble; // if div is done, we can jump to next bubble
				end
				else begin
					sfp_div_state_nxt = S_wait_div_done; // if div is not done, stay in this state and wait for div to be done
				end
			end
			default: sfp_div_state_nxt = S_PMEM_read_bubble;
		endcase
	
	end

end





// ########################################### //
//          SFP & result save logic            //
// ########################################### //
assign save_done = (op_mode==OP_MODE_MULT) ? (result_addr==VEC_LEN) : (div_all_done && (result_addr==VEC_LEN));



always @(*) begin
	if(acc_all_done && (div_done_cnt==0) && !div_done)begin
		result_addr_nxt = 4'd0; // this reg will be used for both acc and div result writing, so we need to reset it when we finish acc and start div
	end
	else if(ofifo_valid || div_done)begin
		result_addr_nxt = result_addr + 4'd1; // increment address when we have valid data from ofifo or when we finish one div
	end
	else begin
		result_addr_nxt = result_addr;
	end
end



assign sfp_fifo_ext_rd = 1'b0;    // unused in single core
assign sfp_sum_in = {bw_psum+4{1'b0}}; // unused in single core



always @(posedge clk ) begin
	if(reset)begin
		mode <= 3'b100; //pure matrix mult, output to pmem
	end	
	else if(set_mode && !busy)begin
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
	.mode(mode),
	.status(status),
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
        .rd(ofifo_valid),
        .o_valid(ofifo_valid),
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
	.acc_start(acc_start),
	.acc_done(acc_done),
	.div_start(div_start),
	.div_done(div_done),
	.div_busy(div_busy),
	.sum_in(sfp_sum_in),
	.sum_out(sfp_sum_out),
	.sfp_in(sfp_in),
	.sfp_div_out(sfp_div_out)
);



	
	always @(posedge clk ) begin
		mac_load_D1 <= mac_load;
		mac_exec_D1 <= mac_exec;
	end


	
  always @(posedge clk ) begin
	if(reset)begin
		result_addr <= 4'd0;
	end
	else begin
		result_addr <= result_addr_nxt;
	end
  end

  always @(posedge clk ) begin
	if(reset)begin
		sfp_div_state <= S_PMEM_read_bubble;
	end
	else begin
		sfp_div_state <= sfp_div_state_nxt;
	end
  end

endmodule