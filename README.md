# AMBA-AHB
The AMBA-AHB protocol is a system bus architecture designed by ARM Holdings for use in embedded systems, such as microcontrollers and mobile devices. It provides a scalable and flexible interface for connecting peripherals to the central processing unit (CPU).

## Overview
AMBA-AHB is based on a shared memory model, where all buses are synchronized using a clock signal. The protocol consists of two main components:

AMBA Bus : A high-speed bus used for CPU-to-Peripherals communication.
AHB Bus : A lower-speed bus used for Peripheral-to-Peripheral communication.

## Key Features
- Scalable and flexible architecture
- Supports a wide range of devices, from simple microcontrollers to complex systems-on-chip (SoCs)
- High-speed data transfer rates up to 1 Gbps
- Low power consumption
  
## AMBA-AHB Protocol
The AMBA-AHB protocol consists of the following components:
- Bus Interface Unit (BIU) : Manages bus access and handles bus transactions between peripherals.
- Memory Management Unit (MMU) : Manages memory allocation, virtualization, and page table management.
- System Control Unit (SCU) : Controls system-level operations, such as power management, reset, and interrupt handling.

## Transaction Modes
The AMBA-AHB protocol supports three transaction modes:
- Transfer Mode : Used for data transfer between peripherals.
- Write-Only Transfer Mode : Used for writing data to memory.
- Read-Only Transfer Mode : Used for reading data from memory.

## Advantages and Disadvantages
Advantages:
- Scalable architecture
- High-speed data transfer rates
- Low power consumption

Disadvantages:
- Complexity of the protocol
- Limited control over system-level operations
