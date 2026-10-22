# Kế hoạch dựng Flutter FE theo từng phase

Tài liệu này chia việc dựng FE AmiMate thành các bước nhỏ, có thể hoàn thành và kiểm tra độc lập. Mỗi phase chỉ bắt đầu sau khi phase trước đạt tiêu chí nghiệm thu; không gộp nhiều phase trong một lượt để dễ kiểm soát thay đổi và tìm lỗi.

## Phạm vi và quyết định đã chốt

- Phạm vi hiện tại: **Batch 1 MVP**, chạy local trên **iOS Simulator**.
- Backend local: `http://localhost:8080`; API prefix: `/api/v1`.
- Tách cấu hình Base URL để Batch 3 có thể chuyển sang một URL production dùng chung cho iOS và Android.
- State management: **Riverpod**; điều hướng: **GoRouter**.
- Ngôn ngữ UI: **tiếng Việt**; màu chủ đạo: **xanh biển – trắng**.
- Splash chỉ kiểm tra phiên đăng nhập và điều hướng; không có onboarding giới thiệu.
- Đăng ký thành công: lưu JWT nhận được và mở Dashboard ngay.
- JWT hiện là một token duy nhất; lưu bằng `flutter_secure_storage`.
- Không làm QR, refresh token, chat realtime, quản lý hồ sơ hay gỡ thiết bị trong Batch 1.

## Nguyên tắc thực hiện

1. Mỗi phase chỉ thay đổi phần thuộc phạm vi đã ghi; không tự ý mở rộng tính năng.
2. Trước khi chuyển phase, chạy format, analyze và các test liên quan; sửa lỗi do phase hiện tại gây ra.
3. Mỗi màn hình phải có trạng thái loading, empty (nếu phù hợp), success và lỗi.
4. Không log JWT, mật khẩu hoặc PIN. Lỗi mạng/API phải được trình bày rõ ràng bằng tiếng Việt.
5. Dùng `createdAt` theo thời điểm UTC từ BE và định dạng sang giờ địa phương khi hiển thị.

---

## Phase 0 — Chốt nền tảng và chạy ứng dụng Flutter hiện trạng

**Trạng thái: Hoàn tất.**

**Mục tiêu:** xác nhận môi trường Flutter/iOS Simulator và điểm khởi chạy hiện tại trước khi dựng cấu trúc.

**Phạm vi:**
- Kiểm tra `pubspec.yaml`, `lib/main.dart`, cấu hình iOS và các test khởi tạo hiện có.
- Xác nhận phiên bản Flutter/Dart và iOS Simulator đang dùng.
- Chạy ứng dụng mẫu và kiểm tra `flutter analyze`/test hiện trạng.
- Chỉ ghi nhận lỗi baseline; chưa triển khai tính năng.

**Nghiệm thu:**
- Ứng dụng hiện trạng chạy được trên iOS Simulator hoặc có blocker cụ thể được ghi nhận.
- Có kết quả baseline cho analyze và test.
- Không thay đổi dependency hay code ứng dụng trong phase này nếu chưa cần thiết.

**Kết quả thực hiện:** Flutter 3.47.6/Dart 3.13.5; iPhone 17 Pro Max Simulator khả dụng. Baseline analyze sạch; test ban đầu không chạy do file test và `main.dart` trống. Ứng dụng đã được chạy thành công trên Simulator sau Phase 1.

## Phase 1 — Dựng app shell, theme và điều hướng khung

**Trạng thái: Hoàn tất.**

**Mục tiêu:** tạo bộ khung ứng dụng tối thiểu, chưa gọi API.

**Phạm vi:**
- Thêm `ProviderScope` và điểm khởi tạo ứng dụng; cân nhắc `app.dart` để giữ `main.dart` gọn.
- Tạo theme Material dùng xanh biển – trắng, typography, khoảng cách và style nút/ô nhập cơ bản.
- Cấu hình GoRouter với các route placeholder: Splash, Login, Register, Dashboard, Claim Device, Chat History, Settings.
- Tạo màn hình placeholder tiếng Việt để kiểm tra điều hướng.

