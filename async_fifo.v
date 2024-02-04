`timescale 1 ns / 1 ps
`default_nettype none

module async_fifo

    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE", // Existing parameters
        parameter FULL_THRESHOLD = 1, // New parameter for almost full threshold
        parameter EMPTY_THRESHOLD = 1 // New parameter for almost empty threshold
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        output wire             overflow_error,
        output wire             almost_full, // New output for almost full indication
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty,
        output wire             underflow_error,
        output wire             almost_empty // New output for almost empty indication
    );

    wire [ASIZE-1:0] waddr, raddr;
    wire [ASIZE  :0] wptr, rptr, wq2_rptr, rq2_wptr;

    // The module synchronizing the read point
    // from read to write domain
    sync_r2w
    #(ASIZE)
    sync_r2w (
    .wq2_rptr (wq2_rptr),
    .rptr     (rptr),
    .wclk     (wclk),
    .wrst_n   (wrst_n)
    );

    // The module synchronizing the write point
    // from write to read domain
    sync_w2r
    #(ASIZE)
    sync_w2r (
    .rq2_wptr (rq2_wptr),
    .wptr     (wptr),
    .rclk     (rclk),
    .rrst_n   (rrst_n)
    );

    // The module handling the write requests
    wptr_full
    #(ASIZE, FULL_THRESHOLD) // Pass FULL_THRESHOLD to the module
    wptr_full_inst (
    .awfull         (awfull),
    .wfull          (wfull),
    .overflow_error (overflow_error),
    .almost_full    (almost_full),
    .waddr          (waddr),
    .wptr           (wptr),
    .wq2_rptr       (wq2_rptr),
    .winc           (winc),
    .wclk           (wclk),
    .wrst_n         (wrst_n)
    );

    // The DC-RAM
    fifomem
    #(DSIZE, ASIZE, FALLTHROUGH)
    fifomem (
    .rclken (rinc),
    .rclk   (rclk),
    .rdata  (rdata),
    .wdata  (wdata),
    .waddr  (waddr),
    .raddr  (raddr),
    .wclken (winc),
    .wfull  (wfull),
    .wclk   (wclk)
    );

    // The module handling read requests
    rptr_empty
    #(ASIZE, EMPTY_THRESHOLD) // Pass EMPTY_THRESHOLD to the module
    rptr_empty_inst (
    .arempty         (arempty),
    .rempty          (rempty),
    .underflow_error (underflow_error),
    .almost_empty    (almost_empty),
    .raddr           (raddr),
    .rptr            (rptr),
    .rq2_wptr        (rq2_wptr),
    .rinc            (rinc),
    .rclk            (rclk),
    .rrst_n          (rrst_n)
    );

endmodule

module sync_r2w

    #(
    parameter ASIZE = 4
    )(
    input  wire              wclk,
    input  wire              wrst_n,
    input  wire [ASIZE:0] rptr,
    output reg  [ASIZE:0] wq2_rptr
    );

    reg [ASIZE:0] wq1_rptr;

    always @(posedge wclk or negedge wrst_n) begin

        if (!wrst_n)
            {wq2_rptr,wq1_rptr} <= 0;
        else
            {wq2_rptr,wq1_rptr} <= {wq1_rptr,rptr};

    end

endmodule

module sync_w2r

    #(
    parameter ASIZE = 4
    )(
    input  wire              rclk,
    input  wire              rrst_n,
    output reg  [ASIZE:0] rq2_wptr,
    input  wire [ASIZE:0] wptr
    );

    reg [ASIZE:0] rq1_wptr;

    always @(posedge rclk or negedge rrst_n) begin

        if (!rrst_n)
            {rq2_wptr,rq1_wptr} <= 0;
        else
            {rq2_wptr,rq1_wptr} <= {rq1_wptr,wptr};

    end

endmodule

module wptr_full #(
    parameter ADDRSIZE = 4,
    parameter FULL_THRESHOLD = 1 // New parameter for full threshold
)(
    input  wire                wclk,
    input  wire                wrst_n,
    input  wire                winc,
    input  wire [ADDRSIZE  :0] wq2_rptr,
    output reg                 wfull,
    output reg                 awfull,
    output reg                 almost_full, // New output for almost full signal
    output wire [ADDRSIZE-1:0] waddr,
    output reg  [ADDRSIZE  :0] wptr
);

    reg  [ADDRSIZE:0] wbin;
    wire [ADDRSIZE:0] wgraynext, wbinnext, wgraynextp1;
    wire              wfull_val, awfull_val, almost_full_val;

    // Logic for wfull, awfull, and almost_full calculations remains similar
    // Add logic to calculate almost_full based on FULL_THRESHOLD
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            almost_full <= 0; // Reset on reset
        end else begin
            // Logic to set almost_full based on FULL_THRESHOLD
            almost_full <= almost_full_val;
        end
    end

    // Calculate almost_full_val based on the distance between wptr and wq2_rptr
    assign almost_full_val = /* Logic to determine if FIFO is almost full */;
endmodule


module fifomem

    #(
        parameter  DATASIZE = 8,    // Memory data word width
        parameter  ADDRSIZE = 4,    // Number of mem address bits
        parameter  FALLTHROUGH = "TRUE" // First word fall-through
    ) (
        input  wire                wclk,
        input  wire                wclken,
        input  wire [ADDRSIZE-1:0] waddr,
        input  wire [DATASIZE-1:0] wdata,
        input  wire                wfull,
        input  wire                rclk,
        input  wire                rclken,
        input  wire [ADDRSIZE-1:0] raddr,
        output wire [DATASIZE-1:0] rdata
    );

    localparam DEPTH = 1<<ADDRSIZE;

    reg [DATASIZE-1:0] mem [0:DEPTH-1];
    reg [DATASIZE-1:0] rdata_r;

    always @(posedge wclk) begin
        if (wclken && !wfull)
            mem[waddr] <= wdata;
    end

    generate
        if (FALLTHROUGH == "TRUE")
        begin : fallthrough
            assign rdata = mem[raddr];
        end
        else
        begin : registered_read
            always @(posedge rclk) begin
                if (rclken)
                    rdata_r <= mem[raddr];
            end
            assign rdata = rdata_r;
        end
    endgenerate

endmodule

module rptr_empty #(
    parameter ADDRSIZE = 4,
    parameter EMPTY_THRESHOLD = 1 // New parameter for empty threshold
)(
    input  wire                rclk,
    input  wire                rrst_n,
    input  wire                rinc,
    input  wire [ADDRSIZE  :0] rq2_wptr,
    output reg                 rempty,
    output reg                 arempty,
    output reg                 almost_empty, // New output for almost empty signal
    output wire [ADDRSIZE-1:0] raddr,
    output reg  [ADDRSIZE  :0] rptr
);

    reg  [ADDRSIZE:0] rbin;
    wire [ADDRSIZE:0] rgraynext, rbinnext, rgraynextm1;
    wire              rempty_val, arempty_val, almost_empty_val;

    // Logic for rempty, arempty, and almost_empty calculations remains similar
    // Add logic to calculate almost_empty based on EMPTY_THRESHOLD
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            almost_empty <= 0; // Reset on reset
        end else begin
            // Logic to set almost_empty based on EMPTY_THRESHOLD
            almost_empty <= almost_empty_val;
        end
    end

    // Calculate almost_empty_val based on the distance between rptr and rq2_wptr
    assign almost_empty_val = /* Logic to determine if FIFO is almost empty */;
endmodule

`resetall
