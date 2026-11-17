# Chiến dịch "Đánh thức Học viên Ngủ đông"

Phân tích vì sao các ticket của khách vãng lai (`student_id` là `NULL`) khiến câu lệnh `NOT IN` trả về danh sách rỗng, và sửa lại truy vấn con để tìm đúng những học viên chưa từng gửi ticket hỗ trợ.

## 1. Đề bài

- **Bối cảnh:** form "liên hệ hỗ trợ" nhận yêu cầu từ 2 loại người gửi, và tất cả được lưu vào bảng `Support_Tickets`:
  - **Học viên chính thức** (đã đăng nhập): hệ thống lưu `student_id`.
  - **Khách vãng lai** (chưa đăng nhập): `student_id` là `NULL`.
- **Nghiệp vụ:** CSKH muốn gửi email *"Bạn có đang gặp khó khăn gì không?"* tới những **học viên đã đăng ký nhưng chưa từng gửi ticket nào**.
- **Câu lệnh của Dev Junior:**

```sql
SELECT email, full_name
FROM Students
WHERE id NOT IN (SELECT student_id FROM Support_Tickets);
```

- **Nỗi đau:** câu lệnh trả về **0 người**, dù thực tế có rất nhiều học viên chưa từng mở ticket.

## 2. Phân tích bản chất logic

### Truy vấn con trả về gì?

Với dữ liệu mẫu, `SELECT student_id FROM Support_Tickets` trả về:

```
(1, NULL, NULL, 2, 4)
```

Hai giá trị `NULL` đến từ 2 ticket của khách vãng lai.

### NOT IN được tính như thế nào?

`NOT IN` là phủ định của một chuỗi `OR`, theo luật De Morgan trở thành **một chuỗi `AND`**:

```
id NOT IN (1, NULL, NULL, 2, 4)
⟺ id <> 1 AND id <> NULL AND id <> NULL AND id <> 2 AND id <> 4
```

SQL dùng **logic ba giá trị** (TRUE, FALSE, UNKNOWN). `NULL` nghĩa là "không xác định", nên mọi phép so sánh với `NULL` như `id <> NULL` đều cho ra **UNKNOWN**. Hệ quả với từng học viên:

| Học viên | Các vế so sánh với 1, 2, 4 | Vế `id <> NULL` | Kết quả của chuỗi AND |
|---|---|---|---|
| 3 – Lê Ngọc Diệp (chưa gửi ticket) | Tất cả TRUE | UNKNOWN | TRUE AND UNKNOWN = **UNKNOWN** |
| 1 – Nguyễn Minh Anh (đã gửi ticket) | Có vế FALSE (`1 <> 1`) | UNKNOWN | FALSE AND UNKNOWN = **FALSE** |

Điều kiện **không bao giờ đạt TRUE** với bất kỳ học viên nào. `WHERE` chỉ giữ dòng có điều kiện **TRUE**, nên kết quả là **danh sách rỗng**.

Nói cách khác: với mỗi học viên, Database đang tự hỏi *"học viên này có phải là một trong những khách vãng lai không xác định danh tính kia không?"*. Câu trả lời luôn là "không biết", nên không ai được chọn.

Chỉ cần **một** ticket của khách vãng lai là đủ làm hỏng cả chiến dịch, và câu lệnh không báo lỗi gì nên rất khó phát hiện.

## 3. Thực thi và sửa lỗi

### Cách sửa theo yêu cầu: loại NULL trong truy vấn con

```sql
SELECT email, full_name
FROM Students
WHERE id NOT IN (
    SELECT student_id
    FROM Support_Tickets
    WHERE student_id IS NOT NULL
)
ORDER BY id;
```

- `WHERE student_id IS NOT NULL` loại các ticket của khách vãng lai **trước khi** đưa vào danh sách so sánh. Phải dùng `IS NOT NULL`, vì `<> NULL` cũng cho ra UNKNOWN.
- Truy vấn con giờ chỉ còn `(1, 2, 4)`, nên mọi phép so sánh đều cho TRUE hoặc FALSE, và `NOT IN` hoạt động đúng.
- Về nghiệp vụ, điều kiện này cũng hợp lý: ticket của khách vãng lai không thuộc về học viên nào, nên không liên quan tới việc một học viên "đã từng gửi ticket hay chưa".

### Cách viết thay thế: NOT EXISTS

```sql
SELECT s.email, s.full_name
FROM Students s
WHERE NOT EXISTS (
    SELECT 1
    FROM Support_Tickets t
    WHERE t.student_id = s.id
)
ORDER BY s.id;
```

`EXISTS` chỉ trả về TRUE hoặc FALSE, không bao giờ UNKNOWN. Ticket có `student_id` là `NULL` đơn giản là không khớp với học viên nào. Cách này an toàn với `NULL` mà **không cần nhớ thêm điều kiện**, nên được khuyên dùng trong các dự án thực tế.

## 4. Kết quả

| Học viên | Ticket đã gửi | Code lỗi | Code đã sửa |
|---|---|---|---|
| 1 – Nguyễn Minh Anh | Lỗi đăng nhập | Không lấy | Không lấy (đã gửi ticket) |
| 2 – Trần Hoàng Bách | Video mất tiếng | Không lấy | Không lấy (đã gửi ticket) |
| 3 – Lê Ngọc Diệp | Chưa gửi | ❌ Bỏ sót | ✅ Lấy |
| 4 – Phạm Quốc Bảo | Thanh toán chưa kích hoạt | Không lấy | Không lấy (đã gửi ticket) |
| 5 – Vũ Hải Đăng | Chưa gửi | ❌ Bỏ sót | ✅ Lấy |

Danh sách gửi email:

| email | full_name |
|---|---|
| diep.le@email.com | Lê Ngọc Diệp |
| dang.vu@email.com | Vũ Hải Đăng |

Cả hai cách sửa (`NOT IN` + `IS NOT NULL` và `NOT EXISTS`) đều cho cùng kết quả này.

## 5. Bài học rút ra

- `NOT IN` + truy vấn con trên cột **có thể chứa NULL** là một cái bẫy: chỉ một giá trị `NULL` là đủ làm kết quả rỗng.
- Nguyên nhân là **logic ba giá trị**: `x <> NULL` là UNKNOWN, và `TRUE AND UNKNOWN` vẫn là UNKNOWN.
- Khi dùng `NOT IN`, luôn thêm `WHERE cột IS NOT NULL` vào truy vấn con. Tốt hơn nữa, dùng `NOT EXISTS`.
- Kiểm thử với dữ liệu có `NULL`, vì đây là dữ liệu "bình thường" của hệ thống (khách vãng lai), không phải dữ liệu lỗi.
