/*
* status[2:0] = {busy, qmem_locked, kmem_locked}
*   MSB: busy              (controller won't accept start if busy=1)
*      : qmem_locked       (controller can't accept qmem write if qmem_locked=1)
*   LSB: kmem_locked       (controller can't accept kmem write if kmem_locked=1) 
*/

module controller(clk, reset, start, mode_from_reg_map, status_to_reg_map, save_done, inst_ctrl, mem_ext_ctrl_sel);

// ============== I/O ============== // 
    input             clk, reset;
    input             start;
    
    input  [2:0]      mode_from_reg_map; //register map value
    output [2:0]      status_to_reg_map; // {busy, qmem_locked, kmem_locked}

    input             save_done;    // provided by SFP to indicate whether can send data to it.

    output [7:0]      inst_ctrl;  // control bus to drive core.inst (replace external inst)
    output [2:0]      mem_ext_ctrl_sel; // external memory selection

     



// ============== States and counter ============== // 
    reg    [3:0]      mac_counter, mac_counter_nxt; 
    reg    [2:0]      state, state_nxt;
    localparam S_MAC_IDLE   = 3'd0;
    localparam S_MAC_LOAD   = 3'd1;
    localparam S_MAC_EXEC   = 3'd2;
    localparam S_MAC_DONE   = 3'd3;
    localparam S_MAC_LOAD_DUMMY   = 3'd4;  // I hate this lol
    

    localparam VEC_LEN      = 4'd8;



    // // ============== Wires & Regs ============== // 
    // wire      busy, qmem_locked, kmem_locked;
    wire      op_mode, sfp_write_to_kmem, sfp_write_to_pmem; // update from mode_from_reg_map when start&&!busy
    assign    op_mode           = mode_from_reg_map[2];
    assign    sfp_write_to_kmem = mode_from_reg_map[1];
    assign    sfp_write_to_pmem = mode_from_reg_map[0];

    wire     kmem_ext_wr_sel, qmem_ext_wr_sel, pmem_ext_rd_sel;
    assign   mem_ext_ctrl_sel = {kmem_ext_wr_sel, qmem_ext_wr_sel, pmem_ext_rd_sel};


    reg      [3:0] qkmem_rd_addr;
    wire     [1:0] mac_inst;
    wire           kmem_rd, qmem_rd;
    
    assign    inst_ctrl[7]   = qmem_rd;
    assign    inst_ctrl[6]   = kmem_rd;
    assign    inst_ctrl[5:2] = qkmem_rd_addr;  
    assign    inst_ctrl[1:0] = mac_inst;


    // =============== output logic =============
    assign  kmem_ext_wr_sel = (state == S_MAC_IDLE) || (state == S_MAC_DONE && !sfp_write_to_kmem);
    assign  qmem_ext_wr_sel = (state == S_MAC_IDLE) || (state == S_MAC_DONE);
    assign  pmem_ext_rd_sel = (state == S_MAC_IDLE);


    wire   rd_mac_load, rd_mac_exec;
    
    assign rd_mac_load = (state==S_MAC_LOAD_DUMMY) || (state == S_MAC_LOAD) && (mac_counter < VEC_LEN);
    assign rd_mac_exec = (state == S_MAC_EXEC) && (mac_counter < VEC_LEN);
    

    assign kmem_rd = rd_mac_load;
    assign qmem_rd = rd_mac_exec;
    assign mac_inst = {rd_mac_exec, rd_mac_load};


    always @(*) begin

        if(state==S_MAC_LOAD || state==S_MAC_EXEC)begin
            qkmem_rd_addr = mac_counter;
        end
        else begin
            qkmem_rd_addr = 4'd0;
        end
    end

    
            

    reg [3:0]  wait_cycle, wait_cycle_nxt;

    // state transition
    always @(*) begin
        case (state)
            S_MAC_IDLE: begin
                if (start) begin
                    state_nxt = S_MAC_LOAD_DUMMY;
                end
                else begin
                    state_nxt = S_MAC_IDLE; 
                end
                mac_counter_nxt = 4'd0;
            end
            S_MAC_LOAD_DUMMY: begin
                state_nxt = S_MAC_LOAD;
                mac_counter_nxt = 4'd0;
            end
            S_MAC_LOAD: begin
                if (mac_counter < VEC_LEN) begin
                    state_nxt = S_MAC_LOAD;
                    mac_counter_nxt = mac_counter + 4'd1;
                end
                else begin
                    state_nxt = S_MAC_EXEC;
                    mac_counter_nxt = 4'd0;
                end
            end


            S_MAC_EXEC: begin
                if (mac_counter < VEC_LEN) begin
                    state_nxt = S_MAC_EXEC;
                    mac_counter_nxt = mac_counter + 4'd1;
                end
                else begin
                    state_nxt = S_MAC_DONE;
                    mac_counter_nxt = 4'd0;
                end
            end

            S_MAC_DONE: begin
                if(save_done) begin
                    state_nxt = S_MAC_IDLE;
                end
                else begin
                    state_nxt = S_MAC_DONE;
                end
            end

            default: begin
                state_nxt = state;
                mac_counter_nxt = mac_counter;
            end
            
        endcase
    end



    // don't need reset here since reg_map has it already
    // controller mode only updates when start and not busy, otherwise hold the value
    // always @(posedge clk) begin 
    //     if(start && !busy) begin
    //         {op_mode, sfp_write_to_kmem, sfp_write_to_pmem} <= mode_from_reg_map; // update controller mode from reg_map shadow when start and not busy
    //     end
    //     else begin
    //         {op_mode, sfp_write_to_kmem, sfp_write_to_pmem} <= {op_mode, sfp_write_to_kmem, sfp_write_to_pmem}; 
    //     end
    // end



    // ==================================================
    // response: memory returns data 1 cycle later
    // ==================================================





    // ============================== //
    // state/counter logic
    // ============================== //
    always @(posedge clk) begin
        if(reset) begin
            state <= S_MAC_IDLE;
            mac_counter <= 4'd0;
        end
        else begin
            state <= state_nxt;
            mac_counter <= mac_counter_nxt;
        end
    end



endmodule