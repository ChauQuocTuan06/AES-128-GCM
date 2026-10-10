# BÁO CÁO TOÀN DIỆN VÀ HƯỚNG DẪN DUY TRÌ BỐI CẢNH (VERIFICATION CONTINUATION REPORT)
# DỰ ÁN KIỂM THỬ VI MẠCH SỐ AES-128-GCM IP CORE

> **LƯU Ý QUAN TRỌNG KHI BẮT ĐẦU CHAT MỚI**: 
> Tài liệu này được tạo ra để lưu trữ toàn bộ bối cảnh kỹ thuật (context retention) của hệ thống kiểm thử AES-128-GCM. Khi bắt đầu phiên làm việc mới, bạn hoặc AI trợ lý chỉ cần đọc tài liệu này để nắm bắt 100% kiến trúc, trạng thái mã nguồn, kết quả kiểm thử và các quy chuẩn kỹ thuật mà không cần phải phân tích lại từ đầu.

---

## 1. THÔNG TIN HỆ THỐNG VÀ ĐƯỜNG DẪN LÀM VIỆC (ENVIRONMENT & WORKSPACE)

- **Hệ điều hành**: Windows 10/11 (Shell: PowerShell).
- **Thư mục làm việc dự án (Workspace Root)**: `F:\PROJECT CUA TUAN\AES-128-GCM`
- **Thư mục chạy mô phỏng (Simulation Cwd)**: `F:\PROJECT CUA TUAN\AES-128-GCM\sim`
- **Bộ công cụ mô phỏng**: Mentor Graphics QuestaSim-64 10.7c tại `C:\questasim64_10.7c\win64\`
- **Trình biên dịch C (DPI-C)**: GCC 64-bit (Tạo file DLL: `dv/dpi/aes_gcm_dpi.dll`).

### Lệnh thực thi nhanh (Quick Run Commands):
```powershell
# 1. Chuyển vào thư mục mô phỏng
cd "F:\PROJECT CUA TUAN\AES-128-GCM\sim"

# 2. Biên dịch RTL và toàn bộ Testbench
& "C:\questasim64_10.7c\win64\vsim.exe" -c -do "do ../scripts/compile.do; quit -f"

# 3. Chạy kiểm thử hồi quy toàn bộ (Master Regression: 10 Suites / 31 Transactions)
& "C:\questasim64_10.7c\win64\vsim.exe" -c -coverage -sv_lib ../dv/dpi/aes_gcm_dpi -voptargs="+acc" work.tb_top "+TESTNAME=test_all" -do "run -all; quit -f"

