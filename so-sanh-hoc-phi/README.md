# Sửa lỗi Module "So sánh Học phí"

Phân tích vì sao toán tử `=` kết hợp với truy vấn con làm sập màn hình Kế toán khi giảng viên mở thêm khóa học, và sửa lại bằng `IN` để code chạy đúng dù giảng viên có 1 hay 100 khóa học.

## 1. Đề bài

- **Nghiệp vụ:** Phòng Kế toán muốn tìm tất cả khóa học có mức giá **bằng** mức giá của các khóa học do giảng viên **Trần Văn A** (`instructor_id = 5`) giảng dạy.
- **Đoạn code của Dev:**

```sql
SELECT title, price
FROM Courses
WHERE price = (SELECT price FROM Courses WHERE instructor_id = 5);
```

- **Nỗi đau:** hôm qua code chạy bình thường. Hôm nay ông A mở bán thêm 2 khóa học với giá khác nhau, và màn hình Kế toán báo lỗi *Subquery returns more than 1 row*.

## 2. Phân tích

### Bản chất toán học của `=` với truy vấn con

Toán tử `=` là phép so sánh **một giá trị với một giá trị**: `price = x`. Vì vậy, khi đặt truy vấn con ở vế phải của `=`, Database yêu cầu truy vấn con là **Scalar Subquery**, tức trả về **đúng 1 dòng, 1 cột**.

| Truy vấn con trả về | `price = (...)` |
|---|---|
| 1 dòng, ví dụ `1200000` | ✅ So sánh được: `price = 1200000` |
| Nhiều dòng, ví dụ `1200000, 1500000, 2500000` | ❌ Không xác định: `price = {1200000, 1500000, 2500000}` là vô nghĩa, một số không thể "bằng" một tập hợp |
| 0 dòng | Trả về `NULL`, phép so sánh là UNKNOWN, kết quả rỗng (không lỗi) |

### Vì sao ông A mở thêm khóa học lại làm sập hệ thống?

- **Hôm qua:** ông A chỉ có **1 khóa học** (Lập trình C++ căn bản, 1.200.000). Truy vấn con trả về đúng 1 giá trị nên `=` hoạt động, và code "tình cờ" chạy đúng.
- **Hôm nay:** ông A có **3 khóa học** với giá 1.200.000, 1.500.000 và 2.500.000. Truy vấn con trả về **3 dòng**, phép `=` không thể thực hiện, nên MySQL báo lỗi `ERROR 1242: Subquery returns more than 1 row` và toàn bộ câu lệnh dừng lại.

Lỗi gốc nằm ở **thiết kế**: Dev đã ngầm giả định "mỗi giảng viên chỉ có một khóa học", trong khi quan hệ thật giữa giảng viên và khóa học là **1 – nhiều**. Code đúng hay sai phụ thuộc vào dữ liệu tại thời điểm chạy, nên lỗi chỉ lộ ra khi dữ liệu thay đổi.

## 3. Lời giải

Đổi `=` thành `IN` để so sánh với một **tập hợp** giá:

```sql
SELECT title, price
FROM Courses
WHERE price IN (SELECT price FROM Courses WHERE instructor_id = 5)
ORDER BY price, title;
```

`price IN (a, b, c)` tương đương `price = a OR price = b OR price = c`, nên:

| Số khóa học của ông A | Kết quả |
|---|---|
| 0 | Rỗng, không lỗi |
| 1 | Giống hệt code cũ |
| 3 hay 100 | Lấy mọi khóa học có giá trùng với **bất kỳ** khóa nào của ông A |

`ORDER BY` được thêm vào để Kế toán dễ đối chiếu theo từng mức giá.

### Mở rộng: loại các khóa học của chính ông A

Kết quả trên bao gồm cả các khóa học của ông A, vì giá của chúng hiển nhiên trùng với chính nó. Nếu Kế toán chỉ cần các khóa học của **giảng viên khác**, thêm điều kiện:

```sql
SELECT title, price
FROM Courses
WHERE price IN (SELECT price FROM Courses WHERE instructor_id = 5)
  AND (instructor_id <> 5 OR instructor_id IS NULL)
ORDER BY price, title;
```

Vế `instructor_id IS NULL` giữ lại các khóa học chưa gán giảng viên, vì `NULL <> 5` cho kết quả UNKNOWN và sẽ bị loại nếu không xử lý.

## 4. Kết quả

Dữ liệu mẫu từ đề bài, cộng thêm 2 khóa học mới của ông A để tái hiện sự cố:

| title | price | instructor_id |
|---|---|---|
| ReactJS Cơ bản | 1.500.000 | 1 |
| NodeJS Thực chiến | 2.000.000 | 2 |
| Cấu trúc dữ liệu | 1.200.000 | 1 |
| Lập trình C++ căn bản | 1.200.000 | 5 |
| C++ Nâng cao | 1.800.000 | 3 |
| C++ Hướng đối tượng *(mới)* | 1.500.000 | 5 |
| Thuật toán phỏng vấn *(mới)* | 2.500.000 | 5 |

| Thời điểm | Code cũ (`=`) | Code đã sửa (`IN`) |
|---|---|---|
| Ông A có 1 khóa học | Cấu trúc dữ liệu, Lập trình C++ căn bản | Giống code cũ |
| Ông A có 3 khóa học | ❌ Lỗi *Subquery returns more than 1 row* | 5 khóa học, xem bảng dưới |

Kết quả của code đã sửa:

| title | price |
|---|---|
| Cấu trúc dữ liệu | 1.200.000 |
| Lập trình C++ căn bản | 1.200.000 |
| C++ Hướng đối tượng | 1.500.000 |
| ReactJS Cơ bản | 1.500.000 |
| Thuật toán phỏng vấn | 2.500.000 |

Kết quả phần mở rộng (chỉ giảng viên khác): **Cấu trúc dữ liệu** (1.200.000) và **ReactJS Cơ bản** (1.500.000).

## 5. Bài học rút ra

- `=`, `<`, `>` chỉ dùng với truy vấn con trả về **đúng 1 giá trị**. Truy vấn con có thể trả về nhiều dòng thì dùng `IN` (hoặc `EXISTS`).
- Đừng thiết kế code dựa trên dữ liệu **hiện tại**. Hãy dựa vào **quan hệ** giữa các bảng: giảng viên – khóa học là quan hệ 1 – nhiều.
- Kiểm thử với các trường hợp 0, 1 và nhiều kết quả để phát hiện lỗi trước khi dữ liệu thật thay đổi.
