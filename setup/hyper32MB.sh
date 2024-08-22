CURR_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $CURR_DIR/hyper_generic.sh

export HYPERRAM_SIZE=0x2000000
export HYPERRAM_LATENCY_ACCESS=0x6
export HYPERRAM_ADDRESS_SPACE=0
export HYPPERAM_NO_OF_CHIPS=4
export HYPERRAM_WHICH_PHY=1
export HYPERRAM_PHYS_IN_USE=1
export HYPERRAM_CFG_BASE_ADDR=0x1a101000
export HYPERRAM_CFG_FILE="generated/hyperram_config.cfg"