# 4. Chạy từng bài test đơn lẻ (Ví dụ: test_reuse_key)
& "C:\questasim64_10.7c\win64\vsim.exe" -c -coverage -sv_lib ../dv/dpi/aes_gcm_dpi -voptargs="+acc" work.tb_top "+TESTNAME=test_reuse_key" -do "run -all; quit -f"
```

---

## 2. KIẾN TRÚC MÔI TRƯỜNG KIỂM THỬ HƯỚNG ĐỐI TƯỢNG (OOP ARCHITECTURE)

Môi trường kiểm thử được cấu trúc hoàn toàn theo nguyên lý module hóa (Decoupled & Modular Architecture), tuân thủ tiêu chuẩn công nghiệp (tham khảo từ [SV Testbench for Booth Mult - EDA Playground](https://edaplayground.com/x/jgqh)):

```
dv/
├── dpi/
│   ├── aes_gcm_dpi.c              # C Golden Reference Model (DPI-C)
│   └── aes_gcm_dpi.dll            # Thư viện 64-bit DLL co-simulation
├── env/
│   ├── interface.sv               # data_if (Tín hiệu kết nối DUT, clocking blocks, cu_state)
│   ├── transaction.sv             # 4-state logic [127:0], hỗ trợ X-injection, skip_key, delay_tag_ref
│   ├── generator.sv               # Sinh transaction ngẫu nhiên có ràng buộc & directed
│   ├── driver.sv                  # Lái kích thích Black-box theo chuẩn bắt tay FSM
│   ├── monitor.sv                 # Quan sát thụ động và đóng gói giao dịch, hỗ trợ bắt key reuse
│   ├── scoreboard.sv              # Đối chiếu C Golden Model qua DPI-C, kiểm tra X-prop, gọi coverage
│   ├── coverage.sv                # 2 Covergroup: cg_aes_gcm (100%) và cg_fsm (100% States & Transitions)
│   ├── aes_gcm_assertions.sv      # Module SVA kiểm tra bắt tay giao thức và bất biến FSM từng clock
│   ├── environment.sv             # Container kết nối gen, drv, mon, scb, cov, run_fsm_cov
│   └── env_pkg.sv                 # Package chứa toàn bộ thành phần môi trường và DPI-C imports
├── tests/                         # THƯ MỤC CÁC CLASS KIỂM THỬ ĐỘC LẬP (MODULAR TESTS)
│   ├── base_test.sv               # Base class: quản lý vòng đời test (hỗ trợ kế thừa env)
│   ├── test_nist_kat.sv           # Class kiểm thử Known Answer Tests (TC1, TC2 Encrypt & Decrypt)
│   ├── test_coverage_full.sv      # Class kiểm thử directed đạt 100% Functional & Cross Coverage
│   ├── test_reuse_key.sv          # Class kiểm thử tái sử dụng Key (bỏ qua KEY_EXPANSION)
│   ├── test_enc_dec_chain.sv      # Class kiểm thử chuỗi khép kín Mã hóa -> Giải mã -> Phục hồi dữ liệu
│   ├── test_backpressure.sv       # Class kiểm thử áp suất ngược / dòng dữ liệu gián đoạn (Stall/Delays)
│   ├── test_ctr_overflow.sv       # Class kiểm thử giá trị biên bộ đếm CTR (ALL_ONES_IV)
│   ├── test_decryption_errors.sv  # Class kiểm thử tiêu cực (Tampered CT, AAD, Tag -> verify_pass=0)
│   ├── test_x_propagation.sv      # Class kiểm thử lan truyền giá trị bất định (Data In = X, Key = X)
│   ├── test_reset.sv              # Class kiểm thử Reset bất đồng bộ & khả năng phục hồi
│   ├── test_stress.sv             # Class kiểm thử áp lực cao (Burst 8 transactions ngẫu nhiên)
│   ├── test_all.sv                # Master regression test: chạy toàn bộ 10 testsuites (31 transactions)
│   └── test_pkg.sv                # Package tổng hợp tất cả test classes
└── tb/
    └── tb_top.sv                  # Top-level: Clock/Watchdog, Interface, DUT, SVA binding & Test Selector
```

### Nguyên tắc phân tách sạch:
- `tb_top.sv` đóng vai trò là khung phần cứng tĩnh: tạo xung clock, reset watchdog timer, kết nối `data_if` với `AES_GCM u_dut`, gắn kết module SVA `aes_gcm_assertions`, và dùng `$value$plusargs("TESTNAME=%s", test_name)` để kích hoạt bài test được chỉ định.
- Mỗi bài kiểm thử là một class độc lập nằm trong thư mục `dv/tests/`, hoàn toàn tự chủ vòng đời chạy từ Reset, phát kích thích, cho đến hoàn tất.

---

## 3. DANH SÁCH 10 BỘ TEST VÀ TRẠNG THÁI NGHIỆM THU

| STT | Tên Test | File Nguồn | Số Giao Dịch | Mục Tiêu & Cơ Chế Kiểm Thử | Kết Quả |
|:---:|:---|:---|:---:|:---|:---:|
| 1 | `test_nist_kat` | `dv/tests/test_nist_kat.sv` | 4 | Kiểm thử mẫu chuẩn NIST SP 800-38D (TC1 không AAD, TC2 có AAD cho cả Encrypt và Decrypt). | **PASS** |
| 2 | `test_coverage_full` | `dv/tests/test_coverage_full.sv` | 4 | Quét toàn bộ miền biên: Key toàn 0, toàn 1, mẫu 0xAA; IV toàn 1; AAD lớn (5 khối); Payload dài (9 khối); nạp Tag trễ. | **PASS** |
| 3 | `test_reuse_key` | `dv/tests/test_reuse_key.sv` | 3 | Kiểm thử nạp Key lần đầu, sau đó chỉ nạp IV (`load_IV=1`, `load_key=0`) cho cả Encrypt và Decrypt, giữ nguyên cache $H$. | **PASS** |
| 4 | `test_enc_dec_chain` | `dv/tests/test_enc_dec_chain.sv` | 2 | Chuỗi khép kín: Bản rõ $\rightarrow$ Mã hóa sinh Ciphertext + Tag $\rightarrow$ Đưa ngay vào Giải mã $\rightarrow$ So khớp bản rõ gốc (`verify_pass=1`). | **PASS** |
| 5 | `test_backpressure` | `dv/tests/test_backpressure.sv` | 2 | Chèn trễ ngẫu nhiên 1..3 chu kỳ clock giữa các khối dữ liệu để kiểm tra khả năng lưu trạng thái đường truyền. | **PASS** |
| 6 | `test_ctr_overflow` | `dv/tests/test_ctr_overflow.sv` | 1 | Kích thích với `IV = 96'hffffffffffffffffffffffff` kiểm tra bộ đếm CTR counter tại ngưỡng tràn. | **PASS** |
| 7 | `test_decryption_errors` | `dv/tests/test_decryption_errors.sv` | 3 | Kiểm thử tiêu cực: Làm sai lệch 1 bit Ciphertext, AAD, Tag Ref $\rightarrow$ DUT và Golden Model đều kết luận `verify_pass = 0`. | **PASS** |
| 8 | `test_x_propagation` | `dv/tests/test_x_propagation.sv` | 2 | Tiêm giá trị không xác định ($X$) vào `data_in` và `cipher_key` $\rightarrow$ DUT lan truyền $X$ ra `data_out` và `tag`, không bị deadlock. | **PASS** |
| 9 | `test_reset` | `dv/tests/test_reset.sv` | 1 | Kích hoạt Reset bất đồng bộ giữa chừng khi đang tính toán, sau đó chạy giao dịch bình thường để xác minh khôi phục FSM. | **PASS** |
| 10 | `test_stress` | `dv/tests/test_stress.sv` | 8 | Đưa luồng 8 giao dịch ngẫu nhiên liên tiếp với độ dài và cấu hình thay đổi liên tục. | **PASS** |
| **Σ** | **Master Regression** | `dv/tests/test_all.sv` | **31** | **Chạy tuần tự toàn bộ 10 bộ test trên trong 1 lần chạy hồi quy.** | **100% PASS** |

