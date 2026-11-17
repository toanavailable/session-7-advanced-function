# Khắc phục lỗi và Tối ưu hóa Truy vấn lồng (Subquery)

Thực hành xử lý giá trị `NULL` bằng `IS NOT NULL`, sửa lỗi thiếu bí danh cho bảng tạm, kiểm thử độc lập truy vấn con, và chuyển truy vấn lồng sang `INNER JOIN` để tối ưu.

## 1. Đề bài

- **Mục tiêu:** xử lý `NULL` trước khi tính toán; sửa lỗi thiếu alias cho bảng trung gian; kiểm thử từng truy vấn con; chuyển truy vấn lồng sang `JOIN`.
- **Dữ liệu:** cột `customer_id` của bảng `orders` có thể là `NULL` với đơn hàng vãng lai.

| id | name |
|---|---|
| 1 | Nguyen Van Minh |
| 2 | Tran Thi Ha |

| id | total_amount | customer_id |
|---|---|---|
| 101 | 500 | 1 |
| 102 | 300 | 1 |
| 103 | 200 | NULL |

Đề bài viết tên cột theo hai kiểu (`CustomerId` trong bảng dữ liệu, `customer_id` / `total_amount` trong đoạn code lỗi). Lời giải thống nhất dùng kiểu **snake_case** theo đoạn code lỗi, để câu lệnh ở Bước 2 khớp với đề.

## 2. Phân tích

| Bước | Vấn đề | Cách xử lý |
|---|---|---|
| 1 | Đơn vãng lai có `customer_id` là `NULL`. Nếu đưa vào truy vấn con dùng với `NOT IN`, kết quả sẽ rỗng; nếu tính toán theo khách hàng, sẽ xuất hiện một nhóm "khách NULL" vô nghĩa | Lọc bằng `WHERE customer_id IS NOT NULL`. Phải dùng `IS NOT NULL`, vì `<> NULL` luôn cho kết quả UNKNOWN |
| 2 | Truy vấn con trong `FROM` tạo ra bảng tạm **không có tên** | Đặt bí danh bằng `AS`. Đặt thêm tên cho cột `SUM(...)` để truy vấn ngoài dễ tham chiếu |
| 3 | Truy vấn lồng (nhất là truy vấn tương quan) có thể chạy lại nhiều lần và khó đọc | Dùng `INNER JOIN` nối hai bảng qua khóa ngoại |

## 3. Lời giải

### Bước 1: Xử lý NULL và test độc lập

```sql
SELECT DISTINCT customer_id
FROM orders
WHERE customer_id IS NOT NULL;
```

- `IS NOT NULL` loại đơn hàng vãng lai 103.
- `DISTINCT` gộp các giá trị trùng: khách 1 có 2 đơn hàng, nhưng chỉ cần xuất hiện một lần trong danh sách. Bỏ `DISTINCT` thì kết quả là `1, 1`, vẫn đúng logic nhưng lặp lại.

| customer_id |
|---|
| 1 |

### Bước 2: Sửa lỗi thiếu alias

Code lỗi:

```sql
SELECT * FROM (SELECT customer_id, SUM(total_amount) FROM orders WHERE customer_id IS NOT NULL GROUP BY customer_id);
```

MySQL báo `ERROR 1248: Every derived table must have its own alias`, vì truy vấn con trong `FROM` tạo ra một bảng tạm không có tên, và truy vấn ngoài không có cách nào tham chiếu tới nó.

Code đã sửa:

```sql
SELECT *
FROM (
    SELECT customer_id, SUM(total_amount) AS total_spent
    FROM orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
) AS customer_totals;
```

- `AS customer_totals`: bí danh có ý nghĩa cho bảng tạm.
- `AS total_spent`: đặt tên cho cột tổng, thay vì để tên mặc định khó dùng là `SUM(total_amount)`.

| customer_id | total_spent |
|---|---|
| 1 | 800 |

### Bước 3: Tối ưu bằng INNER JOIN

Nếu dùng truy vấn lồng, cách viết sẽ phải có một truy vấn con tương quan để lấy tên cho **từng đơn hàng**:

```sql
SELECT (SELECT c.name FROM customers c WHERE c.id = o.customer_id) AS name,
       o.total_amount
FROM orders o
WHERE o.customer_id IN (SELECT id FROM customers);
```

Truy vấn con lấy tên chạy lại cho từng đơn hàng, và câu lệnh khó đọc. Viết lại bằng `INNER JOIN`:

```sql
SELECT c.name AS Name, o.total_amount AS TotalAmount
FROM customers AS c
INNER JOIN orders AS o ON o.customer_id = c.id
ORDER BY o.id;
```

- `INNER JOIN` chỉ giữ các cặp khớp ở cả hai bảng. Đơn 103 có `customer_id` là `NULL`, phép so sánh `NULL = c.id` cho kết quả UNKNOWN, nên đơn này **tự động bị loại** mà không cần thêm điều kiện.
- Khách Tran Thi Ha chưa có đơn hàng nào nên cũng không xuất hiện.
- MySQL có thể dùng Index trên khóa chính và khóa ngoại để nối hai bảng một lần, thay vì chạy truy vấn con lặp lại.

| Name | TotalAmount |
|---|---|
| Nguyen Van Minh | 500 |
| Nguyen Van Minh | 300 |

## 4. Kết quả

| Tiêu chí tự đánh giá | Kết quả |
|---|---|
| Bước 1 chỉ trả về `customer_id` là 1, đơn 103 có NULL bị loại | ✅ |
| Bước 2 chạy thành công, tạo được bảng tạm có bí danh | ✅ |
| Bước 3 khớp Output mong đợi | ✅ |

## 5. Bài học rút ra

- Kiểm tra `NULL` bằng `IS NOT NULL`, và loại `NULL` trước khi đưa dữ liệu vào truy vấn con hoặc phép tính.
- Bảng tạm trong `FROM` luôn cần bí danh. Đặt luôn tên cho các cột tính toán.
- Chạy thử từng truy vấn con riêng lẻ trước khi ghép vào câu lệnh lớn.
- Khi cần lấy dữ liệu từ nhiều bảng, ưu tiên `JOIN` thay vì truy vấn lồng: gọn hơn, dễ đọc hơn và thường nhanh hơn.
