# Xây dựng và Tối ưu hóa Truy vấn lồng nhiều cấp

Xây dựng truy vấn lồng 3 cấp theo nguyên tắc **"từ trong ra ngoài"**, kiểm thử độc lập từng truy vấn con, và trình bày code sạch với thụt lề và bí danh rõ ràng, để tìm nhân viên làm việc tại khu vực "Miền Bắc".

## 1. Đề bài

- **Mục tiêu:** xây dựng truy vấn lồng 3 cấp, kiểm thử từng truy vấn con, chỉnh hàng dấu ngoặc và đặt bí danh có ý nghĩa.
- **Dữ liệu:** 3 bảng liên kết theo chuỗi **Khu vực → Cửa hàng → Nhân viên**:

| ID | RegionName |
|---|---|
| 1 | Miền Bắc |
| 2 | Miền Nam |

| ID | StoreName | RegionId |
|---|---|---|
| 101 | CH Hà Nội | 1 |
| 102 | CH HCM | 2 |

| ID | Name | StoreId |
|---|---|---|
| 1001 | Nguyen Van A | 101 |
| 1002 | Tran Thi B | 101 |
| 1003 | Le Van C | 102 |

- **Yêu cầu:** tìm các nhân viên làm việc tại khu vực "Miền Bắc".

## 2. Phân tích

Bảng `Staffs` không có thông tin khu vực, nên phải đi qua bảng `Stores` để nối tới `Regions`. Bài toán được chia thành 3 câu hỏi nhỏ, trả lời **từ trong ra ngoài**:

| Cấp | Câu hỏi | Bảng | Kết quả |
|---|---|---|---|
| 3 (trong cùng) | Miền Bắc có ID là gì? | `Regions` | `1` |
| 2 (trung gian) | Những cửa hàng nào thuộc khu vực đó? | `Stores` | `101` |
| 1 (ngoài cùng) | Những nhân viên nào làm ở các cửa hàng đó? | `Staffs` | Nguyen Van A, Tran Thi B |

Mỗi cấp được **chạy thử độc lập** trước khi lồng vào cấp tiếp theo. Nếu kết quả cuối sai, chỉ cần kiểm tra lại từng bước là biết lỗi nằm ở cấp nào.

Các cấp đều dùng `IN` thay vì `=`, vì một khu vực có thể có **nhiều** cửa hàng, và sau này có thể có nhiều khu vực trùng điều kiện.

## 3. Lời giải

### Bước 1: Test truy vấn trong cùng (Cấp 3)

```sql
SELECT r.ID
FROM Regions AS r
WHERE r.RegionName = 'Miền Bắc';
```

Kết quả: `1`.

### Bước 2: Test truy vấn trung gian (Cấp 2)

```sql
SELECT st.ID
FROM Stores AS st
WHERE st.RegionId IN (
    SELECT r.ID
    FROM Regions AS r
    WHERE r.RegionName = 'Miền Bắc'
);
```

Kết quả: `101`.

### Bước 3: Hoàn thiện 3 cấp (Cấp 1)

```sql
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
```

Quy tắc trình bày:

- **Thụt lề 4 khoảng trắng** cho mỗi cấp lồng, nhìn vào là biết truy vấn nào nằm trong truy vấn nào.
- **Ngoặc mở** đặt cuối dòng chứa `IN (`, **ngoặc đóng** đặt trên một dòng riêng, thẳng hàng với từ khóa `WHERE` của cấp chứa nó.
- **Bí danh có ý nghĩa:** `r` = Regions, `st` = Stores, `sf` = Staffs. Dùng `sf` cho Staffs để không trùng với `st` của Stores.

| Name |
|---|
| Nguyen Van A |
| Tran Thi B |

### Tối ưu hóa: viết lại bằng JOIN

Truy vấn lồng 3 cấp dễ hiểu theo từng bước, nhưng cùng bài toán có thể viết "phẳng" hơn bằng `JOIN`:

```sql
SELECT sf.Name
FROM Staffs AS sf
JOIN Stores  AS st ON st.ID = sf.StoreId
JOIN Regions AS r  ON r.ID  = st.RegionId
WHERE r.RegionName = 'Miền Bắc'
ORDER BY sf.ID;
```

Cách này cho cùng kết quả, ngắn gọn hơn, và giúp bộ tối ưu của MySQL dễ chọn thứ tự nối bảng và dùng Index. Khi số cấp lồng tăng lên quá 3–4 cấp, nên chuyển sang `JOIN`.

## 4. Kết quả

| Bước | Kết quả chạy thử |
|---|---|
| 1 – Cấp 3 | `1` |
| 2 – Cấp 2 | `101` |
| 3 – Cấp 1 | Nguyen Van A, Tran Thi B |
| Phiên bản JOIN | Nguyen Van A, Tran Thi B |

Chỉ nhân viên làm ở cửa hàng 101 (thuộc Miền Bắc) được hiển thị, khớp với Output mong đợi. Le Van C làm ở cửa hàng 102 (Miền Nam) nên bị loại.

## 5. Bài học rút ra

- Xây dựng truy vấn lồng **từ trong ra ngoài**, và **chạy thử từng cấp** trước khi lồng vào cấp tiếp theo.
- Dùng `IN` khi truy vấn con có thể trả về nhiều giá trị.
- Thụt lề và chỉnh hàng dấu ngoặc giúp code nhiều cấp dễ đọc và dễ tìm lỗi.
- Đặt bí danh ngắn nhưng **không trùng nhau** và gợi đúng tên bảng.
- Khi truy vấn lồng quá sâu, cân nhắc chuyển sang `JOIN`.
