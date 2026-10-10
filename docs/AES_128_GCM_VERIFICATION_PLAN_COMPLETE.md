# KẾ HOẠCH VÀ BÁO CÁO KIỂM THỬ HOÀN CHỈNH (COMPLETE VERIFICATION PLAN & REPORT)
# VI MẠCH SỐ AES-128-GCM CHUẨN CÔNG NGHIỆP

---

## 1. TỔNG QUAN VÀ MỤC TIÊU KIỂM THỬ (VERIFICATION GOALS & SCOPE)

### 1.1. Mục tiêu
Tài liệu này xác định toàn bộ **Kế hoạch kiểm thử (Verification Plan)** và **Báo cáo nghiệm thu (Verification Sign-off Report)** cho lõi IP phần cứng **AES-128-GCM** (NIST SP 800-38D). Môi trường kiểm thử được xây dựng theo chuẩn công nghiệp hướng đối tượng (OOP SystemVerilog Testbench Architecture, lấy cảm hứng từ chuẩn UVM / EDA Playground).

### 1.2. Tiêu chuẩn nghiệm thu (Sign-off Criteria)
1. **Độ chính xác dữ liệu (Data Integrity)**: Đạt 100% khớp từng bit giữa DUT và C Golden Reference Model qua giao diện DPI-C co-simulation trên toàn bộ các chế độ Mã hóa (Encryption) và Giải mã xác thực (Decryption & Authentication).
2. **Độ bao phủ chức năng (Functional Coverage)**: Đạt **100.00%** đối với tất cả các Coverpoints không gian dữ liệu (Key, IV, AAD length, Payload length, Mode, Verify pass, Key reuse) và tất cả các Cross Coverage tương ứng.
3. **Độ bao phủ máy trạng thái hữu hạn (FSM Coverage)**: Đạt **100.00%** cho toàn bộ 11 trạng thái phần cứng và **100.00% (17/17)** cho tất cả các cung chuyển trạng thái nhánh (FSM Transitions).
4. **Giám sát giao thức chu kỳ thực (Protocol Assertions - SVA)**: 10 thuộc tính SVA giám sát trực tiếp trên bus tín hiệu phần cứng với **0 lỗi vi phạm (Zero violations)**.
5. **Độ bền bỉ phần cứng (Robustness & Resiliency)**: Kiểm tra thành công khả năng chặn/lan truyền giá trị bất định ($X$), phục hồi tức thì sau Reset bất đồng bộ, xử lý áp suất ngược (Backpressure stalls), và áp lực cao liên tục (Stress bursts).

---

## 2. MA TRẬN TÍNH NĂNG THIẾT KẾ (DESIGN FEATURE MATRIX)

