// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 


module add_tb;

parameter bw = 4;
parameter psum_bw = 4+2;

reg clk = 0;

reg  [bw-1:0] x;
reg  [bw-1:0] y;
reg  [bw-1:0] z;
wire [psum_bw-1:0] out;
reg  [psum_bw-1:0] expected_out = 0;
reg  [psum_bw-1:0] expected_out_delay = 0;


integer x_file ; // file handler
integer x_scan_file ; // file handler

integer y_file ; // file handler
integer y_scan_file ; // file handler

integer z_file ; // file handler
integer z_scan_file ; // file handler

integer x_dec;
integer y_dec;
integer z_dec;
integer i; 
integer u; 
integer error = 0;

function [3:0] dec2bin ;
  input integer  weight ;
  begin

    if (weight>7) begin
     dec2bin[3] = 1;
     weight = weight - 8;
    end
    else 
     dec2bin[3] = 0;

    if (weight>3) begin
     dec2bin[2] = 1;
     weight = weight - 4;
    end
    else 
     dec2bin[2] = 0;

    if (weight>1) begin
     dec2bin[1] = 1;
     weight = weight - 2;
    end
    else 
     dec2bin[1] = 0;

    if (weight>0) 
     dec2bin[0] = 1;
    else 
     dec2bin[0] = 0;

  end
endfunction




// Below function is for verification
function [psum_bw-1:0] add_predicted;
  
  input [bw-1:0] a, b;
  input [psum_bw-1:0] c;
  reg [psum_bw-1:0] psum;
 
  begin 
    add_predicted =  a + b + c;
  end 
endfunction



add  add_instance (
	.clk(clk), 
        .x(x), 
        .y(y),
        .z(z),
	.out(out)
); 
 
initial $sdf_annotate("./constraints/add_WC.sdf", add_instance, , ,"MAXIMUM","1:1:1","FROM_MTM");

initial begin 

  x_file = $fopen("x_data.txt", "r");  //activation
  y_file = $fopen("y_data.txt", "r");  //activation
  z_file = $fopen("z_data.txt", "r");  //activation


  $dumpfile("add_tb_wcccc.vcd");
  $display("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%");
  $dumpvars(0,add_tb);
 
  #1 clk = 1'b0;  
  #1 clk = 1'b1;  
  #1 clk = 1'b0;

  $display("-------------------- Computation start --------------------");
  

  for (i=0; i<10; i=i+1) begin  // Data lenghh is 10 in the data files

     #1 clk = 1'b0;

     x_scan_file = $fscanf(x_file, "%d\n", x_dec);
     y_scan_file = $fscanf(y_file, "%d\n", y_dec);
     z_scan_file = $fscanf(z_file, "%d\n", z_dec);

     x = dec2bin(x_dec); 
     y = dec2bin(y_dec); 
     z = dec2bin(z_dec); 

     if (i>1) begin // this if condition is needed as the output is available at the next cycle

       if (out == expected_out_delay) 
          $display("Computed data matched :D, %2d vs. %2d",   out, expected_out_delay);
       else begin
          $display("Computed data ERROR (>.<), %2d vs. %2d",  out, expected_out_delay);
          error = error+1;
       end
       $display("Total ERROR: %3d",  error);
     end


     #1 clk = 1'b1;
       expected_out_delay = expected_out;
       expected_out = add_predicted(x, y, z);
  end


  #1 clk = 1'b1;
  #1 clk = 1'b0;

  $display("-------------------- Computation completed --------------------");

  #10 $finish;


end

endmodule




