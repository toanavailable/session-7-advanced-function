-- =====================================================
-- Báo cáo "Độ Lệch Học Phí"
-- =====================================================

-- 1. Tạo bảng
CREATE TABLE Courses (
    id    INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

-- 2. Dữ liệu mẫu
INSERT INTO Courses (id, title, price) VALUES
    (1, 'Lập trình C++ Cơ bản',    1000000),
    (2, 'Nhập môn ReactJS',        1500000),
    (3, 'Làm chủ NodeJS',          2000000),
    (4, 'Python for Data Science', 1200000),
    (5, 'Fullstack Web với Java',  2500000);

-- -----------------------------------------------------
-- 3. CÁCH VIẾT SAI (KHÔNG DÙNG)
-- AVG gộp cả bảng thành 1 dòng -> mất chi tiết từng khóa học
-- MySQL 8.0 (ONLY_FULL_GROUP_BY) còn báo lỗi vì title, price không nằm trong GROUP BY
-- -----------------------------------------------------
-- SELECT title, price, price - AVG(price) AS Price_Difference
-- FROM Courses;

-- -----------------------------------------------------
-- 4. CÂU LỆNH HOÀN CHỈNH: Scalar Subquery trong SELECT
-- -----------------------------------------------------
SELECT title,
       price,
       ROUND(price - (SELECT AVG(price) FROM Courses), 0) AS Price_Difference
FROM Courses
ORDER BY Price_Difference DESC;

-- Giá trung bình toàn sàn = 1.640.000
-- Kết quả mong đợi:
--   Fullstack Web với Java   2500000   +860000
--   Làm chủ NodeJS           2000000   +360000
--   Nhập môn ReactJS         1500000   -140000
--   Python for Data Science  1200000   -440000
--   Lập trình C++ Cơ bản     1000000   -640000

-- -----------------------------------------------------
-- 5. MỞ RỘNG: hiển thị thêm giá trung bình để đối chiếu
-- -----------------------------------------------------
SELECT title,
       price,
       ROUND((SELECT AVG(price) FROM Courses), 0)         AS Avg_Price,
       ROUND(price - (SELECT AVG(price) FROM Courses), 0) AS Price_Difference
FROM Courses
ORDER BY Price_Difference DESC;
