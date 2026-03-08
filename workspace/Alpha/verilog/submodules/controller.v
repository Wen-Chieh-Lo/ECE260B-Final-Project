/*
* status[2:0] = {busy, qmem_locked, kmem_locked}
*   MSB: busy              (controller won't accept start if busy=1)
*      : qmem_locked       (controller can't accept qmem write if qmem_locked=1)
*   LSB: kmem_locked       (controller can't accept kmem write if kmem_locked=1) 
*/

module controller(clk, reset, start, mode_from_reg_map, status_to_reg_map, ofifo_valid, sfp_busy, inst_ctrl);

// ============== I/O ============== // 
    input             clk, reset;
    input             start;
    
    input  [2:0]      mode_from_reg_map; //register map value
    output [2:0]      status_to_reg_map; // {busy, qmem_locked, kmem_locked}

    input             ofifo_valid; // to determine SFP state transition
    input             sfp_busy;    // provided by SFP to indicate whether can send data to it.

    output [19:0]     inst_ctrl;  // control bus to drive core.inst (replace external inst)

     



// ============== States and counter ============== // 
    reg    [3:0]      MAC_counter, MAC_counter_nxt; 
    reg    [1:0]      MAC_state, MAC_state_nxt;
    localparam S_MAC_IDLE   = 2'b00;
    localparam S_MAC_LOAD   = 2'b01;
    localparam S_MAC_EXEC   = 2'b10;
    localparam S_MAC_DONE   = 2'b11;

    reg    [3:0]      SFP_counter, SFP_counter_nxt; 
    reg    [1:0]      SFP_state, SFP_state_nxt;
    localparam S_SFP_IDLE   = 2'b00;
    localparam S_SFP_bypass_to_PMEM = 2'b01;
    localparam S_SFP_SFP    = 2'b10;
    localparam S_SFP_DONE   = 2'b11;

    localparam Q_vec_LEN_minus1    = 4'd7;
    localparam K_vec_LEN_minus1    = 4'd7;



    // ============== Wires & Regs ============== // 
    wire      busy, qmem_locked, kmem_locked;
    reg       op_mode, sfp_write_to_kmem, sfp_write_to_pmem; // update from mode_from_reg_map when start&&!busy


    assign    status_to_reg_map = {busy, qmem_locked, kmem_locked};
    assign    kmem_locked = (MAC_state == S_MAC_LOAD);
    assign    qmem_locked = (MAC_state == S_MAC_EXEC) || (SFP_state == S_SFP_SFP && sfp_write_to_kmem);
    assign    busy = ((MAC_state != S_MAC_IDLE) || (SFP_state != S_SFP_IDLE)) && ((MAC_state != S_MAC_DONE) || (SFP_state != S_SFP_DONE)); 

    // inst_ctrl[19:0] maps to core.inst: [19]VN_mode [18]sfp_div [17]sfp_acc [16]sfp_processing
    //   [15:12]qkmem_add [11:8]pmem_add [7:6]mac_inst [5]qmem_rd [4]qmem_wr [3]kmem_rd [2]kmem_wr [1]pmem_rd [0]pmem_wr
      // TODO: derive from MAC_state, SFP_state, MAC_counter, SFP_counter, op_mode, etc.

    reg      VN_mode, sfp_div, sfp_acc, sfp_processing, qmem_rd, qmem_wr, kmem_rd, kmem_wr, pmem_rd, pmem_wr;
    reg      [3:0] qkmem_add, pmem_add;
    reg      [1:0] mac_inst;

    assign    inst_ctrl[19] = VN_mode;
    assign    inst_ctrl[18] = sfp_div;
    assign    inst_ctrl[17] = sfp_acc;
    assign    inst_ctrl[16] = sfp_processing;
    assign    inst_ctrl[15:12] = qkmem_add;
    assign    inst_ctrl[11:8] = pmem_add;
    assign    inst_ctrl[7:6] = mac_inst;
    assign    inst_ctrl[5] = qmem_rd;
    assign    inst_ctrl[4] = qmem_wr;
    assign    inst_ctrl[3] = kmem_rd;
    assign    inst_ctrl[2] = kmem_wr;
    assign    inst_ctrl[1] = pmem_rd;
    assign    inst_ctrl[0] = pmem_wr;







    // ============== MAC_state transition logic ============== // 
    always @(*) begin
        case (MAC_state)
            S_MAC_IDLE: begin
                if(start && !busy) begin
                    MAC_state_nxt = S_MAC_LOAD;
                end
                else begin
                    MAC_state_nxt = S_MAC_IDLE; // hold in IDLE if not starting or busy
                end
                MAC_counter_nxt = 4'd0;     // reset counter in IDLE
            end
            
            S_MAC_LOAD: begin
                if(MAC_counter == K_vec_LEN_minus1) begin
                    MAC_state_nxt = S_MAC_EXEC; 
                    MAC_counter_nxt = 4'd0; // stay in MAC_EXEC for 8 cycles
                end
                else begin
                    MAC_state_nxt = S_MAC_LOAD; 
                    MAC_counter_nxt = MAC_counter + 4'd1; // count up in MAC_LOAD
                end
            end

            S_MAC_EXEC: begin
                if(MAC_counter == Q_vec_LEN_minus1) begin
                    MAC_state_nxt = S_MAC_DONE; 
                    MAC_counter_nxt = 4'd0; // reset MAC_counter when back to IDLE
                end
                else begin
                    MAC_state_nxt = S_MAC_EXEC; 
                    MAC_counter_nxt = MAC_counter + 4'd1; // count up in MAC_EXEC
                end
            end

            default: begin // S_MAC_DONE
                MAC_state_nxt = S_MAC_DONE; 
                MAC_counter_nxt = 4'd0;
            end
        endcase
    end


    // ============== SFP_state transition logic ============== // 
    always @(*) begin
        case (SFP_state)
            S_SFP_IDLE: begin
                if(ofifo_valid) begin
                    SFP_state_nxt = (op_mode==0) ? S_SFP_SFP : S_SFP_bypass_to_PMEM;
                    SFP_counter_nxt = 4'd0;
                end
                else begin
                    SFP_state_nxt = S_SFP_IDLE;
                    SFP_counter_nxt = 4'd0; // reset SFP_counter in IDLE
                end
                
            end

            S_SFP_bypass_to_PMEM: begin
                if(!ofifo_valid && SFP_counter == Q_vec_LEN_minus1) begin
                    SFP_state_nxt = S_SFP_DONE; 
                    SFP_counter_nxt = 4'd0; // reset SFP_counter
                end
                else if (ofifo_valid && SFP_counter != Q_vec_LEN_minus1) begin
                    SFP_state_nxt = S_SFP_bypass_to_PMEM; 
                    SFP_counter_nxt = SFP_counter + 4'd1; // count up in SFP_bypass_to_PMEM    
                end
                else begin // hold in until ofifo_valid again
                    SFP_state_nxt = S_SFP_bypass_to_PMEM; 
                    SFP_counter_nxt = SFP_counter;
                end
    
            end
            S_SFP_SFP: begin
                if(!sfp_busy && !ofifo_valid && SFP_counter == Q_vec_LEN_minus1)begin
                    SFP_state_nxt = S_SFP_DONE; 
                    SFP_counter_nxt = 4'd0; // reset SFP_counter
                end
                else if (!sfp_busy && ofifo_valid && SFP_counter != Q_vec_LEN_minus1) begin
                    SFP_state_nxt = S_SFP_SFP; 
                    SFP_counter_nxt = SFP_counter + 4'd1; // count up in SFP_SFP
                end
                else begin // hold
                    SFP_state_nxt = S_SFP_SFP; 
                    SFP_counter_nxt = SFP_counter;
                end
                
            end
            default: begin // S_SFP_DONE
                SFP_state_nxt = S_SFP_DONE; 
                SFP_counter_nxt = 4'd0;
            end

        endcase
    end


    // don't need reset here since reg_map has it already
    // controller mode only updates when start and not busy, otherwise hold the value
    always @(posedge clk) begin 
        if(start && !busy) begin
            {op_mode, sfp_write_to_kmem, sfp_write_to_pmem} <= mode_from_reg_map; // update controller mode from reg_map shadow when start and not busy
        end
        else begin
            {op_mode, sfp_write_to_kmem, sfp_write_to_pmem} <= {op_mode, sfp_write_to_kmem, sfp_write_to_pmem}; 
        end
    end

    // sequential logic
    always @(posedge clk) begin
        if(reset) begin
            MAC_state <= S_MAC_IDLE;
            MAC_counter <= 4'd0;
            SFP_state <= S_SFP_IDLE;
            SFP_counter <= 4'd0;
        end
        else begin
            MAC_state <= MAC_state_nxt;
            MAC_counter <= MAC_counter_nxt;
            SFP_state <= SFP_state_nxt;
            SFP_counter <= SFP_counter_nxt;
        end
    end



endmodule