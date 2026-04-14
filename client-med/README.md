# MedIntel Client (Flutter)

Ứng dụng mobile cho MedIntel, kết nối backend `server-med-up`.

## Chạy nhanh

1. Cài dependency:

```bash
flutter pub get
```

2. Chạy app với API base URL:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Ghi chú:
- iOS simulator thường dùng được `127.0.0.1`.
- Android emulator nên dùng `10.0.2.2` thay cho `127.0.0.1`.

## Các màn chính đã nối backend

- `Home`: medication/schedule/log + adherence summary.
- `Scan`: OCR đơn thuốc (`/api/v1/scan/prescription`).
- `AI Chat`: chat + welcome hints + suggested questions + quick-action deep-link.
- `History`: filter/range/search/sort + chi tiết log.
- `Care`: theo dõi profile được chọn.
- `Settings`: mở màn `Medical Records` và `Memory`.

## API liên quan

- Auth: `/api/v1/auth/*`
- Treatment: `/api/v1/treatment/*`
- Chat: `/api/v1/chat/*`
- Scan: `/api/v1/scan/prescription`
- Medical Records: `/api/v1/medical-records/`
- Memory: `/api/v1/memory/`

## Test nhanh

```bash
flutter test
flutter analyze
```
