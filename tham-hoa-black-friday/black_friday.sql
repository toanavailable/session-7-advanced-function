-- =====================================================
-- Thảm họa "Black Friday"
-- =====================================================

-- 1. Tạo bảng
CREATE TABLE Courses (
    id    INT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

CREATE TABLE Enrollments (
    id              INT PRIMARY KEY AUTO_INCREMENT,
    student_id      INT NOT NULL,
    course_id       INT,                 -- bị bug API chèn NULL
    enrollment_date DATE
);

-- 2. Dữ liệu mẫu
INSERT INTO Courses (id, title, price) VALUES
    (1, 'Lập trình C++ Cơ bản',    1000000),
    (2, 'Nhập môn ReactJS',        1500000),
    (3, 'Làm chủ NodeJS',          2000000),
    (4, 'Python for Data Science', 1200000),
    (5, 'Fullstack Web với Java',  2500000);

INSERT INTO Enrollments (student_id, course_id, enrollment_date) VALUES
    (101, 1,    '2026-01-10'),
    (102, NULL, '2026-10-15'),   -- dữ liệu rác do bug API
    (103, NULL, '2026-10-15'),   -- dữ liệu rác do bug API
    (104, 3,    '2026-02-12'),
    (105, 5,    '2026-02-20');

-- 3. Index hỗ trợ tra cứu theo course_id
CREATE INDEX idx_enrollments_course ON Enrollments (course_id);

-- -----------------------------------------------------
-- 4. CODE LỖI: truy vấn con trả về (1, NULL, NULL, 3, 5)
-- => NOT IN luôn ra UNKNOWN hoặc FALSE => kết quả rỗng
-- -----------------------------------------------------
SELECT id, title, price
FROM Courses
WHERE id NOT IN (SELECT course_id FROM Enrollments);

-- -----------------------------------------------------
-- 5. GIẢI PHÁP 1: NOT IN + loại NULL trong truy vấn con
-- -----------------------------------------------------
SELECT id, title, price
FROM Courses
WHERE id NOT IN (
    SELECT course_id
    FROM Enrollments
    WHERE course_id IS NOT NULL
)
ORDER BY id;

-- -----------------------------------------------------
-- 6. GIẢI PHÁP 2 (KHUYÊN DÙNG): NOT EXISTS
-- -----------------------------------------------------
SELECT c.id, c.title, c.price
FROM Courses c
WHERE NOT EXISTS (
    SELECT 1
    FROM Enrollments e
    WHERE e.course_id = c.id
)
ORDER BY c.id;

-- -----------------------------------------------------
-- 7. GIẢI PHÁP 3: LEFT JOIN + IS NULL
-- -----------------------------------------------------
SELECT c.id, c.title, c.price
FROM Courses c
LEFT JOIN Enrollments e ON e.course_id = c.id
WHERE e.id IS NULL
ORDER BY c.id;

-- Kết quả mong đợi của cả 3 giải pháp:
--   2  Nhập môn ReactJS         1500000
--   4  Python for Data Science  1200000

-- -----------------------------------------------------
-- 8. XỬ LÝ TẬN GỐC (chạy sau khi đã đối soát với đội Backend)
-- Ngăn bug API chèn NULL và dữ liệu không hợp lệ trong tương lai
-- -----------------------------------------------------
-- DELETE FROM Enrollments WHERE course_id IS NULL;
-- ALTER TABLE Enrollments
--     MODIFY course_id INT NOT NULL,
--     ADD CONSTRAINT fk_enrollments_course
--         FOREIGN KEY (course_id) REFERENCES Courses(id);
