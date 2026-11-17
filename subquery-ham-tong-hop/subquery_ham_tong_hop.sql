-- =====================================================
-- Kết hợp truy vấn lồng (Subquery) và hàm tổng hợp
-- =====================================================

-- 1. Tạo bảng
CREATE TABLE students (
    ID      INT PRIMARY KEY,
    Name    VARCHAR(100) NOT NULL,
    ClassId VARCHAR(10) NOT NULL,
    Score   DECIMAL(4, 2) NOT NULL
);

-- 2. Dữ liệu mẫu
INSERT INTO students (ID, Name, ClassId, Score) VALUES
    (1, 'Nguyen Van A', 'A1', 8),
    (2, 'Tran Thi B',   'A1', 9),
    (3, 'Le Van C',     'A2', 5),
    (4, 'Pham Thi D',   'A2', 6),
    (5, 'Hoang Van E',  'A3', 10);

-- Bước 1: Lọc bằng WHERE - học viên có điểm cao hơn trung bình toàn trường (7.6)
SELECT ID, Name, ClassId, Score
FROM students
WHERE Score > (SELECT AVG(Score) FROM students)
ORDER BY Score DESC;
-- Kết quả mong đợi: Hoang Van E (10), Tran Thi B (9), Nguyen Van A (8)

-- Bước 2: Lọc bằng HAVING - lớp có điểm trung bình > 120% trung bình toàn trường (9.12)
SELECT ClassId, AVG(Score) AS AverageScore
FROM students
GROUP BY ClassId
HAVING AVG(Score) > (SELECT AVG(Score) FROM students) * 1.2;
-- Kết quả mong đợi: A3 10
