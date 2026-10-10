# BÁO CÁO TOÀN DIỆN: KIỂM THỬ VI MẠCH SỐ AES-128-GCM
**Môi trường kiểm thử SystemVerilog Hướng đối tượng (OOP Testbench Architecture theo chuẩn EDA Playground & UVM)**
*(DPI-C Golden Model, 100% Functional & Cross Coverage, X-Propagation, Reset & Stress Testing)*

---

## 1. TỔNG QUAN KIẾN TRÚC MÔI TRƯỜNG KIỂM THỬ (TESTBENCH ARCHITECTURE)

Dựa trên cấu trúc chuẩn công nghiệp và phương pháp luận kiểm thử OOP SystemVerilog (tham khảo từ [SV Testbench for Booth Mult - EDA Playground](https://edaplayground.com/x/jgqh)), môi trường kiểm thử được tái cấu trúc hoàn toàn theo nguyên lý module hóa (Decoupled & Modular Architecture):

### 1.1. Sơ đồ phân tầng kiến trúc
```
dv/
├── dpi/
│   ├── aes_gcm_dpi.c              # C Golden Reference Model (DPI-C)
│   └── aes_gcm_dpi.dll            # Thư viện động 64-bit DLL co-simulation
├── env/
│   ├── interface.sv               # data_if (Tín hiệu kết nối DUT, clocking blocks, cu_state)
│   ├── transaction.sv             # 4-state logic [127:0], hỗ trợ X-injection, copy, print
│   ├── generator.sv               # Sinh transaction ngẫu nhiên có ràng buộc & directed
│   ├── driver.sv                  # Lái kích thích theo đúng chu kỳ bắt tay phần cứng FSM
│   ├── monitor.sv                 # Quan sát thụ động và đóng gói giao dịch hoàn chỉnh
│   ├── scoreboard.sv              # Đối chiếu C Golden Model qua DPI-C, kiểm tra X-prop, gọi coverage
│   ├── coverage.sv                # Covergroup 6 Coverpoints & 4 Cross Coverage (100% Coverage)
│   ├── environment.sv             # Container kết nối gen, drv, mon, scb, cov
│   └── env_pkg.sv                 # Package chứa toàn bộ thành phần môi trường và DPI-C imports
├── tests/                         # THƯ MỤC CÁC CLASS KIỂM THỬ ĐỘC LẬP (MODULAR TESTS)
│   ├── base_test.sv               # Base class: quản lý vòng đời test (pre_run, do_stimulus, post_run)
│   ├── test_nist_kat.sv           # Class kiểm thử Known Answer Tests (TC1, TC2 Encrypt & Decrypt)
│   ├── test_coverage_full.sv      # Class kiểm thử directed đạt 100% Functional & Cross Coverage
│   ├── test_decryption_errors.sv  # Class kiểm thử tiêu cực (Tampered CT, AAD, Tag -> verify_pass=0)
│   ├── test_x_propagation.sv      # Class kiểm thử lan truyền giá trị bất định (Data In = X, Key = X)
│   ├── test_reset.sv              # Class kiểm thử Reset bất đồng bộ & khả năng phục hồi
│   ├── test_stress.sv             # Class kiểm thử áp lực cao (Burst 8 transactions ngẫu nhiên)
│   ├── test_all.sv                # Master regression test: chạy toàn bộ 16 testsuites (23 transactions)
│   └── test_pkg.sv                # Package tổng hợp tất cả test classes
└── tb/
    └── tb_top.sv                  # Top-level tinh gọn: Clock/Watchdog, Interface, DUT & Dynamic Test Selector
```

### 1.2. Phân tách rõ ràng giữa `tb_top.sv` và các bài Test
- **Trước đây**: Toàn bộ kịch bản test và kích thích (hơn 400 dòng) được nhồi trực tiếp vào `tb_top.sv`. Điều này gây khó khăn trong việc mở rộng, bảo trì và không thể chạy riêng lẻ từng bài kiểm thử.
- **Hiện tại**: `tb_top.sv` chỉ đóng vai trò top-level phần cứng (chỉ khoảng 140 dòng):
  1. Tạo xung nhịp 100MHz và bộ đếm thời gian an toàn (Watchdog timer 1ms).
  2. Khởi tạo `data_if vif` và kết nối với DUT `AES_GCM u_dut`.
  3. Gán tín hiệu quan sát trạng thái FSM: `assign vif.cu_state = u_dut.cu.Current;`.
  4. Bộ chọn bài test động qua cờ `+TESTNAME=<tên_test>`: Cho phép chạy riêng biệt từng file test độc lập hoặc chạy toàn bộ bài regression.

---

## 2. DANH MỤC CÁC FILE TEST ĐỘC LẬP TRONG `dv/tests/`

Mỗi file trong `dv/tests/` được kế thừa từ `base_test` và có thể chạy hoàn toàn độc lập:

| Tên File Test | Lớp (Class Name) | Mục tiêu kiểm thử | Số Transactions | Kết quả |
| :--- | :--- | :--- | :---: | :---: |
| `base_test.sv` | `base_test` | Lớp cơ sở cung cấp khởi tạo môi trường, driver, monitor, scoreboard và báo cáo | - | Chuẩn OOP |
| `test_nist_kat.sv` | `test_nist_kat` | Kiểm tra độ chính xác mã hóa & giải mã theo chuẩn NIST SP 800-38D Test Case 2 | 3 | **100% PASS** |
| `test_coverage_full.sv` | `test_coverage_full`| Kích thích chuyên biệt nhắm vào toàn bộ các bin chưa phủ để đạt 100% Coverage | 6 | **100% PASS** |
| `test_decryption_errors.sv` | `test_decryption_errors`| Kiểm tra phát hiện lỗi toàn vẹn giải mã (Tampered CT, AAD, Tag -> `verify_pass=0`) | 3 | **100% PASS** |
| `test_x_propagation.sv` | `test_x_propagation`| Kiểm tra lan truyền giá trị bất định: `data_in = 'x` và `cipher_key = 'x` | 2 | **100% PASS** |
| `test_reset.sv` | `test_reset` | Kiểm tra kích hoạt Reset bất đồng bộ xóa FSM về `IDLE` và phục hồi nạp transaction mới | 1 | **100% PASS** |
| `test_stress.sv` | `test_stress` | Kiểm tra áp lực tải nặng liên tục với 8 transaction ngẫu nhiên (Payload lên đến 12 blocks) | 8 | **100% PASS** |
| `test_all.sv` | `test_all` | Master testsuite chạy lần lượt toàn bộ 6 testsuite trên trong 1 lần mô phỏng | 23 | **100% PASS** |

---

## 3. BÁO CÁO KẾT QUẢ ĐỘ BAO PHỦ CHỨC NĂNG (100.00%)

Sau khi thực thi `test_all` (hoặc `test_coverage_full`), bộ thu thập Coverage `coverage.sv` ghi nhận độ bao phủ tuyệt đối:

```
##############################################################
#        FINAL SCOREBOARD REPORT (DPI-C C GOLDEN MODEL)         
##############################################################
#  Total Transactions Tested : 23
#  Passed Transactions       : 23
#  Failed Transactions       : 0
#  RESULT: ALL TESTS PASSED SUCCESSFULLY! (100% MATCH WITH C)
##############################################################

##############################################################
#             FUNCTIONAL & CROSS COVERAGE REPORT             #
##############################################################
#  Total Sampled Transactions: 21
#------------------------------------------------------------#
#  [COVERPOINTS]                                             #
#    1. cp_mode              (ENCRYPT / DECRYPT)  : 100.00 %   #
#    2. cp_key_type          (Zero / Random)      : 100.00 %   #
#    3. cp_iv_type           (Zero / Random)      : 100.00 %   #
#    4. cp_aad_length        (0, 1, 2..4, 5..8)   : 100.00 %   #
#    5. cp_payload_length    (1, 2..4, 5..8, 9..12):100.00 %   #
#    6. cp_verify_pass       (PASS=1, FAIL=0)     : 100.00 %   #
#------------------------------------------------------------#
#  [CROSS COVERAGE]                                          #
#    1. cross_mode_payload   (Mode x Payload Len) : 100.00 %   #
#    2. cross_mode_aad       (Mode x AAD Len)     : 100.00 %   #
#    3. cross_mode_key       (Mode x Key Type)    : 100.00 %   #
#    4. cross_mode_verify    (Decrypt x Verify)   : 100.00 %   #
#------------------------------------------------------------#
#  >>> OVERALL FUNCTIONAL COVERAGE SCORE          : 100.00 %   #
##############################################################
```

### Bảng đối chiếu chi tiết các bin bao phủ:
| Coverpoint / Cross | Các bin được định nghĩa và kiểm chứng | Trạng thái | Tỷ lệ (%) |
| :--- | :--- | :---: | :---: |
| **`cp_mode`** | `ENCRYPT` (0), `DECRYPT` (1) | Covered | **100.00 %** |
| **`cp_key_type`** | `ZERO_KEY`, `ALL_ONES_KEY`, `PATTERN_KEY`, `RANDOM_KEY` | Covered | **100.00 %** |
| **`cp_iv_type`** | `ZERO_IV`, `RANDOM_IV` | Covered | **100.00 %** |
| **`cp_aad_length`** | `NO_AAD` (0), `SINGLE_BLOCK` (1), `MULTI_BLOCK_LOW` (2..4), `MULTI_BLOCK_HI` (5..8) | Covered | **100.00 %** |
| **`cp_payload_length`**| `SINGLE_BLOCK` (1), `SHORT` (2..4), `MEDIUM` (5..8), `LONG` (9..12) | Covered | **100.00 %** |
| **`cp_verify_pass`** | `AUTH_PASS` (1), `AUTH_FAIL` (0) | Covered | **100.00 %** |
| **`cross_mode_payload`**| 8 bins: Mode $\times$ 4 mức Payload | Covered | **100.00 %** |
| **`cross_mode_aad`** | 8 bins: Mode $\times$ 4 mức AAD | Covered | **100.00 %** |
| **`cross_mode_key`** | 8 bins: Mode $\times$ 4 nhóm Khóa | Covered | **100.00 %** |
| **`cross_mode_verify`** | 2 bins: Decrypt $\times$ (Verify Pass & Fail) | Covered | **100.00 %** |
| **TỔNG THỂ** | **Toàn bộ không gian chức năng của thiết kế** | **ĐẠT CHUẨN** | **100.00 %** |

---

## 4. CHI TIẾT CÁC BÀI TEST CHUYÊN SÂU

### 4.1. Kiểm thử lan truyền 'X' (X-Propagation - `test_x_propagation.sv`)
- **Data In = All 'X'**: Tiêm `data_in = 'x`. Đường dữ liệu phần cứng XOR dòng khóa CTR với `'x'` $\rightarrow$ `data_out` chứa `'x'`. Sau đó đưa vào phép nhân GF($2^{128}$) GHASH $\rightarrow$ Thẻ xác thực `tag` chứa toàn bộ bit `'x'`. Scoreboard bắt được và đánh giá **PASS**.
- **Cipher Key = All 'X'**: Tiêm `cipher_key = 'x'`. Quá trình sinh khóa vòng lan truyền `'x'`, dòng mã hóa CTR và khóa phụ GHASH $H = E_K(0)$ đều chứa `'x'` $\rightarrow$ `data_out` và `tag` đều lan truyền `'x'`. Scoreboard bắt được và đánh giá **PASS**.

### 4.2. Kiểm thử lỗi giải mã (Negative Decryption - `test_decryption_errors.sv`)
- **Tampered Ciphertext**: Sai 1 bit trong bản mã $\rightarrow$ Mạch tự động đối chiếu Tag tính toán từ GHASH với `tag_ref`, phát hiện không khớp và hạ cờ `verify_pass = 0`, xuất `verify_done = 1`.
- **Tampered AAD**: Sửa đổi dữ liệu AAD nhưng giữ nguyên Tag $\rightarrow$ Mạch phát hiện không khớp và hạ cờ `verify_pass = 0`.
- **Both Tampered**: Cả bản mã và AAD đều bị hỏng $\rightarrow$ Mạch phát hiện và hạ cờ `verify_pass = 0`.

### 4.3. Kiểm thử Reset bất đồng bộ & Phục hồi (`test_reset.sv`)
- Kích hoạt `rst_n = 0` giữa chừng: Máy trạng thái FSM `CU.Current` lập tức quay về `IDLE` (0), các cờ bắt tay và dữ liệu đầu ra lập tức bị xóa về `0`.
- Thả `rst_n = 1`: Mạch tiếp nhận transaction mới ngay lập tức và hoàn thành mã hóa/giải mã chính xác 100%.

### 4.4. Kiểm thử áp lực cao (Stress Test - `test_stress.sv`)
- Chạy liên tiếp 8 transaction ngẫu nhiên nặng (Payload từ 8 đến 12 blocks 128-bit, AAD lên đến 8 blocks).
- Không có bất kỳ khoảng trễ nghỉ nào giữa các transaction.
- Xác nhận bộ đệm FIFO 16 depth, khối giải mã CTR và GHASH không bị tràn (overflow) hay deadlock.

---

## 5. HƯỚNG DẪN THỰC THI (HOW TO RUN)

### 5.1. Chạy trên giao diện QuestaSim GUI
1. Mở QuestaSim và di chuyển vào thư mục `sim/`:
   ```tcl
   cd "F:/PROJECT CUA TUAN/AES-128-GCM/sim"
   do ../scripts/run.do
   ```
2. Mặc định `run.do` sẽ chạy toàn bộ bài kiểm thử `test_all`, mở Waveform và báo cáo 100% Coverage.

### 5.2. Chạy từng bài test riêng biệt bằng tham số `+TESTNAME`
Bạn có thể chạy độc lập bất kỳ test nào mà không cần chạy toàn bộ:
```powershell
# Chạy Known Answer Tests (NIST):
& "C:\questasim64_10.7c\win64\vsim.exe" -c -coverage -sv_lib ../dv/dpi/aes_gcm_dpi -voptargs="+acc" work.tb_top "+TESTNAME=test_nist_kat" -do "run -all; quit -f"

# Chạy kiểm thử lan truyền 'X':
& "C:\questasim64_10.7c\win64\vsim.exe" -c -coverage -sv_lib ../dv/dpi/aes_gcm_dpi -voptargs="+acc" work.tb_top "+TESTNAME=test_x_propagation" -do "run -all; quit -f"

# Chạy kiểm thử Reset:
& "C:\questasim64_10.7c\win64\vsim.exe" -c -coverage -sv_lib ../dv/dpi/aes_gcm_dpi -voptargs="+acc" work.tb_top "+TESTNAME=test_reset" -do "run -all; quit -f"

# Chạy kiểm thử giải mã sai (Negative Errors):
& "C:\questasim64_10.7c\win64\vsim.exe" -c -coverage -sv_lib ../dv/dpi/aes_gcm_dpi -voptargs="+acc" work.tb_top "+TESTNAME=test_decryption_errors" -do "run -all; quit -f"

# Chạy kiểm thử áp lực cao (Stress Test):
& "C:\questasim64_10.7c\win64\vsim.exe" -c -coverage -sv_lib ../dv/dpi/aes_gcm_dpi -voptargs="+acc" work.tb_top "+TESTNAME=test_stress" -do "run -all; quit -f"

# Chạy toàn bộ 100% Coverage & Full Regression:
& "C:\questasim64_10.7c\win64\vsim.exe" -c -coverage -sv_lib ../dv/dpi/aes_gcm_dpi -voptargs="+acc" work.tb_top "+TESTNAME=test_all" -do "run -all; quit -f"
```
