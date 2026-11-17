# Kết hợp Truy vấn lồng (Subquery) và Hàm tổng hợp

Thực hành dùng truy vấn con chứa hàm tổng hợp `AVG` làm mức chuẩn để lọc dữ liệu: lọc từng học viên bằng `WHERE` và lọc từng lớp học bằng `HAVING`.

## 1. Đề bài

- **Mục tiêu:**
  - Dùng truy vấn con chứa hàm tổng hợp làm điều kiện lọc trong `WHERE`.
  - Kết hợp `HAVING` với truy vấn con để lọc các nhóm sau khi `GROUP BY`.
  - Nắm quy tắc: `WHERE` lọc bản ghi **trước** khi nhóm, `HAVING` lọc kết quả **sau** khi nhóm.
- **Dữ liệu:** bảng `students`:

| ID | Name | ClassId | Score |
|---|---|---|---|
| 1 | Nguyen Van A | A1 | 8 |
| 2 | Tran Thi B | A1 | 9 |
| 3 | Le Van C | A2 | 5 |
| 4 | Pham Thi D | A2 | 6 |
| 5 | Hoang Van E | A3 | 10 |

- **Yêu cầu:**
  - **Bước 1:** tìm học viên có điểm **lớn hơn điểm trung bình toàn trường**.
  - **Bước 2:** tìm lớp học có điểm trung bình **cao hơn 120%** điểm trung bình toàn trường.

## 2. Phân tích

Cả hai bước đều dùng chung một **mức chuẩn**: điểm trung bình toàn trường, tính bằng truy vấn con độc lập:

```sql
(SELECT AVG(Score) FROM students)   -- (8 + 9 + 5 + 6 + 10) / 5 = 7.6
```

Điểm khác nhau là **đối tượng được so sánh** với mức chuẩn:

| Bước | So sánh cái gì | Có sau GROUP BY không? | Mệnh đề |
|---|---|---|---|
| 1 | Điểm của **từng học viên** (`Score`) | Không, là cột thường | `WHERE` |
| 2 | Điểm trung bình của **từng lớp** (`AVG(Score)`) | Có, chỉ tồn tại sau khi gom nhóm | `HAVING` |

Thứ tự thực thi: **FROM → WHERE → GROUP BY → HAVING → SELECT**. Ở Bước 2, `AVG(Score)` của từng lớp chỉ có sau `GROUP BY`, nên điều kiện phải đặt ở `HAVING`. Đặt trong `WHERE` sẽ bị báo lỗi *Invalid use of group function*.

Lưu ý: `AVG(Score)` **trong truy vấn con** khác với `AVG(Score)` **ở truy vấn ngoài**. Truy vấn con có `FROM` riêng và không có `GROUP BY`, nên nó tính trung bình của **cả trường**. Truy vấn ngoài có `GROUP BY ClassId`, nên nó tính trung bình của **từng lớp**.

## 3. Lời giải

### Bước 1: Lọc bằng WHERE

```sql
SELECT ID, Name, ClassId, Score
FROM students
WHERE Score > (SELECT AVG(Score) FROM students)
ORDER BY Score DESC;
```

- Truy vấn con chạy **một lần**, trả về 7.6.
- Truy vấn ngoài trở thành `WHERE Score > 7.6` và xét **từng học viên** một cách độc lập.

| ID | Name | ClassId | Score |
|---|---|---|---|
| 5 | Hoang Van E | A3 | 10 |
| 2 | Tran Thi B | A1 | 9 |
| 1 | Nguyen Van A | A1 | 8 |

### Bước 2: Lọc bằng HAVING

```sql
SELECT ClassId, AVG(Score) AS AverageScore
FROM students
GROUP BY ClassId
HAVING AVG(Score) > (SELECT AVG(Score) FROM students) * 1.2;
```

- `GROUP BY ClassId` gom học viên theo lớp, rồi `AVG(Score)` tính điểm trung bình mỗi lớp.
- Truy vấn con trả về 7.6, nhân 1.2 được mức chuẩn **9.12**.
- `HAVING` chỉ giữ các lớp có điểm trung bình lớn hơn 9.12.

| ClassId | Điểm trung bình lớp | So với 9.12 | Kết quả |
|---|---|---|---|
| A1 | (8 + 9) / 2 = 8.5 | Nhỏ hơn | Loại |
| A2 | (5 + 6) / 2 = 5.5 | Nhỏ hơn | Loại |
| A3 | 10 / 1 = 10 | Lớn hơn | ✅ Giữ |

Kết quả:

| ClassId | AverageScore |
|---|---|
| A3 | 10 |

## 4. Kết quả

| Tiêu chí tự đánh giá | Kết quả |
|---|---|
| Truy vấn con Bước 1 nằm trong `WHERE`, lọc trên từng bản ghi | ✅ |
| Truy vấn con Bước 2 nằm trong `HAVING`, lọc trên trung bình từng lớp | ✅ |
| Trung bình toàn trường 7.6, mức chuẩn 120% là 9.12, chỉ còn lớp A3 | ✅ |

## 5. Bài học rút ra

- Truy vấn con chứa hàm tổng hợp là cách tạo một **mức chuẩn** (trung bình, lớn nhất…) để so sánh.
- So sánh **từng bản ghi** với mức chuẩn thì đặt ở `WHERE`. So sánh **kết quả của từng nhóm** với mức chuẩn thì đặt ở `HAVING`.
- Có thể tính toán trực tiếp trên kết quả truy vấn con, ví dụ `(SELECT AVG(Score) FROM students) * 1.2`.
- Truy vấn con độc lập chỉ chạy một lần, dù được so sánh với bao nhiêu dòng hoặc nhóm.
