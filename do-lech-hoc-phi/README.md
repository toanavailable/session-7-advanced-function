# Báo cáo "Độ Lệch Học Phí"

Dùng **Scalar Subquery** đặt trong mệnh đề `SELECT` để vừa hiển thị chi tiết từng khóa học, vừa so sánh giá của nó với giá trung bình toàn sàn.

## 1. Đề bài

Giám đốc cần một danh sách gồm 3 cột:

| Cột | Ý nghĩa |
|---|---|
| `title` | Tên khóa học |
| `price` | Giá của khóa học |
| `Price_Difference` | Giá khóa học **trừ** giá trung bình của **toàn bộ** khóa học trên sàn |

**Thách thức:** nếu chỉ dùng `AVG()` thông thường, Database gộp toàn bộ khóa học thành **một dòng**, nên không thể in ra chi tiết từng khóa học.

## 2. Phân tích kỹ thuật

### Vì sao không dùng AVG() trực tiếp được?

```sql
SELECT title, price, price - AVG(price) AS Price_Difference
FROM Courses;
```

- `AVG()` là hàm tổng hợp: nó **gộp nhiều dòng thành một giá trị**. Khi có hàm tổng hợp mà không có `GROUP BY`, cả bảng được coi là một nhóm duy nhất, nên kết quả chỉ còn **1 dòng**.
- `title` và `price` lại là các cột có **nhiều giá trị khác nhau** trên từng dòng. Database không biết hiển thị tên khóa học nào trên dòng duy nhất đó. MySQL 8.0 (chế độ `ONLY_FULL_GROUP_BY`) báo lỗi ngay.
- Thêm `GROUP BY title, price` cũng không giải quyết được: mỗi nhóm chỉ còn 1 khóa học, nên `AVG(price)` thành giá của **chính khóa học đó**, và độ lệch luôn bằng 0.

Mâu thuẫn ở đây là: bài toán cần **chi tiết từng dòng** và **một con số tổng quan của cả bảng** cùng lúc.

### Bản chất của Scalar Subquery trong SELECT

**Scalar Subquery** là truy vấn con trả về **đúng 1 dòng, 1 cột**, tức một giá trị duy nhất:

```sql
(SELECT AVG(price) FROM Courses)   -- trả về 1640000
```

Khi đặt nó vào trong mệnh đề `SELECT`:

1. **Tách biệt phạm vi tính toán:** truy vấn con có mệnh đề `FROM` riêng, nên `AVG()` chỉ gộp dữ liệu **bên trong truy vấn con**. Truy vấn ngoài không có hàm tổng hợp nào, nên **không bị gộp dòng** và vẫn giữ nguyên từng khóa học.
2. **Hoạt động như một hằng số:** truy vấn con là **độc lập** (không tham chiếu cột của truy vấn ngoài), nên Database chỉ cần tính **một lần**. Kết quả 1.640.000 được dùng như một con số cố định trong biểu thức `price - 1640000` của mọi dòng.
3. **Ghép chi tiết với tổng quan:** mỗi dòng kết quả vừa có dữ liệu riêng của khóa học (`title`, `price`), vừa có giá trị chung của toàn sàn để so sánh.

Có thể hình dung truy vấn ngoài là danh sách từng khóa học, còn truy vấn con là một "tấm bảng" treo phía trên ghi giá trung bình toàn sàn. Mỗi dòng nhìn lên tấm bảng đó để tính độ lệch của mình.

Lưu ý: truy vấn con trong `SELECT` **bắt buộc** trả về một giá trị duy nhất. Nếu trả về nhiều dòng, MySQL báo lỗi *Subquery returns more than 1 row*.

## 3. Thực thi

```sql
SELECT title,
       price,
       ROUND(price - (SELECT AVG(price) FROM Courses), 0) AS Price_Difference
FROM Courses
ORDER BY Price_Difference DESC;
```

- `(SELECT AVG(price) FROM Courses)`: Scalar Subquery tính giá trung bình toàn sàn.
- `price - (...)`: độ lệch của từng khóa học. Dương là **đắt hơn** mức trung bình, âm là **rẻ hơn**.
- `ROUND(..., 0)`: làm tròn về đồng, vì `AVG` trên kiểu `DECIMAL` có thể sinh ra nhiều chữ số thập phân.
- `ORDER BY Price_Difference DESC`: khóa học đắt nhất so với mặt bằng chung lên đầu, giúp Giám đốc nhìn ra ngay các khóa cần xem lại giá.

### Mở rộng: hiển thị thêm giá trung bình để đối chiếu

```sql
SELECT title,
       price,
       ROUND((SELECT AVG(price) FROM Courses), 0)         AS Avg_Price,
       ROUND(price - (SELECT AVG(price) FROM Courses), 0) AS Price_Difference
FROM Courses
ORDER BY Price_Difference DESC;
```

## 4. Kết quả

Giá trung bình toàn sàn: (1.000.000 + 1.500.000 + 2.000.000 + 1.200.000 + 2.500.000) / 5 = **1.640.000**.

| title | price | Price_Difference |
|---|---|---|
| Fullstack Web với Java | 2.500.000 | +860.000 |
| Làm chủ NodeJS | 2.000.000 | +360.000 |
| Nhập môn ReactJS | 1.500.000 | −140.000 |
| Python for Data Science | 1.200.000 | −440.000 |
| Lập trình C++ Cơ bản | 1.000.000 | −640.000 |

Kiểm tra: tổng các độ lệch bằng 0 (860.000 + 360.000 − 140.000 − 440.000 − 640.000 = 0), đúng tính chất của độ lệch so với giá trị trung bình.

## 5. Bài học rút ra

- Hàm tổng hợp ở truy vấn ngoài sẽ **gộp dòng**. Muốn giữ chi tiết từng dòng mà vẫn có số liệu tổng quan, hãy đưa hàm tổng hợp vào **Scalar Subquery**.
- Scalar Subquery phải trả về **đúng một giá trị**, và nếu là truy vấn độc lập thì chỉ được tính **một lần**.
- Kiểm tra lại kết quả bằng một tính chất toán học đơn giản, ở đây là tổng độ lệch bằng 0.
