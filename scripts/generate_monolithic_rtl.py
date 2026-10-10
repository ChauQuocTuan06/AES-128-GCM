import os
import re
from collections import defaultdict, deque

# List of all 38 RTL source files
RTL_FILES = [
    # SBox
    r"rtl/AES-CTR/SBox/AffineTransform.sv",
    r"rtl/AES-CTR/SBox/MultiplicativeInv.sv",
    r"rtl/AES-CTR/SBox/SBox.sv",
    # Key Expansion
    r"rtl/AES-CTR/Key_Expansion/GFunction/AddRcon.sv",
    r"rtl/AES-CTR/Key_Expansion/GFunction/RotWord.sv",
    r"rtl/AES-CTR/Key_Expansion/GFunction/SubWord.sv",
    r"rtl/AES-CTR/Key_Expansion/GFunction/GFunction.sv",
    r"rtl/AES-CTR/Key_Expansion/Counter.sv",
    r"rtl/AES-CTR/Key_Expansion/KeyExpansion.sv",
    # Counter Generator
    r"rtl/AES-CTR/counter_generator/CTR_counter.sv",
    r"rtl/AES-CTR/counter_generator/IV_register.sv",
    r"rtl/AES-CTR/counter_generator/J0_register.sv",
    r"rtl/AES-CTR/counter_generator/counter_block_generator.sv",
    r"rtl/AES-CTR/counter_generator/output_unit.sv",
    r"rtl/AES-CTR/counter_generator/type_generator.sv",
    r"rtl/AES-CTR/counter_generator/counter_generator.sv",
    # FIFO
    r"rtl/AES-CTR/FIFO/FIFO_memory.sv",
    r"rtl/AES-CTR/FIFO/Read_pointer.sv",
    r"rtl/AES-CTR/FIFO/Write_pointer.sv",
    r"rtl/AES-CTR/FIFO/FIFO.sv",
    # AES Rounds & Pipeline
    r"rtl/AES-CTR/AES_encryption/AES_round/MixColumns/MUL_MixColumns.sv",
    r"rtl/AES-CTR/AES_encryption/AES_round/MixColumns/MixCol.sv",
    r"rtl/AES-CTR/AES_encryption/AES_round/MixColumns/MixColumns.sv",
    r"rtl/AES-CTR/AES_encryption/AES_round/AddRoundKeys.sv",
    r"rtl/AES-CTR/AES_encryption/AES_round/AES_register.sv",
    r"rtl/AES-CTR/AES_encryption/AES_round/ShiftRows.sv",
    r"rtl/AES-CTR/AES_encryption/AES_round/SubBytes.sv",
    r"rtl/AES-CTR/AES_encryption/AES_first_round.sv",
    r"rtl/AES-CTR/AES_encryption/AES_round.sv",
    r"rtl/AES-CTR/AES_encryption/AES_last_round.sv",
    r"rtl/AES-CTR/AES_encryption/AES_encryption.sv",
    # AES-CTR Top
    r"rtl/AES-CTR/AES_CTR.sv",
    # GCM-GHASH
    r"rtl/GCM-GHASH/GF128bitMultiply.sv",
    r"rtl/GCM-GHASH/GHASH.sv",
    r"rtl/GCM-GHASH/LengthBlockCounter.sv",
    r"rtl/GCM-GHASH/TagProcessing.sv",
    # Control Unit
    r"rtl/CU/CU.sv",
    # Top Level
    r"rtl/AES_GCM.sv",
]

def extract_modules_from_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Pattern to match: module <name> ... endmodule
    # Note: using non-greedy match for module ... endmodule
    module_pattern = re.compile(
        r'(?ms)^([ \t]*module\s+(\w+)\b.*?^([ \t]*endmodule\b.*?$))'
    )

    modules = []
    for match in module_pattern.finditer(content):
        mod_code = match.group(1)
        mod_name = match.group(2)
        modules.append((mod_name, mod_code, file_path))
    return modules

