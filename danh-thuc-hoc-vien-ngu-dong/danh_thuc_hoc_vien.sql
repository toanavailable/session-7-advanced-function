-- =====================================================
-- Chiến dịch "Đánh thức Học viên Ngủ đông"
-- =====================================================

-- 1. Tạo bảng
CREATE TABLE Students (
    id        INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100) NOT NULL,
    email     VARCHAR(100) NOT NULL
);

CREATE TABLE Support_Tickets (
    id         INT PRIMARY KEY AUTO_INCREMENT,
    content    TEXT NOT NULL,
    student_id INT,                         -- NULL nếu là khách vãng lai
    FOREIGN KEY (student_id) REFERENCES Students(id)
);

-- 2. Dữ liệu mẫu
INSERT INTO Students (id, full_name, email) VALUES
    (1, 'Nguyễn Minh Anh', 'minhanh.nguyen@email.com'),
    (2, 'Trần Hoàng Bách', 'bach.tran@email.com'),
    (3, 'Lê Ngọc Diệp',    'diep.le@email.com'),
    (4, 'Phạm Quốc Bảo',   'bao.pham@email.com'),
    (5, 'Vũ Hải Đăng',     'dang.vu@email.com');

INSERT INTO Support_Tickets (content, student_id) VALUES
    ('Lỗi không đăng nhập được vào hệ thống',         1),
    ('Quên mật khẩu, nhờ hỗ trợ lấy lại',             NULL),   -- khách vãng lai
    ('Hỏi về lộ trình học Fullstack chuyên nghiệp',   NULL),   -- khách vãng lai
    ('Video bài giảng số 5 bị mất tiếng',             2),
    ('Thanh toán học phí nhưng chưa được kích hoạt',  4);

-- -----------------------------------------------------
-- 3. CODE LỖI CỦA DEV JUNIOR
-- Truy vấn con trả về (1, NULL, NULL, 2, 4) -> NOT IN luôn ra UNKNOWN
-- Kết quả: rỗng
-- -----------------------------------------------------
SELECT email, full_name
FROM Students
WHERE id NOT IN (SELECT student_id FROM Support_Tickets);

-- -----------------------------------------------------
-- 4. CODE ĐÃ SỬA: loại NULL ngay trong truy vấn con
-- -----------------------------------------------------
SELECT email, full_name
FROM Students
WHERE id NOT IN (
    SELECT student_id
    FROM Support_Tickets
    WHERE student_id IS NOT NULL
)
ORDER BY id;
-- Kết quả mong đợi:
--   diep.le@email.com  Lê Ngọc Diệp
--   dang.vu@email.com  Vũ Hải Đăng

-- -----------------------------------------------------
-- 5. CÁCH VIẾT THAY THẾ: NOT EXISTS (an toàn với NULL)
-- -----------------------------------------------------
SELECT s.email, s.full_name
FROM Students s
WHERE NOT EXISTS (
    SELECT 1
    FROM Support_Tickets t
    WHERE t.student_id = s.id
)
ORDER BY s.id;
