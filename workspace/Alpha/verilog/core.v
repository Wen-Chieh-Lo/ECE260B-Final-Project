// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module core (clk, reset, set_mode, mode_in, start, 
			mem_in, inst_ext,
			sum_in, sum_in_valid, sum_in_fifo_pop, sum_out, sum_out_valid,
            out, status);

parameter col = 8;
parameter bw = 8;
parameter bw_psum = 2*bw+4;
parameter sfp_out_shift = 7;
parameter pr = 8;
localparam VEC_LEN      = 4'd8;


input  [bw_psum+3:0] sum_in;
input                sum_in_valid;    //indicates sum_in is valid, which means we have valid dividend for div in norm mode.
output				 sum_in_fifo_pop; //pop the fifo after we've used the sum_in. use div_start is fine.
output [bw_psum+3:0] sum_out;
output               sum_out_valid;   //writes ext async fifo
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
wire  [col-1:0] 		ofifo_wr;
wire  [bw_psum*col-1:0] ofifo_out;

// #####   Controller   ###########
wire [2:0] mem_ext_ctrl_sel;
wire [7:0] inst_ctrl;
reg  [2:0]	mode; // {op_mode, sfp_write_to_kmem, sfp_write_to_pmem}, default QK+norm, sfp->kmem only
wire 		busy;
assign 		busy = status[3];
wire  core_done;

// ######    SFP    ###############
wire acc_start, div_start;
wire acc_done, div_done, div_busy;
wire  [bw_psum+3:0] sfp_sum_in;
wire  [bw_psum+3:0] sfp_sum_out;
wire  [col*bw_psum-1:0] sfp_in;
wire  [bw*col-1:0] 	sfp_div_out;
wire  [bw_psum*col-1:0] sfp_out_BW_extended;

// ##### Post MAC Processing States  #######
localparam [1:0] S_MULT_ONLY = 2'b00;
localparam [1:0] S_MULT_NORM_ACC = 2'b01;
localparam [1:0] S_MULT_NORM_DIV = 2'b10;
localparam [1:0] S_DONE = 2'b11;
reg        [1:0] postMAC_state, postMAC_state_nxt;

// substates of S_MULT_NORM_DIV
localparam [1:0] SUB_PMEM_rd_bubble = 2'b00; //Initial State
localparam [1:0] SUB_dividend_ready = 2'b01;
localparam [1:0] SUB_wait_div_done = 2'b10;
reg        [1:0] normDiv_substate, normDiv_substate_nxt; // PMEM has rd/wr here. PMEM has 1 cyc read latency.

// ########## Counters ######################
reg [3:0] ofifo_valid_cnt, ofifo_valid_cnt_nxt; 
reg [3:0] acc_done_cnt, acc_done_cnt_nxt;
reg [3:0] div_done_cnt, div_done_cnt_nxt;

// ##########
assign acc_start = (postMAC_state==S_MULT_NORM_ACC) && ofifo_valid; // start acc when the first valid data comes in
assign div_start = (postMAC_state==S_MULT_NORM_DIV) && (normDiv_substate==SUB_dividend_ready) && sum_in_valid; // start div when we are in div state, and we have valid sum_in from SFP, and we are ready for dividend (which means we have valid divisor and we have read the dividend from PMEM)
assign sfp_in = (postMAC_state==S_MULT_NORM_ACC)? ofifo_out : pmem_out; 

assign sum_out = sfp_sum_out;
assign sum_out_valid = acc_done;	
assign sum_in_fifo_pop = div_start; // sum_in fifo can be popped next cycle when we start div




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
	else if((postMAC_state==S_MULT_NORM_DIV) && sfp_write_to_kmem) begin //SFP div write if sfp_write_to_kmem is set, only for norm mode and when we have valid result to write
		kmem_wr  = div_done;
		kmem_rd  = 1'b0;
		kmem_add = div_done_cnt;
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
		pmem_in  = ofifo_out; //Don't Care
	end else if((postMAC_state==S_MULT_ONLY)||(postMAC_state==S_MULT_NORM_ACC))begin
		// In these 2 states, we only write to PMEM from ofifo, and we don't read from PMEM. 
		// So we can directly use ofifo_valid to control PMEM write, and ignore PMEM read.
		pmem_rd  = 1'b0;
		pmem_wr  = ofifo_valid;
		pmem_add = ofifo_valid_cnt; 
		pmem_in  = ofifo_out;
	end else if(postMAC_state==S_MULT_NORM_DIV) begin 
		if(div_done)begin // write to PMEM (if only sfp_write_to_pmem is set) 
			pmem_rd  = 1'b0;
			pmem_wr  = sfp_write_to_pmem;			
			pmem_add = div_done_cnt; 
			pmem_in  = sfp_out_BW_extended;
		end else begin // we read
			pmem_rd  = 1'b1;
			pmem_wr  = 1'b0;
			pmem_add = div_done_cnt;
			pmem_in  = ofifo_out;    //Don't care
		end
	end else begin
		// postMAC done. We don't read or write PMEM anymore. We chill.
		pmem_rd  = 1'b0;
		pmem_wr  = 1'b0;
		pmem_add = addr_ext; //Don't care
		pmem_in  = ofifo_out; //Don't care
	end
end
	

