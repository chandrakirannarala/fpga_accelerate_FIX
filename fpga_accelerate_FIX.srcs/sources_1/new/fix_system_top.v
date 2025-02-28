`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 17:57:30 PM
// Design Name: 
// Module Name: fix_system_top
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

module fix_system_top(
    input  wire        clk,              // System clock
    input  wire        rst,              // System reset
    // UART interface
    input  wire        uart_rx,          // UART receive
    output wire        uart_tx,          // UART transmit
    // LED indicators for status
    output wire [3:0]  status_leds,      // Status LEDs
    // Optional Ethernet interface
    output wire        eth_tx_clk,       // Ethernet transmit clock
    output wire [7:0]  eth_tx_data,      // Ethernet transmit data
    output wire        eth_tx_en         // Ethernet transmit enable
);

    // Internal signals
    wire [7:0] uart_data_out;
    wire       uart_data_valid;
    
    // FIFO signals
    wire [7:0] fifo0_data;
    wire       fifo0_empty;
    wire [7:0] fifo1_data;
    wire       fifo1_empty;
    wire [7:0] fifo2_data;
    wire       fifo2_empty;
    wire [7:0] fifo3_data;
    wire       fifo3_empty;
    
    // Parser signals
    wire [15:0] parsed_value;
    wire        parsed_valid;
    
    // Order processing signals
    wire [63:0] order_data;
    wire        order_valid;
    
    // Ethernet signals
    wire        sop_int, eop_int;
    wire [63:0] eth_data_int;
    wire [2:0]  byte_count_int;
    
    // ASCII to Binary converter signals
    wire [15:0] binary_value;
    wire        binary_valid;
    
    // Status indicators
    reg [3:0] status_reg;
    
    // UART Receiver instance
    uart_receiver uart_inst (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .data_out(uart_data_out),
        .data_valid(uart_data_valid)
    );
    
    // FIX Message Buffer instance
    fix_message_buffer buffer_inst (
        .clk(clk),
        .rst(rst),
        .data_in(uart_data_out),
        .data_valid(uart_data_valid),
        .fifo0_data(fifo0_data),
        .fifo0_empty(fifo0_empty),
        .fifo1_data(fifo1_data),
        .fifo1_empty(fifo1_empty),
        .fifo2_data(fifo2_data),
        .fifo2_empty(fifo2_empty),
        .fifo3_data(fifo3_data),
        .fifo3_empty(fifo3_empty)
    );
    
    // FIFO read logic and parser control - implementing a round-robin scheduler
    reg [1:0] fifo_read_sel;
    reg fifo0_rd_en, fifo1_rd_en, fifo2_rd_en, fifo3_rd_en;
    wire [7:0] selected_fifo_data;
    wire selected_fifo_empty;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            fifo_read_sel <= 2'b00;
            fifo0_rd_en <= 1'b0;
            fifo1_rd_en <= 1'b0;
            fifo2_rd_en <= 1'b0;
            fifo3_rd_en <= 1'b0;
        end else begin
            // Default values
            fifo0_rd_en <= 1'b0;
            fifo1_rd_en <= 1'b0;
            fifo2_rd_en <= 1'b0;
            fifo3_rd_en <= 1'b0;
            
            case (fifo_read_sel)
                2'b00: begin
                    if (!fifo0_empty) fifo0_rd_en <= 1'b1;
                    else fifo_read_sel <= fifo_read_sel + 1;
                end
                2'b01: begin
                    if (!fifo1_empty) fifo1_rd_en <= 1'b1;
                    else fifo_read_sel <= fifo_read_sel + 1;
                end
                2'b10: begin
                    if (!fifo2_empty) fifo2_rd_en <= 1'b1;
                    else fifo_read_sel <= fifo_read_sel + 1;
                end
                2'b11: begin
                    if (!fifo3_empty) fifo3_rd_en <= 1'b1;
                    else fifo_read_sel <= fifo_read_sel + 1;
                end
            endcase
            
            // Move to next FIFO when current message is processed
            if (parsed_valid) fifo_read_sel <= fifo_read_sel + 1;
        end
    end
    
    // Multiplexing logic for FIFO data selection
    assign selected_fifo_data = (fifo_read_sel == 2'b00) ? fifo0_data :
                              (fifo_read_sel == 2'b01) ? fifo1_data :
                              (fifo_read_sel == 2'b10) ? fifo2_data : fifo3_data;
                              
    assign selected_fifo_empty = (fifo_read_sel == 2'b00) ? fifo0_empty :
                               (fifo_read_sel == 2'b01) ? fifo1_empty :
                               (fifo_read_sel == 2'b10) ? fifo2_empty : fifo3_empty;
    
    // FIX Parser instance
    fix_parser parser_inst (
        .clk(clk),
        .rst(rst),
        .data_in(selected_fifo_data),
        .data_valid(!selected_fifo_empty && (fifo0_rd_en || fifo1_rd_en || fifo2_rd_en || fifo3_rd_en)),
        .parsed_value(parsed_value),
        .valid_out(parsed_valid)
    );
    
    // ASCII to Binary Converter instance
    ascii_to_binary converter_inst (
        .clk(clk),
        .rst(rst),
        .ascii_in(parsed_value),
        .ascii_valid(parsed_valid),
        .binary_out(binary_value),
        .binary_valid(binary_valid)
    );
    
    // Order Processing instance
    order_processor order_proc_inst (
        .clk(clk),
        .rst(rst),
        .value_in(binary_value),
        .value_valid(binary_valid),
        .order_data(order_data),
        .order_valid(order_valid)
    );
    
    // Ethernet header prepender instance
    prepend_ethernet_header eth_header_inst (
        .clk_i(clk),
        .start_of_packet_i(order_valid),
        .end_of_packet_i(order_valid),  // For this simple example, start and end are the same
        .data_i(order_data),
        .byte_count_i(3'b111),  // Assuming full 8 bytes
        .start_of_packet_o(sop_int),
        .end_of_packet_o(eop_int),
        .data_o(eth_data_int),
        .byte_count_o(byte_count_int)
    );
    
    // Output handler instance
    output_handler output_inst (
        .clk(clk),
        .rst(rst),
        .data_in(eth_data_int),
        .sop(sop_int),
        .eop(eop_int),
        .byte_count(byte_count_int),
        .tx_clk(eth_tx_clk),
        .tx_data(eth_tx_data),
        .tx_en(eth_tx_en)
    );
    
    // Status LED control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            status_reg <= 4'b0000;
        end else begin
            status_reg[0] <= uart_data_valid;                  // UART activity
            status_reg[1] <= !(fifo0_empty && fifo1_empty &&   // FIFO has data
                             fifo2_empty && fifo3_empty);
            status_reg[2] <= parsed_valid;                     // Parser activity
            status_reg[3] <= order_valid;                      // Order processing
        end
    end
    
    assign status_leds = status_reg;

endmodule
