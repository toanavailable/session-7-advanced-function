-- =====================================================
-- Sửa lỗi Module "So sánh Học phí"
-- =====================================================

-- 1. Tạo bảng
CREATE TABLE Instructors (
    id        INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL
);

CREATE TABLE Courses (
    id            INT PRIMARY KEY AUTO_INCREMENT,
    title         VARCHAR(255) NOT NULL,
    price         DECIMAL(10, 2) NOT NULL,
    instructor_id INT,
    FOREIGN KEY (instructor_id) REFERENCES Instructors(id)
);

-- 2. Dữ liệu mẫu
INSERT INTO Instructors (id, full_name) VALUES
    (1, 'Nguyen Van B'),
    (2, 'Le Thi C'),
    (3, 'Nguyen Minh Anh'),
    (4, 'Phan Hoang Bach'),
    (5, 'Tran Van A');

INSERT INTO Courses (title, price, instructor_id) VALUES
    ('ReactJS Cơ bản',        1500000, 1),
    ('NodeJS Thực chiến',     2000000, 2),
    ('Cấu trúc dữ liệu',      1200000, 1),
    ('Lập trình C++ căn bản', 1200000, 5),
    ('C++ Nâng cao',          1800000, 3);

-- 3. Index hỗ trợ truy vấn con và so khớp giá
CREATE INDEX idx_courses_instructor ON Courses (instructor_id);
CREATE INDEX idx_courses_price      ON Courses (price);

-- -----------------------------------------------------
-- 4. "Ngày hôm qua": ông A chỉ có 1 khóa học -> code cũ vẫn chạy
-- -----------------------------------------------------
SELECT title, price
FROM Courses
WHERE price = (SELECT price FROM Courses WHERE instructor_id = 5);
-- Kết quả: Cấu trúc dữ liệu, Lập trình C++ căn bản (cùng 1.200.000)

-- -----------------------------------------------------
-- 5. "Hôm nay": ông A mở bán thêm 2 khóa học với giá khác nhau
-- -----------------------------------------------------
INSERT INTO Courses (title, price, instructor_id) VALUES
    ('C++ Hướng đối tượng',   1500000, 5),
    ('Thuật toán phỏng vấn',  2500000, 5);

-- Code cũ giờ báo lỗi (KHÔNG CHẠY):
-- ERROR 1242 (21000): Subquery returns more than 1 row
-- SELECT title, price
-- FROM Courses
-- WHERE price = (SELECT price FROM Courses WHERE instructor_id = 5);

-- -----------------------------------------------------
-- 6. CODE ĐÃ SỬA: dùng IN để so sánh với tập hợp giá
-- -----------------------------------------------------
SELECT title, price
FROM Courses
WHERE price IN (SELECT price FROM Courses WHERE instructor_id = 5)
ORDER BY price, title;

-- Kết quả mong đợi:
--   Cấu trúc dữ liệu        1.200.000
--   Lập trình C++ căn bản   1.200.000
--   C++ Hướng đối tượng     1.500.000
--   ReactJS Cơ bản          1.500.000
--   Thuật toán phỏng vấn    2.500.000

-- -----------------------------------------------------
-- 7. MỞ RỘNG: chỉ lấy khóa học của giảng viên KHÁC có giá trùng với ông A
-- -----------------------------------------------------
SELECT title, price
FROM Courses
WHERE price IN (SELECT price FROM Courses WHERE instructor_id = 5)
  AND (instructor_id <> 5 OR instructor_id IS NULL)
ORDER BY price, title;
-- Kết quả: Cấu trúc dữ liệu (1.200.000), ReactJS Cơ bản (1.500.000)
