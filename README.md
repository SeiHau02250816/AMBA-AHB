# AMBA-AHB
The AMBA-AHB protocol is a system bus architecture designed by ARM Holdings for use in embedded systems, such as microcontrollers and mobile devices. It provides a scalable and flexible interface for connecting peripherals to the central processing unit (CPU).

## Block Diagram of Current Design
![Block Diagram](https://github.com/user-attachments/assets/d7aa2162-419b-4777-ac52-c81eacc47eb4)

## Revision
- **v1.0:** Created initial version with descriptions.  
- **v1.1:** Added AHB Basic Transfers feature.
- **v1.2:** Added HSIZE handling for different transfer sizes (byte, halfword, word)
- **v1.3:** Added write strobe (HWSTRB) handling for byte-level control.
- **v1.4:** Added IDLE and BUSY transactions handling.

## Overview
AMBA-AHB is based on a shared memory model, where all buses are synchronized using a clock signal. The protocol consists of two main components:

- **AMBA Bus:** A high-speed bus used for CPU-to-Peripherals communication.  
- **AHB Bus:** A lower-speed bus used for Peripheral-to-Peripheral communication.

## Key Features
- Scalable and flexible architecture  
- Supports a wide range of devices, from simple microcontrollers to complex systems-on-chip (SoCs)  
- High-speed data transfer rates up to 1 Gbps  
- Low power consumption  

## AMBA-AHB Protocol
The AMBA-AHB protocol consists of the following components:
- **Bus Interface Unit (BIU):** Manages bus access and handles bus transactions between peripherals.  
- **Memory Management Unit (MMU):** Manages memory allocation, virtualization, and page table management.  
- **System Control Unit (SCU):** Controls system-level operations, such as power management, reset, and interrupt handling.

### Master Locked Transfers
- **Note:** Master locked transfer feature is not implemented since only one master exists in this design.

## Transaction Modes
The AMBA-AHB protocol supports three transaction modes:
- **Transfer Mode:** Used for data transfer between peripherals.  
- **Write-Only Transfer Mode:** Used for writing data to memory.  
- **Read-Only Transfer Mode:** Used for reading data from memory.

## Advantages and Disadvantages
### Advantages:
- Scalable architecture  
- High-speed data transfer rates  
- Low power consumption  

### Disadvantages:
- Complexity of the protocol  
- Limited control over system-level operations  
