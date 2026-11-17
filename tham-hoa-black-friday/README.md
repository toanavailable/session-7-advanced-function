# Thảm họa "Black Friday"

Phân tích vì sao dữ liệu rác `NULL` trong bảng `Enrollments` khiến câu lệnh `NOT IN` trả về rỗng, khắc phục bằng 3 phương pháp khác nhau, và so sánh để chọn giải pháp tốt nhất.

## 1. Đề bài

- **Yêu cầu của Product Owner:** lấy danh sách các khóa học **chưa từng được ai đăng ký** (không tồn tại trong bảng `Enrollments`) để set giá 0 đồng dịp Black Friday.
- **Câu lệnh của lập trình viên:**

```sql
SELECT id, title, price
FROM Courses
WHERE id NOT IN (SELECT course_id FROM Enrollments);
```

- **Sự cố:** một bug ở luồng API thanh toán làm mất tham số mã khóa học trước khi `INSERT`, nên bảng `Enrollments` bị chèn một số dòng rác có `course_id` là `NULL`. Từ đó câu lệnh trên trả về danh sách rỗng.

## 2. Phân tích nguyên nhân

Với dữ liệu mẫu, truy vấn con trả về:

```
(1, NULL, NULL, 3, 5)
```

`NOT IN` là phủ định của chuỗi `OR`, theo luật De Morgan trở thành **chuỗi `AND`**:

```
id NOT IN (1, NULL, NULL, 3, 5)
⟺ id <> 1 AND id <> NULL AND id <> NULL AND id <> 3 AND id <> 5
```

SQL dùng **logic ba giá trị**: TRUE, FALSE và UNKNOWN. `NULL` nghĩa là "không xác định", nên `id <> NULL` luôn cho ra **UNKNOWN**: Database không thể khẳng định một khóa học có khác một giá trị không xác định hay không.

Bảng chân lý của phép `AND` khi có UNKNOWN:

| A | B | A AND B |
|---|---|---|
| TRUE | UNKNOWN | **UNKNOWN** |
| FALSE | UNKNOWN | **FALSE** |

Áp dụng cho từng khóa học:

| Khóa học | So với 1, 3, 5 | So với NULL | Kết quả |
|---|---|---|---|
| 2 – Nhập môn ReactJS (chưa ai đăng ký) | Tất cả TRUE | UNKNOWN | **UNKNOWN** |
| 1 – Lập trình C++ Cơ bản (đã có người đăng ký) | Có vế FALSE | UNKNOWN | **FALSE** |

Biểu thức **không bao giờ đạt TRUE**. Mệnh đề `WHERE` chỉ giữ dòng có điều kiện **TRUE**, nên loại bỏ **toàn bộ** khóa học, kể cả những khóa thật sự chưa ai đăng ký.

Chỉ cần **một** dòng rác `NULL` là cả báo cáo bị sai. Câu lệnh không báo lỗi gì, nên Product Owner sẽ tưởng rằng mọi khóa học đều đã có người đăng ký và chiến dịch xả kho bị bỏ lỡ.

## 3. Thực thi đa giải pháp

### Giải pháp 1: NOT IN + loại NULL trong truy vấn con

```sql
SELECT id, title, price
FROM Courses
WHERE id NOT IN (
    SELECT course_id
    FROM Enrollments
    WHERE course_id IS NOT NULL
)
ORDER BY id;
```

Truy vấn con chỉ còn `(1, 3, 5)`, nên mọi phép so sánh đều cho TRUE hoặc FALSE.

### Giải pháp 2: NOT EXISTS

```sql
SELECT c.id, c.title, c.price
FROM Courses c
WHERE NOT EXISTS (
    SELECT 1
    FROM Enrollments e
    WHERE e.course_id = c.id
)
ORDER BY c.id;
```

`EXISTS` chỉ trả về TRUE hoặc FALSE, không bao giờ UNKNOWN. Dòng có `course_id` là `NULL` không khớp với khóa học nào, nên không ảnh hưởng đến kết quả.

### Giải pháp 3: LEFT JOIN + IS NULL

```sql
SELECT c.id, c.title, c.price
FROM Courses c
LEFT JOIN Enrollments e ON e.course_id = c.id
WHERE e.id IS NULL
ORDER BY c.id;
```

`LEFT JOIN` giữ toàn bộ khóa học. Khóa học không có lượt đăng ký nào khớp sẽ có các cột của `Enrollments` là `NULL`. Kiểm tra `IS NULL` trên **khóa chính** `e.id` (không bao giờ `NULL` trong dữ liệu thật) để chắc chắn đó là dòng không khớp.

## 4. So sánh và đánh giá

