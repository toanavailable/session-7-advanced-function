-- =====================================================
-- Khắc phục lỗi và tối ưu hóa truy vấn lồng (Subquery)
-- =====================================================

-- 1. Tạo bảng
CREATE TABLE customers (
    id   INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE orders (
    id           INT PRIMARY KEY,
    total_amount DECIMAL(12, 2) NOT NULL,
    customer_id  INT NULL,               -- NULL với đơn hàng vãng lai
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

-- 2. Dữ liệu mẫu
INSERT INTO customers (id, name) VALUES
    (1, 'Nguyen Van Minh'),
    (2, 'Tran Thi Ha');

INSERT INTO orders (id, total_amount, customer_id) VALUES
    (101, 500, 1),
    (102, 300, 1),
    (103, 200, NULL);                   -- đơn hàng vãng lai

-- Bước 1 - Xử lý NULL & test độc lập truy vấn con
SELECT DISTINCT customer_id
FROM orders
WHERE customer_id IS NOT NULL;
-- Kết quả: 1 (đơn 103 có customer_id NULL đã bị loại)

-- Bước 2 - Sửa lỗi thiếu alias cho bảng tạm
-- Code lỗi: ERROR 1248 Every derived table must have its own alias
-- SELECT * FROM (SELECT customer_id, SUM(total_amount) FROM orders
--                WHERE customer_id IS NOT NULL GROUP BY customer_id);
SELECT *
FROM (
    SELECT customer_id, SUM(total_amount) AS total_spent
    FROM orders
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
) AS customer_totals;
-- Kết quả: customer_id 1, total_spent 800

-- Bước 3 - Tối ưu hóa: dùng INNER JOIN thay cho truy vấn lồng
-- Cách viết bằng truy vấn lồng (để so sánh):
-- SELECT (SELECT c.name FROM customers c WHERE c.id = o.customer_id) AS name,
--        o.total_amount
-- FROM orders o
-- WHERE o.customer_id IN (SELECT id FROM customers);
SELECT c.name AS Name, o.total_amount AS TotalAmount
FROM customers AS c
INNER JOIN orders AS o ON o.customer_id = c.id
ORDER BY o.id;
-- Kết quả mong đợi:
--   Nguyen Van Minh  500
--   Nguyen Van Minh  300
