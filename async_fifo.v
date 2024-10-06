module async_fifo #(parameter WIDTH = 8, parameter DEPTH = 16) (
    input wire wr_clk, // Write clock signal 
    input wire rd_clk, // Read clock signal 
    input wire reset,  // Active low reset signal
    input wire wr_en,  // Write enable signal
    input wire rd_en,  // Read enable signal
    input wire [WIDTH-1:0] write_data, // Input data 
    output reg [WIDTH-1:0] read_data, // Output data 
    output wire full, // FIFO full flag
    output wire empty // FIFO empty flag
);

    // Calculate the number of address bits required based on FIFO depth
    localparam ADDR = $clog2(DEPTH);

    // FIFO memory 
    reg [WIDTH-1:0] fifo_mem [0:DEPTH-1];
    
    // Write and read pointers to track the position in the FIFO
    // Pointers are gray-coded to prevent metastability when crossing clock domains
    reg [WIDTH:0] wr_ptr, rd_ptr;
    reg [WIDTH:0] wr_ptr_gray, rd_ptr_gray;
    reg [WIDTH:0] wr_ptr_gray_sync, rd_ptr_gray_sync; // Synchronized gray-coded pointers

    // Write logic
    always @(posedge wr_clk or negedge reset) begin
        if (!reset) 
        begin
            wr_ptr <= 0;      // Reset write pointer
            wr_ptr_gray <= 0; // Reset gray-coded write pointer
        end 
        else if (wr_en && !full) 
        begin
            fifo_mem[wr_ptr[ADDR-1:0]] <= write_data; // Write data to the FIFO memory
            wr_ptr <= wr_ptr + 1;                      // Increment write pointer
            wr_ptr_gray <= (wr_ptr >> 1) ^ wr_ptr;     // Convert write pointer to gray code
        end
    end

    // Read logic
    always @(posedge rd_clk or negedge reset) 
    begin
        if (!reset) begin
            rd_ptr <= 0;      // Reset read pointer
            rd_ptr_gray <= 0; // Reset gray-coded read pointer
            read_data <= 0;     // Reset output data 
        end 
        else if (rd_en && !empty) 
        begin
            read_data <= fifo_mem[rd_ptr[ADDR-1:0]]; // Read data from FIFO memory
            rd_ptr <= rd_ptr + 1;                    // Increment read pointer
            rd_ptr_gray <= (rd_ptr >> 1) ^ rd_ptr;   // Convert read pointer to gray code
        end
    end

    // Synchronize the write pointer into the read clock domain
    always @(posedge rd_clk or negedge reset) 
    begin
        if (!reset) 
        begin
            wr_ptr_gray_sync <= 0;           // Reset synchronized write pointer
        end 
        else 
        begin
            wr_ptr_gray_sync <= wr_ptr_gray; // Synchronize gray-coded write pointer
        end
    end

    // Synchronize the read pointer into the write clock domain
    always @(posedge wr_clk or negedge reset) 
    begin
        if (!reset) 
        begin
            rd_ptr_gray_sync <= 0;           // Reset synchronized read pointer
        end 
        else 
        begin
            rd_ptr_gray_sync <= rd_ptr_gray; // Synchronize gray-coded read pointer
        end
    end

    // Full condition: When the gray-coded write pointer is one position behind
    assign full  = (wr_ptr_gray == {~rd_ptr_gray_sync[ADDR:ADDR-1], rd_ptr_gray_sync[ADDR-2:0]});
    
    // Empty condition: When the gray-coded write pointer is equal to the synchronized
    assign empty = (rd_ptr_gray == wr_ptr_gray_sync);

endmodule

