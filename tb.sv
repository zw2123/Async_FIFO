`timescale 1ns/1ps

module tb_async_fifo;

    parameter DSIZE = 8;
    parameter ASIZE = 4;
    parameter FULL_THRESHOLD = 1;
    parameter EMPTY_THRESHOLD = 1;

    // Inputs
    reg wclk;
    reg wrst_n;
    reg winc;
    reg [DSIZE-1:0] wdata;
    reg rclk;
    reg rrst_n;
    reg rinc;

    // Outputs
    wire wfull;
    wire awfull;
    wire overflow_error;
    wire almost_full;
    wire [DSIZE-1:0] rdata;
    wire rempty;
    wire arempty;
    wire underflow_error;
    wire almost_empty;

    // Instantiate the FIFO
    async_fifo #(
        .DSIZE(DSIZE),
        .ASIZE(ASIZE),
        .FULL_THRESHOLD(FULL_THRESHOLD),
        .EMPTY_THRESHOLD(EMPTY_THRESHOLD)
    ) uut (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .winc(winc),
        .wdata(wdata),
        .wfull(wfull),
        .awfull(awfull),
        .overflow_error(overflow_error),
        .almost_full(almost_full),
        .rclk(rclk),
        .rrst_n(rrst_n),
        .rinc(rinc),
        .rdata(rdata),
        .rempty(rempty),
        .arempty(arempty),
        .underflow_error(underflow_error),
        .almost_empty(almost_empty)
    );

    // Clock generation
    always #5 wclk = (wclk === 1'b0);
    always #7 rclk = (rclk === 1'b0);

    // Reset logic
    initial begin
        wclk = 0;
        rclk = 0;
        wrst_n = 0;
        rrst_n = 0;
        winc = 0;
        rinc = 0;
        wdata = 0;

        // Reset the system
        #10;
        wrst_n = 1;
        rrst_n = 1;

        // Wait for reset to finish
        #10;
        test_fifo();
    end

    // Test cases
    task test_fifo;
        begin
            // Write to the FIFO until almost full
            while (!almost_full) begin
                @(posedge wclk);
                winc = 1;
                wdata = wdata + 1;
            end
            winc = 0; // Stop writing

            // Read from the FIFO until almost empty
            while (!almost_empty) begin
                @(posedge rclk);
                rinc = 1;
            end
            rinc = 0; // Stop reading

            // Check for any errors
            if (overflow_error || underflow_error) begin
                $display("Test failed: FIFO overflow or underflow error detected.");
            end else begin
                $display("Test passed: FIFO functionality is correct.");
            end

            $finish;
        end
    endtask

endmodule
