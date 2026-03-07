/* reg_map provides a control interface for the utilization of the core.
* It has 3 registers:
* 1. CTRL: control signals to start the operation and enable PMEM access
* 2. MODE: configuration for operation mode
* 3. STATUS: read-only status signals from the controller
*
* ADDR=0: MODE             (Won't take effect until controller received start!)
*   MSB: op_mode           (0: QK+Norm, 1: VN)
*      : sfp_write_to_kmem (Only for op_mode=0.)
*   LSB: sfp_write_to_pmem (Only for op_mode=0.)

* ADDR=1: STATUS (read-only)
*   MSB: busy              (controller won't accept start if busy=1)
*      : qmem_free         (controller can accept qmem write if qmem_free=1)
*   LSB: kmem_free         (controller can accept kmem write if kmem_free=1)
*/


module reg_map (clk, reset, wen, cen, addr, data_in, data_out, status_from_controller, mode_to_controller);

    // read & write interface for upper level
    input            clk;
    input            reset;
    input            wen;
    input            cen;
    input            addr;
    input      [2:0] data_in;
    output reg [2:0] data_out;

    // register map
    localparam MODE_ADDR   = 1'b0;
    localparam STATUS_ADDR = 1'b1;
    reg [2:0] mode_reg;           // {op_mode, sfp_write_to_kmem, sfp_write_to_pmem}

    input      [2:0] status_from_controller;
    output     [2:0] mode_to_controller; 


    // output to upper level
    always @(*) begin
        if (!cen && !wen) begin
            case (addr)
                MODE_ADDR   : data_out = mode_reg;
                STATUS_ADDR : data_out = status_from_controller;
                default     : data_out = 3'b000;
            endcase
        end
        data_out = 3'b000; // default to 0 when not reading
    end

    // output to controller
    assign mode_to_controller = mode_reg; //controller can read mode reg directly



    // sequential logic
    always @(posedge clk) begin
        if (reset) begin
            mode_reg   <= 3'b010; // default to QK mode, sfp write to kmem only
        end 
        else begin
            if(!cen && wen && addr==MODE_ADDR)
                mode_reg   <= data_in; // update mode register on write
            else
                mode_reg   <= mode_reg; // hold mode register value when not writing
        end
    end



endmodule