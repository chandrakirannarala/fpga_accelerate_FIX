`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/18/2025 08:20:39 PM
// Design Name: 
// Module Name: prepend_ethernet_header_tb
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


//module prepend_ethernet_header_tb( 
//    );
    
//    localparam STDIN = 'h8000_0000;
 
//    reg start_of_packet_in = 'b0;
//    reg end_of_packet_in = 'b0;
//    reg [63:0] data_in = 'b0;
//    reg [2:0] byte_count_in = 'b0;
    
//    wire start_of_packet_out;
//    wire end_of_packet_out;
//    wire [63:0] data_out;
//    wire [2:0] byte_count_out;
//    reg clk = 'b1;
//    always #5 clk = ~clk;
    
//    initial #400 $finish;
    
//    integer ret;
//    always@(posedge clk) begin
//        #1; ret = $fscanf(STDIN, "%h %h %h %h", start_of_packet_in, end_of_packet_in, data_in, byte_count_in);
//    end
//    always@(posedge clk) begin
//        $display("%h %h %h %h", start_of_packet_out, end_of_packet_out, data_out, byte_count_out);
//    end
    
    
//    prepend_ethernet_header dut_inst (
//    .clk_i(clk),
//    .start_of_packet_i(start_of_packet_in) ,
//    .end_of_packet_i(end_of_packet_in),
//    .data_i(data_in),
//    .byte_count_i(byte_count_in),
//    .start_of_packet_o (start_of_packet_out),
//    .end_of_packet_o(end_of_packet_out),
//    .data_o(data_out) ,
//    .byte_count_o(byte_count_out));


//endmodule

module prepend_ethernet_header_tb( 
    );
    
    // Do not modify I/O formatting.
    reg         start_of_packet_in = 1'b0;
    reg         end_of_packet_in   = 1'b0;
    reg [63:0]  data_in            = 64'b0;
    reg [2:0]   byte_count_in      = 3'b0;
    
    wire        start_of_packet_out;
    wire        end_of_packet_out;
    wire [63:0] data_out;
    wire [2:0]  byte_count_out;
    
    reg clk = 1'b1;
    always #5 clk = ~clk;
    
    // End simulation after enough time.
    initial #100 $finish;
    
    // Remove the STDIN $fscanf stimulus and instead drive the signals directly.
    initial begin
        // Wait a couple of clock cycles before starting
        @(posedge clk);
        @(posedge clk);
        
        // --- Packet Cycle 1: Provide the given input data ---
        // Feed: "1 0 0102030405060708 0"
        start_of_packet_in = 1'b1;             // 1 (start-of-packet asserted)
        end_of_packet_in   = 1'b0;             // 0
        data_in            = 64'h0102030405060708; // 64-bit data value as given
        byte_count_in      = 3'd0;             // 0 as given
        
        @(posedge clk);
        
        // --- Packet Cycle 2: End of packet ---
        // To meet the minimum 2-cycle packet length, de-assert start and assert end.
        start_of_packet_in = 1'b0;
        end_of_packet_in   = 1'b1;             // Mark end-of-packet
        data_in            = 64'h0000000000000000; // (Payload data for cycle 2, can be any value)
        byte_count_in      = 3'd8;             // For example, assume 8 valid bytes
        
        @(posedge clk);
        
        // --- Post-Packet Idle: At least 4 clock cycles between packets ---
        start_of_packet_in = 1'b0;
        end_of_packet_in   = 1'b0;
        data_in            = 64'h0;
        byte_count_in      = 3'd0;
        repeat (4) @(posedge clk);
        
        // Optionally, additional packets can be inserted here.
        $finish;
    end
    
    // Display output values on each clock edge.
    always @(posedge clk) begin
        $display("%t: SOP_out=%h, EOP_out=%h, Data_out=%h, Byte_Count_out=%h", 
                 $time, start_of_packet_out, end_of_packet_out, data_out, byte_count_out);
    end
    
    // Instantiate the Device Under Test (DUT)
    prepend_ethernet_header dut_inst (
        .clk_i(clk),
        .start_of_packet_i(start_of_packet_in),
        .end_of_packet_i(end_of_packet_in),
        .data_i(data_in),
        .byte_count_i(byte_count_in),
        .start_of_packet_o(start_of_packet_out),
        .end_of_packet_o(end_of_packet_out),
        .data_o(data_out),
        .byte_count_o(byte_count_out)
    );

endmodule