**Nghiệm thu:**
- Ứng dụng khởi động ổn định trên iOS Simulator.
- Có thể đi qua các route placeholder, không lỗi khi back/forward.
- Theme thống nhất và không có endpoint/API logic trong UI.

**Kết quả thực hiện:** đã thêm ProviderScope, theme xanh biển – trắng, locale tiếng Việt, GoRouter và các màn hình placeholder. Có widget test cho điều hướng splash → đăng nhập và Dashboard → thêm thiết bị.

## Phase 2 — Cấu hình network, lưu trữ token và xử lý lỗi chung

**Trạng thái: Hoàn tất.**

**Mục tiêu:** cung cấp nền tảng dùng chung cho mọi API parent app.

**Phạm vi:**
- Chọn và cấu hình HTTP client (Dio), timeout và Base URL `http://localhost:8080/api/v1`.
- Tạo cấu hình môi trường tách biệt khỏi repository; endpoint chỉ ghép từ API prefix và path.
- Tạo `flutter_secure_storage` abstraction để đọc, ghi và xóa JWT.
- Thêm interceptor gửi `Authorization: Bearer <token>` khi có token.
- Chuẩn hóa Problem Details và lỗi mạng/status; với `401`, xóa phiên và chuyển về luồng đăng nhập theo một cơ chế tập trung.
- Chưa thêm refresh token; không gửi token cho endpoint auth.

**Nghiệm thu:**
- Có test cho tạo URL, gắn/không gắn Authorization, parse lỗi Problem Details và xóa token khi gặp 401.
- Không có JWT trong log hoặc thông báo lỗi.
- Base URL được quản lý tại một nơi duy nhất.

**Kết quả thực hiện:** đã thêm Dio với timeout 15 giây, cấu hình Base URL qua `AMIMATE_BASE_URL` (mặc định `http://localhost:8080/api/v1`), lưu JWT bằng `flutter_secure_storage`, interceptor gắn Bearer token và loại trừ endpoint login/register. Request bảo vệ trả 401 sẽ xóa token và đưa router về Login. Đã chuẩn hóa Problem Details/lỗi mạng thành `ApiFailure` và thêm 9 test cho cấu hình, parse lỗi, token và xử lý 401.

## Phase 3 — Splash, phiên đăng nhập và xác thực

**Trạng thái: Hoàn tất.**

**Mục tiêu:** hoàn thiện luồng khởi động, đăng nhập và đăng ký.

**Phạm vi:**
- Tạo model cho request/response auth theo BE: `email`, `password`, `token`, `expiresInSeconds`.
- Tạo auth repository và Riverpod controller/provider.
- Làm Login và Register bằng tiếng Việt, validation đầu vào và trạng thái loading/lỗi.
- Splash đọc token trong secure storage rồi điều hướng đến Dashboard hoặc Login.
- Đăng nhập thành công lưu token và vào Dashboard.
- Đăng ký thành công lưu token và vào Dashboard ngay.
- Thêm kiểm soát route để người chưa đăng nhập không vào được các màn hình yêu cầu JWT.

**Nghiệm thu:**
- Có test cho parse AuthResponse, controller thành công/thất bại và các nhánh điều hướng theo trạng thái token.
- Đăng ký/đăng nhập gửi đúng endpoint và body BE.
- Có thể đăng xuất/xóa phiên về mặt logic (UI Settings sẽ hoàn thiện ở Phase 7).

**Kết quả thực hiện:** đã thêm model/repository/controller cho auth; form đăng nhập/đăng ký tiếng Việt có validation, loading và lỗi API; Splash khôi phục phiên theo sự hiện diện của JWT; route yêu cầu đăng nhập được bảo vệ; đăng nhập/đăng ký lưu token và mở Dashboard. Controller có logic xóa token khi đăng xuất; UI Settings vẫn để Phase 7. Đã bổ sung test cho mapping request/response, controller, khôi phục phiên, route guard và các luồng UI auth.

## Phase 4 — Danh sách thiết bị và Dashboard

**Trạng thái: Hoàn tất.**

**Mục tiêu:** hiển thị robot thuộc tài khoản phụ huynh.

