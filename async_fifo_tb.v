module async_fifo_tb;

    parameter WIDTH = 8;
    parameter DEPTH = 16;

    // Signals for the FIFO 
    reg wr_clk;             
    reg rd_clk;             
    reg reset;              
    reg wr_en;              
    reg rd_en;              
    reg [WIDTH-1:0] write_data; 
    wire [WIDTH-1:0] read_data; 
    wire full;              
    wire empty;             

    // Instantiate the asynchronous FIFO module
    async_fifo #(WIDTH, DEPTH) fifo_inst (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .reset(reset),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .write_data(write_data),
        .read_data(read_data),
        .full(full),
        .empty(empty)
    );

    // Generate the write clock signal 
    initial begin
        wr_clk = 0;
        forever #5 wr_clk = ~wr_clk; // Toggle write clock every 5 time units
    end

    // Generate the read clock signal 
    initial begin
        rd_clk = 0;
        forever #7 rd_clk = ~rd_clk; // Toggle read clock every 7 time units
    end

    // Testbench sequence to test the FIFO functionality
    initial begin
        reset = 0;       // Apply reset (active low)
        wr_en = 0;       // Disable write
        rd_en = 0;       // Disable read
        write_data = 0;  // Set initial write data

        // Release reset after 10 time units
        #10 reset = 1;

        // Write 3 data values to the FIFO
        #10 wr_en = 1;
        write_data = 8'hA5;     // First data (0xA5)
        #10 write_data = 8'h5A; // Second data (0x5A)
        #10 write_data = 8'h3C; // Third data (0x3C)
        #10 wr_en = 0;          // Stop writing after 3 values
        #10;                    // Allow time for write to process

        // Wait and then start reading data from the FIFO
        #20 rd_en = 1;  // Enable read
        #40 rd_en = 0;  // Read data for a short time
        #10;            // Allow time for read to process

        // Check read results
        $display("Read Data: %h", read_data);

        // Test for FIFO Full Condition
        #50;
        $display("Starting FIFO full test...");
        wr_en = 1;
        // Try writing 16 values to fill the FIFO
        repeat (DEPTH) 
        begin
            write_data = $random; // Use random data
            #10;                  // Allow time for each write
        end

        // Check if FIFO is full after writing 16 values
        #10 wr_en = 0; // Stop writing
        #10;           // Allow time for full condition to settle
        if (!full) 
            $display("Error: FIFO should be full after writing 16 values!");

        // Try writing one more value (should not write since full)
        write_data = 8'hFF;
        wr_en = 1;
        #10;
        if (full) 
            $display("FIFO is full. Cannot write more data.");
        wr_en = 0;

        // Read all data out of the FIFO 
        #20;
        rd_en = 1; // Enable read
        // Read until FIFO is empty
        while (!empty) begin
            #10; // Allow time for each read operation
            $display("Time = %0t, Read Data = %h, Empty = %b", $time, read_data, empty);
        end
        
        rd_en = 0; // Disable read after done

        // Allow additional time for the FIFO state to settle
        #20; 

        // Check if FIFO is empty after reading all values 
        if (!empty) 
            $display("Error: FIFO should be empty after reading all values!");
        else 
            $display("FIFO is empty as expected.");

        // Test for FIFO Empty Condition 
        rd_en = 1; // Try reading when FIFO is empty
        #10;
        if (empty) 
            $display("FIFO is empty. Cannot read more data.");
        rd_en = 0;

        // End the simulation after 100 time units
        #100 $finish;
    end

    // Monitor the values of important signals for debugging
    initial begin
        $monitor("Time = %0t, wr_data = %h, rd_data = %h, full = %b, empty = %b", 
                 $time, write_data, read_data, full, empty);
    end

endmodule
