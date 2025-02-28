`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/16/2025 12:09:30 AM
// Design Name: 
// Module Name: fix_message_buffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fix_message_buffer(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data_in,      // Incoming ASCII data
    input  wire       data_valid,   // Data valid signal
    // FIFO Outputs (for example purposes, here we expose each FIFO's output and empty flag)
    output wire [7:0] fifo0_data,
    output wire       fifo0_empty,
    output wire [7:0] fifo1_data,
    output wire       fifo1_empty,
    output wire [7:0] fifo2_data,
    output wire       fifo2_empty,
    output wire [7:0] fifo3_data,
    output wire       fifo3_empty
);

    // Define the message terminator (using newline 0x0A as an example)
    localparam MSG_TERM = 8'h0A;  
    
    reg [2:0] state, next_state; //for statemachine for determining rr_index
    parameter S0 = 2'b00, S1 = 2'b01, S2 = 2'b10;


    // Round-robin pointer (2 bits for 4 FIFOs)
    reg [1:0] rr_index;

    // Write enable and data signals for each FIFO
    reg fifo0_we, fifo1_we, fifo2_we, fifo3_we;
    reg [7:0] fifo0_din, fifo1_din, fifo2_din, fifo3_din;

    // Internal wires to check FIFO full status (if needed)
    wire fifo0_full, fifo1_full, fifo2_full, fifo3_full;

    // Round-robin write logic: write incoming data to the selected FIFO.
    // When the message terminator is encountered, move to the next FIFO.
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rr_index   <= 2'b00;
            fifo0_we   <= 1'b0;
            fifo1_we   <= 1'b0;
            fifo2_we   <= 1'b0;
            fifo3_we   <= 1'b0;
            fifo0_din  <= 8'd0;
            fifo1_din  <= 8'd0;
            fifo2_din  <= 8'd0;
            fifo3_din  <= 8'd0;
            state <= IDLE;
        end else begin
            // Default: disable all write enables
            fifo0_we <= 1'b0;
            fifo1_we <= 1'b0;
            fifo2_we <= 1'b0;
            fifo3_we <= 1'b0;
            state <= next_state;

            if (data_valid) begin
                // Write to the FIFO selected by rr_index, if not full
                case (rr_index)
                    2'b00: begin
                        if (!fifo0_full) begin
                            fifo0_we  <= 1'b1;
                            fifo0_din <= data_in;
                        end
                    end
                    2'b01: begin
                        if (!fifo1_full) begin
                            fifo1_we  <= 1'b1;
                            fifo1_din <= data_in;
                        end
                    end
                    2'b10: begin
                        if (!fifo2_full) begin
                            fifo2_we  <= 1'b1;
                            fifo2_din <= data_in;
                        end
                    end
                    2'b11: begin
                        if (!fifo3_full) begin
                            fifo3_we  <= 1'b1;
                            fifo3_din <= data_in;
                        end
                    end
                endcase

                // If this byte is the message terminator, finish the message
                // and move to the next FIFO for the next message.
                      // Update state
            // Check for rr_index increment condition
                    if (state == S2 && data_in == "|") begin
                        rr_index <= rr_index + 1;  // Increment rr_index when '|' is detected
                    end

//                if (data_in == MSG_TERM)
//                    rr_index <= rr_index + 1;  // Wraps around automatically (2-bit register)
                //
            end
        end
    end
     
     //Statemachine for determining the end of the FIX message
     always @(*) begin
        // Default next state is the current state
        next_state = state;

        case (state)
            // IDLE State: Waiting for '1'
            IDLE: begin
                if (data_in == "1")
                    next_state = S1;
                else
                    next_state = IDLE;
            end

            // S1 State: Waiting for '0' after '1'
            S1: begin
                if (data_in == "0")
                    next_state = S2;
                else
                    next_state = IDLE;
            end

            // S2 State: Consuming '=', digits, and checking for '|'
            S2: begin
                if (data_in == "=")
                    next_state = S2;  // Stay in S2 after '='
                else if (data_in >= "0" && data_in <= "9")
                    next_state = S2;  // Stay in S2 while consuming digits
                else if (data_in == "|")
                    next_state = IDLE;  // After detecting '|', reset to IDLE
                else
                    next_state = IDLE;  // Any other character resets to IDLE
            end

            default: next_state = IDLE;
        endcase
    end
fifo_generator_0 fifo0 (
        .clk(clk),
        .srst(rst),
	     .din(fifo0_din),
        .wr_en(fifo0_we),
        .rd_en(1'b0),
        .dout(fifo0_data),
        .full(fifo0_full),
        .empty(fifo0_empty)
    );

    fifo_generator_0 fifo1 (
        .clk(clk),
        .srst(rst),
	     .din(fifo1_din),
        .wr_en(fifo1_we),
        .rd_en(1'b0),
        .dout(fifo1_data),
        .full(fifo1_full),
        .empty(fifo1_empty)
    );
fifo_generator_0 fifo2 (
        .clk(clk),
        .srst(rst),
	     .din(fifo2_din),
        .wr_en(fifo2_we),
        .rd_en(1'b0),
        .dout(fifo2_data),
        .full(fifo2_full),
        .empty(fifo2_empty)
    );
fifo_generator_0 fifo3 (
        .clk(clk),
        .srst(rst),
	     .din(fifo3_din),
        .wr_en(fifo3_we),
        .rd_en(1'b0),
        .dout(fifo3_data),
        .full(fifo3_full),
        .empty(fifo3_empty)
    );


endmodule

