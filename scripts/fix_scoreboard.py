path = "F:/PROJECT CUA TUAN/AES-128-GCM/dv/env/scoreboard.sv"
with open(path, "r", encoding="utf-8") as f:
    code = f.read()

# Fix typos
code = code.replace("8'fc,", "8'hfc,")
code = code.replace("8'xfb,", "8'hfb,")
code = code.replace("8'xea,", "8'hea,")
code = code.replace("8'h24, 8'h5e, 8'hc2", "8'h24, 8'h5c, 8'hc2")

with open(path, "w", encoding="utf-8") as f:
    f.write(code)

print("Scoreboard fixed successfully!")