| Mã Tính Năng | Mô tả tính năng phần cứng (DUT Feature) | Trạng thái / Cổng liên quan | Mức độ ưu tiên |
|:---|:---|:---|:---:|
| **FEAT-01** | Chuẩn mã hóa AES-128 GCM (NIST SP 800-38D KAT) | `mode=0`, `cipher_key`, `IV`, `tag` | P1 (Critical) |
| **FEAT-02** | Giải mã và xác thực toàn vẹn dữ liệu (Tag Verification) | `mode=1`, `tag_ref`, `verify_pass`, `verify_done` | P1 (Critical) |
| **FEAT-03** | Hỗ trợ dữ liệu AAD linh hoạt (0 block đến nhiều block) | `no_AAD`, `load_AAD`, `AAD_last`, `AAD_ready` | P1 (Critical) |
| **FEAT-04** | Hỗ trợ độ dài Payload linh hoạt (1 block đến nhiều block) | `load_data`, `data_in_last`, `data_ready` | P1 (Critical) |
| **FEAT-05** | Tái sử dụng Key (Hardware Key Reuse - Giữ lại cache $H$ & round keys) | Bỏ qua xung `load_key`, chỉ cấp xung `load_IV` | P1 (Critical) |
| **FEAT-06** | Bắt tay hai chiều giải mã (`verify_done` -> `verify_checked`) | `verify_done`, `verify_checked` handshake | P1 (Critical) |
| **FEAT-07** | Phát hiện giả mạo dữ liệu / Tag không khớp (Decryption Fail) | `verify_pass = 0`, cảnh báo giả mạo | P1 (Critical) |
| **FEAT-08** | Khả năng điều tiết lưu lượng / Chịu trễ bus (Backpressure / Inter-block stalls) | Treo `load_data` / `load_AAD` ngẫu nhiên 1-3 chu kỳ | P2 (High) |
| **FEAT-09** | Xử lý giá trị biên bộ đếm CTR (CTR Counter Boundary / ALL_ONES_IV) | `IV = 96'hffffffffffffffffffffffff` | P2 (High) |
| **FEAT-10** | Miễn nhiễm và lan truyền giá trị bất định ($X$-State Propagation) | Input $X$ -> Tag & Ciphertext phải báo $X$ | P2 (High) |
| **FEAT-11** | Khởi động lại bất đồng bộ an toàn (Asynchronous Reset Recovery) | Kích hoạt `rst_n = 0` giữa chừng và khôi phục | P1 (Critical) |
| **FEAT-12** | Chịu tải áp lực liên tục (Stress Burst Streaming) | Dòng giao dịch ngẫu nhiên liên tiếp không ngừng nghỉ | P2 (High) |

---

## 3. KIẾN TRÚC MÔI TRƯỜNG KIỂM THỬ (OOP TESTBENCH ARCHITECTURE)

