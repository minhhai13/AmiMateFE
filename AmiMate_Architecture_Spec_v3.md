# 🤖 Đặc Tả Kiến Trúc Hệ Thống AmiMate (IoT Ecosystem)

Tài liệu này mô tả chi tiết kiến trúc bảo mật, luồng cấp phát thiết bị, Màn hình Front-end và **API Contract** cần thiết cho dự án AmiMate. 

---

## 📌 Lộ Trình Phát Triển (Phased Rollout)

* **Batch 1 (MVP - Giai đoạn hiện tại)**: Tập trung luồng cốt lõi: phụ huynh liên kết Robot bằng cách **nhập mã thủ công** (nhập Device ID và PIN) và **xem lại danh sách lịch sử hội thoại** của bé. Hệ thống xác thực tạm thời dùng **1 mã JWT duy nhất**.
* **Batch 2 (Nâng cấp trải nghiệm & Bảo mật)**: 
  * Nâng cấp hệ thống JWT thành cặp **Access Token & Refresh Token**.
  * Bổ sung tính năng **Quét mã QR** để tự động điền mã liên kết Robot (chức năng nhập tay vẫn giữ làm dự phòng).
* **Batch 3 (Triển khai đa nền tảng)**:
  * Triển khai ứng dụng cho iOS và Android.
  * Chuyển từ BE local sang một **Base URL production duy nhất** dùng chung cho cả iOS và Android.

### Môi trường phát triển MVP
* **Batch 1 chỉ chạy trên iOS Simulator** khi phát triển local.
* Base URL local của BE: `http://localhost:8080/api/v1`.
* Cấu hình Base URL nên được tách riêng để Batch 3 có thể đổi sang Base URL production dùng chung mà không sửa các API endpoint.

### Quyết định triển khai FE Batch 1
* State management: **Riverpod**; điều hướng: **GoRouter**.
* Splash chỉ kiểm tra trạng thái JWT rồi điều hướng đến Dashboard hoặc Login; không có onboarding giới thiệu riêng.
* Đăng ký thành công sẽ lưu JWT nhận được và mở Dashboard ngay.
* Ngôn ngữ giao diện: **tiếng Việt**.
* Thiết kế giao diện theo tông **xanh biển – trắng**.

---

## 1. Tổng Quan Hệ Thống
AmiMate là hệ sinh thái IoT gồm:
* **Robot (ESP32)**: Thu âm, phát giọng nói (Giao tiếp 1 chiều: ESP32 -> Server).
* **Server (Spring Boot / MS SQL Server)**: RESTful API, quản lý dữ liệu.
* **Parent App (Flutter)**: App quản lý dành cho phụ huynh.

**Kiến trúc Bảo mật**: 
* Parent App dùng **JWT (JSON Web Token)**.
* Robot dùng **API Key tĩnh** nạp cứng trong mạch.
* Liên kết thiết bị: **PIN Pairing** (Giống quy trình thêm camera thông minh).

---

## 2. Luồng Hoạt Động Chính (Lifecycle Thiết Bị)

### Giai đoạn 1: Khởi Tạo Tại Xưởng
1. Kỹ sư dùng Postman gọi API `/api/v1/devices/factory/generate` (Kèm Header `X-Factory-Secret`).
2. Server sinh ngẫu nhiên `deviceId`, `apiKey`, và `PIN` (6 số). Băm Hash SHA-256 đối với `apiKey` và `PIN` để lưu DB (`ownerId` = null).
3. Server trả dữ liệu gốc 1 lần duy nhất. Kỹ sư nạp `deviceId`, `apiKey` vào ESP32 và in `deviceId`, `PIN` lên vỏ hộp.

### Giai đoạn 2: Về Tay Phụ Huynh (PIN Pairing)
1. Khách hàng bóc hộp, tải App, tạo tài khoản và Đăng nhập (nhận JWT).
2. Khách hàng chọn **"Thêm thiết bị mới"**, nhập tay `deviceId` và `PIN` vào App.
3. App gọi API `/api/v1/devices/claim`. Server băm PIN nhập vào so với DB. Khớp -> cập nhật `ownerId`.

---

## 3. Yêu Cầu Frontend (Flutter App) - Dành cho AI Generator
Để phủ kín luồng nghiệp vụ Batch 1, yêu cầu tạo các màn hình sau:
1. **Splash & Onboarding**: Kiểm tra JWT trong `secure_storage`, điều hướng ra Home hoặc Login.
2. **Login / Register Screen**: Form nhập Email, Password. 
3. **Dashboard / My Devices Screen**: Hiển thị danh sách Robot đang sở hữu (Dạng Grid hoặc List). Có Floating Action Button để thêm Robot.
4. **Claim Device Screen (Thêm Robot)**: Form 2 ô nhập: `Device ID` và `Mã PIN (6 số)`. (Ghi chú cho AI: Chưa cần code quét QR ở Batch này).
5. **Chat History Screen**:
   * Màn hình đầu tiên hiển thị danh sách các cuộc hội thoại, mỗi mục đại diện một `chatId` (`sessionId`) và có thời điểm hoạt động gần nhất.
   * Phụ huynh chọn một cuộc hội thoại để mở màn chi tiết dạng chat, tin nhắn cũ ở phía trên và tin mới nhất ở cuối màn hình.
   * Khi mở chi tiết, hiển thị phần mới nhất trước; cuộn lên để tải và xem các tin nhắn cũ hơn theo trang.
