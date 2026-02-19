// ### ASYNCHRONOUS FIFO ###

// NOTE : I am doing all comparisions in gray itself rather than converting the gray process into binary 

module async_fifo (wr_clk,rd_clk,rst,wr_en,rd_en,wr_data,rd_data,full,empty) ;

input wr_clk,rd_clk,rst,wr_en,rd_en ;
input [7:0] wr_data ;
output reg [7:0] rd_data ;
output full,empty ;

reg [3:0] wr_ptr,rd_ptr;
wire [3:0] wr_ptr_gray,rd_ptr_gray ;

reg [7:0] mem [7:0] ; // FIFO

reg [3:0] wr_ptr_gray_ff1,wr_ptr_gray_ff2  ; // Synchronize read and write pointers ( Gray Code )
reg [3:0] wr_ptr_gray_sync ;
reg [3:0] rd_ptr_gray_ff1,rd_ptr_gray_ff2 ;
reg [3:0] rd_ptr_gray_sync ;

// ***** WRITE OPERATION *****
always @ (posedge wr_clk)
    begin
        if (rst)
            wr_ptr <= 4'b0 ;
        else
            begin
                if (wr_en && !full) 
                    begin
                        mem[wr_ptr] <= wr_data ;
                        wr_ptr <= wr_ptr + 1 ;
                    end    
            end    
    end

// ***** READ OPERATION *****
always @ (posedge rd_clk) 
    begin
        if (rst)
            rd_ptr <= 4'b0 ;
        else
            begin
                if (rd_en && !empty)
                    begin
                        rd_data <= mem[rd_ptr] ;
                        rd_ptr <= rd_ptr + 1 ;
                    end
            end
    end
// ***** Convert Binary read and write pointers to Gray code *****
assign wr_ptr_gray = wr_ptr ^ (wr_ptr >> 1) ;
assign rd_ptr_gray = rd_ptr ^ (rd_ptr >> 1) ;

// ***** Synchronize the write pointer to the read clock domain *****
always @ (posedge rd_clk) 
    begin
        if (rst) 
            begin
                wr_ptr_gray_ff1 <= 0 ;
                wr_ptr_gray_ff2 <= 0 ;
                wr_ptr_gray_sync <= 0 ;
            end
        else
            begin
                wr_ptr_gray_ff1 <= wr_ptr_gray ;
                wr_ptr_gray_ff2 <= wr_ptr_gray_ff1 ;
                wr_ptr_gray_sync <= wr_ptr_gray_ff2 ;
            end    
    end

// ***** Synchronize the read pointer to the write clock domain *****
always @ (posedge wr_clk) 
    begin
        if (rst) 
            begin
                rd_ptr_gray_ff1 <= 0 ;
                rd_ptr_gray_ff2 <= 0 ;
                rd_ptr_gray_sync <= 0 ;
            end
        else
            begin
                rd_ptr_gray_ff1 <= rd_ptr_gray ;
                rd_ptr_gray_ff2 <= rd_ptr_gray_ff1 ;
                rd_ptr_gray_sync <= rd_ptr_gray_ff2 ;
            end    
    end

// ***** EMPTY CONDITION *****
assign empty = (rd_ptr_gray == wr_ptr_gray_sync) ;

// ***** FULL CONDITION *****
assign full = (wr_ptr_gray == {~rd_ptr_gray_sync[3:2], rd_ptr_gray_sync[1:0]});

endmodule