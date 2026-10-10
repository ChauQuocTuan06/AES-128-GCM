# AES-128-GCM Digital IC Design & Verification Project

Dự án thiết kế và kiểm thử vi mạch số cho lõi xử lý mã hóa xác thực **AES-128-GCM** (Advanced Encryption Standard - Galois/Counter Mode) tuân thủ tiêu chuẩn **NIST SP 800-38D**.

Môi trường kiểm thử được xây dựng theo kiến trúc phân tầng chuẩn SystemVerilog (Layered Testbench Architecture) với mô hình tham chiếu Golden Model NIST.

---

## 📌 Sơ đồ cổng giao tiếp Lõi AES-GCM Top (High-Level Architecture)

Khối `AES_GCM` top-level được đồng bộ theo thiết kế giao tiếp mới:

```text
                  +--------------------------------+
                  |          AES-GCM top           |
       clk ------>|                                |---> tag [127:0]
     rst_n ------>|                                |---> tag_valid
                  |                                |---> verify_pass
cipher_key [127:0]|                                |---> verify_done
  load_key ------>|                                |---> CTR_counter_overflow
  IV [95:0] ----->|                                |---> data_out [127:0]
   load_IV ------>|                                |---> data_valid
      mode ------>|                                |---> data_out_last
 tag_ref [127:0]->|                                |---> finish
load_tag_ref ---->|                                |---> key_ready
 AAD [127:0] ---->|                                |---> IV_ready
  load_AAD ------>|                                |---> tag_ref_ready
    no_AAD ------>|                                |---> AAD_ready
  AAD_last ------>|                                |---> data_ready
 data_in [127:0]->|                                |
 load_data ------>|                                |
data_in_last ---->|                                |
verify_checked -->|                                |
                  +--------------------------------+
```

### 🤝 Cơ chế bắt tay giải mã xác thực (Decryption Verification Handshake)
- Khi `mode = 1` (Decrypt): Sau khi hoàn tất giải mã và tính toán Tag, DUT sẽ chuyển sang trạng thái `VERIFY_PASS` và xuất xung/mức `verify_done = 1`.
- Phía Testbench/CPU quan sát `verify_pass` và phát xung đáp ứng `verify_checked = 1`.
- DUT nhận `verify_checked = 1` sẽ chuyển trạng thái hoàn tất, phát cờ `finish = 1` và trở về `IDLE`.

---

## 📁 Cấu trúc thư mục (Project Directory Tree)

