module fifo_depth16_async (
    rd_clk,
    wr_clk,
    rd,
    wr,
    reset,
    in,
    out,
    o_full,
    o_empty
);

  parameter bw   = 4;
  parameter simd = 1;

  localparam W  = simd*bw;
  localparam AW = 4;   // 16 deep
  localparam PW = 5;   // address bits + wrap bit

  input              rd_clk;
  input              wr_clk;
  input              rd;
  input              wr;
  input              reset;
  input  [W-1:0]     in;
  output [W-1:0]     out;
  output             o_full;
  output             o_empty;

  reg  [PW-1:0] rd_ptr_bin,  wr_ptr_bin;
  reg  [PW-1:0] rd_ptr_gray, wr_ptr_gray;

  reg  [PW-1:0] rd_ptr_gray_sync_wr1, rd_ptr_gray_sync_wr2;
  reg  [PW-1:0] wr_ptr_gray_sync_rd1, wr_ptr_gray_sync_rd2;

  reg  [W-1:0] mem [0:(1<<AW)-1];

  wire [PW-1:0] rd_ptr_bin_next;
  wire [PW-1:0] wr_ptr_bin_next;
  wire [PW-1:0] rd_ptr_gray_next;
  wire [PW-1:0] wr_ptr_gray_next;

  wire          empty;
  wire          full;
  wire          rd_fire;
  wire          wr_fire;

  integer i;

  function automatic [PW-1:0] bin2gray(input [PW-1:0] bin);
    begin
      bin2gray = (bin >> 1) ^ bin;
    end
  endfunction

  assign rd_ptr_bin_next  = rd_ptr_bin + {{(PW-1){1'b0}}, 1'b1};
  assign wr_ptr_bin_next  = wr_ptr_bin + {{(PW-1){1'b0}}, 1'b1};
  assign rd_ptr_gray_next = bin2gray(rd_ptr_bin_next);
  assign wr_ptr_gray_next = bin2gray(wr_ptr_bin_next);

  // Empty when synchronized write pointer equals current read pointer
  assign empty = (wr_ptr_gray_sync_rd2 == rd_ptr_gray);

  // Standard async FIFO full check:
  // next write gray == synchronized read gray with top 2 bits inverted
  assign full =
      (wr_ptr_gray_next ==
       {~rd_ptr_gray_sync_wr2[PW-1:PW-2], rd_ptr_gray_sync_wr2[PW-3:0]});

  assign o_empty = empty;
  assign o_full  = full;

  assign rd_fire = rd && !empty;
  assign wr_fire = wr && !full;

  // Preserve old visible timing style:
  // current word at read pointer is visible combinationally.
  assign out = mem[rd_ptr_bin[AW-1:0]];

  // ---------------------------
  // Read clock domain
  // ---------------------------
  always @(posedge rd_clk or posedge reset) begin
    if (reset) begin
      rd_ptr_bin          <= {PW{1'b0}};
      rd_ptr_gray         <= {PW{1'b0}};
      wr_ptr_gray_sync_rd1 <= {PW{1'b0}};
      wr_ptr_gray_sync_rd2 <= {PW{1'b0}};
    end
    else begin
      // sync write pointer into read domain
      wr_ptr_gray_sync_rd1 <= wr_ptr_gray;
      wr_ptr_gray_sync_rd2 <= wr_ptr_gray_sync_rd1;

      if (rd_fire) begin
        rd_ptr_bin  <= rd_ptr_bin_next;
        rd_ptr_gray <= rd_ptr_gray_next;
      end
    end
  end

  // ---------------------------
  // Write clock domain
  // ---------------------------
  always @(posedge wr_clk or posedge reset) begin
    if (reset) begin
      wr_ptr_bin           <= {PW{1'b0}};
      wr_ptr_gray          <= {PW{1'b0}};
      rd_ptr_gray_sync_wr1 <= {PW{1'b0}};
      rd_ptr_gray_sync_wr2 <= {PW{1'b0}};

      for (i = 0; i < (1<<AW); i = i + 1)
        mem[i] <= {W{1'b0}};
    end
    else begin
      // sync read pointer into write domain
      rd_ptr_gray_sync_wr1 <= rd_ptr_gray;
      rd_ptr_gray_sync_wr2 <= rd_ptr_gray_sync_wr1;

      if (wr_fire) begin
        mem[wr_ptr_bin[AW-1:0]] <= in;
        wr_ptr_bin  <= wr_ptr_bin_next;
        wr_ptr_gray <= wr_ptr_gray_next;
      end
    end
  end

endmodule

