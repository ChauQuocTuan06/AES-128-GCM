import re

with open("F:/PROJECT CUA TUAN/AES-128-GCM/dv/env/scoreboard.sv", "r", encoding="utf-8") as f:
    text = f.read()

tokens = re.findall(r"\b8'[a-zA-Z0-9]+", text)
print("Total 8' tokens:", len(tokens))
for t in tokens:
    if not t.startswith("8'h") and not t.startswith("8'd") and not t.startswith("8'b"):
        print("BAD TOKEN:", t)

# Also check 128' or 96' or 32'
all_consts = re.findall(r"\b\d+'[a-zA-Z0-9]+", text)
print("Total const tokens:", len(all_consts))
for t in all_consts:
    m = re.match(r"^\d+'([a-zA-Z])", t)
    if m and m.group(1).lower() not in ['h', 'd', 'b', 'o']:
        print("BAD CONST:", t)
