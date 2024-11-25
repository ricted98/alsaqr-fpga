#!/usr/bin/env python3

import argparse
import math

def clog2(x):
    return math.ceil(math.log2(x))

def main():
    parser = argparse.ArgumentParser(description='Generate HyperRAM configuration instructions.')
    parser.add_argument('--hyperram_size', type=lambda x: int(x, 0), required=True, help='Size of HyperRAM (decimal or hex)')
    parser.add_argument('--hyperram_which_phy', type=int, required=True, help='Which PHY to use for HyperRAM')
    parser.add_argument('--hyperram_phys_in_use', type=int, required=True, help='Physical layer in use for HyperRAM')
    parser.add_argument('--hyperram_address_space', type=int, required=True, help='Address Space to be used')
    parser.add_argument('--hyperbus_cfg_base_addr', type=lambda x: int(x, 0), required=True, help='Base address for HyperBus configuration (decimal or hex)')
    parser.add_argument('--memory_base_addr', type=lambda x: int(x, 0), required=True, help='Base address for memory (decimal or hex)')
    parser.add_argument('--hypperam_no_of_chips', type=lambda x: int(x, 0), required=True, help='Number of physical chips (decimal or hex)')
    parser.add_argument('--hyperram_t_latency_access', type=lambda x: int(x, 0), required=True, help='Initial Latency value (decimal or hex)')
    parser.add_argument('--output_file', type=str, default='hyperram_config.txt', help='Output file name')

    args = parser.parse_args()

    cfg = {
    "t_latency_access":      None,
    "en_latency_additional": None,
    "t_burst_max":           None,
    "t_read_write_recovery": None,
    "t_rx_clk_delay":        None,
    "t_tx_clk_delay":        None,
    "address_mask_msb":      None,
    "address_space":         None,
    "phys_in_use":           None,
    "which_phy":             None,
    "t_csh_cycles":          None
    }

    cfg_map = {
        "t_latency_access":      args.hyperbus_cfg_base_addr + (0x0 << 2),
        "en_latency_additional": args.hyperbus_cfg_base_addr + (0x1 << 2),
        "t_burst_max":           args.hyperbus_cfg_base_addr + (0x2 << 2),
        "t_read_write_recovery": args.hyperbus_cfg_base_addr + (0x3 << 2),
        "t_rx_clk_delay":        args.hyperbus_cfg_base_addr + (0x4 << 2),
        "t_tx_clk_delay":        args.hyperbus_cfg_base_addr + (0x5 << 2),
        "address_mask_msb":      args.hyperbus_cfg_base_addr + (0x6 << 2),
        "address_space":         args.hyperbus_cfg_base_addr + (0x7 << 2),
        "phys_in_use":           args.hyperbus_cfg_base_addr + (0x8 << 2),
        "which_phy":             args.hyperbus_cfg_base_addr + (0x9 << 2),
        "t_csh_cycles":          args.hyperbus_cfg_base_addr + (0xa << 2)
    }


    single_chip_size = args.hyperram_size // args.hypperam_no_of_chips

    if (args.hyperram_phys_in_use == 1):
        effective_hyperram_size = args.hyperram_size
        memory_stride = 2 * single_chip_size
    else:
        effective_hyperram_size = args.hyperram_size // 2
        memory_stride = single_chip_size

    mask = clog2(effective_hyperram_size) - 1



    cfg["address_mask_msb"] = mask
    cfg["phys_in_use"]      = args.hyperram_phys_in_use
    cfg["which_phy"]        = args.hyperram_which_phy
    cfg["t_latency_access"] = args.hyperram_t_latency_access
    cfg["address_space"]    = args.hyperram_address_space

    instructions = []

    for k,v in cfg.items():
        if v is not None:
            instructions.append(f"mww 0x{cfg_map[k]:X} 0x{v:X}")

    no_of_ranges = args.hypperam_no_of_chips // 2

    for idx in range(no_of_ranges):
        offset_start = 0x2C + idx * 8
        offset_end   = 0x30 + idx * 8
        instructions += [
            f"mww 0x{args.hyperbus_cfg_base_addr + offset_start:X} 0x{args.memory_base_addr + memory_stride * idx:X}",
            f"mww 0x{args.hyperbus_cfg_base_addr + offset_end:X} 0x{args.memory_base_addr + memory_stride * (idx+1):X}",
        ]

    with open(args.output_file, 'w') as f:
        for instruction in instructions:
            f.write(instruction + '\n')

    print(f"Configuration instructions written to {args.output_file}")

if __name__ == '__main__':
    main()
