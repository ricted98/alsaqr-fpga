# Define default variables
OPENOCD       ?= sudo $(shell which openocd)
GDB           ?= riscv64-unknown-elf-gdb
ADAPTER_SPEED ?= 1000
INTERFACE     ?= olimex-arm-usb-ocd-h
BOARD         ?= vcu-118
TARGET        ?= smp

# CVA6 SDK variables
CVA6_SDK_DIR  ?= cva6-sdk
IMAGES_DIR    ?= $(CVA6_SDK_DIR)/install64
PAYLOAD       ?= $(IMAGES_DIR)/fw_payload.elf


INITIAL_PC    ?= $(shell LC_ALL=C riscv64-unknown-elf-objdump -f $(PAYLOAD) | awk '/start address/ {print $NF}')
MEM_BASE_ADDR ?= 0x80000000

# Hyperram config
HYPERRAM_SIZE           ?= 0x2000000
HYPERRAM_LATENCY_ACCESS ?= 0x6
HYPERRAM_ADDRESS_SPACE  ?= 0
HYPPERAM_NO_OF_CHIPS    ?= 4
HYPERRAM_WHICH_PHY      ?= 0
HYPERRAM_PHYS_IN_USE    ?= 1
HYPERRAM_CFG_BASE_ADDR  ?= 0x1a101000
HYPERRAM_CFG_FILE       ?= generated/hyperram_config.cfg

OPENOCD_DEPS           :=

# Set NUM_HARTS based on core configuration
NUM_HARTS     ?= 2

# OpenOCD directory
OPENOCD_DIR   ?= openocd

# Initialize OpenOCD command arguments
OPENOCD_ARGS  = -s "$(OPENOCD_DIR)"

# Initialize OpenOCD commands
OPENOCD_CMDS  = -c "adapter speed $(ADAPTER_SPEED)" \
               -c "set _INTERFACE $(INTERFACE); echo \"Interface: $(INTERFACE)\"" \
               -c "set _BOARD $(BOARD); echo \"Board: $(BOARD)\"" \
               -c "set _NUM_CORES $(NUM_HARTS); echo \"Number of cores: $(NUM_HARTS)\"" \
               -c "set _TARGET $(TARGET); echo \"Target: $(TARGET)\"" \
               -f "openocd.cfg" \
               -c "init" \
               -c "reset halt"

# Conditional programming of Hyperram interface
ifeq ($(use-hyper),1)
	OPENOCD_CMDS += -f $(HYPERRAM_CFG_FILE)
	OPENOCD_DEPS += $(HYPERRAM_CFG_FILE)
endif

# Conditional load of DTB file
ifeq ($(load-dtb),1)
	DTB_FILE      ?= $(CVA6_SDK_DIR)/alsaqr.dtb
	DTB_ADDR      ?= 0x81800000
	OPENOCD_CMDS += -c "load_image $(DTB_FILE) $(DTB_ADDR)"
endif

# Append OpenOCD commands to arguments
OPENOCD_ARGS += $(OPENOCD_CMDS)

$(HYPERRAM_CFG_FILE):
	mkdir -p $(dir $@)
	python3 utils/hyperram_cfg.py  	--hyperram_size             $(HYPERRAM_SIZE) \
									--hyperram_t_latency_access $(HYPERRAM_LATENCY_ACCESS) \
									--hypperam_no_of_chips      $(HYPPERAM_NO_OF_CHIPS) \
									--hyperram_which_phy        $(HYPERRAM_WHICH_PHY) \
									--hyperram_address_space    $(HYPERRAM_ADDRESS_SPACE) \
									--hyperram_phys_in_use      $(HYPERRAM_PHYS_IN_USE) \
									--hyperbus_cfg_base_addr    $(HYPERRAM_CFG_BASE_ADDR) \
									--memory_base_addr          $(MEM_BASE_ADDR) \
									--output_file               $@

# Run OpenOCD to set up a GDB server
.PHONY: openocd
openocd: $(OPENOCD_DEPS)
	$(OPENOCD) $(OPENOCD_ARGS) -c "echo \"Ready for Remote Connections\""

# Run GDB to load the payload and execute it
.PHONY: gdb gdb-load-payload
gdb:
	$(GDB) \
	-ex "target extended-remote :3333"
gdb-load-payload:
	$(GDB) \
	-ex "file $(PAYLOAD)" \
	-ex "target extended-remote :3333" \
	$(foreach i, $(shell seq 1 $(NUM_HARTS)), -ex "thread $(i)" -ex "set \$$pc=$(INITIAL_PC)" -ex "info registers pc") \
	-ex "load" \
	-ex "continue"

.PHONY: clean

clean:
	rm -f generated/*
