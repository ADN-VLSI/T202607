# UART Registers

| Register    | Address | Reset Value | Type | Description                              |
| ----------- | ------- | ----------- | ---- | ---------------------------------------- |
| UART_CTRL   | 0x00    | 0x00000000  | RW   | Control register for UART configuration  |
| UART_CFG    | 0x04    | 0x          | RW   | Configuration register for UART settings |
| UART_STATUS | 0x08    | 0x          | RO   | Status register for UART operations      |
| UART_TXD    | 0x0C    | 0x          | WO   | Transmit data register for UART          |
| UART_RXD    | 0x10    | 0x          | RO   | Receive data register for UART           |
| UART_INTR   | 0x14    | 0x          | RW   | Interrupt register for UART              |

## UART_CTRL Register

The UART_CTRL register is used to control the operation of the UART interface. It contains various bits that enable or disable specific features of the UART.

| Bit  | Name     | Reset Value | Description                                 |
| ---- | -------- | ----------- | ------------------------------------------- |
| 0    | TX_EN    | 0x0         | Enable transmission (1:enabled, 0:disabled) |
| 1    | RX_EN    | 0x0         | Enable reception (1:enabled, 0:disabled)    |
| 2    | TX_FLUSH | 0x0         | Flush the transmit FIFO (write 1 to flush)  |
| 3    | RX_FLUSH | 0x0         | Flush the receive FIFO (write 1 to flush)   |
| 31:4 | Reserved | 0x0         | Reserved for future use                     |

## UART_CFG Register

The UART_CFG register is used to configure the settings of the UART interface, such as baud rate, parity, and stop bits.

| Bit   | Name        | Reset Value | Description                                                  |
| ----- | ----------- | ----------- | ------------------------------------------------------------ |
| 15:0  | BAUD_DIV    | 0x28B0      | Baud rate divisor (used to set the baud rate)                |
| 17:16 | NUM_BITS    | 0x3         | Number of data bits (0:5 bits, 1:6 bits, 2:7 bits, 3:8 bits) |
| 18    | PARITY_EN   | 0x0         | Enable parity (1:enabled, 0:disabled)                        |
| 19    | PARITY_TYPE | 0x0         | Parity type (0:even, 1:odd)                                  |
| 20    | EXTRA_STOP  | 0x0         | Extra stop bit (1:enabled, 0:disabled)                       |
| 31:21 | Reserved    | 0x0         | Reserved for future use                                      |

## UART_STATUS Register

The UART_STATUS register provides information about the current status of the UART interface, including flags for transmission and reception.

| Bit   | Name          | Reset Value | Description                             |
| ----- | ------------- | ----------- | --------------------------------------- |
| 9:0   | TX_FIFO_COUNT | 0x0         | Number of bytes in the transmit FIFO    |
| 19:10 | RX_FIFO_COUNT | 0x0         | Number of bytes in the receive FIFO     |
| 20    | TX_BUSY       | 0x0         | Transmission busy flag (1:busy, 0:idle) |
| 21    | RX_BUSY       | 0x0         | Reception busy flag (1:busy, 0:idle)    |
| 31:22 | Reserved      | 0x0         | Reserved for future use                 |

## UART_TXD Register

The UART_TXD register is used to write data to be transmitted over the UART interface. Writing a byte to this register will place it in the transmit FIFO.

| Bit  | Name     | Reset Value | Description                         |
| ---- | -------- | ----------- | ----------------------------------- |
| 7:0  | TXD      | 0x0         | Data to be transmitted (write-only) |
| 31:8 | Reserved | 0x0         | Reserved for future use             |

## UART_RXD Register

The UART_RXD register is used to read data received over the UART interface. Reading from this register will retrieve a byte from the receive FIFO.

| Bit  | Name     | Reset Value | Description               |
| ---- | -------- | ----------- | ------------------------- |
| 7:0  | RXD      | 0x0         | Data received (read-only) |
| 31:8 | Reserved | 0x0         | Reserved for future use   |

## UART_INTR Register

The UART_INTR register is used to configure and monitor interrupts for the UART interface. It allows enabling or disabling specific interrupt sources.

| Bit | Name     | Reset Value | Description                                                  |
| --- | -------- | ----------- | ------------------------------------------------------------ |
| 0   | TX_FULL  | 0x0         | Transmit FIFO full interrupt enable (1:enabled, 0:disabled)  |
| 1   | RX_FULL  | 0x0         | Receive FIFO full interrupt enable (1:enabled, 0:disabled)   |
| 2   | TX_EMPTY | 0x0         | Transmit FIFO empty interrupt enable (1:enabled, 0:disabled) |
| 3   | RX_EMPTY | 0x0         | Receive FIFO empty interrupt enable (1:enabled, 0:disabled)  |
