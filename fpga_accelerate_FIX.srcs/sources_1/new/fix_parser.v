`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/15/2025 05:49:44 PM
// Design Name: 
// Module Name: fix_parser
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


module fix_parser(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data_in,      // Incoming ASCII character
    input  wire       data_valid,   // Indicates valid data_in
    output reg [15:0] parsed_value, // Output parsed numeric value
    output reg        valid_out     // High when parsed_value is valid

    );

// Define FSM states
localparam IDLE             = 3'd0,
           READ_TAG         = 3'd1,
           READ_VALUE       = 3'd2,
           FIELD_COMPLETE   = 3'd3,
           MESSAGE_COMPLETE = 3'd4;

reg [2:0] state, next_state;
reg [15:0] value_buffer;
reg [3:0]  value_index;  // (Optional) to count digits, if needed

// Sequential block: state update and state-dependent operations
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state         <= IDLE;
        value_buffer  <= 16'd0;
        value_index   <= 4'd0;
        parsed_value  <= 16'd0;
        valid_out     <= 1'b0;
    end else begin
        state <= next_state;
        case (state)
            // While reading the value, accumulate digit characters
            READ_VALUE: begin
                if (data_valid) begin
                    // Check if the character is a digit ('0' to '9')
                    if (data_in >= "0" && data_in <= "9") begin
                        // Convert ASCII digit to numeric and accumulate
                        value_buffer <= value_buffer * 10 + (data_in - "0");
                        value_index  <= value_index + 1;
                    end
                end
            end
            // When a field is complete, output the parsed value
            FIELD_COMPLETE: begin
                parsed_value <= value_buffer;
                valid_out    <= 1'b1;
                // Reset the buffer for the next field
                value_buffer <= 16'd0;
                value_index  <= 4'd0;
            end
            default: begin
                valid_out <= 1'b0;
            end
        endcase
    end
end

// Combinational block: next state logic
always @(*) begin
    next_state = state; // Default: remain in current state
    case (state)
        IDLE: begin
            // Wait for the start-of-message; here we check for '8' (as in "8=FIX.4.2")
            if (data_valid && data_in == "8")
                next_state = READ_TAG;
        end
        READ_TAG: begin
            // Expect the equals sign ("=") to denote end of the tag field
            if (data_valid && data_in == "=")
                next_state = READ_VALUE;
        end
        READ_VALUE: begin
            // Continue reading value characters until a delimiter '|' is received
            if (data_valid && data_in == "|")
                next_state = FIELD_COMPLETE;
        end
        FIELD_COMPLETE: begin
            // After processing one field, for this basic example, we assume the message is complete.
            // In a more elaborate design, you would return to READ_TAG to parse the next field.
            next_state = MESSAGE_COMPLETE;
        end
        MESSAGE_COMPLETE: begin
            // End-of-message processing complete; return to IDLE to await a new message
            next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end

endmodule

