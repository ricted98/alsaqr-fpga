
# Al Saqr FPGA emulation

## Overview

This project is set up to build and deploy software on the Al Saqr platform by using FPGA emulation on the VCU-118 development board. The provided Makefile is designed to automate various tasks including setting up the environment, configuring HyperRAM, and running OpenOCD and GDB for debugging.

## Requirements

- `openocd`: OpenOCD should be installed and accessible via the command line.
- `riscv64-unknown-elf-gdb`: GDB for RISC-V.
- `python3`: Required for running the HyperRAM configuration script.

## Variables

The Makefile uses several variables that can be customized:

| **Variable**                 | **Default Value**                      |
|------------------------------|----------------------------------------|
| OPENOCD                      | sudo $(shell which openocd)            |
| GDB                          | riscv64-unknown-elf-gdb                |
| ADAPTER_SPEED                | 1000                                   |
| INTERFACE                    | olimex-arm-usb-ocd-h                   |
| BOARD                        | vcu-118                                |
| TARGET                       | smp                                    |
| CVA6_SDK_DIR                 | cva6-sdk                               |
| IMAGES_DIR                   | $(CVA6_SDK_DIR)/install64              |
| PAYLOAD                      | $(IMAGES_DIR)/fw_payload.elf           |
| DTB_FILE                     | $(CVA6_SDK_DIR)/alsaqr.dtb             |
| DTB_ADDR                     | 0x81800000                             |
| INITIAL_PC                   | Entry point of $(PAYLOAD)              |
| MEM_BASE_ADDR                | 0x80000000                             |
| NUM_HARTS                    | 2                                      |
| TARGET_FREQ                  | 50000000 (Hz)                          |
| OPENOCD_DIR                  | openocd                                |

### HyperRAM Variables

| **Variable**                 | **Default Value**                      |
|------------------------------|----------------------------------------|
| HYPERRAM_SIZE                | 0x2000000                              |
| HYPERRAM_LATENCY_ACCESS      | 0x6                                    |
| HYPERRAM_ADDRESS_SPACE       | 0                                      |
| HYPPERAM_NO_OF_CHIPS         | 4                                      |
| HYPERRAM_WHICH_PHY           | 0                                      |
| HYPERRAM_PHYS_IN_USE         | 1                                      |
| HYPERRAM_CFG_BASE_ADDR       | 0x1a101000                             |
| HYPERRAM_CFG_FILE            | generated/hyperram_config.cfg          |

## Targets

- **openocd**: Runs OpenOCD with the specified configuration to set up a GDB server.

  ```sh
  make openocd
  ```

- **gdb**: Runs GDB and connects to the OpenOCD server.

  ```sh
  make gdb
  ```

- **gdb-load-payload**: Loads the payload into GDB and sets the program counter for each hart, then continues execution.

  ```sh
  make gdb-load-payload
  ```

- **clean**: Cleans the build files and generated files.

  ```sh
  make clean
  ```

- **deep-clean**: Performs a deeper clean, including cleaning the buildroot.

  ```sh
  make deep-clean
  ```

## Conditional Configuration

- **HyperRAM Configuration**: If `use-hyper=1` is set, the HyperRAM configuration file is generated and used.
- **Load DTB File**: If `load-dtb=1` is set, the DTB file is loaded.

## HyperRAM Configuration

The HyperRAM configuration file is generated using a Python script (`utils/hyperram_cfg.py`) with the following command:

```sh
python3 utils/hyperram_cfg.py --hyperram_size $(HYPERRAM_SIZE) \
                              --hyperram_t_latency_access $(HYPERRAM_LATENCY_ACCESS) \
                              --hypperam_no_of_chips $(HYPPERAM_NO_OF_CHIPS) \
                              --hyperram_which_phy $(HYPERRAM_WHICH_PHY) \
                              --hyperram_address_space $(HYPERRAM_ADDRESS_SPACE) \
                              --hyperram_phys_in_use $(HYPERRAM_PHYS_IN_USE) \
                              --hyperbus_cfg_base_addr $(HYPERRAM_CFG_BASE_ADDR) \
                              --memory_base_addr $(MEM_BASE_ADDR) \
                              --output_file $(HYPERRAM_CFG_FILE)
```

## CVA6 SDK Targets

- **Clone CVA6 SDK**: Clones the CVA6 SDK repository.

  ```sh
  make $(CVA6_SDK_DIR)
  ```

- **Build DTB File**: Builds the DTB file.

  ```sh
  make $(DTB_FILE)
  ```

- **Build Payload**: Builds the payload.

  ```sh
  make $(IMAGES_DIR)/fw_payload.elf
  ```

By following these instructions and using the provided Makefile, you can automate the process of setting up, configuring, and debugging your software on the CVA6 core.