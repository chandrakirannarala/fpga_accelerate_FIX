`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/15/2025 05:54:23 PM
// Design Name: 
// Module Name: fix_parser_tb
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


module fix_parser_tb;

  reg         clk;
  reg         rst;
  reg  [7:0]  data_in;
  reg         data_valid;
  wire [15:0] parsed_value;
  wire        valid_out;

  // Instantiate the fix_parser module
  fix_parser uut (
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .data_valid(data_valid),
    .parsed_value(parsed_value),
    .valid_out(valid_out)
  );

  // Clock generation: 10ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Stimulus generation
  initial begin
    $display("Starting simulation...");
    
    // Initialize signals
    rst = 1;
    data_valid = 0;
    data_in = 8'd0;
    #15;
    
    // Release reset
    rst = 0;
    
    // Feed a simplified FIX message: "8=123|" as in "8=FIX.4.2"
    // Note: In ASCII, '8' = 56, '=' = 61, '1' = 49, '2' = 50, '3' = 51, '|' = 124
    // Here, we use Verilog character literals which represent their ASCII values.
    
    // Provide "8" (start-of-message)
    #10;
    data_valid = 1;
    data_in = "8";
    
    // Provide "=" to complete the tag reading
    #10;
    data_in = "=";
    
    // Provide digits "1", "2", "3"
    #10; data_in = "F";
    #10; data_in = "I";
    #10; data_in = "X";
    #10; data_in = ".";
    #10; data_in = "4";
    #10; data_in = ".";
    #10; data_in = "2";
    
    // Provide "|" as a delimiter to indicate end-of-field
    #10;
    data_in = "|";
    
    // Disable data after finishing the message
    #10;
    data_valid = 0;
    
    // Wait to capture the output
    #50;
    if (valid_out)
      $display("Parsed Value: %d, valid_out: %b", parsed_value, valid_out);
    else
      $display("Parsed Value not valid yet.");
    
    #100;
    $finish;
  end

endmodule

