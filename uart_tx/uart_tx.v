/*
# Team ID:          4513
# Theme:            MazeSolver Bot - UART Communication
# Author List:      Parv Voraliya,Niraj Bailmare
# Filename:         uart_tx.v
# File Description: UART Transmitter module to send serial data frames with parity.
# Global variables: None
*/
module uart_tx(
    input clk_3125,                // System clock input (3.125 MHz)
    input parity_type,             // Even(0)/Odd(1) parity selector
    input tx_start,                // Start transmission trigger
    input [7:0] data,              // 8-bit data to be transmitted
    output reg tx,                 // UART TX output line
    output reg tx_done,            // Transmission done flag
    output reg [2:0] tx_state      // UART FSM state (for debug/monitoring)
);

//Initialize outputs
initial begin
    tx = 1'b1;   
    tx_done = 1'b0;
end

// TX_IDLE: UART transmitter idle state (line high, waiting for start)
localparam TX_IDLE   = 0;  
// TX_START: Start bit transmission state (line pulled low)
localparam TX_START  = 1;  
// TX_WRITE: Data bit transmission state
localparam TX_WRITE  = 2;  
// TX_PARITY: Parity bit transmission state
localparam TX_PARITY = 3;  
// TX_STOP: Stop bit transmission state (line high)
localparam TX_STOP   = 4;  

// tx_counter: Counts clock cycles for baud rate timing (~27 cycles @3.125MHz for 115200bps)
reg [4:0] tx_counter;  

// bit_count: Tracks which data bit is being transmitted (0 to 7)
reg [2:0] bit_count;   

initial begin
    tx_state   = TX_IDLE;
    tx_counter = 4'd0;
    bit_count  = 3'd0;
end

always @(posedge clk_3125) begin
    case(tx_state)
    
        // IDLE STATE
        TX_IDLE : begin
            tx_done <= 1'b0;
            if(tx_start) begin
                tx_state <= TX_START;
                tx_counter <= 0;
                tx <= 1'b0;  // Start bit (low)
            end
            else begin
                tx <= 1'b1;  // Idle line (high)
            end
        end

        // START BIT STATE
        TX_START : begin
            if(tx_counter == 5'd26) begin
                tx_state <= TX_WRITE;
                bit_count <= 0;
                tx_counter <= 0;
                tx <= data[3'd7 - bit_count]; // Send MSB first
            end
            else tx_counter <= tx_counter + 1;
        end

        // DATA TRANSMISSION STATE
        TX_WRITE : begin
            if(tx_counter == 5'd26) begin
                tx_counter <= 0;
                if(bit_count == 3'd7) begin
                    bit_count <= 0;
                    tx_state <= TX_PARITY;
                  tx <= ((^data) ^ parity_type); // for parity (even/odd)
                end
                else begin
                    bit_count <= bit_count + 1;
                    tx_state <= TX_WRITE;
                    tx <= data[3'd7 - (bit_count + 1)];
                end
            end
            else tx_counter <= tx_counter + 1;
        end

        // PARITY BIT STATE
        TX_PARITY : begin
            if(tx_counter == 5'd26) begin
                tx_counter <= 0;
                tx_state <= TX_STOP;
                tx <= 1'b1; // Stop bit (high)
            end
            else tx_counter <= tx_counter + 1;
        end

      // STOP BIT STATE
        TX_STOP : begin
            if(tx_counter == 5'd25) begin
                tx_counter <= 0;
                tx_state <= TX_IDLE;
                tx_done <= 1'b1; // Transmission complete flag
            end
            else tx_counter <= tx_counter + 1;
        end

    endcase
end 
endmodule