```
dv/
├── dpi/
│   ├── aes_gcm_dpi.c              # C Golden Reference Model (DPI-C)
│   └── aes_gcm_dpi.dll            # Thư viện động 64-bit DLL co-simulation
├── env/
│   ├── interface.sv               # data_if (Tín hiệu kết nối DUT, clocking blocks, cu_state)
│   ├── transaction.sv             # 4-state logic [127:0], hỗ trợ X-injection, skip_key, delay_tag_ref
│   ├── generator.sv               # Sinh transaction ngẫu nhiên có ràng buộc & directed
│   ├── driver.sv                  # Lái kích thích theo đúng chu kỳ bắt tay FSM, hỗ trợ key reuse & stall delay
│   ├── monitor.sv                 # Quan sát thụ động và đóng gói giao dịch, hỗ trợ bắt key reuse
│   ├── scoreboard.sv              # Đối chiếu C Golden Model qua DPI-C, kiểm tra X-prop, gọi coverage
│   ├── coverage.sv                # 2 Covergroup: cg_aes_gcm (100%) và cg_fsm (FSM states & transitions 100%)
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

### 3.1. Các nguyên tắc thiết kế chính
1. **Phân tách tuyệt đối giữa Top-level và Test logic**: `tb_top.sv` chỉ chứa kết nối dây và chọn test qua `+TESTNAME`. Mỗi test là một class riêng biệt kế thừa từ `base_test`.
2. **DPI-C Co-simulation**: Sử dụng hàm C chuẩn ANSI kết nối qua DPI-C để đối chiếu trực tiếp kết quả với DUT mà không cần file text trung gian.
3. **Passive Monitoring**: Monitor không điều khiển DUT, chỉ thụ động lấy mẫu tại cạnh lên xung nhịp thông qua `monitor_cb`.

---

## 4. MA TRẬN TEST SUITE VÀ TESTCASE (TEST PLAN MATRIX)

Toàn bộ 10 bộ kiểm thử (Test Suites) với **31 giao dịch phần cứng** được tích hợp trong bộ kiểm thử Master Regression `test_all`:

| STT | Tên Test Suite | File Kiểm thử | Số Trans | Mục tiêu kiểm thử | Tính năng xác nhận | Kết quả |
|:---:|:---|:---|:---:|:---|:---|:---:|
| 1 | **NIST KAT** | `test_nist_kat.sv` | 4 | Kiểm thử mẫu chuẩn NIST SP 800-38D (TC1 không AAD, TC2 có AAD cho cả Encrypt và Decrypt) | FEAT-01, FEAT-02, FEAT-03 | **PASS** |
| 2 | **Full Coverage** | `test_coverage_full.sv` | 4 | Kích hoạt các miền giá trị biên: Khóa mẫu 0xAAAA, Khóa toàn 1 0xFFFF, IV toàn 1, AAD lớn (5 khối), Payload dài (9 khối), nạp trễ Tag Ref | FEAT-01, FEAT-02, FEAT-04, FEAT-09 | **PASS** |
| 3 | **Key Reuse** | `test_reuse_key.sv` | 3 | Kiểm thử nạp Key ban đầu, sau đó thực hiện Encrypt và Decrypt liên tiếp chỉ bằng xung `load_IV` (bỏ qua `load_key`) | FEAT-05 | **PASS** |
| 4 | **Enc-Dec Chain** | `test_enc_dec_chain.sv` | 2 | Chuỗi khép kín: Bản rõ -> Mã hóa (sinh ra Ciphertext & Tag) -> Giải mã trực tiếp -> Đối chiếu bản rõ gốc | FEAT-01, FEAT-02 | **PASS** |
| 5 | **Backpressure** | `test_backpressure.sv` | 2 | Chèn trễ ngẫu nhiên 1..3 chu kỳ clock giữa các khối AAD và Payload để kiểm tra khả năng giữ trạng thái | FEAT-08 | **PASS** |
| 6 | **CTR Overflow** | `test_ctr_overflow.sv` | 1 | Kích thích với `IV = 96'hffffffffffffffffffffffff` kiểm tra bộ đếm CTR counter tại ngưỡng tràn | FEAT-09 | **PASS** |
| 7 | **Decryption Error** | `test_decryption_errors.sv` | 3 | Tiêm lỗi giả mạo vào Ciphertext, AAD, và Tag Ref. Kỳ vọng DUT phát hiện và hạ cờ `verify_pass = 0` | FEAT-07 | **PASS** |
| 8 | **X-Propagation** | `test_x_propagation.sv` | 2 | Tiêm giá trị không xác định ($X$) vào `data_in` và `cipher_key`. Kiểm tra DUT phản hồi giá trị $X$ an toàn | FEAT-10 | **PASS** |
| 9 | **Reset Recovery** | `test_reset.sv` | 2 | Kích hoạt Reset bất đồng bộ giữa chừng khi đang tính toán, sau đó khởi chạy giao dịch mới để xác minh phục hồi | FEAT-11 | **PASS** |
| 10 | **Stress Testing** | `test_stress.sv` | 8 | Đưa luồng 8 giao dịch ngẫu nhiên liên tiếp với độ dài và cấu hình thay đổi liên tục | FEAT-12 | **PASS** |
| **TỔNG** | **10 TEST SUITES** | **Master: test_all** | **31** | **Bao phủ toàn diện mọi ngóc ngách chức năng và trạng thái phần cứng** | **FEAT 01-12** | **100% PASS** |

---

## 5. KẾ HOẠCH VÀ KẾT QUẢ ĐỘ BAO PHỦ (COVERAGE PLAN & RESULTS)

### 5.1. Transaction Functional Coverage (`cg_aes_gcm`) — Đạt 100.00%

