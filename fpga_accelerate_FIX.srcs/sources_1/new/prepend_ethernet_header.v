`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/18/2025 08:19:55 PM
// Design Name: 
// Module Name: prepend_ethernet_header
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

module prepend_ethernet_header
#(
    parameter [47:0] DST_ADDR   = 48'h00105E000000,
    parameter [47:0] SRC_ADDR   = 48'h00155E2ABC01,
    parameter [15:0] ETHER_TYPE = 16'h0800
)
(
    input         clk_i,
    input         start_of_packet_i,
    input         end_of_packet_i,
    input  [63:0] data_i,
    input  [2:0]  byte_count_i,
    output        start_of_packet_o,
    output        end_of_packet_o,
    output [63:0] data_o,
    output [2:0]  byte_count_o
);

    parameter IDLE    = 2'b00;
    parameter HEADER1 = 2'b01;
    parameter HEADER2 = 2'b10;
    parameter PAYLOAD = 2'b11;

    reg [1:0] state, next_state;
    reg [63:0] data_reg;
    reg [2:0]  bc_reg;

    always @(posedge clk_i) begin
        state    <= next_state;
        data_reg <= data_i;
        bc_reg   <= byte_count_i;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:    next_state = start_of_packet_i ? HEADER1 : IDLE;
            HEADER1: next_state = HEADER2;
            HEADER2: next_state = PAYLOAD;
            PAYLOAD: next_state = end_of_packet_i ? IDLE : PAYLOAD;
            default: next_state = IDLE;
        endcase
    end

    wire [63:0] header_word1 = { DST_ADDR, SRC_ADDR[47:32] };
    wire [63:0] header_word2 = { SRC_ADDR[31:0], ETHER_TYPE, 16'b0 }; // Pad with zeros instead of payload data

    reg        start_of_packet_int;
    reg        end_of_packet_int;
    reg [63:0] data_int;
    reg [2:0]  bc_int;

    always @(*) begin
        start_of_packet_int = 0;
        end_of_packet_int   = 0;
        data_int            = 0;
        bc_int              = 0;

        case (state)
            HEADER1: begin
                start_of_packet_int = 1;
                data_int = header_word1;
                bc_int = 3'b111; // 8 bytes valid
            end
            HEADER2: begin
                data_int = header_word2;
                bc_int = 3'b101; // 6 bytes valid
            end
            PAYLOAD: begin
                data_int = data_reg;
                bc_int = bc_reg;
                end_of_packet_int = end_of_packet_i;
            end
            default: ;
        endcase
    end

    assign start_of_packet_o = start_of_packet_int;
    assign end_of_packet_o   = end_of_packet_int;
    assign data_o            = data_int;
    assign byte_count_o      = bc_int;

endmodule