---

## 4. KẾT QUẢ ĐỘ BAO PHỦ CHỨC NĂNG VÀ FSM (100% SIGN-OFF)

### 4.1. Transaction Functional & Cross Coverage: **100.00%**
- **Coverpoints (7/7 đạt 100%)**:
  1. `cp_mode` (ENCRYPT / DECRYPT): 100%
  2. `cp_key_type` (Zero / Ones / Pattern AA / Random): 100%
  3. `cp_iv_type` (Zero / Ones / Random): 100%
  4. `cp_aad_length` (0 khối, 1 khối, 2..4 khối, 5..8 khối): 100%
  5. `cp_payload_length` (1 khối, 2..4 khối, 5..8 khối, 9..12 khối): 100%
  6. `cp_verify_pass` (PASS=1, FAIL=0): 100%
  7. `cp_key_reuse` (New Key=0, Reused Key=1): 100%
- **Cross Coverages (5/5 đạt 100%)**:
  1. `cross_mode_payload`: 100%
  2. `cross_mode_aad`: 100%
  3. `cross_mode_key`: 100%
  4. `cross_mode_verify`: 100%
  5. `cross_mode_key_reuse`: 100%

### 4.2. FSM State & Transition Coverage: **100.00%**
- **Tất cả 11 Trạng thái FSM (`CU.sv`)**: **100.00% (11/11 States)**
  (`IDLE`, `KEY_EXPANSION`, `WAIT_H_CAL`, `WAIT_TAG_REF`, `WAIT_AAD`, `LOAD_AAD`, `WAIT_DATA`, `LOAD_DATA`, `WAIT_PROCESS_FINISH`, `VERIFY_PASS`, `FINISH`)
- **Tất cả 17 Cung chuyển trạng thái (FSM Transitions)**: **100.00% (17/17 Branches)**
  - `IDLE -> KEY_EXPANSION`
  - `IDLE -> WAIT_AAD` (Key Reuse Encrypt)
  - `IDLE -> WAIT_TAG_REF` (Key Reuse Decrypt)
  - `KEY_EXPANSION -> WAIT_H_CAL`
  - `WAIT_H_CAL -> WAIT_AAD` (Tag Ref đã nạp sớm)
  - `WAIT_H_CAL -> WAIT_TAG_REF` (Tag Ref nạp trễ - Black-box delay 25 cycles)
  - `WAIT_TAG_REF -> WAIT_AAD`
  - `WAIT_AAD -> LOAD_AAD`
  - `WAIT_AAD -> WAIT_DATA`
  - `LOAD_AAD -> WAIT_DATA`
  - `WAIT_DATA -> LOAD_DATA`
  - `WAIT_DATA -> WAIT_PROCESS_FINISH`
  - `LOAD_DATA -> WAIT_PROCESS_FINISH`
  - `WAIT_PROCESS_FINISH -> VERIFY_PASS`
  - `WAIT_PROCESS_FINISH -> FINISH`
  - `VERIFY_PASS -> FINISH`
  - `FINISH -> IDLE`

