
import { DrugReference } from '../types';

export const DRUG_DATABASE: DrugReference[] = [
  {
    id: 'd1',
    name: 'Panadol Extra',
    ingredient: 'Paracetamol 500mg, Caffeine 65mg',
    group: 'Giảm đau, Hạ sốt',
    usage: 'Điều trị đau nhẹ đến vừa: đau đầu, đau nửa đầu, đau cơ, đau bụng kinh, đau họng, đau răng, sốt.',
    dosage: 'Người lớn: 1-2 viên mỗi 4-6 giờ. Tối đa 8 viên/ngày.',
    contraindication: 'Mẫn cảm với Paracetamol/Caffeine. Suy gan nặng.',
    sideEffect: 'Hiếm gặp: Phản ứng da, giảm tiểu cầu. Caffeine có thể gây mất ngủ, bồn chồn.',
    warning: 'Không dùng chung với các thuốc khác chứa Paracetamol.',
    iconType: 'tablet'
  },
  {
    id: 'd2',
    name: 'Augmentin 625mg',
    ingredient: 'Amoxicillin 500mg, Clavulanic acid 125mg',
    group: 'Kháng sinh nhóm Beta-lactam',
    usage: 'Nhiễm khuẩn đường hô hấp trên/dưới, nhiễm khuẩn da, đường tiết niệu.',
    dosage: 'Người lớn: 1 viên x 2-3 lần/ngày. Uống ngay trước bữa ăn để giảm kích ứng dạ dày.',
    contraindication: 'Dị ứng Penicillin/Cephalosporin. Tiền sử vàng da/rối loạn chức năng gan.',
    sideEffect: 'Tiêu chảy, buồn nôn, nôn, phát ban, nhiễm nấm Candida.',
    warning: 'Cần uống đủ liệu trình. Thận trọng với người suy gan, suy thận.',
    iconType: 'tablet'
  },
  {
    id: 'd3',
    name: 'Berberin',
    ingredient: 'Berberin clorid',
    group: 'Thuốc đường tiêu hóa',
    usage: 'Tiêu chảy, lỵ trực khuẩn, viêm ruột, viêm ống mật.',
    dosage: 'Người lớn: 4-6 viên 50mg x 2 lần/ngày.',
    contraindication: 'Phụ nữ mang thai (kích thích co bóp tử cung). Mẫn cảm với thành phần.',
    sideEffect: 'Táo bón (nếu dùng liều cao kéo dài), buồn nôn.',
    warning: 'Tránh dùng kéo dài. Cẩn trọng với phụ nữ cho con bú.',
    iconType: 'pill'
  },
  {
    id: 'd4',
    name: 'Smecta',
    ingredient: 'Diosmectite',
    group: 'Thuốc đường tiêu hóa',
    usage: 'Điều trị triệu chứng đau của bệnh thực quản - dạ dày - tá tràng. Tiêu chảy cấp và mãn tính.',
    dosage: 'Người lớn: 3 gói/ngày, hòa với nửa ly nước.',
    contraindication: 'Quá mẫn với Diosmectite.',
    sideEffect: 'Táo bón.',
    warning: 'Nên uống xa bữa ăn (trừ viêm thực quản). Không dùng quá 7 ngày nếu không đỡ.',
    iconType: 'syrup'
  },
  {
    id: 'd5',
    name: 'Gaviscon Dual Action',
    ingredient: 'Sodium alginate, Calcium carbonate, Sodium bicarbonate',
    group: 'Kháng acid & trào ngược dạ dày',
    usage: 'Điều trị trào ngược dạ dày thực quản (ợ nóng, khó tiêu).',
    dosage: 'Người lớn: 1-2 gói sau ăn và lúc đi ngủ (tối đa 4 lần/ngày).',
    contraindication: 'Mẫn cảm với thành phần. Suy thận nặng (do chứa muối).',
    sideEffect: 'Đầy hơi, chướng bụng (hiếm).',
    warning: 'Lắc kỹ trước khi dùng. Cách xa các thuốc khác 2 giờ.',
    iconType: 'syrup'
  },
  {
    id: 'd6',
    name: 'Oresol',
    ingredient: 'Glucose khan, Natri clorid, Natri citrat, Kali clorid',
    group: 'Bù nước và điện giải',
    usage: 'Phòng và điều trị mất nước do tiêu chảy, nôn mửa, sốt cao, vận động nặng.',
    dosage: 'Pha 1 gói với đúng lượng nước quy định (thường 200ml hoặc 1 lít). Uống theo nhu cầu.',
    contraindication: 'Vô niệu, tắc ruột, nôn nhiều kéo dài.',
    sideEffect: 'Nôn nhẹ, thừa nước (mi mắt sưng) nếu uống quá nhiều.',
    warning: 'Pha đúng tỷ lệ. Dung dịch đã pha chỉ dùng trong 24h.',
    iconType: 'syrup'
  },
  {
    id: 'd7',
    name: 'Neurobion',
    ingredient: 'Vitamin B1, B6, B12',
    group: 'Vitamin & Khoáng chất',
    usage: 'Rối loạn thần kinh ngoại biên (đau dây thần kinh, tê bì chân tay). Bổ sung vitamin nhóm B.',
    dosage: '1-3 viên/ngày theo chỉ định.',
    contraindication: 'Mẫn cảm với thành phần. U ác tính.',
    sideEffect: 'Rất hiếm: Phản ứng dị ứng.',
    warning: 'Dùng B6 liều cao kéo dài có thể gây bệnh thần kinh ngoại biên.',
    iconType: 'tablet'
  },
  {
    id: 'd8',
    name: 'Amlodipin 5mg',
    ingredient: 'Amlodipine besylate',
    group: 'Thuốc tim mạch (Chẹn kênh Canxi)',
    usage: 'Điều trị tăng huyết áp, đau thắt ngực ổn định.',
    dosage: 'Khởi đầu 5mg/ngày. Tối đa 10mg/ngày.',
    contraindication: 'Huyết áp thấp nghiêm trọng, sốc tim, suy tim không ổn định sau nhồi máu cơ tim.',
    sideEffect: 'Phù cổ chân, đỏ bừng mặt, đau đầu, mệt mỏi.',
    warning: 'Thận trọng với người suy gan, người già.',
    iconType: 'tablet'
  },
  {
    id: 'd9',
    name: 'Metformin 500mg',
    ingredient: 'Metformin hydrochloride',
    group: 'Thuốc điều trị tiểu đường',
    usage: 'Đái tháo đường tuýp 2 (không phụ thuộc insulin).',
    dosage: 'Khởi đầu 500mg x 1-2 lần/ngày trong hoặc sau bữa ăn.',
    contraindication: 'Suy thận nặng, nhiễm toan chuyển hóa, tiền hôn mê đái tháo đường.',
    sideEffect: 'Rối loạn tiêu hóa (buồn nôn, tiêu chảy), miệng có vị kim loại.',
    warning: 'Ngừng thuốc khi chụp X-quang có cản quang.',
    iconType: 'tablet'
  },
  {
    id: 'd10',
    name: 'Fugacar',
    ingredient: 'Mebendazole 500mg',
    group: 'Thuốc tẩy giun',
    usage: 'Điều trị nhiễm một hoặc nhiều loại giun đường ruột.',
    dosage: '1 viên duy nhất. Nhai kỹ trước khi nuốt.',
    contraindication: 'Phụ nữ có thai 3 tháng đầu. Trẻ em dưới 2 tuổi.',
    sideEffect: 'Đau bụng thoáng qua, tiêu chảy.',
    warning: 'Tránh ăn thực phẩm nhiều dầu mỡ khi uống thuốc.',
    iconType: 'tablet'
  }
];
