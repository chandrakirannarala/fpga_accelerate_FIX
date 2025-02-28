`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 17:57:30 PM
// Design Name: 
// Module Name: order_processor
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

module order_processor(
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] value_in,     // Parsed and converted field value
    input  wire        value_valid,  // Value valid signal
    output reg  [63:0] order_data,   // Order data for transmission
    output reg         order_valid   // Order valid signal
);

    // FIX tag constants (based on the FIX 4.4 spec)
    localparam TAG_MSGTYPE     = 16'd35;
    localparam TAG_PRICE       = 16'd44;
    localparam TAG_ORDERQTY    = 16'd38;
    localparam TAG_SIDE        = 16'd54;
    localparam TAG_SYMBOL      = 16'd55;
    localparam TAG_CLORDID     = 16'd11;
    
    // Order types
    localparam NEW_ORDER       = 8'h44; // 'D' for NewOrderSingle
    localparam ORDER_CANCEL    = 8'h46; // 'F' for OrderCancelRequest
    
    // Side values
    localparam SIDE_BUY        = 8'h31; // '1' for Buy
    localparam SIDE_SELL       = 8'h32; // '2' for Sell
    
    // FSM States
    localparam IDLE            = 3'b000;
    localparam CAPTURE_TAG     = 3'b001;
    localparam STORE_VALUE     = 3'b010;
    localparam PROCESS_ORDER   = 3'b011;
    localparam OUTPUT_ORDER    = 3'b100;
    
    // State and storage registers
    reg [2:0]  state;
    reg [15:0] current_tag;
    reg [15:0] msg_type;
    reg [15:0] price;
    reg [15:0] quantity;
    reg [15:0] side;
    reg [15:0] symbol;
    reg [15:0] clordid;
    reg        expecting_value;
    
    // State machine for order processing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= IDLE;
            current_tag   <= 16'd0;
            msg_type      <= 16'd0;
            price         <= 16'd0;
            quantity      <= 16'd0;
            side          <= 16'd0;
            symbol        <= 16'd0;
            clordid       <= 16'd0;
            order_data    <= 64'd0;
            order_valid   <= 1'b0;
            expecting_value <= 1'b0;
        end else begin
            // Default state for output valid
            order_valid <= 1'b0;
            
            case (state)
                IDLE: begin
                    if (value_valid) begin
                        current_tag <= value_in;
                        state <= CAPTURE_TAG;
                        expecting_value <= 1'b1;
                    end
                end
                
                CAPTURE_TAG: begin
                    if (value_valid && expecting_value) begin
                        expecting_value <= 1'b0;
                        
                        // Store the value based on tag
                        case (current_tag)
                            TAG_MSGTYPE:  msg_type  <= value_in;
                            TAG_PRICE:    price     <= value_in;
                            TAG_ORDERQTY: quantity  <= value_in;
                            TAG_SIDE:     side      <= value_in;
                            TAG_SYMBOL:   symbol    <= value_in;
                            TAG_CLORDID:  clordid   <= value_in;
                        endcase
                        
                        // Check if we have enough information to process the order
                        if (msg_type != 0 && price != 0 && quantity != 0 && 
                            side != 0 && symbol != 0 && clordid != 0) begin
                            state <= PROCESS_ORDER;
                        end else if (value_valid) begin
                            // Capture next tag
                            state <= IDLE;
                        end
                    end else if (value_valid) begin
                        // New tag received
                        current_tag <= value_in;
                        expecting_value <= 1'b1;
                    end
                end
                
                PROCESS_ORDER: begin
                    // Pack order data
                    // Format: [msgType(8) | side(8) | symbol(16) | price(16) | qty(16)]
                    order_data <= {
                        8'h00, 
                        msg_type[7:0],        // Message Type
                        side[7:0],            // Side (Buy/Sell)
                        symbol[15:0],         // Symbol
                        price[15:0],          // Price
                        quantity[15:0]        // Quantity
                    };
                    
                    state <= OUTPUT_ORDER;
                end
                
                OUTPUT_ORDER: begin
                    order_valid <= 1'b1;
                    
                    // Reset for next order
                    msg_type    <= 16'd0;
                    price       <= 16'd0;
                    quantity    <= 16'd0;
                    side        <= 16'd0;
                    symbol      <= 16'd0;
                    clordid     <= 16'd0;
                    
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