#### Các điểm bao phủ đơn lẻ (Coverpoints):
| Coverpoint | Biến quan sát | Các Bins định nghĩa | Tỷ lệ bao phủ |
|:---|:---|:---|:---:|
| `cp_mode` | `tr.mode` | `ENCRYPT (0)`, `DECRYPT (1)` | **100.00%** |
| `cp_key_type` | `tr.cipher_key` | `ALL_ZEROS`, `ALL_ONES`, `PATTERN_AA`, `RANDOM` | **100.00%** |
| `cp_iv_type` | `tr.IV` | `ALL_ZEROS`, `ALL_ONES`, `RANDOM` | **100.00%** |
| `cp_aad_length` | `tr.aad_blocks.size()` | `NO_AAD (0)`, `SINGLE (1)`, `MULTI_LOW (2..4)`, `MULTI_HI (5..8)` | **100.00%** |
| `cp_payload_length`| `tr.data_in_blocks.size()` | `SINGLE (1)`, `SHORT (2..4)`, `MEDIUM (5..8)`, `LONG (9..12)` | **100.00%** |
| `cp_verify_pass` | `tr.verify_pass` | `PASS (1)`, `FAIL (0)` | **100.00%** |
| `cp_key_reuse` | `tr.skip_key` | `NEW_KEY (0)`, `REUSED_KEY (1)` | **100.00%** |

#### Các điểm giao nhau (Cross Coverage):
| Cross Coverage | Các thành phần giao nhau | Ý nghĩa kiểm thử | Tỷ lệ bao phủ |
|:---|:---|:---|:---:|
| `cross_mode_payload` | `cp_mode` x `cp_payload_length` | Mọi độ dài payload đều được kiểm tra ở cả 2 chế độ Encrypt & Decrypt | **100.00%** |
| `cross_mode_aad` | `cp_mode` x `cp_aad_length` | Mọi kích thước AAD đều được kiểm tra ở cả 2 chế độ | **100.00%** |
| `cross_mode_key` | `cp_mode` x `cp_key_type` | Các dạng key đặc biệt đều được kiểm tra ở cả 2 chế độ | **100.00%** |
| `cross_mode_verify` | `cp_mode` x `cp_verify_pass` | Xác nhận kết quả Pass/Fail trong chế độ giải mã Decrypt | **100.00%** |
| `cross_mode_key_reuse`| `cp_mode` x `cp_key_reuse` | Tính năng Key Reuse được kích hoạt ở cả Encrypt và Decrypt | **100.00%** |

---

### 5.2. Máy trạng thái hữu hạn FSM Coverage (`cg_fsm`) — Đạt 100.00%

FSM điều khiển trung tâm (`CU.sv`) gồm **11 trạng thái**. Bộ đo `cg_fsm` được kích hoạt liên tục thông qua tiến trình quan sát `@(vif.cu_state)` trong `environment.sv`.

#### A. Bao phủ toàn bộ trạng thái (11/11 States = 100.00%):
1. `IDLE (0)`: Trạng thái nghỉ, chờ nạp khóa hoặc nạp IV.
2. `KEY_EXPANSION (1)`: Mở rộng khóa 10 vòng mã hóa AES.
3. `WAIT_H_CAL (2)`: Tính giá trị hash subkey $H = AES_K(0)$.
4. `WAIT_TAG_REF (3)`: Chờ nạp thẻ tham chiếu `tag_ref` (chế độ giải mã).
5. `WAIT_AAD (4)`: Chờ tín hiệu bắt tay nạp AAD.
6. `LOAD_AAD (5)`: Đang nạp dòng dữ liệu AAD qua bus.
7. `WAIT_DATA (6)`: Chờ tín hiệu bắt tay nạp Payload.
8. `LOAD_DATA (7)`: Đang nạp dòng dữ liệu Payload qua bus.
9. `WAIT_PROCESS_FINISH (8)`: Chờ khối GHASH và Tag Processing hoàn tất.
10. `VERIFY_PASS (9)`: Trạng thái so khớp thẻ Tag ở chế độ Decrypt.
11. `FINISH (10)`: Phát xung hoàn tất giao dịch `finish = 1`.

#### B. Bao phủ toàn bộ cung chuyển trạng thái (17/17 Transitions = 100.00%):

