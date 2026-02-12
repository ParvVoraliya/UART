# UART RTL Design and Verification (Verilog)

## 📌 Overview
This project implements a Universal Asynchronous Receiver Transmitter (UART) 
using RTL design in Verilog and functional verification using a Verilog testbench.

The design includes transmitter, receiver, and baud rate generator modules.

---

## 🏗 Architecture

UART consists of:

- Baud Rate Generator
- Transmitter (TX)
- Receiver (RX)

The transmitter serializes parallel data.
The receiver reconstructs serial data back to parallel format.

---

## ⚙️ Design Specifications

- Data Bits: 8
- Stop Bits: 1
- Parity: None
- Configurable Baud Rate
- Asynchronous Communication

---

## 📂 Project Structure

