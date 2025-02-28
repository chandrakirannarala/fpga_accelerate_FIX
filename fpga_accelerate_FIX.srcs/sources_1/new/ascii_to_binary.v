`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 17:57:30 PM
// Design Name: 
// Module Name: ascii_to_binary
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
module ascii_to_binary(
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] ascii_in,       // ASCII value to convert (e.g., tag value)
    input  wire        ascii_valid,    // Input valid signal
    output reg  [15:0] binary_out,     // Binary representation
    output reg         binary_valid    // Output valid signal
);

    // Intermediate registers
    reg [15:0] ascii_buffer;
    reg        processing;
    reg [3:0]  digit_count;
    reg [15:0] result;
    
    // ASCII to binary conversion state machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            binary_out    <= 16'd0;
            binary_valid  <= 1'b0;
            ascii_buffer  <= 16'd0;
            processing    <= 1'b0;
            digit_count   <= 4'd0;
            result        <= 16'd0;
        end else begin
            // Default state for output valid
            binary_valid <= 1'b0;
            
            // Capture new input when valid
            if (ascii_valid && !processing) begin
                ascii_buffer <= ascii_in;
                processing   <= 1'b1;
                digit_count  <= 4'd0;
                result       <= 16'd0;
            end
            
            // Process the conversion
            if (processing) begin
                // Check if current ASCII code is a digit (0-9)
                if (ascii_buffer[7:0] >= 8'd48 && ascii_buffer[7:0] <= 8'd57) begin
                    // Convert ASCII to numeric value and add to result
                    result <= result * 10 + (ascii_buffer[7:0] - 8'd48);
                    digit_count <= digit_count + 1;
                end
                
                // Move to next digit if there's a higher byte
                if (digit_count < 4'd4 && |ascii_buffer[15:8]) begin
                    ascii_buffer <= {8'h00, ascii_buffer[15:8]};
                end else begin
                    // Conversion complete
                    binary_out   <= result;
                    binary_valid <= 1'b1;
                    processing   <= 1'b0;
                end
            end
        end
    end

endmodule