**Phạm vi:**
- Tạo `DeviceResponse` với `deviceId`, `name`, `createdAt`.
- Tạo device repository và controller/provider lấy `GET /devices`.
- Dựng Dashboard dạng danh sách/thẻ, nút thêm thiết bị và nút mở lịch sử của từng robot.
- Thiết kế loading, lỗi có thao tác tải lại, danh sách rỗng có hướng dẫn thêm robot.
- Làm mới danh sách sau khi claim thành công.

**Nghiệm thu:**
- Parse được danh sách rỗng và danh sách có dữ liệu theo response BE.
- Dashboard phân biệt đúng loading/empty/error/success.
- Chọn robot mở đúng màn hình lịch sử với `deviceId`.

**Kết quả thực hiện:** đã thêm model, repository và AsyncNotifier lấy mảng trực tiếp từ `GET /devices`; Dashboard hiển thị danh sách thẻ cùng thời gian local, trạng thái loading/empty/error và thao tác tải lại. Có nút thêm thiết bị, nút Settings và điều hướng từ robot đến lịch sử bằng đúng `deviceId`. Dashboard tải lại danh sách khi màn hình claim được đóng; phần submit claim và điều hướng sau claim thành công sẽ nối ở Phase 5. Đã thêm test cho parse response, mảng rỗng/có dữ liệu, lỗi và retry, điều hướng lịch sử.

## Phase 5 — Claim/liên kết thiết bị

**Trạng thái: Hoàn tất.**

**Mục tiêu:** hoàn thiện luồng nhập Device ID và PIN thủ công.

**Phạm vi:**
- Tạo request/response claim theo BE: request gồm `deviceId`, `pinCode`; response là `DeviceResponse`.
- Tạo form nhập Device ID và PIN đúng 6 chữ số; không có tính năng quét QR.
- Tạo repository/controller gọi `POST /devices/claim`.
- Hiển thị lỗi validation/API thân thiện, bao gồm PIN sai, thiết bị không tồn tại hoặc đã được liên kết.
- Khi thành công, quay về Dashboard và tải lại danh sách thiết bị.

**Nghiệm thu:**
- Không gửi request nếu dữ liệu đầu vào không hợp lệ.
- Test request mapping, validation/controller thành công và lỗi.
- Claim thành công làm robot xuất hiện trên Dashboard mà không cần khởi động lại app.

**Kết quả thực hiện:** đã thêm request model/repository/controller cho `POST /devices/claim`; form tiếng Việt trim và chuyển Device ID thành chữ hoa trước khi gửi, chỉ nhận PIN gồm 6 chữ số. Lỗi từ BE được hiển thị rõ trên form; thành công quay về Dashboard, nơi tự tải lại danh sách. Không thêm QR. Đã kiểm thử request mapping, validation đầu vào, phản hồi lỗi, thành công và cập nhật danh sách sau claim.

## Phase 6 — Lịch sử hội thoại và phân trang

**Trạng thái: Hoàn tất.**

**Mục tiêu:** xem log theo dạng lưu trữ, không phải giao diện chat realtime.

**Phạm vi:**
- Tạo model log và page response theo BE: `items`, `page`, `size`, `totalElements`, `hasNext`.
- Tạo repository gọi `GET /logs?deviceId=...&page=...&size=...`; bắt đầu `page=0`, mặc định `size=50`.
- Tạo controller giữ danh sách, trạng thái tải trang tiếp theo và lỗi tải thêm.
- Dựng danh sách card/timeline hiển thị “Bé nói”, “AmiMate trả lời” và thời gian local.
- Thêm pull-to-refresh, tải thêm khi gần cuối danh sách, empty state và retry.
- Chặn gọi trùng trang; dừng tải khi `hasNext == false`.

**Nghiệm thu:**
- Test parse log/page, thứ tự và logic `hasNext`/tải thêm.
- Không nhân đôi bản ghi khi tải thêm hoặc refresh.
- Màn hình không dùng chat bubbles hoặc tạo cảm giác chat trực tiếp.
- API luôn nhận đúng `deviceId` của robot đang xem.