def find_submodule_instantiations(mod_code, all_mod_names, self_name):
    instantiated = set()
    for name in all_mod_names:
        if name == self_name:
            continue
        # Check if name is instantiated: name [#(params)] instance_name (
        pattern = re.compile(r'\b' + re.escape(name) + r'\s+(?:#\s*\([^;]*?\)\s*)?[a-zA-Z_]\w*\s*\(')
        if pattern.search(mod_code):
            instantiated.add(name)
    return instantiated

def main():
    all_modules = []
    for fp in RTL_FILES:
        mods = extract_modules_from_file(fp)
        all_modules.extend(mods)

    all_mod_names = set(m[0] for m in all_modules)
    print(f"Total modules extracted: {len(all_modules)}")

    # Map name -> (code, origin_file)
    mod_dict = {m[0]: (m[1], m[2]) for m in all_modules}

    # Build dependency graph: mod -> set of submodules it depends on
    deps = {}
    for name, (code, origin) in mod_dict.items():
        submods = find_submodule_instantiations(code, all_mod_names, name)
        deps[name] = submods

    # Topological sort (Kahn's algorithm)
    # in-degree of a module = number of submodules it depends on that are not yet placed
    # Or reverse: child -> parents. If B is instantiated by A, B must come BEFORE A.
    in_degree = {name: len(deps[name]) for name in all_mod_names}
    dependents = defaultdict(set)
    for parent, children in deps.items():
        for child in children:
            dependents[child].add(parent)

    queue = deque([name for name, deg in in_degree.items() if deg == 0])
    sorted_modules = []

    # To preserve stable/readable grouping, sort queue by original appearance order
    orig_order = {m[0]: i for i, m in enumerate(all_modules)}

    while queue:
        # Sort queue items to maintain intuitive order (S-Box -> KeyEx -> Counter -> FIFO -> AES -> CTR -> GCM -> CU -> Top)
        current_queue = sorted(list(queue), key=lambda x: orig_order[x])
        queue.clear()

        curr = current_queue.pop(0)
        # Put rest back in queue
        for item in current_queue:
            queue.append(item)

        sorted_modules.append(curr)

        for parent in sorted(dependents[curr], key=lambda x: orig_order[x]):
            in_degree[parent] -= 1
            if in_degree[parent] == 0:
                queue.append(parent)

    if len(sorted_modules) != len(all_mod_names):
        print(f"Error: Dependency cycle detected! Sorted {len(sorted_modules)} of {len(all_mod_names)}")
        return

    print("Topological sort successful! 100% strict bottom-up order:")
    for idx, name in enumerate(sorted_modules, 1):
        origin = mod_dict[name][1]
        print(f"  {idx:2d}. {name:<25} (from {origin})")

    # Generate monolithic file
    out_path = r"rtl/aes_128_gcm_all.sv"
    with open(out_path, 'w', encoding='utf-8') as out:
        out.write("""// =============================================================================
// Project     : AES-128-GCM Hardware Accelerator
// File        : aes_128_gcm_all.sv
// Description : Complete Monolithic SystemVerilog RTL Implementation of AES-128-GCM.
//               Combines all 50 submodules in strict bottom-up dependency order.
//               All leaf modules and sub-blocks are defined prior to instantiation.
// Standard    : NIST SP 800-38D / FIPS 197 compliant
// Top Module  : AES_GCM
// =============================================================================

`timescale 1ns/1ps

""")
        for idx, name in enumerate(sorted_modules, 1):
            code, origin = mod_dict[name]
            submods = sorted(list(deps[name]))
            submods_str = ", ".join(submods) if submods else "None (Leaf module)"
            out.write(f"""// -----------------------------------------------------------------------------
// [{idx}/{len(sorted_modules)}] Module: {name}
// Source   : {origin}
// Submodules: {submods_str}
// -----------------------------------------------------------------------------
{code.strip()}

""")

    print(f"\nWritten {out_path} successfully ({os.path.getsize(out_path)} bytes).")

if __name__ == '__main__':
    main()
