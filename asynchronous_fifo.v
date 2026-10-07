// ============================================================
//  ASYNCHRONOUS FIFO - Dual-Clock Domain Communication
//  Depth : 8 entries | Width : 8 bits
//  Pointers : 4-bit (3 address bits + 1 wrap bit)
//  CDC : Gray-coded pointers, registered in the source domain,
//        synchronized via 2-flop synchronizer (+1 margin stage)
//  NOTE : All full/empty comparisons are done directly in Gray
// ============================================================

module async_fifo (wr_clk, rd_clk, rst, wr_en, rd_en,
                   wr_data, rd_data, full, empty);

  input        wr_clk, rd_clk, rst, wr_en, rd_en;
  input  [7:0] wr_data;
  output reg [7:0] rd_data;
  output       full, empty;

  // ---------------- Storage ----------------
  reg [7:0] mem [7:0];                    // 8 entries x 8 bits

  // ---------------- Pointers ----------------
  reg [3:0] wr_ptr, rd_ptr;               // binary pointers
  reg [3:0] wr_ptr_gray, rd_ptr_gray;     // Gray pointers (registered)

  // ---------------- Synchronizers ----------------
  // ff1 -> ff2 : standard 2-flop synchronizer
  // sync       : extra register stage for additional MTBF margin
  reg [3:0] wr_ptr_gray_ff1, wr_ptr_gray_ff2, wr_ptr_gray_sync; // into rd_clk
  reg [3:0] rd_ptr_gray_ff1, rd_ptr_gray_ff2, rd_ptr_gray_sync; // into wr_clk

  // ---------------- Next-pointer logic ----------------
  wire [3:0] wr_ptr_next = wr_ptr + {3'b000, (wr_en && !full)};
  wire [3:0] rd_ptr_next = rd_ptr + {3'b000, (rd_en && !empty)};

  // ***** WRITE OPERATION (wr_clk domain) *****
  always @(posedge wr_clk) begin
    if (rst) begin
      wr_ptr      <= 4'b0;
      wr_ptr_gray <= 4'b0;
    end
    else begin
      if (wr_en && !full)
        mem[wr_ptr[2:0]] <= wr_data;      // index with address bits only
      wr_ptr      <= wr_ptr_next;
      wr_ptr_gray <= wr_ptr_next ^ (wr_ptr_next >> 1);
    end
  end

  // ***** READ OPERATION (rd_clk domain) *****
  always @(posedge rd_clk) begin
    if (rst) begin
      rd_ptr      <= 4'b0;
      rd_ptr_gray <= 4'b0;
    end
    else begin
      if (rd_en && !empty)
        rd_data <= mem[rd_ptr[2:0]];      // registered read (1-cycle latency)
      rd_ptr      <= rd_ptr_next;
      rd_ptr_gray <= rd_ptr_next ^ (rd_ptr_next >> 1);
    end
  end

  // ***** Synchronize write pointer into read clock domain *****
  always @(posedge rd_clk) begin
    if (rst) begin
      wr_ptr_gray_ff1  <= 4'b0;
      wr_ptr_gray_ff2  <= 4'b0;
      wr_ptr_gray_sync <= 4'b0;
    end
    else begin
      wr_ptr_gray_ff1  <= wr_ptr_gray;
      wr_ptr_gray_ff2  <= wr_ptr_gray_ff1;
      wr_ptr_gray_sync <= wr_ptr_gray_ff2;
    end
  end

  // ***** Synchronize read pointer into write clock domain *****
  always @(posedge wr_clk) begin
    if (rst) begin
      rd_ptr_gray_ff1  <= 4'b0;
      rd_ptr_gray_ff2  <= 4'b0;
      rd_ptr_gray_sync <= 4'b0;
    end
    else begin
      rd_ptr_gray_ff1  <= rd_ptr_gray;
      rd_ptr_gray_ff2  <= rd_ptr_gray_ff1;
      rd_ptr_gray_sync <= rd_ptr_gray_ff2;
    end
  end

  // ***** EMPTY CONDITION (read domain) *****
  assign empty = (rd_ptr_gray == wr_ptr_gray_sync);

  // ***** FULL CONDITION (write domain) *****
  // Binary full = MSB differs, lower bits equal.
  // In Gray this maps to: top two bits inverted, remaining bits equal.
  assign full  = (wr_ptr_gray == {~rd_ptr_gray_sync[3:2], rd_ptr_gray_sync[1:0]});

endmodule