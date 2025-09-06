# APB-UART-IP Project

This repository contains the design and verification of an **APB-based UART IP** implemented on the **Basys3 FPGA** using Vivado.

## Repository Structure
```
APB-UART-IP/
│
├── src/         # RTL design files
│   ├── receiver.v       # UART receiver (with baud rate + FSM)
│   ├── transmitter.v    # UART transmitter (with baud rate)
│   ├── apb_if.v         # APB interface (with FSM)
│
├── dv/          # Testbench files
│   ├── uart_tb.v        # Testbench for simulation
│
├── fpga/        # FPGA implementation files
│   ├── Constraints_basys3.xdc
│   └── vivado_project/  # Vivado project files
│
├── docs/        # Project documents
│   └── APB_UART_Report.docx
│
└── README.md
```

## Design Description
- **Receiver**: Converts serial data to parallel data, checks start/stop bits, includes baud rate generator and FSM.  
- **Transmitter**: Converts parallel data to serial format, includes baud rate logic.  
- **APB Interface**: Provides communication between UART and APB bus, controlled by FSM.  
- **FSM**: Used in both the **Receiver** and the **APB interface** to control states.  
- **Testbench**: Developed to verify functionality of the design.  

## Tools
- **Vivado**: Used for synthesis, implementation, and FPGA deployment.
- ModelSim: Used for simulation and waveform analysis 
- **Basys3 FPGA**: Used for hardware testing.  

## How to Run
1. Open the Vivado project in the `fpga/` folder.  
2. Synthesize and implement the design.  
3. Generate the bitstream and program the Basys3 FPGA.  
4. To simulate, run the testbench files inside dv/ using ModelSim or Vivado Simulator.  
