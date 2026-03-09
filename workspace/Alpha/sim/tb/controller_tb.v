`timescale 1ns/1ps
`define CYCLE 1
`define H_CYCLE 0.5
`define TIME_OUT 10000

module controller_tb;
  //================= Timeout ======================//
  initial #(`TIME_OUT) $finish;

	//================= clk set up ===================//
  reg clk;
  initial clk = 0;
  always #(`H_CYCLE) clk = ~clk;

  //================= integers =====================//
  

  // ================= reg_map =====================//
	reg             reset=0;
	reg             reg_map_wen, reg_map_cen;
	reg             reg_map_addr;
	reg  [2:0]      reg_map_data_in;
	wire [2:0]      reg_map_data_out;

	wire [2:0] 			controller_regmap_bus0;
	wire [2:0] 			controller_regmap_bus1;


	// ================ controller ===================//
	reg 						start=0;
	reg  				 		sfp_done=0;
	reg op_mode, sfp_write_to_kmem, sfp_write_to_pmem;
	assign controller_regmap_bus0 = {op_mode, sfp_write_to_kmem, sfp_write_to_pmem};
	wire [19:0] 				inst_ctrl;

	controller controller_inst(
		.clk(clk),
		.reset(reset),
		.start(start),
		.mode_from_reg_map(controller_regmap_bus0),
		.status_to_reg_map(controller_regmap_bus1),
		.sfp_done(sfp_done),
		.inst_ctrl(inst_ctrl)
	);

	// data selecting logic
	




  	initial begin
		$dumpfile("sim/waveform/controller.vcd");
		$dumpvars(0, controller_tb);
			
		// Apply reset
		reset = 0;
		repeat(2) @(negedge clk); 
		reset = 1;
		repeat(2) @(negedge clk); 
		reset = 0;
		@(negedge clk);


		
		// Test QK+SFP mode
		op_mode = 0;
		sfp_write_to_kmem = 1;
		sfp_write_to_pmem = 0;

		// Write data to KMEM
		// Write data to QMEM
		// Start the controller

		start = 1; // start the controller to update mode from reg_map
		repeat(1) @(negedge clk);

		start = 0;
		@(negedge clk);

		// wait
		repeat(20) @(negedge clk);

		repeat(8) begin
			sfp_done = 1;
			@(negedge clk);
		end	
		sfp_done = 0;
		repeat(20)@(negedge clk);
		


		//#########################################################
		//#             Set reg_map to VN mode                #
		//#########################################################
		// Apply reset
		reset = 0;
		repeat(2) @(negedge clk); 

    reset = 1;
    repeat(2) @(negedge clk); 

    reset = 0;
		@(negedge clk);



		@(negedge clk);
		reg_map_cen = 0; // enable write
		reg_map_wen = 1; // write
		reg_map_addr = 0; // mode register
		reg_map_data_in = 3'b100; // set op_mode=1(VN), the other 2 bits are don't care
		@(negedge clk);
		reg_map_cen = 1; // disable write


		start = 1; // start the controller to update mode from reg_map
		repeat(2) @(negedge clk);

		start = 0;
		@(negedge clk);

		// wait
		repeat(10) @(negedge clk);

		
		repeat(8) begin
			sfp_done = 1;
			@(negedge clk);
		end	
		sfp_done = 0;
		@(negedge clk);


  
  repeat(10) @(negedge clk);
  //#########################################################
  //#               End of Testbench Setup                  #
  //#########################################################










    #10 $finish;
  end

endmodule