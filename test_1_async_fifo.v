// ============================================================
//  Testbench 1 : Write clock FASTER, Read clock SLOWER
//  wr_clk = 10 ns period, rd_clk = 20 ns period
//  Exercises the FULL condition
// ============================================================

`timescale 1ns/1ps

module test_bench;

  reg        wr_clk, rd_clk, rst, wr_en, rd_en;
  reg  [7:0] wr_data;
  wire [7:0] rd_data;
  wire       full, empty;

  async_fifo ASYNC_FIFO (wr_clk, rd_clk, rst, wr_en, rd_en,
                         wr_data, rd_data, full, empty);

  // Write clock : 10 ns period (faster)
  initial begin
    wr_clk = 1'b0;
    forever #5 wr_clk = ~wr_clk;
  end

  // Read clock : 20 ns period (slower)
  initial begin
    rd_clk = 1'b1;
    forever #10 rd_clk = ~rd_clk;
  end

  initial begin
    $dumpfile("FIFO_test1.vcd");
    $dumpvars(0, test_bench);
    $monitor("t=%0t | wr_en=%b wr_data=%h | rd_en=%b rd_data=%h | full=%b empty=%b",
             $time, wr_en, wr_data, rd_en, rd_data, full, empty);

    rst     = 1;
    wr_en   = 0;
    rd_en   = 0;
    wr_data = 8'h00;
    #12;
    rst = 0;

    // ---- Write phase : 10 attempts (FIFO depth is 8) ----
    repeat (10) begin
      @(posedge wr_clk);
      if (!full) begin
        wr_en   = 1;
        wr_data = wr_data + 1;
      end
      else
        wr_en = 0;
    end
    wr_en = 0;

    #20;

    // ---- Read phase : 10 attempts ----
    repeat (10) begin
      @(posedge rd_clk);
      if (!empty)
        rd_en = 1;
      else
        rd_en = 0;
    end
    rd_en = 0;

    #100 $finish;
  end

endmodule