// ########################################### //
//         Mem Out Data flow                   //
// ########################################### //
assign mac_in  = mac_load_D1 ? kmem_out : 
				 mac_exec_D1 ? qmem_out : {(pr*bw-1){1'b0}};
assign out     = pmem_out;


// ########################################### //
// 			Post-MAC state & substates    	   //
// ########################################### //
always @(*) begin
	case (postMAC_state)
		S_MULT_ONLY: begin
			if((ofifo_valid_cnt == VEC_LEN - 4'd1) && ofifo_valid) begin
				postMAC_state_nxt = S_DONE;
			end
			else begin //reinforce the init state of 2 op modes.
				if(op_mode==OP_MODE_MULT_NORM) begin //
					postMAC_state_nxt = S_MULT_NORM_ACC; 
				end else begin
					postMAC_state_nxt = S_MULT_ONLY;
				end
			end
		end
		S_MULT_NORM_ACC: begin
			if((acc_done_cnt == VEC_LEN - 4'd1) && acc_done) begin
				postMAC_state_nxt = S_MULT_NORM_DIV;
			end
			else begin //reinforce the init state of 2 op modes.
				if(op_mode==OP_MODE_MULT_NORM) begin //
					postMAC_state_nxt = S_MULT_NORM_ACC; 
				end else begin
					postMAC_state_nxt = S_MULT_ONLY;
				end
			end
		end
		S_MULT_NORM_DIV: begin
			if((div_done_cnt == VEC_LEN - 4'd1) && div_done) begin
				postMAC_state_nxt = S_DONE;
			end
			else begin //reinforce the init state of 2 op modes.
				postMAC_state_nxt = S_MULT_NORM_DIV;
			end
		end
		S_DONE: begin
			postMAC_state_nxt = S_DONE; // stay in done state until reset
		end
		default: begin
			postMAC_state_nxt = postMAC_state; // stay in the same state
		end
	endcase
end
// substate next for normDiv
always @(*) begin
	if(postMAC_state!=S_MULT_NORM_DIV)begin
		normDiv_substate_nxt = SUB_PMEM_rd_bubble; // reset to initial substate when we are not in normDiv state
	end
	else begin
		case(normDiv_substate)
			SUB_PMEM_rd_bubble: begin
				normDiv_substate_nxt = SUB_dividend_ready; // after one cycle bubble, we can start div
			end
			SUB_dividend_ready: begin
				if(div_start && div_done)begin 				// div lat=0. Result written. Rd for next cyc
					normDiv_substate_nxt = SUB_PMEM_rd_bubble; 
				end else if(div_start && !div_done)begin 	// div lat>0. Result not yet written. 
					normDiv_substate_nxt = SUB_wait_div_done; 
				end else begin 								// wait for div to start
					normDiv_substate_nxt = SUB_dividend_ready; 
				end
			end
			SUB_wait_div_done: begin
				if(div_done)begin							// if div done. Result written. Rd for next cyc
					normDiv_substate_nxt = SUB_PMEM_rd_bubble; 
				end else begin								// wait for div to done
					normDiv_substate_nxt = SUB_wait_div_done; 
				end
			end
			default: normDiv_substate_nxt = SUB_PMEM_rd_bubble;
		endcase
	end
end



// ########################################### //
//          SFP & result save logic            //
// ########################################### //
assign core_done = (postMAC_state==S_DONE);

assign sfp_sum_in = sum_in; // other core's accumulated sum, via fullchip sample-and-hold


// ########################################### //
//        	  Core Operate Mode		           //
// ########################################### //
always @(posedge clk ) begin
	if(reset)begin
		mode <= 3'b100; //pure matrix mult, output to pmem
	end	else if(set_mode && !busy)begin
		mode <= mode_in;
	end else begin
		mode <= mode;
	end
end




controller controller_instance (
	.clk(clk),
	.reset(reset),
	.start(start),
	.mode(mode),
	.status(status),
	.core_done(core_done),
	.inst_ctrl(inst_ctrl),
	.mem_ext_ctrl_sel(mem_ext_ctrl_sel)
);

mac_array #(.bw(bw), .bw_psum(bw_psum), .col(col), .pr(pr)) mac_array_instance (
		.in(mac_in), 
		.clk(clk), 
		.reset(reset), 
		.inst(mac_inst),     
		.fifo_wr(ofifo_wr),     
		.out(array_out)
);

ofifo #(.bw(bw_psum), .col(col))  ofifo_inst (
		.reset(reset),
		.clk(clk),
		.in(array_out),
		.wr(ofifo_wr),
		.rd(ofifo_valid),
		.o_valid(ofifo_valid),
		.out(ofifo_out)
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


// ################################################### //
// ######		Trivial Sequential Logic		######
// ################################################### //				
	// Delayed Signals
	always @(posedge clk ) begin
		mac_load_D1 <= mac_load;
		mac_exec_D1 <= mac_exec;
	end
	// postMAC_state_nxt update logic
	always @(posedge clk ) begin
		if(reset)begin
			postMAC_state <= S_MULT_ONLY; // just a default. Will be set to the correct initial state in the combinational logic based on op_mode
			normDiv_substate <= SUB_PMEM_rd_bubble;
		end else begin
			postMAC_state <= postMAC_state_nxt;
			normDiv_substate <= normDiv_substate_nxt;
		end
	end
	// counters: ofifo_valid_cnt, acc_done_cnt, div_done_cnt
	always @(posedge clk ) begin
		if(reset) begin
			ofifo_valid_cnt <= 4'd0;
		end else if(ofifo_valid) begin
			ofifo_valid_cnt <= ofifo_valid_cnt + 4'd1;
		end	else begin
			ofifo_valid_cnt <= ofifo_valid_cnt;
		end
		if(reset) begin
			acc_done_cnt <= 4'd0;
		end	else if(acc_done) begin
			acc_done_cnt <= acc_done_cnt + 4'd1;
		end else begin
			acc_done_cnt <= acc_done_cnt;
		end
		if(reset) begin
			div_done_cnt <= 4'd0;
		end else if(div_done) begin
			div_done_cnt <= div_done_cnt + 4'd1;
		end	else begin
			div_done_cnt <= div_done_cnt;
		end
	end


endmodule