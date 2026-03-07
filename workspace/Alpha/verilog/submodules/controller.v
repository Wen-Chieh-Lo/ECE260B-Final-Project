/*
* status[2:0] = {busy, qmem_free, kmem_free}
*   MSB: busy              (controller won't accept start if busy=1)
*      : qmem_free         (controller can accept qmem write if qmem_free=1)
*   LSB: kmem_free         (controller can accept kmem write if kmem_free=1) 
*/




module controller(clk, reset, start, mode_from_reg_map, status_to_reg_map, kmem_ctrl, qmem_ctrl, pmem_ctrl, sfp_ctrl, mac_ctrl);
    input             clk, reset;
    input             start;
    
    input  [2:0]      mode_from_reg_map; //register map value
    output [2:0]      status_to_reg_map; // {busy, qmem_free, kmem_free}

    output [5:0]      kmem_ctrl; // {kmem_rd, kmem_wr, kmem_addr}
    output [5:0]      qmem_ctrl; // {qmem_rd, qmem_wr, qmem_addr}
    output [5:0]      pmem_ctrl; // {pmem_rd, pmem_wr, pmem_addr}
    output [5:0]      sfp_ctrl;  // {sfp_write_to_kmem, sfp_write_to_pmem, 
    
    









    wire              busy, qmem_free, kmem_free;
    reg               op_mode, sfp_write_to_kmem, sfp_write_to_pmem; // update from mode_from_reg_map when start&&!busy





    assign    status_to_reg_map = {busy, qmem_free, kmem_free};

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





endmodule