| STT | Cung chuyển trạng thái (FSM Transition) | Mã Bins | Điều kiện kích hoạt trong phần cứng | Trạng thái đạt được |
|:---:|:---|:---:|:---|:---:|
| 1 | `IDLE -> KEY_EXPANSION` | `4'd0 => 4'd1` | Nạp Master Key mới (`load_key = 1`) | **HIT** |
| 2 | `IDLE -> WAIT_TAG_REF` | `4'd0 => 4'd3` | Key Reuse trong chế độ Decrypt (`skip_key=1, mode=1`) | **HIT** |
| 3 | `IDLE -> WAIT_AAD` | `4'd0 => 4'd4` | Key Reuse trong chế độ Encrypt (`skip_key=1, mode=0`) | **HIT** |
| 4 | `KEY_EXPANSION -> WAIT_H_CAL` | `4'd1 => 4'd2` | Quá trình mở rộng khóa 10 vòng kết thúc (`expansion_finish=1`) | **HIT** |
| 5 | `WAIT_H_CAL -> WAIT_AAD` | `4'd2 => 4'd4` | Tính xong H khi `tag_ref` đã nạp sớm trong `KEY_EXPANSION` | **HIT** |
| 6 | **`WAIT_H_CAL -> WAIT_TAG_REF`** | **`4'd2 => 4'd3`** | **Tính xong H trong Decrypt nhưng `tag_ref` chưa được nạp (`tag_ref_loaded=0`)** | **HIT (Đã giải quyết)** |
| 7 | `WAIT_TAG_REF -> WAIT_AAD` | `4'd3 => 4'd4` | Nạp thành công thẻ `tag_ref` (`tag_ref_loaded=1`) | **HIT** |
| 8 | `WAIT_AAD -> LOAD_AAD` | `4'd4 => 4'd5` | Bắt đầu nạp khối AAD đầu tiên khi có nhiều khối AAD | **HIT** |
| 9 | `WAIT_AAD -> WAIT_DATA` | `4'd4 => 4'd6` | Không có AAD (`no_AAD=1`) hoặc chỉ có đúng 1 khối AAD | **HIT** |
| 10 | `LOAD_AAD -> WAIT_DATA` | `4'd5 => 4'd6` | Nạp khối AAD cuối cùng (`AAD_last=1`) | **HIT** |
| 11 | `WAIT_DATA -> LOAD_DATA` | `4'd6 => 4'd7` | Bắt đầu nạp khối dữ liệu đầu tiên khi có nhiều khối | **HIT** |
| 12 | `WAIT_DATA -> WAIT_PROCESS_FINISH` | `4'd6 => 4'd8` | Chỉ có duy nhất 1 khối dữ liệu (`data_in_last=1`) | **HIT** |
| 13 | `LOAD_DATA -> WAIT_PROCESS_FINISH` | `4'd7 => 4'd8` | Nạp khối dữ liệu cuối cùng (`data_in_last=1`) | **HIT** |
| 14 | `WAIT_PROCESS_FINISH -> VERIFY_PASS`| `4'd8 => 4'd9` | Kết thúc xử lý trong chế độ Giải mã (`mode=1`) | **HIT** |
| 15 | `WAIT_PROCESS_FINISH -> FINISH` | `4'd8 => 4'd10`| Kết thúc xử lý trong chế độ Mã hóa (`mode=0`) | **HIT** |
| 16 | `VERIFY_PASS -> FINISH` | `4'd9 => 4'd10`| Nhận xung phản hồi bắt tay `verify_checked = 1` | **HIT** |
| 17 | `FINISH -> IDLE` | `4'd10 => 4'd0`| Kết thúc chu kỳ hoàn tất, FSM tự động quay về trạng thái rảnh | **HIT** |

---

### 5.3. Giải thích chi tiết: Tại sao từng xảy ra hiện tượng 16/17 cung chuyển và cách giải quyết

