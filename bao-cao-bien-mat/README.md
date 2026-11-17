# Báo cáo "Biến mất" của phòng Đào tạo

Phân tích lỗi *Every derived table must have its own alias* khi đặt truy vấn con trong mệnh đề `FROM`, và sửa lại câu lệnh để tính tổng doanh thu từ học viên VIP.

## 1. Đề bài

- **Nghiệp vụ:** Phòng Đào tạo cần tính **tổng số tiền** hệ thống thu được từ **học viên VIP**, tức những người có tổng chi tiêu cá nhân lớn hơn 10.000.000đ.
- **Câu lệnh của Data Analyst:**

```sql
SELECT SUM(total_spent)
FROM (
    SELECT student_id, SUM(amount) AS total_spent
    FROM Payments
    GROUP BY student_id
    HAVING SUM(amount) > 10000000
);
```

- **Nỗi đau:** logic hoàn toàn đúng, nhưng MySQL báo lỗi cú pháp *Every derived table must have its own alias*.

## 2. Phân tích

### Logic của câu lệnh

Câu lệnh gồm 2 lớp, chạy từ trong ra ngoài:

1. **Lớp trong:** gom các khoản thanh toán theo từng học viên, tính `total_spent`, rồi dùng `HAVING` giữ lại các học viên có tổng chi tiêu trên 10 triệu.
2. **Lớp ngoài:** cộng `total_spent` của các học viên VIP đó lại thành một con số.

Logic này đúng. Lỗi chỉ nằm ở **cú pháp**: bảng tạm thiếu tên.

### Vì sao bảng tạm bắt buộc phải có bí danh?

Khi truy vấn con nằm trong `FROM`, kết quả của nó được Database coi là một **bảng tạm (derived table)**. Bảng này chỉ tồn tại trong lúc câu lệnh chạy, **không có tên** trong cơ sở dữ liệu như các bảng thật (`Payments`, `Students`). Trong khi đó, mệnh đề `FROM` được thiết kế để làm việc với **các bảng có tên**:

- **Để tham chiếu:** truy vấn ngoài cần một cái tên để chỉ ra cột thuộc bảng nào, ví dụ `vip.total_spent`. Không có tên thì không có cách gọi bảng tạm.
- **Để phân biệt:** một câu lệnh có thể chứa nhiều bảng tạm, hoặc JOIN bảng tạm với bảng thật có cột trùng tên (ví dụ `student_id`). Tên là thứ giúp Database biết cột nào của bảng nào.
- **Theo chuẩn SQL:** mỗi phần tử trong `FROM` phải có một tên định danh. Bảng thật dùng tên của chính nó, còn bảng tạm thì người viết phải tự đặt bằng `AS`.

Vì vậy MySQL từ chối ngay ở bước phân tích cú pháp, trước khi chạy bất kỳ phép tính nào:

```
ERROR 1248 (42000): Every derived table must have its own alias
```

## 3. Lời giải

Đặt bí danh `vip` cho bảng tạm và tham chiếu cột qua bí danh đó:

```sql
SELECT SUM(vip.total_spent) AS vip_revenue
FROM (
    SELECT student_id, SUM(amount) AS total_spent
    FROM Payments
    GROUP BY student_id
    HAVING SUM(amount) > 10000000
) AS vip;
```

- `AS vip`: đặt tên cho bảng tạm. Từ khóa `AS` có thể bỏ, nhưng nên giữ để câu lệnh dễ đọc.
- `vip.total_spent`: tham chiếu rõ cột thuộc bảng tạm nào.
- `AS vip_revenue`: đặt tên cho cột kết quả để báo cáo dễ hiểu.
- Bí danh nên **rõ nghĩa** (`vip`, `vip_students`) thay vì các tên như `t`, `x`, để người đọc biết bảng tạm chứa gì.

Nhờ có bí danh, bảng tạm còn có thể JOIN với bảng khác. Ví dụ, lấy danh sách học viên VIP để kiểm tra lại con số:

```sql
SELECT s.full_name, vip.total_spent
FROM (
    SELECT student_id, SUM(amount) AS total_spent
    FROM Payments
    GROUP BY student_id
    HAVING SUM(amount) > 10000000
) AS vip
JOIN Students s ON s.id = vip.student_id
ORDER BY vip.total_spent DESC, s.full_name;
```

## 4. Kết quả

Tổng chi tiêu của từng học viên theo dữ liệu mẫu:

| student_id | full_name | Các khoản thanh toán | total_spent | VIP (> 10 triệu) |
|---|---|---|---|---|
| 1 | Nguyễn Văn A | 10.000.000 + 5.000.000 | 15.000.000 | ✅ |
| 2 | Nguyễn Văn B | 12.000.000 | 12.000.000 | ✅ |
| 3 | Trần Thị C | 8.000.000 | 8.000.000 | ❌ |
| 4 | Phạm Văn D | 5.000.000 | 5.000.000 | ❌ |
| 5 | Lê Hoàng Nam | 15.000.000 | 15.000.000 | ✅ |

Nguyễn Văn A có từng khoản thanh toán không vượt quá 10 triệu, nhưng **tổng** vượt 10 triệu nên vẫn là VIP. Đây là lý do phải gom nhóm rồi mới lọc bằng `HAVING`.

Kết quả của câu lệnh đã sửa:

| vip_revenue |
|---|
| 42.000.000 |

Kiểm tra lại: 15.000.000 + 12.000.000 + 15.000.000 = 42.000.000.

## 5. Bài học rút ra

- Truy vấn con trong `FROM` tạo ra một **bảng tạm không có tên**, và MySQL bắt buộc phải đặt bí danh cho nó.
- Bí danh giúp truy vấn ngoài **tham chiếu** và **phân biệt** các cột của bảng tạm, đặc biệt khi JOIN với bảng khác.
- Đặt bí danh **rõ nghĩa** để câu lệnh nhiều lớp dễ đọc và dễ bảo trì.
- Câu lệnh "đúng logic" vẫn có thể sai cú pháp. Hãy chạy thử từng lớp, từ trong ra ngoài, để tách lỗi logic khỏi lỗi cú pháp.