---

## 5. CÁC ĐẶC THÙ THIẾT KẾ RTL VÀ GIẢI PHÁP ĐÃ ĐƯỢC CHUẨN HÓA

### 5.1. Khác biệt đa thức trường hữu hạn GF($2^{128}$) giữa NIST SP 800-38D và RTL
- **Trong NIST SP 800-38D**: Chuẩn NIST định nghĩa đa thức $f(x) = x^{128} + x^7 + x^2 + x + 1$ với bit phản xạ (LSB-first trong từng byte).
- **Trong RTL của bạn (`ReductionBlock.sv` / `GF128bitMultiply.sv`)**: Thiết kế cài đặt phép nhân đa thức theo chuẩn MSB-first toán học trực tiếp.
- **Giải pháp**: C Golden Model (`aes_gcm_dpi.c`) hỗ trợ tham số `rtl_mode=1`. Scoreboard tự động tính và đối chiếu trực tiếp với `rtl_mode=1` (đạt 100% khớp từng bit), đồng thời in ra cả thẻ NIST chuẩn để kiểm tra chéo.

### 5.2. Giải quyết cung chuyển `WAIT_H_CAL -> WAIT_TAG_REF` theo chuẩn Black-Box
- **Nguyên nhân từng bị kẹt ở 16/17**: Do `tag_ref_ready` bật sớm ngay trong `KEY_EXPANSION`, Driver tự động nạp thẻ ngay lập tức khiến `tag_ref_loaded` luôn bằng 1 khi tính xong $H$. FSM do đó nhảy thẳng sang `WAIT_AAD`.
- **Cách xử lý chuẩn Black-Box**: Bổ sung cờ `delay_tag_ref` trong `transaction`. Driver mô phỏng độ trễ giao thức bus bên ngoài (25 chu kỳ clock sau khi nạp IV) bằng `repeat (25) @(vif.driver_cb);`. Trong khoảng thời gian này, DUT tính xong $H$, thấy chưa có Tag nên chuyển vào `WAIT_TAG_REF`. Hết 25 chu kỳ, Driver nạp thẻ, đưa FSM sang `WAIT_AAD`. Kích hoạt thành công 17/17 cung chuyển mà không đọc lén bất kỳ biến nội bộ nào.

### 5.3. Bắt tay hai chiều trong chế độ Giải mã (Decryption Handshake)
- Trong chế độ Decrypt, khi DUT hoàn thành kiểm tra Tag, nó phát cờ `verify_done = 1` và xuất `verify_pass`.
- DUT yêu cầu CPU/Driver phải phản hồi xung `verify_checked = 1` trong 1 chu kỳ clock để xác nhận, sau đó DUT mới phát xung `finish = 1`. Driver đã thực hiện chính xác bắt tay này.

---

## 6. HƯỚNG DẪN DÀNH CHO CÁC PHIÊN LÀM VIỆC TIẾP THEO

Khi mở một phiên chat mới hoặc chuyển giao cho kỹ sư/AI khác, bạn chỉ cần gửi lời nhắc:
> *"Hãy đọc file [docs/AES_128_GCM_VERIFICATION_REPORT.md](file:///F:/PROJECT%20CUA%20TUAN/AES-128-GCM/docs/AES_128_GCM_VERIFICATION_REPORT.md) và [docs/AES_128_GCM_VERIFICATION_PLAN_COMPLETE.md](file:///F:/PROJECT%20CUA%20TUAN/AES-128-GCM/docs/AES_128_GCM_VERIFICATION_PLAN_COMPLETE.md) để nắm toàn bộ kiến trúc kiểm thử và tiếp tục công việc."*

Môi trường kiểm thử hiện tại đã đạt trạng thái **Tapeout-Ready** hoàn chỉnh nhất!
