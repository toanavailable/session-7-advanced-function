-- =====================================================
-- Xây dựng và tối ưu hóa truy vấn lồng nhiều cấp
-- =====================================================

-- 1. Tạo bảng
CREATE TABLE Regions (
    ID         INT PRIMARY KEY,
    RegionName VARCHAR(50) NOT NULL
);

CREATE TABLE Stores (
    ID        INT PRIMARY KEY,
    StoreName VARCHAR(100) NOT NULL,
    RegionId  INT,
    FOREIGN KEY (RegionId) REFERENCES Regions(ID)
);

CREATE TABLE Staffs (
    ID      INT PRIMARY KEY,
    Name    VARCHAR(100) NOT NULL,
    StoreId INT,
    FOREIGN KEY (StoreId) REFERENCES Stores(ID)
);

-- 2. Dữ liệu mẫu
INSERT INTO Regions (ID, RegionName) VALUES
    (1, 'Miền Bắc'),
    (2, 'Miền Nam');

INSERT INTO Stores (ID, StoreName, RegionId) VALUES
    (101, 'CH Hà Nội', 1),
    (102, 'CH HCM',    2);

INSERT INTO Staffs (ID, Name, StoreId) VALUES
    (1001, 'Nguyen Van A', 101),
    (1002, 'Tran Thi B',   101),
    (1003, 'Le Van C',     102);

-- Bước 1 - Test truy vấn trong cùng (Cấp 3): ID khu vực Miền Bắc
SELECT r.ID
FROM Regions AS r
WHERE r.RegionName = 'Miền Bắc';
-- Kết quả: 1

-- Bước 2 - Test truy vấn trung gian (Cấp 2): ID cửa hàng thuộc Miền Bắc
SELECT st.ID
FROM Stores AS st
WHERE st.RegionId IN (
    SELECT r.ID
    FROM Regions AS r
    WHERE r.RegionName = 'Miền Bắc'
);
-- Kết quả: 101

-- Bước 3 - Hoàn thiện 3 cấp (Cấp 1): nhân viên làm việc tại Miền Bắc
SELECT sf.Name
FROM Staffs AS sf
WHERE sf.StoreId IN (
    SELECT st.ID
    FROM Stores AS st
    WHERE st.RegionId IN (
        SELECT r.ID
        FROM Regions AS r
        WHERE r.RegionName = 'Miền Bắc'
    )
)
ORDER BY sf.ID;
-- Kết quả mong đợi: Nguyen Van A, Tran Thi B

-- Tối ưu hóa: viết lại bằng JOIN, cho cùng kết quả
SELECT sf.Name
FROM Staffs AS sf
JOIN Stores  AS st ON st.ID = sf.StoreId
JOIN Regions AS r  ON r.ID  = st.RegionId
WHERE r.RegionName = 'Miền Bắc'
ORDER BY sf.ID;
