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
DTB_FILE      ?= $(CVA6_SDK_DIR)/alsaqr.dtb
DTB_ADDR      ?= 0x81800000


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

# Set NUM_HARTS and TARGET_FREQ
NUM_HARTS     ?= 2
TARGET_FREQ   ?= 50000000 # Hz

export NUM_HARTS TARGET_FREQ

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
	USE_HYPER = 1
	export USE_HYPER
endif

# Conditional load of DTB file
ifeq ($(load-dtb),1)
	OPENOCD_CMDS += -c "load_image $(DTB_FILE) $(DTB_ADDR)"
	OPENOCD_DEPS += $(DTB_FILE)
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

# CVA6 SDK targets
.PHONY: $(CVA6_SDK_DIR)

$(CVA6_SDK_DIR):
	if [ ! -d "$(CVA6_SDK_DIR)/.git" ] || [ -z "$(shell ls -A $(CVA6_SDK_DIR))" ]; then \
		git submodule update --init --recursive $@; \
	fi

$(DTB_FILE): $(CVA6_SDK_DIR)
	make -C $(CVA6_SDK_DIR) $(notdir $@)

$(IMAGES_DIR)/fw_payload.elf: $(CVA6_SDK_DIR)
	make -C $(CVA6_SDK_DIR) images

# Run OpenOCD to set up a GDB server
.PHONY: openocd
openocd: $(OPENOCD_DEPS)
	$(OPENOCD) $(OPENOCD_ARGS) -c "echo \"Ready for Remote Connections\""

# Run GDB to load the payload and execute it
.PHONY: gdb gdb-load-payload
gdb:
	$(GDB) \
	-ex "target extended-remote :3333"
gdb-load-payload: $(PAYLOAD)
	$(GDB) \
	-ex "file $(PAYLOAD)" \
	-ex "target extended-remote :3333" \
	$(foreach i, $(shell seq 1 $(NUM_HARTS)), -ex "thread $(i)" -ex "set \$$pc=$(INITIAL_PC)" -ex "info registers pc") \
	-ex "load" \
	-ex "continue"

.PHONY: clean deep-clean

clean:
	make -C $(CVA6_SDK_DIR)/opensbi clean
	rm -f generated/* $(DTB_FILE) $(IMAGES_DIR)/*

deep-clean: clean
	make -C $(CVA6_SDK_DIR)/buildroot clean

.PHONY: init
init: $(CVA6_SDK_DIR)
