-- =====================================================
-- Phân loại và xây dựng các dạng truy vấn lồng (Subquery)
-- =====================================================

-- 1. Tạo bảng
CREATE TABLE Departments (
    DeptId   INT PRIMARY KEY,
    DeptName VARCHAR(50) NOT NULL,
    Rating   VARCHAR(20)
);

CREATE TABLE Employees (
    EmpId    INT PRIMARY KEY,
    EmpName  VARCHAR(100) NOT NULL,
    Phone    VARCHAR(15),
    KpiScore INT,
    DeptId   INT,
    FOREIGN KEY (DeptId) REFERENCES Departments(DeptId)
);

-- 2. Dữ liệu mẫu
INSERT INTO Departments (DeptId, DeptName, Rating) VALUES
    (1, 'Sales', 'Excellent'),
    (2, 'HR',    'Good');

INSERT INTO Employees (EmpId, EmpName, Phone, KpiScore, DeptId) VALUES
    (101, 'Nguyễn Văn Tuấn', '0901112233', 85, 1),
    (102, 'Trần Mai Phương', '0912223344', 92, 1),
    (103, 'Lê Hoàng Phúc',   '0923334455', 75, 2),
    (104, 'Phạm Hải Yến',    '0934445566', 88, 2);

-- Bước 1: Scalar Subquery - KPI cao hơn mức trung bình toàn bộ nhân viên (85)
SELECT EmpName, KpiScore
FROM Employees
WHERE KpiScore > (SELECT AVG(KpiScore) FROM Employees)
ORDER BY EmpId;

-- Bước 2: Column Subquery - nhân viên thuộc phòng ban đạt đánh giá 'Excellent'
SELECT *
FROM Employees
WHERE DeptId IN (SELECT DeptId FROM Departments WHERE Rating = 'Excellent')
ORDER BY EmpId;

-- Bước 3: Table Subquery - bảng tạm chỉ gồm EmpName và Phone
SELECT EmployeeContacts.EmpName, EmployeeContacts.Phone
FROM (
    SELECT EmpName, Phone
    FROM Employees
) AS EmployeeContacts;