```text
AES-128-GCM/
├── docs/                                  # Tài liệu kỹ thuật & tiêu chuẩn NIST
│   ├── spec/                              # Tiêu chuẩn NIST & mã C tham chiếu
│   └── notes/                             # Báo cáo kiến trúc & sơ đồ khối (.drawio, .md)
├── rtl/                                   # Mã nguồn thiết kế phần cứng RTL (SystemVerilog)
│   ├── aes_128_gcm_all.sv                 # File nguyên khối 50 module theo thứ tự Bottom-Up
│   ├── AES_GCM.sv                         # Top-level module AES-128-GCM (đã cập nhật port)
│   ├── CU/CU.sv                           # Khối điều khiển FSM Control Unit
│   ├── GCM-GHASH/                         # Khối băm GHASH & xử lý Authentication Tag
│   └── AES-CTR/                           # Khối AES Counter Mode, Pipeline 10 vòng, SBox, KeyEx
├── dv/                                    # Môi trường kiểm tra (Layered Testbench Environment)
│   ├── env/                               # Các thành phần cốt lõi của Environment
│   │   ├── interface.sv                   # Interface kết nối pin-level & clocking blocks
│   │   ├── transaction.sv                 # Class định nghĩa gói dữ liệu Stimulus & Response
│   │   ├── generator.sv                   # Class tạo stimulus (ngẫu nhiên có ràng buộc & test định hướng)
│   │   ├── driver.sv                      # Class lái tín hiệu bus, tuân thủ giao thức bắt tay
│   │   ├── monitor.sv                     # Class thụ động quan sát bus và đóng gói transaction
│   │   ├── scoreboard.sv                  # Class đối chiếu kết quả với NIST SP 800-38D Golden Model
│   │   ├── environment.sv                 # Class tích hợp liên kết toàn bộ các component
│   │   └── env_pkg.sv                     # Package tổng hợp toàn bộ các class kiểm thử
│   ├── tb/                                # Top-level Testbench
│   │   └── tb_top.sv                      # Top TB kết nối DUT, cấp clock/reset và chạy test suite
│   └── submodule_tb/                      # Các testbench kiểm tra khối con độc lập
├── scripts/                               # Scripts biên dịch và cấu hình QuestaSim
│   ├── filelist_rtl.f                     # Danh sách file RTL
│   ├── filelist_dv.f                      # Danh sách file Testbench
│   ├── compile.do                         # Script biên dịch thư viện QuestaSim
│   ├── wave.do                            # Cấu hình waveform đầy đủ tín hiệu giao tiếp
│   ├── lint.do                            # Script kiểm tra lint tĩnh trong QuestaSim
│   └── check_lint.py                      # Bộ kiểm tra lint tĩnh rule-based Python
├── sim/                                   # Thư mục thực thi mô phỏng độc lập
│   ├── Makefile                           # Makefile tiện ích (compile, run, gui, lint, clean)
│   ├── run.bat                            # Script chạy nhanh cho Windows CMD
│   ├── run.ps1                            # Script chạy cho Windows PowerShell
│   └── .gitignore                         # Loại bỏ thư viện work, log, wlf, ucdb
└── README.md
```

---

## ⚡ Hướng dẫn chạy mô phỏng trên QuestaSim / ModelSim

> **Nguyên tắc:** Toàn bộ quá trình chạy mô phỏng được thực hiện bên trong thư mục `sim/`.

### 1. Chạy trên giao diện đồ họa QuestaSim GUI (Khuyến nghị)
1. Mở phần mềm **QuestaSim** hoặc **ModelSim**.
2. Trên thanh menu hoặc cửa sổ **Transcript**, chuyển thư mục làm việc đến `sim/`:
   ```tcl
   cd "f:/PROJECT CỦA TUẤN/AES-128-GCM/sim"
   ```
3. Chạy lệnh:
   ```tcl
   do ../scripts/run.do
   ```
   - Tự động biên dịch RTL và toàn bộ gói kiểm thử `env_pkg`.
   - Mở cửa sổ dạng sóng Waveform với cấu hình tín hiệu đầy đủ từ [`scripts/wave.do`](file:///f:/PROJECT%20C%E1%BB%A6A%20TU%E1%BA%A4N/AES-128-GCM/scripts/wave.do).
   - Chạy các kịch bản test:
     1. **NIST SP 800-38D Test Case 2 (Encryption)**: Kiểm tra Ciphertext và Tag.
     2. **NIST SP 800-38D Test Case 2 (Decryption - Valid Tag)**: Kiểm tra `verify_pass = 1`, bắt tay `verify_done` và `verify_checked`.
     3. **NIST SP 800-38D Test Case 2 (Decryption - Tampered Tag)**: Kiểm tra phát hiện Tag giả mạo `verify_pass = 0`.
     4. **Random Constrained Tests**: Sinh ngẫu nhiên dữ liệu và tự động đối chiếu với Golden Reference Model.

---

### 2. Chạy nhanh qua Windows Terminal (PowerShell / CMD)
Mở cửa sổ dòng lệnh tại `f:\PROJECT CỦA TUẤN\AES-128-GCM\sim`:
- **Chế độ GUI (mở QuestaSim & Waveform):**
  ```powershell
  .\run.ps1
  # hoặc:
  .\run.bat
  ```
- **Chế độ Batch (chạy nhanh trên Command Line):**
  ```powershell
  .\run.ps1 -Batch
  # hoặc:
  .\run.bat c
  ```
- **Kiểm tra Lint:**
  ```powershell
  .\run.ps1 -Lint
  ```
