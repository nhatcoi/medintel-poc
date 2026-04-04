-- Dữ liệu mẫu dev (mật khẩu: password — bcrypt hash test phổ biến)
-- Chỉ dùng môi trường phát triển.

INSERT INTO users (id, email, hashed_password, full_name, role)
VALUES (
    uuid_generate_v4(),
    'demo@medintel.local',
    '$2b$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'Bệnh nhân demo',
    'patient'
)
ON CONFLICT (email) DO NOTHING;

-- Nếu cần id cố định cho script, thay uuid_generate_v4() bằng literal UUID.