**Kết quả thực hiện:** đã bổ sung danh sách hội thoại phân trang theo `sessionId`/`chatId` (`GET /logs/sessions`) và lọc log theo chat (`GET /logs?deviceId=...&sessionId=...`). Danh sách chat sắp xếp theo hoạt động mới nhất; người dùng chọn một chat để mở màn hình dạng bong bóng hội thoại, tin mới nhất nằm dưới cùng, cuộn lên để tải các lượt cũ hơn. Phân trang vẫn dùng `page`/`size`, có refresh, trạng thái tải/lỗi và retry. Nút đồng bộ demo Xiaozhi tiếp tục nằm trên danh sách chat; sau sync, danh sách được tải lại. Token chỉ cấu hình ở BE, dữ liệu được nhập idempotent vào `chat_log` với timestamp gốc. Đã bổ sung test API mapping, điều hướng dashboard → danh sách chat → chi tiết, hiển thị thứ tự hội thoại, phân trang, refresh và sync. Tích hợp xác thực với BE thật vẫn thuộc Phase 8.

## Phase 7 — Settings, đăng xuất và hoàn thiện điều hướng

**Trạng thái: Hoàn tất.**

**Mục tiêu:** hoàn tất hành trình sử dụng và kết thúc phiên an toàn.

**Phạm vi:**
- Dựng Settings tối thiểu, hiển thị thông tin phù hợp với dữ liệu sẵn có; không giả định endpoint hồ sơ.
- Thêm xác nhận đăng xuất nếu phù hợp; xóa JWT khỏi secure storage và reset state trong bộ nhớ.
- Điều hướng về Login và ngăn quay lại các màn hình đã xác thực sau đăng xuất.
- Kiểm tra đồng bộ hành vi logout thủ công và 401 từ API.

**Nghiệm thu:**
- Token đã bị xóa sau đăng xuất và Splash đưa người dùng đến Login ở lần mở tiếp theo.
- Back navigation không mở lại màn hình đã đăng nhập.
- Không gọi API hồ sơ vì BE MVP chưa cung cấp endpoint đó.

**Kết quả thực hiện:** đã thay Settings placeholder bằng trang cài đặt tối thiểu không giả định dữ liệu hồ sơ, có xác nhận đăng xuất và phản hồi lỗi khi không xóa được phiên. Đăng xuất thành công xóa JWT, điều hướng về Login; redirect bảo vệ route đã xác thực. Provider danh sách thiết bị và lịch sử hội thoại dùng auto-dispose để dọn dữ liệu bộ nhớ khi rời phiên/màn hình. 401 trên request có JWT xóa token, cập nhật trạng thái phiên và đưa người dùng về Login; login/register 401 không bị coi là hết phiên. Đã thêm test UI cho hủy/xác nhận đăng xuất, back navigation, 401 và header Bearer.

## Phase 8 — Tích hợp end-to-end và kiểm thử MVP

**Mục tiêu:** kiểm chứng luồng phụ huynh từ lúc mở app đến lúc xem được lịch sử robot.

**Phạm vi:**
- Chạy BE và database local cần thiết; xác nhận iOS Simulator truy cập được `localhost:8080`.
- Kiểm thử thủ công luồng: đăng ký → Dashboard rỗng → claim → chọn robot → xem/tải thêm log → đăng xuất → đăng nhập lại.
- Kiểm tra lỗi mạng, 401, validation, response rỗng và loading.
- Chạy `dart format`, `flutter analyze`, unit/widget test liên quan và build/run trên iOS Simulator.
- Sửa lỗi phát sinh từ tích hợp MVP; không thêm Batch 2/3.

**Nghiệm thu MVP:**
- Tất cả luồng nêu trên hoạt động với BE thật.
- Analyze và test FE liên quan đạt; nếu test phụ thuộc BE/DB thì ghi rõ điều kiện chạy.
- Không còn placeholder trong các màn hình thuộc MVP.
- Không có QR, refresh token hoặc cấu hình production trong phạm vi thực thi Batch 1.

## Ngoài phạm vi Batch 1

- Quét QR và quyền camera.
- Access/refresh token và tự động refresh token.
- Android/thiết bị thật, production URL và phát hành ứng dụng (Batch 3).
- Chat realtime, gửi tin nhắn từ phụ huynh, push notification.
- Quản lý tài khoản, đổi/khôi phục mật khẩu, hồ sơ phụ huynh.
- Đổi tên robot hoặc gỡ/unclaim thiết bị khi BE chưa có API hỗ trợ.
