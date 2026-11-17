-- =====================================================
-- Báo cáo "Biến mất" của phòng Đào tạo
-- =====================================================

-- 1. Tạo bảng
CREATE TABLE Students (
    id        INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    email     VARCHAR(100)
);

CREATE TABLE Payments (
    id           INT PRIMARY KEY AUTO_INCREMENT,
    student_id   INT,
    amount       DECIMAL(12, 2) NOT NULL,
    payment_date DATE,
    FOREIGN KEY (student_id) REFERENCES Students(id)
);

-- 2. Dữ liệu mẫu
INSERT INTO Students (id, full_name) VALUES
    (1, 'Nguyễn Văn A'),
    (2, 'Nguyễn Văn B'),
    (3, 'Trần Thị C'),
    (4, 'Phạm Văn D'),
    (5, 'Lê Hoàng Nam');

INSERT INTO Payments (student_id, amount, payment_date) VALUES
    (1, 10000000, '2026-01-10'),
    (1,  5000000, '2026-02-15'),
    (2, 12000000, '2026-01-12'),
    (3,  8000000, '2026-03-01'),
    (4,  5000000, '2026-03-05'),
    (5, 15000000, '2026-01-20');

-- 3. Index hỗ trợ gom nhóm theo học viên
CREATE INDEX idx_payments_student ON Payments (student_id, amount);

-- -----------------------------------------------------
-- 4. CODE LỖI CỦA DA (KHÔNG CHẠY)
-- ERROR 1248 (42000): Every derived table must have its own alias
-- -----------------------------------------------------
-- SELECT SUM(total_spent)
-- FROM (
--     SELECT student_id, SUM(amount) AS total_spent
--     FROM Payments
--     GROUP BY student_id
--     HAVING SUM(amount) > 10000000
-- );

-- -----------------------------------------------------
-- 5. CODE ĐÃ SỬA: đặt bí danh cho bảng tạm
-- -----------------------------------------------------
SELECT SUM(vip.total_spent) AS vip_revenue
FROM (
    SELECT student_id, SUM(amount) AS total_spent
    FROM Payments
    GROUP BY student_id
    HAVING SUM(amount) > 10000000
) AS vip;
-- Kết quả mong đợi: 42.000.000

-- -----------------------------------------------------
-- 6. KIỂM TRA: danh sách học viên VIP trong bảng tạm
-- -----------------------------------------------------
SELECT s.full_name, vip.total_spent
FROM (
    SELECT student_id, SUM(amount) AS total_spent
    FROM Payments
    GROUP BY student_id
    HAVING SUM(amount) > 10000000
) AS vip
JOIN Students s ON s.id = vip.student_id
ORDER BY vip.total_spent DESC, s.full_name;
-- Kết quả mong đợi:
--   Lê Hoàng Nam   15.000.000
--   Nguyễn Văn A   15.000.000
--   Nguyễn Văn B   12.000.000
