/*
# Team ID:          4513
# Theme:            MazeSolver Bot - UART Communication
# Author List:      Parv Voraliya,Niraj Bailmare
# Filename:         uart_rx.v
# File Description: UART Receiver module to receive serial data frames with even parity.
# Global variables: None
*/

/*
Instructions
-------------------
Students are not allowed to make any changes in the Module declaration.

This file is used to receive UART Rx data packets and reconstruct 8-bit messages 
with parity checking.

Recommended Quartus Version : 20.1
The submitted project file must be 20.1 compatible as the evaluation will be done on Quartus Prime Lite 20.1.

Warning: The error due to compatibility will not be entertained.
-------------------
*/

/*
Module UART Receiver

Input:
    clk_3125 - 3125 KHz clock input
    rx       - UART receive line

Output:
    rx_msg      - 8-bit received data message
    rx_parity   - received parity bit
    rx_complete - data reception complete flag
    state       - FSM state output (for debugging/monitoring)

Baudrate: 115200 bps (approx. 27 clock cycles per bit)
*/

// ================================================================
// Module Declaration
// ================================================================
module uart_rx(
    input clk_3125,                // System clock (3.125 MHz)
    input rx,                      // UART serial input
    output reg [7:0] rx_msg,       // 8-bit parallel received data
    output reg rx_parity,          // Parity bit received from data frame
    output reg rx_complete,        // Data reception completion flag
    output reg [2:0] state         // FSM state (for debug)
);

//////////////////DO NOT MAKE ANY CHANGES ABOVE THIS LINE//////////////////

// ================================================================
// Parameter Declarations
// ================================================================

// BUFFER: Initial buffer state before starting reception
localparam BUFFER       = 0;  
// RX_IDLE: Waiting for start bit (idle line is high)
localparam RX_IDLE      = 1;  
// RX_START: Start bit detected (line pulled low)
localparam RX_START     = 2;  
// RX_READ_WAIT: Wait before sampling next bit (to align mid-bit)
localparam RX_READ_WAIT = 3;  
// RX_READ: Reading incoming serial bits
localparam RX_READ      = 4;  
// RX_PARITY: Reading parity bit
localparam RX_PARITY    = 5;  
// RX_STOP: Reading stop bit
localparam RX_STOP      = 6;  
// END_BUFFER: Buffer state for processing received frame
localparam END_BUFFER   = 7;  


// ================================================================
// Internal Registers
// ================================================================

// bit_count: Counter to track number of received data bits (0–7)
reg [2:0] bit_count;      

// rx_counter: Counts clock cycles per bit for timing (~26 for 115200 baud)
reg [4:0] rx_counter;     

// data_in: Temporary shift register that stores incoming bits (LSB first)
reg [7:0] data_in;        

// parity_in: Stores the received parity bit
reg parity_in;            


// ================================================================
// Initialization Block
// ================================================================
initial begin
    rx_msg      = 8'b0;
    rx_parity   = 1'b0;
    rx_complete = 1'b0;
    state       = BUFFER;
    bit_count   = 0;
    rx_counter  = 0;
    data_in     = 0;
    parity_in   = 0;
end


// ================================================================
// Main FSM for UART Reception
// ================================================================
always @(posedge clk_3125) begin
    /*
    Purpose:
    ---
    This procedural block implements a finite state machine (FSM)
    for receiving serial UART data with even parity checking.
    The FSM transitions through states:
    BUFFER → IDLE → START → READ_WAIT → READ → PARITY → STOP → END_BUFFER.
    */
    case (state)

        // --------------------------------------------------------
        // BUFFER STATE
        // --------------------------------------------------------
        BUFFER: begin
            state <= RX_IDLE;  // Initialize to IDLE on startup
        end

        // --------------------------------------------------------
        // IDLE STATE - Waiting for Start Bit
        // --------------------------------------------------------
        RX_IDLE: begin
            rx_complete <= 0;
            if (rx == 0) begin   // Start bit detected (line goes low)
                data_in    <= 8'b0;
                bit_count  <= 3'd0;
                rx_counter <= 5'd0;
                state <= RX_START;
            end
        end

        // --------------------------------------------------------
        // START STATE - Start Bit Detected
        // --------------------------------------------------------
        RX_START: begin
            state <= RX_READ_WAIT;  // Wait before sampling data
        end

        // --------------------------------------------------------
        // READ_WAIT STATE - Bit Timing Alignment
        // --------------------------------------------------------
        RX_READ_WAIT: begin
            // Wait for one bit period to sample in middle of bit
            if (rx_counter == 5'd26) begin
                rx_counter <= 5'd0;
                state <= RX_READ;
            end 
            else begin
                rx_counter <= rx_counter + 1;
            end
        end

        // --------------------------------------------------------
        // READ STATE - Sampling 8 Data Bits
        // --------------------------------------------------------
        RX_READ: begin
            data_in <= {rx, data_in[7:1]};  // Shift in LSB first
            bit_count <= bit_count + 1;
            if (bit_count == 3'd7)
                state <= RX_PARITY;         // After 8 bits, move to parity
            else
                state <= RX_READ_WAIT;      // Continue reading bits
        end

        // --------------------------------------------------------
        // PARITY STATE - Read Parity Bit
        // --------------------------------------------------------
        RX_PARITY: begin
            if (rx_counter == 5'd26) begin
                parity_in <= rx;             // Capture parity bit
                rx_counter <= 5'd0;
                state <= RX_STOP;
            end 
            else begin
                rx_counter <= rx_counter + 1;
            end
        end

        // --------------------------------------------------------
        // STOP STATE - Read Stop Bit
        // --------------------------------------------------------
        RX_STOP: begin
            if (rx_counter == 5'd26) begin
                rx_counter <= 5'd0;
                state <= END_BUFFER;
            end 
            else begin
                rx_counter <= rx_counter + 1;
            end
        end

        // --------------------------------------------------------
        // END_BUFFER STATE - Frame Completion & Parity Check
        // --------------------------------------------------------
        END_BUFFER: begin
            if (rx_counter == 5'd16) begin
                rx_parity <= parity_in;

                // Perform even parity check:
                // (^data_in) gives 1 if number of 1's in data_in is odd.
                // For even parity, parity_in must equal (^data_in).
                if ((^data_in) == parity_in) begin
                    // Reverse bit order to MSB-first (as per UART protocol)
                    rx_msg <= { data_in[0], data_in[1], data_in[2], data_in[3],
                                data_in[4], data_in[5], data_in[6], data_in[7] };
                end 
                else begin
                    rx_msg <= 8'h3F;  // '?' (0x3F) on parity error
                end

                rx_complete <= 1'b1;  // Assert completion flag
                state <= RX_IDLE;     // Return to idle for next frame
                rx_counter <= 5'd0;
            end 
            else begin
                rx_counter <= rx_counter + 1;
            end
        end

        // --------------------------------------------------------
        // DEFAULT STATE HANDLER
        // --------------------------------------------------------
        default: state <= RX_IDLE;

    endcase
end

//////////////////DO NOT MAKE ANY CHANGES BELOW THIS LINE//////////////////
endmodule