| Tiêu chí | Giải pháp 1: NOT IN + IS NOT NULL | Giải pháp 2: NOT EXISTS | Giải pháp 3: LEFT JOIN + IS NULL |
|---|---|---|---|
| **An toàn với NULL** | ⚠️ Chỉ an toàn khi **nhớ** thêm `IS NOT NULL`. Quên một lần là lỗi quay lại | ✅ An toàn tự nhiên, không cần điều kiện phụ | ✅ An toàn tự nhiên |
| **Thể hiện ý nghĩa nghiệp vụ** | Trung bình: "không nằm trong danh sách" | ✅ Rõ nhất: "không tồn tại lượt đăng ký nào" | Gián tiếp: phải hiểu cơ chế điền NULL của LEFT JOIN |
| **Hiệu năng** (MySQL 8.0, có Index trên `Enrollments.course_id`) | Tốt | ✅ Tốt, được tối ưu thành anti-join, dừng ngay khi tìm thấy dòng khớp đầu tiên | Tốt, cũng được tối ưu thành anti-join |
| **Rủi ro khi bảo trì** | Cao: người sau có thể xóa điều kiện `IS NOT NULL` vì tưởng thừa | Thấp | Trung bình: nếu kiểm tra `IS NULL` sai cột (cột có thể NULL sẵn) sẽ ra kết quả sai |
| **Khi nào phù hợp** | Danh sách so sánh nhỏ, cột chắc chắn có ràng buộc `NOT NULL` | Mặc định cho bài toán "có ở A nhưng không có ở B" | Khi cần lấy thêm cột từ bảng bên phải trong cùng câu lệnh |

### Lựa chọn: Giải pháp 2 – NOT EXISTS

1. **An toàn tuyệt đối với NULL** mà không phụ thuộc vào trí nhớ của lập trình viên. Đây là điểm quan trọng nhất, vì sự cố lần này chính là do dữ liệu bẩn không lường trước.
2. **Đúng ý nghĩa nghiệp vụ:** câu lệnh đọc lên đúng như yêu cầu "khóa học không tồn tại lượt đăng ký nào".
3. **Hiệu năng tốt:** với Index trên `Enrollments.course_id`, mỗi khóa học chỉ cần tra Index và dừng ngay khi tìm thấy lượt đăng ký đầu tiên.

### Xử lý tận gốc

Sửa câu lệnh mới chỉ là chữa triệu chứng. Sau khi đối soát với đội Backend, nên:

```sql
DELETE FROM Enrollments WHERE course_id IS NULL;

ALTER TABLE Enrollments
    MODIFY course_id INT NOT NULL,
    ADD CONSTRAINT fk_enrollments_course
        FOREIGN KEY (course_id) REFERENCES Courses(id);
```

- `NOT NULL` khiến Database **từ chối** ngay lệnh `INSERT` thiếu mã khóa học, nên bug API sẽ bị phát hiện thay vì âm thầm chèn dữ liệu rác.
- Khóa ngoại đảm bảo `course_id` luôn trỏ tới một khóa học có thật. Bảng `Enrollments` hiện chưa có ràng buộc này.

## 5. Kết quả

| Khóa học | Lượt đăng ký hợp lệ | Code lỗi | Cả 3 giải pháp |
|---|---|---|---|
| 1 – Lập trình C++ Cơ bản | Học viên 101 | Không lấy | Không lấy |
| 2 – Nhập môn ReactJS | Không có | ❌ Bỏ sót | ✅ Lấy |
| 3 – Làm chủ NodeJS | Học viên 104 | Không lấy | Không lấy |
| 4 – Python for Data Science | Không có | ❌ Bỏ sót | ✅ Lấy |
| 5 – Fullstack Web với Java | Học viên 105 | Không lấy | Không lấy |

Danh sách khóa học xả kho Black Friday:

| id | title | price |
|---|---|---|
| 2 | Nhập môn ReactJS | 1.500.000 |
| 4 | Python for Data Science | 1.200.000 |

## 6. Bài học rút ra

- `NOT IN` với truy vấn con trên cột **có thể chứa NULL** là một cái bẫy: một giá trị `NULL` đủ làm kết quả rỗng.
- Nguyên nhân là **logic ba giá trị**: `x <> NULL` là UNKNOWN, và `TRUE AND UNKNOWN` vẫn là UNKNOWN.
- Ưu tiên **`NOT EXISTS`** cho bài toán "có ở bảng A nhưng không có ở bảng B".
- Ngăn dữ liệu rác **ngay từ thiết kế** bằng `NOT NULL` và khóa ngoại, đừng chỉ vá ở câu truy vấn.