#### Phân tích nguyên nhân gốc rễ (Root Cause Analysis):
Trong thiết kế `CU.sv`, logic chuyển trạng thái tại `WAIT_H_CAL` (trạng thái 2) được lập trình như sau:
```systemverilog
WAIT_H_CAL: begin
    if(H_loaded && IV_loaded) begin
        if(!tag_ref_loaded && mode)
            Next = WAIT_TAG_REF; // Cung h_to_tagref: 4'd2 => 4'd3
        else
            Next = WAIT_AAD;     // Cung h_to_aad:    4'd2 => 4'd4
    end
end
```
Đồng thời, logic điều khiển đầu ra của CU cho phép tín hiệu sẵn sàng `tag_ref_ready` bật lên mức 1 ngay từ khi FSM đang ở trạng thái `KEY_EXPANSION`:
```systemverilog
KEY_EXPANSION: begin
    if (!tag_ref_loaded && mode)
        tag_ref_ready = 1'b1;
end
```
**Cơ chế phát sinh vấn đề:**
- Testbench thông thường (Driver tự động) hoạt động theo cơ chế phản ứng nhanh: Khi thấy `tag_ref_ready = 1`, Driver lập tức phát xung nạp `tag_ref` ngay trong những chu kỳ đầu tiên của `KEY_EXPANSION`.
- Do đó, biến `tag_ref_loaded` đã được ghi nhận bằng `1` từ rất lâu trước khi phép tính toán hash subkey $H$ kết thúc (quá trình tính $H$ mất ~20 chu kỳ clock).
- Khi $H$ tính xong (`H_loaded = 1`), điều kiện kiểm tra `!tag_ref_loaded && mode` luôn luôn trả về **FALSE** (vì `tag_ref_loaded` đã bằng 1).
- Hậu quả: FSM **luôn luôn nhảy thẳng từ `WAIT_H_CAL` sang `WAIT_AAD`** (cung 2 => 4). Cung chuyển trạng thái `WAIT_H_CAL -> WAIT_TAG_REF` (2 => 3) không bao giờ có cơ hội xảy ra, dẫn đến việc độ bao phủ chuyển trạng thái dừng lại ở **16/17 (94.12%)**.

#### Giải pháp kỹ thuật chuẩn công nghiệp (Strict Black-box Verification):
1. **Bổ sung cờ điều khiển `delay_tag_ref`** trong lớp `transaction`: Chỉ thị cho Driver mô phỏng trường hợp CPU/Host bên ngoài chưa có sẵn Tag tham chiếu khi bắt đầu phiên giải mã.
2. **Cập nhật cơ chế Driver theo nguyên lý Black-box**:
   - Driver **không truy cập bất kỳ thanh ghi nội bộ nào** của DUT (`cu_state`).
   - Thay vào đó, Driver chỉ đơn thuần mô phỏng độ trễ giao thức thực tế của hệ thống bên ngoài: sau khi nạp Key và IV, Driver trì hoãn 25 chu kỳ xung nhịp (`repeat (25) @(vif.driver_cb);`) rồi mới gọi `drive_tag_ref(tr)`.
   ```systemverilog
   if (tr.mode == 1'b1) begin
     if (tr.delay_tag_ref) begin
       $display("[DRIVER] DELAY_TAG_REF active: Black-box delay 25 cycles before driving TAG_REF...");
       repeat (25) @(vif.driver_cb);
       drive_tag_ref(tr);
     end else begin
       drive_tag_ref(tr);
     end
   end
   ```
3. **Kích hoạt trong Test Suite**: Trong `test_coverage_full.sv` (Testcase 6 - Decryption), kích hoạt `tc_sb_aad.delay_tag_ref = 1'b1`.
4. **Kết quả**: Trong 25 chu kỳ trễ đó, DUT tính xong $H$ trong khi `tag_ref_loaded == 0`, FSM chuyển sang `WAIT_TAG_REF` (2 => 3). Sau 25 chu kỳ, Driver nạp `tag_ref`, đưa FSM sang `WAIT_AAD` (3 => 4). Toàn bộ **17/17 cung chuyển (100.00%)** được kích hoạt tự nhiên, hoàn toàn tuân thủ nguyên lý kiểm thử Black-box!