6. **Settings Screen**: Nút Đăng xuất (xóa JWT).

---

## 4. API Contract Chi Tiết (Cho Frontend Flutter)

**Base URL:** `http://<SERVER_IP>:8080`
**Chuẩn báo lỗi (Problem Details):** Khi API thất bại (400, 401, 404, 409), Server trả về JSON dạng:
```json
{
  "type": "about:blank",
  "title": "Bad Request",
  "status": 400,
  "detail": "Dữ liệu không hợp lệ",
  "errors": { "pinCode": "Mã PIN phải gồm 6 ký tự" }
}
```

### 4.1. Nhóm Auth (Không cần Token)

**A. Đăng ký tài khoản**
* **Endpoint:** `POST /api/v1/auth/register`
* **Request Body:**
```json
{
  "email": "phuhuynh@example.com",
  "password": "matkhaumanh123"
}
```
* **Response (201 Created):**
```json
{
  "token": "eyJhbGciOi...",
  "expiresInSeconds": 86400
}
```

**B. Đăng nhập**
* **Endpoint:** `POST /api/v1/auth/login`
* **Request Body:** Giống Đăng ký
* **Response (200 OK):** Giống Đăng ký

### 4.2. Nhóm Parent App (Bắt buộc Header `Authorization: Bearer <JWT>`)

**A. Lấy danh sách Robot của tôi**
* **Endpoint:** `GET /api/v1/devices`
* **Response (200 OK):**
```json
[
  {
    "deviceId": "AMI-123456",
    "name": "AmiMate",
    "createdAt": "2026-10-13T09:00:00.000Z"
  }
]
```

**B. Liên kết Robot (Claim Device)**
* **Endpoint:** `POST /api/v1/devices/claim`
* **Request Body:**
```json
{
  "deviceId": "AMI-123456",
  "pinCode": "889900"
}
```
* **Response (200 OK):**
```json
{
  "deviceId": "AMI-123456",
  "name": "AmiMate",
  "createdAt": "2026-10-13T09:00:00.000Z"
}
```

**C. Xem lịch sử hội thoại (Có phân trang)**
* **Endpoint:** `GET /api/v1/logs?deviceId={deviceId}&page={page}&size={size}` (Mặc định page=0, size=50)
* **Response (200 OK):**
```json
{
  "items": [
    {
      "id": 1,
      "deviceId": "AMI-123456",
      "sessionId": "session_abc123",
      "clientMessageId": "AMI-123456-0001",
      "userMessage": "Hôm nay thời tiết thế nào?",
      "botResponse": "Hôm nay trời nắng nhẹ bé nhé.",
      "createdAt": "2026-10-13T09:30:00.123Z"
    }
  ],
  "page": 0,
  "size": 50,
  "totalElements": 1,
  "hasNext": false
}
```

**D. Đồng bộ lịch sử Xiaozhi (demo một robot)**
* **Endpoint:** `POST /api/v1/logs/sync-xiaozhi?deviceId={deviceId}`
* **Headers:** `Authorization: Bearer <JWT người dùng>`
* BE xác minh quyền sở hữu `deviceId`, đọc token Xiaozhi từ `XIAOZHI_BEARER_TOKEN` ở môi trường BE, lấy toàn bộ trang chat/message của agent cấu hình `XIAOZHI_AGENT_ID` (mặc định `2496934`) và nhập các cặp user/assistant vào `chat_log`.
* Lần đồng bộ sau bỏ qua bản ghi đã nhập theo ID ổn định, không tạo duplicate.
* **Response (200 OK):**
```json
{
  "deviceId": "AMI-123456",
  "chatsFetched": 18,
  "messagesFetched": 144,
  "logsImported": 72,
  "logsSkipped": 0
}
```
* Đây là luồng tạm phục vụ demo; token Xiaozhi không được đặt trong FE hoặc commit vào repository.

### 4.3. Nhóm Robot ESP32 (Không dùng JWT, dùng Header `X-Device-Key`)

**A. Gửi Log hội thoại lên Server**
* **Endpoint:** `POST /api/v1/logs`
* **Headers:** `X-Device-Key: amk_XYZ123...`
* **Request Body:**
```json
{
  "clientMessageId": "AMI-123456-0001",
  "sessionId": "session_abc123",
  "userMessage": "Hôm nay thời tiết thế nào?",
  "botResponse": "Hôm nay trời nắng nhẹ bé nhé."
}
```
* **Response (201 Created / 200 OK):** Trả về bản ghi chat vừa tạo giống mảng `items` ở mục 4.2.C.
