`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 17:57:30 PM
// Design Name: 
// Module Name: uart_receiver
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

module uart_receiver #(
    parameter CLKS_PER_BIT = 867  // 100 MHz / 115200 baud ≈ 867
)(
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,
    output reg [7:0]  data_out,
    output reg        data_valid
);

    // States for UART RX state machine
    localparam IDLE         = 3'b000;
    localparam START_BIT    = 3'b001;
    localparam DATA_BITS    = 3'b010;
    localparam STOP_BIT     = 3'b011;
    localparam CLEANUP      = 3'b100;
    
    reg [2:0]  state;
    reg [15:0] clock_count;
    reg [2:0]  bit_index;
    reg        rx_data;
    reg        rx_data_r;
    
    // Double FF synchronizer for RX input
    always @(posedge clk) begin
        rx_data_r <= rx;
        rx_data   <= rx_data_r;
    end
    
    // UART RX state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            clock_count  <= 0;
            bit_index    <= 0;
            data_out     <= 0;
            data_valid   <= 0;
        end else begin
            // Default state for data_valid
            data_valid <= 0;
            
            case (state)
                IDLE: begin
                    clock_count <= 0;
                    bit_index   <= 0;
                    
                    if (rx_data == 1'b0)     // Start bit detected
                        state <= START_BIT;
                    else
                        state <= IDLE;
                end
                
                START_BIT: begin
                    // Check middle of start bit
                    if (clock_count == (CLKS_PER_BIT-1)/2) begin
                        if (rx_data == 1'b0) begin
                            clock_count <= 0;
                            state       <= DATA_BITS;
                        end else
                            state <= IDLE;
                    end else begin
                        clock_count <= clock_count + 1;
                        state       <= START_BIT;
                    end
                end
                
                DATA_BITS: begin
                    if (clock_count < CLKS_PER_BIT-1) begin
                        clock_count <= clock_count + 1;
                        state       <= DATA_BITS;
                    end else begin
                        clock_count          <= 0;
                        data_out[bit_index]  <= rx_data;  // Sample the rx_data
                        
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1;
                            state     <= DATA_BITS;
                        end else begin
                            bit_index <= 0;
                            state     <= STOP_BIT;
                        end
                    end
                end
                
                STOP_BIT: begin
                    if (clock_count < CLKS_PER_BIT-1) begin
                        clock_count <= clock_count + 1;
                        state       <= STOP_BIT;
                    end else begin
                        data_valid  <= 1'b1;
                        clock_count <= 0;
                        state       <= CLEANUP;
                    end
                end
                
                CLEANUP: begin
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
