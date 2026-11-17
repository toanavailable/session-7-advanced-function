# Phân loại và Xây dựng các dạng Truy vấn lồng (Subquery)

Thực hành 3 dạng truy vấn lồng theo kết quả trả về: **Scalar Subquery** (một giá trị), **Column Subquery** (một cột) và **Table Subquery** (một bảng), trên hai bảng `Departments` và `Employees`.

## 1. Đề bài

- **Mục tiêu:**
  - Dùng Scalar Subquery với toán tử so sánh để lọc dữ liệu.
  - Dùng Column Subquery với toán tử `IN`.
  - Dùng Table Subquery làm bảng tạm trong mệnh đề `FROM`.
  - Hiểu bản chất truy vấn độc lập: truy vấn con chỉ chạy 1 lần rồi trả kết quả cho truy vấn ngoài.
- **Dữ liệu:**

| DeptId | DeptName | Rating |
|---|---|---|
| 1 | Sales | Excellent |
| 2 | HR | Good |

| EmpId | EmpName | Phone | KpiScore | DeptId |
|---|---|---|---|---|
| 101 | Nguyễn Văn Tuấn | 0901112233 | 85 | 1 |
| 102 | Trần Mai Phương | 0912223344 | 92 | 1 |
| 103 | Lê Hoàng Phúc | 0923334455 | 75 | 2 |
| 104 | Phạm Hải Yến | 0934445566 | 88 | 2 |

## 2. Phân tích

| Bước | Dạng truy vấn con | Kết quả trả về | Cách dùng ở truy vấn ngoài |
|---|---|---|---|
| 1 | Scalar Subquery | **Một giá trị** (KPI trung bình) | Toán tử so sánh `>` |
| 2 | Column Subquery | **Một cột**, có thể nhiều giá trị (các `DeptId`) | Toán tử `IN` |
| 3 | Table Subquery | **Một bảng** (nhiều dòng, nhiều cột) | Đặt sau `FROM`, bắt buộc có bí danh |

Cả 3 truy vấn con đều là **truy vấn độc lập**: không tham chiếu tới cột nào của truy vấn ngoài. Database chạy truy vấn con **đúng một lần**, rồi dùng kết quả đó cho toàn bộ truy vấn ngoài.

## 3. Lời giải

### Bước 1: Scalar Subquery

```sql
SELECT EmpName, KpiScore
FROM Employees
WHERE KpiScore > (SELECT AVG(KpiScore) FROM Employees)
ORDER BY EmpId;
```

- Truy vấn con tính KPI trung bình của toàn bộ nhân viên: (85 + 92 + 75 + 88) / 4 = **85**.
- Truy vấn ngoài trở thành `WHERE KpiScore > 85`. Nguyễn Văn Tuấn có KPI **đúng bằng** 85 nên không được lấy, vì điều kiện là **lớn hơn**.
- Dùng được `>` vì truy vấn con chắc chắn chỉ trả về **một giá trị**.

| EmpName | KpiScore |
|---|---|
| Trần Mai Phương | 92 |
| Phạm Hải Yến | 88 |

### Bước 2: Column Subquery

```sql
SELECT *
FROM Employees
WHERE DeptId IN (SELECT DeptId FROM Departments WHERE Rating = 'Excellent')
ORDER BY EmpId;
```

- Truy vấn con trả về **cột** `DeptId` của các phòng ban đạt "Excellent". Với dữ liệu mẫu, kết quả là `(1)`.
- Phải dùng `IN` thay vì `=`, vì sau này có thể có **nhiều** phòng ban cùng đạt "Excellent". Khi đó `=` sẽ báo lỗi *Subquery returns more than 1 row*, còn `IN` vẫn chạy đúng.

| EmpId | EmpName | Phone | KpiScore | DeptId |
|---|---|---|---|---|
| 101 | Nguyễn Văn Tuấn | 0901112233 | 85 | 1 |
| 102 | Trần Mai Phương | 0912223344 | 92 | 1 |

### Bước 3: Table Subquery

```sql
SELECT EmployeeContacts.EmpName, EmployeeContacts.Phone
FROM (
    SELECT EmpName, Phone
    FROM Employees
) AS EmployeeContacts;
```

- Truy vấn con trả về một **bảng tạm** gồm 2 cột `EmpName` và `Phone`.
- Bảng tạm **bắt buộc** phải có bí danh. Thiếu `AS EmployeeContacts`, MySQL báo lỗi *Every derived table must have its own alias*.
- Truy vấn ngoài tham chiếu các cột qua bí danh, ví dụ `EmployeeContacts.EmpName`. Bảng tạm chỉ có 2 cột, nên không thể lấy `KpiScore` hay `DeptId` từ nó.

| EmpName | Phone |
|---|---|
| Nguyễn Văn Tuấn | 0901112233 |
| Trần Mai Phương | 0912223344 |
| Lê Hoàng Phúc | 0923334455 |
| Phạm Hải Yến | 0934445566 |

## 4. Kết quả

| Tiêu chí tự đánh giá | Kết quả |
|---|---|
| Bước 1 dùng `>` với truy vấn con trả về 1 giá trị | ✅ |
| Bước 2 dùng `IN` với truy vấn con trả về 1 cột | ✅ |
| Bước 3 có bí danh `AS EmployeeContacts` cho bảng tạm | ✅ |
| Kết quả Bước 1 và Bước 2 khớp Output mong đợi | ✅ |

## 5. Bài học rút ra

- Chọn toán tử theo **kết quả trả về** của truy vấn con: một giá trị dùng `=`, `>`, `<`; một cột dùng `IN`; một bảng đặt trong `FROM`.
- Kể cả khi truy vấn con hiện chỉ trả về 1 dòng (như Bước 2), nếu về bản chất nó **có thể** trả về nhiều dòng thì vẫn phải dùng `IN`.
- Bảng tạm trong `FROM` luôn cần bí danh.
- Truy vấn con độc lập chỉ chạy một lần, nên hiệu năng tốt hơn nhiều so với truy vấn con tương quan.
