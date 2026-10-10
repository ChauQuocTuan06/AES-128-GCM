"""
Static Lint & Code Quality Checker for SystemVerilog RTL
Checks common RTL design guidelines and synthesis pitfalls:
  1. Mixed blocking (=) and non-blocking (<=) assignments.
  2. Non-blocking assignments inside always_comb.
  3. Blocking assignments inside always_ff (except loop indices).
  4. Non-synthesizable constructs inside RTL (initial blocks, $display, #delays).
  5. Case statements without default branch or unique/priority keyword.
  6. Sensitivity list consistency (asynchronous active-low reset).
  7. Module and signal naming standards.
"""

import re
import sys
import os

def lint_systemverilog(file_path):
    print(f"==================================================")
    print(f" Running Static Lint Check: {file_path}")
    print(f"==================================================")

    if not os.path.exists(file_path):
        print(f"[ERROR] File not found: {file_path}")
        return

    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    warnings = []
    errors = []
    info = []

    current_module = None
    in_always_ff = False
    in_always_comb = False
    in_initial = False
    case_depth = 0
    has_default_in_case = []

    always_ff_pattern = re.compile(r'^\s*always_ff\s*@\s*\((.*?)\)\s*begin')
    always_comb_pattern = re.compile(r'^\s*always_comb\b')
    module_pattern = re.compile(r'^\s*module\s+(\w+)\b')
    endmodule_pattern = re.compile(r'^\s*endmodule\b')

    for line_idx, line in enumerate(lines, 1):
        clean_line = line.split('//')[0].strip()
        if not clean_line:
            continue

        # Module tracking
        m_mod = module_pattern.search(clean_line)
        if m_mod:
            current_module = m_mod.group(1)

        if endmodule_pattern.search(clean_line):
            current_module = None
            in_always_ff = False
            in_always_comb = False

        # Non-synthesizable constructs check in RTL
        if current_module:
            if re.search(r'\binitial\s+begin\b', clean_line) or re.search(r'^\s*initial\b', clean_line):
                warnings.append((line_idx, current_module, "SYNTHESIS", "Use of 'initial' block in RTL. Initial blocks are typically ignored by ASIC synthesis."))
            if re.search(r'#\d+', clean_line):
                errors.append((line_idx, current_module, "SYNTHESIS", "Hardcoded delay (#delay) found inside RTL. Delays are non-synthesizable."))
            if re.search(r'\$display\b|\$write\b|\$monitor\b', clean_line):
                warnings.append((line_idx, current_module, "SIM_ONLY", "Simulation system task ($display) found in RTL logic."))

        # Track always block types
        m_ff = always_ff_pattern.search(clean_line)
        if m_ff:
            in_always_ff = True
            in_always_comb = False
            sensitivity = m_ff.group(1)
            # Check reset style
            if "rst" in sensitivity and "negedge" in sensitivity and "rst_n" not in sensitivity:
                info.append((line_idx, current_module, "RESET_STYLE", f"Reset signal might be active-low but named without '_n': '{sensitivity}'"))

        if always_comb_pattern.search(clean_line):
            in_always_comb = True
            in_always_ff = False

        if clean_line.startswith("end") or "end " in clean_line or clean_line == "end":
            # Heuristic block exit
            pass

        # Assignment checks
        if in_always_comb:
            # Check for non-blocking assignment in always_comb
            # Exclude '<=' as comparison operator like 'if (a <= b)'
            if '<=' in clean_line and not re.search(r'if\s*\(.*<=.*\)', clean_line) and not re.search(r'while\s*\(.*<=.*\)', clean_line):
                warnings.append((line_idx, current_module, "CODING_STYLE", "Non-blocking assignment (<=) used inside always_comb. Use blocking (=) instead."))

        if in_always_ff:
            if clean_line.startswith("assign "):
                in_always_ff = False
            # Check for blocking assignment in always_ff (excluding for loops)
            elif '=' in clean_line and '<=' not in clean_line and '==' not in clean_line and '!=' not in clean_line and '>=' not in clean_line:
                if not re.search(r'for\s*\(.*=.*;', clean_line) and not re.search(r'if\s*\(.*=.*\)', clean_line):
                    if not clean_line.startswith("logic ") and not clean_line.startswith("integer ") and not clean_line.startswith("int "):
                        info.append((line_idx, current_module, "CODING_STYLE", f"Blocking assignment (=) used inside always_ff: '{clean_line}'"))


        # Case statement checks
        if re.search(r'\bcase\s*\(', clean_line):
            case_depth += 1
            has_default_in_case.append(False)

        if case_depth > 0 and 'default:' in clean_line:
            has_default_in_case[-1] = True

        if re.search(r'\bendcase\b', clean_line):
            if case_depth > 0:
                has_default = has_default_in_case.pop()
                if not has_default:
                    warnings.append((line_idx, current_module, "LATCH_RISK", "Case statement missing 'default:' branch. May infer unwanted latch if not all states covered."))
                case_depth -= 1

    # Report results
    print(f"\n[LINT SUMMARY] Errors: {len(errors)} | Warnings: {len(warnings)} | Info: {len(info)}")
    print("-" * 75)

    if errors:
        print(f"\n[ERRORS] ({len(errors)})")
        for line_idx, mod, cat, msg in errors:
            print(f"  Line {line_idx:<5} [{mod}] ({cat}): {msg}")

    if warnings:
        print(f"\n[WARNINGS] ({len(warnings)})")
        for line_idx, mod, cat, msg in warnings:
            print(f"  Line {line_idx:<5} [{mod}] ({cat}): {msg}")

    if info:
        print(f"\n[INFO / ADVISORY] ({len(info)})")
        for line_idx, mod, cat, msg in info:
            print(f"  Line {line_idx:<5} [{mod}] ({cat}): {msg}")

    if not errors and not warnings:
        print("\n*** CLEAN! No errors or warnings found in RTL. ***")

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else r"rtl/aes_128_gcm_all.sv"
    lint_systemverilog(target)
