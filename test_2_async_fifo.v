// Write --> Slower and Read --> Faster

module test_bench ;

reg wr_clk,rd_clk,rst,wr_en,rd_en ;
reg [7:0] wr_data ; 
wire [7:0] rd_data ;
wire full,empty ;

async_fifo ASYNC_FIFO (wr_clk,rd_clk,rst,wr_en,rd_en,wr_data,rd_data,full,empty) ;

initial 
    begin
        wr_clk = 1'b0 ;
        forever 
            #10 wr_clk = ~ wr_clk ; // Write slower
    end

initial
    begin
        rd_clk = 1'b1 ;
        forever
            #5 rd_clk = ~ rd_clk ; // Read faster
    end

initial 
    begin
        $dumpfile ("FIFO.vcd") ;
        $dumpvars (0,test_bench) ;
        $monitor("wr_en=%b wr_data=%h | rd_en=%b rd_data=%h | full=%b empty=%b ",
              wr_en, wr_data, rd_en, rd_data, full, empty) ;

        rst = 1 ;
        wr_en = 0 ;
        rd_en = 0 ;
        wr_data = 8'h00 ;
        #12 ;

        rst = 0 ;

        repeat (5) 
            begin
                @(posedge wr_clk);
                if (!full) 
                    begin
                        wr_en = 1;
                        wr_data = wr_data + 1;
                    end 
                else 
                    begin
                        wr_en = 0;
                    end
            end

    wr_en = 0 ;  

    #20;
    repeat (10) 
        begin
            @(posedge rd_clk);
            if (!empty)
                rd_en = 1;
            else
                rd_en = 0;
        end

    rd_en = 0 ;

    #100 $finish ;
    end
endmodule