---

## 6. MA TRẬN KHẲNG ĐỊNH GIAO THỨC PHẦN CỨNG (SVA ASSERTION PLAN)

Toàn bộ 10 thuộc tính SVA (`dv/env/aes_gcm_assertions.sv`) được kiểm tra đồng bộ liên tục tại mọi cạnh lên của xung nhịp `clk`:

| STT | Tên Assertions | Thuộc tính kiểm tra (SVA Property) | Mục tiêu phát hiện lỗi | Vi phạm |
|:---:|:---|:---|:---|:---:|
| 1 | `sva_key_ready_pulse` | `$rose(load_key) \|-> ##[1:2] !key_ready` | Xung `load_key` phải lập tức kéo hạ `key_ready` | 0 |
| 2 | `sva_iv_ready_pulse` | `$rose(load_IV) \|-> ##[1:2] !IV_ready` | Xung `load_IV` phải lập tức kéo hạ `IV_ready` | 0 |
| 3 | `sva_aad_ready_pulse` | `$rose(load_AAD && AAD_last) \|-> ##[1:2] !AAD_ready` | Khối AAD cuối cùng phải lập tức đóng cổng AAD | 0 |
| 4 | `sva_data_ready_pulse`| `$rose(load_data && data_in_last) \|-> ##[1:2] !data_ready` | Khối Data cuối cùng phải lập tức đóng cổng Data | 0 |
| 5 | `sva_verify_handshake` | `$rose(verify_done) \|-> ##[1:20] verify_checked` | Bắt tay xác nhận kết quả kiểm tra Tag giữa CPU và DUT | 0 |
| 6 | `sva_verify_during_finish` | `finish \|-> (verify_done \|\| (mode == 1'b0))` | Khi `finish = 1` ở chế độ Decrypt, bắt buộc phải có `verify_done` | 0 |
| 7 | `sva_tag_valid_encrypt`| `(finish && (mode == 1'b0)) \|-> tag_valid` | Khi `finish = 1` ở chế độ Encrypt, thẻ `tag` phải hợp lệ | 0 |
| 8 | `sva_no_aad_data_ready`| `$rose(no_AAD) \|-> ##[1:10] data_ready` | Khi khai báo `no_AAD`, DUT phải mở cổng Data tiếp nhận ngay | 0 |
| 9 | `sva_fsm_valid_state` | `cu_state <= 4'd10` | FSM tuyệt đối không bao giờ lạc vào các trạng thái rác (11..15) | 0 |
| 10 | `sva_finish_pulse_width` | `$rose(finish) \|=> !finish` | Xung hoàn tất `finish` phải là xung đơn đúng 1 chu kỳ clock | 0 |

---

## 7. BÁO CÁO KẾT QUẢ MÔ PHỎNG THỰC TẾ (REGRESSION RUN RESULTS)

Kết quả thực thi lệnh chạy hồi quy toàn bộ:
```powershell
& "C:\questasim64_10.7c\win64\vsim.exe" -c -coverage -sv_lib ../dv/dpi/aes_gcm_dpi -voptargs="+acc" work.tb_top "+TESTNAME=test_all" -do "run -all; quit -f"
```

### 7.1. Báo cáo đối chiếu dữ liệu Scoreboard (DPI-C C Golden Model)
```
##############################################################
#        FINAL SCOREBOARD REPORT (DPI-C C GOLDEN MODEL)         
##############################################################
#  Total Transactions Tested : 31
#  Passed Transactions       : 31
#  Failed Transactions       : 0
#  RESULT: ALL TESTS PASSED SUCCESSFULLY! (100% MATCH WITH C)
##############################################################
```

### 7.2. Báo cáo độ bao phủ chức năng (Functional Coverage)
```
##############################################################
#             FUNCTIONAL & CROSS COVERAGE REPORT             #
##############################################################
#  Total Sampled Transactions: 29
#------------------------------------------------------------#
#  [COVERPOINTS]                                             #
#    1. cp_mode              (ENCRYPT / DECRYPT)  : 100.00 %   #
#    2. cp_key_type          (Zero/Ones/Pat/Rand) : 100.00 %   #
#    3. cp_iv_type           (Zero/Ones/Rand)     : 100.00 %   #
#    4. cp_aad_length        (0, 1, 2..4, 5..8)   : 100.00 %   #
#    5. cp_payload_length    (1, 2..4, 5..8, 9..12):100.00 %   #
#    6. cp_verify_pass       (PASS=1, FAIL=0)     : 100.00 %   #
#    7. cp_key_reuse         (New Key / Reused)   : 100.00 %   #
#------------------------------------------------------------#
#  [CROSS COVERAGE]                                          #
#    1. cross_mode_payload   (Mode x Payload Len) : 100.00 %   #
#    2. cross_mode_aad       (Mode x AAD Len)     : 100.00 %   #
#    3. cross_mode_key       (Mode x Key Type)    : 100.00 %   #
#    4. cross_mode_verify    (Decrypt x Verify)   : 100.00 %   #
#    5. cross_mode_key_reuse (Mode x Key Reuse)   : 100.00 %   #
#------------------------------------------------------------#
#  >>> OVERALL TRANSACTION COVERAGE SCORE         : 100.00 %   #
##############################################################
```

### 7.3. Báo cáo độ bao phủ máy trạng thái FSM (FSM Coverage)
```
##############################################################
#             FSM STATE & TRANSITION COVERAGE REPORT         #
##############################################################
#  Total FSM State Transition Samples: 262
#    1. FSM All 11 States    (IDLE..FINISH)       : 100.00 %   #
#    2. FSM Transitions      (Branch Paths)       : 100.00 %   #
#  >>> OVERALL FSM COVERAGE SCORE                 : 100.00 %   #
##############################################################
```

---

## 8. KẾT LUẬN VÀ NGHIỆM THU (VERIFICATION SIGN-OFF)

| Tiêu chí nghiệm thu (Sign-off Criteria) | Mục tiêu | Đạt được | Đánh giá |
|:---|:---:|:---:|:---:|
| Khớp dữ liệu với C Golden Reference | 100% | 100% (31/31 Trans) | **ĐẠT (PASSED)** |
| Functional & Cross Coverage | 100% | 100.00% | **ĐẠT (PASSED)** |
| FSM State Coverage | 100% | 100.00% (11/11 States) | **ĐẠT (PASSED)** |
| FSM Transition Coverage | 100% | 100.00% (17/17 Branches) | **ĐẠT (PASSED)** |
| SystemVerilog Protocol Assertions (SVA) | 0 Fail | 0 Violations | **ĐẠT (PASSED)** |
| Kiểm tra khả năng xử lý X & Phục hồi Reset | 100% | 100% (Không treo bus) | **ĐẠT (PASSED)** |
| Kiến trúc mã nguồn module hóa theo chuẩn EDA | Chuẩn OOP | 100% Tách biệt Test/TB | **ĐẠT (PASSED)** |

> **KẾT LUẬN CUỐI CÙNG**: Thiết kế vi mạch **AES-128-GCM IP Core** đã hoàn thành toàn bộ các yêu cầu của Verification Plan, đạt chỉ số chất lượng cao nhất (**100% Functional Coverage, 100% FSM Coverage, 100% Data Match, 0 SVA Errors**), sẵn sàng cho quy trình tổng hợp logic và Tapeout.
