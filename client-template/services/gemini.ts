
import { GoogleGenAI, Type, FunctionDeclaration } from "@google/genai";
import { FormData, ExtendedMedication, Member, HealthLog, Dossier } from "../types";

const ai = new GoogleGenAI({ apiKey: process.env.API_KEY as string });

// --- AGENTIC TOOLS DEFINITION ---
const tools: FunctionDeclaration[] = [
  {
    name: "open_add_medication",
    description: "Open the form to add a new medication manually when user wants to add a pill, drug, or prescription.",
  },
  {
    name: "scan_prescription",
    description: "Open the camera/scanner to scan a prescription or pill bottle using AI.",
  },
  {
    name: "open_add_habit",
    description: "Open the form to create a new health habit or routine (water, exercise, sleep).",
  },
  {
    name: "open_add_dossier",
    description: "Open the form to upload or add a new medical record, test result, or doctor note.",
  },
  {
    name: "open_add_tracker",
    description: "Open the form to record a health metric like blood pressure, weight, glucose, heart rate.",
  },
  {
    name: "open_drug_lookup",
    description: "Open the drug search tool to look up information about a medicine.",
  }
];

export const analyzePatientProfile = async (data: FormData) => {
  const prompt = `
    Analyze the following patient profile for MedIntel Adherence Prediction:
    Role: ${data.userRole}
    Disease: ${data.mainDisease} (${data.diseaseDuration})
    Treatment Stage: ${data.treatmentStage}
    Current Medications: ${data.medications.map(m => m.name).join(', ')}
    Historical Adherence: ${data.forgotFrequency}
    Reasons for forgetting: ${data.forgotReasons.join(', ')}
    
    Generate a concise personalized adherence strategy and baseline risk score (0-100).
    Return the response in structured text that includes:
    1. A summary of their profile.
    2. A risk assessment for non-compliance.
    3. Three specific tips to improve their adherence based on their specific challenges.
  `;

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: prompt,
      config: {
        temperature: 0.7,
      }
    });
    return response.text;
  } catch (error) {
    console.error("Gemini analysis failed", error);
    return "Failed to generate personalized analysis. Please proceed with manual setup.";
  }
};

const MEDICATION_SCHEMA = {
  type: Type.ARRAY,
  items: {
    type: Type.OBJECT,
    properties: {
      name: { type: Type.STRING },
      dosage: { type: Type.STRING },
      dosageUnit: { type: Type.STRING },
      frequency: { type: Type.STRING },
      frequencyType: { type: Type.STRING, enum: ["daily", "interval", "specific_days"] },
      timeOfDay: { type: Type.ARRAY, items: { type: Type.STRING } },
      direction: { type: Type.STRING },
      notes: { type: Type.STRING },
      expectedDuration: { type: Type.STRING },
      icon: { type: Type.STRING },
      color: { type: Type.STRING },
    },
    required: ["name", "frequency", "timeOfDay"],
  },
};

const DOSSIER_SCHEMA = {
  type: Type.OBJECT,
  properties: {
    title: { type: Type.STRING },
    hospital: { type: Type.STRING },
    doctor: { type: Type.STRING },
    date: { type: Type.STRING },
    type: { type: Type.STRING, enum: ['Exam', 'Lab', 'Rx', 'Image', 'Progression', 'Cert'] },
    details: { type: Type.STRING },
  },
  required: ['title', 'type', 'details']
};

export const parseMedicationFromText = async (text: string): Promise<ExtendedMedication[]> => {
  const prompt = `
    Trích xuất thông tin thuốc từ văn bản sau đây và trả về định dạng JSON.
    Văn bản: "${text}"

    Quy tắc:
    1. 'name': Tên thuốc.
    2. 'dosage': Hàm lượng + dạng bào chế (VD: 500mg viên).
    3. 'frequency': Mô tả tần suất (VD: Ngày 2 lần).
    4. 'timeOfDay': Mảng các giờ uống thuốc dự kiến định dạng HH:mm. Tự suy luận hợp lý nếu không có giờ cụ thể (Sáng=08:00, Trưa=12:00, Chiều=17:00, Tối=20:00). Nếu 'cách nhau 4-6h', hãy tạo ra các mốc giờ cách nhau tương ứng bắt đầu từ 08:00.
    5. 'direction': Cách dùng (Sau ăn, Trước ăn, v.v.).
    6. 'notes': Các lưu ý khác (VD: Không quá 4 viên/ngày).
    7. 'expectedDuration': Thời gian dùng thuốc (VD: 5 ngày, 7 ngày). Nếu không rõ để '7 ngày'.
    8. 'icon': Chọn một trong ['pill', 'tablet', 'syrup', 'injection'] dựa trên tên thuốc hoặc dạng bào chế.
    9. 'color': Chọn một mã màu hex ngẫu nhiên.
  `;

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: prompt,
      config: {
        responseMimeType: "application/json",
        responseSchema: MEDICATION_SCHEMA,
      },
    });

    if (response.text) {
      const rawData = JSON.parse(response.text);
      return rawData.map((m: any) => ({
        ...m,
        startDate: new Date().toISOString().split('T')[0],
        reminder: true,
        taken: false,
        skipped: false
      }));
    }
    return [];
  } catch (error) {
    console.error("Gemini prescription parsing failed", error);
    return [];
  }
};

export const parseMedicationFromImage = async (base64Data: string): Promise<ExtendedMedication[]> => {
  const mimeType = base64Data.includes(';') ? base64Data.split(';')[0].split(':')[1] : 'image/jpeg';
  const data = base64Data.includes(',') ? base64Data.split(',')[1] : base64Data;

  const prompt = `
    Bạn là một dược sĩ AI. Hãy nhìn vào hình ảnh đơn thuốc (hoặc vỏ thuốc) này và trích xuất danh sách các loại thuốc.
    
    Yêu cầu chi tiết:
    1. Tìm tên thuốc chính xác (Biệt dược hoặc hoạt chất).
    2. Tìm hàm lượng (dosage) và đơn vị (dosageUnit) nếu có.
    3. Tìm hướng dẫn sử dụng (frequency, direction) trên đơn. Nếu chỉ có tên thuốc, hãy để frequency là "Khi cần" và direction là "Theo chỉ dẫn bác sĩ".
    4. Dự đoán thời gian uống (timeOfDay) dựa trên tần suất (VD: Sáng/Chiều -> ["08:00", "18:00"]).
    5. Chọn icon phù hợp (pill, tablet, syrup, injection).
    6. Chọn một màu (color) ngẫu nhiên để hiển thị.
    
    Trả về kết quả dưới dạng JSON Array theo Schema đã định nghĩa.
  `;

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: [
        {
          inlineData: {
            mimeType: mimeType,
            data: data
          }
        },
        {
          text: prompt
        }
      ],
      config: {
        responseMimeType: "application/json",
        responseSchema: MEDICATION_SCHEMA,
      },
    });

    if (response.text) {
      const rawData = JSON.parse(response.text);
      return rawData.map((m: any) => ({
        ...m,
        startDate: new Date().toISOString().split('T')[0],
        reminder: true,
        taken: false,
        skipped: false,
        dosageUnit: m.dosageUnit || 'viên',
        frequency: m.frequency || 'Theo chỉ dẫn',
        timeOfDay: m.timeOfDay && m.timeOfDay.length > 0 ? m.timeOfDay : []
      }));
    }
    return [];
  } catch (error) {
    console.error("Gemini image parsing failed", error);
    return [];
  }
};

export const parseDossierFromImage = async (base64Data: string): Promise<any> => {
  const mimeType = base64Data.includes(';') ? base64Data.split(';')[0].split(':')[1] : 'image/jpeg';
  const data = base64Data.includes(',') ? base64Data.split(',')[1] : base64Data;

  const prompt = `
    Phân tích hình ảnh tài liệu y tế này (sổ khám, phiếu xét nghiệm, đơn thuốc, hình ảnh chẩn đoán) và trích xuất thông tin chính.
  `;

  try {
    const response = await ai.models.generateContent({
      model: 'gemini-3-flash-preview',
      contents: [
        {
          inlineData: {
            mimeType: mimeType,
            data: data
          }
        },
        {
          text: prompt
        }
      ],
      config: {
        responseMimeType: "application/json",
        responseSchema: DOSSIER_SCHEMA,
      },
    });

    if (response.text) {
      return JSON.parse(response.text);
    }
    return null;
  } catch (error) {
    console.error("Gemini dossier parsing failed", error);
    return null;
  }
};

export interface ChatResponse {
    text: string;
    action?: string;
}

export const chatWithHealthAssistant = async (
    message: string, 
    context: {
        member: Member;
        healthLogs: HealthLog[];
        dossiers: Dossier[];
        todayStr: string;
    }
): Promise<ChatResponse> => {
    // Construct Context String
    const medList = context.member.meds.map(m => 
        `- ${m.name} (${m.dosage}): ${m.timeOfDay.join(', ')}. Trạng thái hôm nay: ${m.history?.[context.todayStr]?.taken ? 'Đã uống' : 'Chưa uống'}`
    ).join('\n');

    const recentLogs = context.healthLogs
        .slice(0, 5)
        .map(l => `- ${l.type} (${l.timestamp}): ${JSON.stringify(l.values)}`)
        .join('\n');

    const recentDossiers = context.dossiers
        .slice(0, 3)
        .map(d => `- ${d.date}: ${d.title} tại ${d.hospital}. ${d.details}`)
        .join('\n');

    const prompt = `
        Bạn là Trợ lý Y tế AI (MedIntel) của người dùng tên là "${context.member.name}".
        
        NGỮ CẢNH NGƯỜI DÙNG:
        1. Thuốc đang dùng:
        ${medList || "Không có thuốc nào."}
        
        2. Chỉ số sức khỏe gần đây:
        ${recentLogs || "Chưa có ghi nhận."}

        3. Hồ sơ bệnh án gần đây:
        ${recentDossiers || "Chưa có hồ sơ."}

        NHIỆM VỤ:
        Trả lời câu hỏi của người dùng: "${message}"

        QUY TẮC:
        - Trả lời ngắn gọn, thân thiện, đồng cảm (dưới 150 từ).
        - Nếu người dùng muốn thực hiện một hành động (ví dụ: thêm thuốc, scan đơn, thêm thói quen, đo huyết áp...), hãy gọi function tương ứng.
        - Nếu họ kêu mệt hoặc có triệu chứng lạ, hãy khuyên nghỉ ngơi hoặc đi khám.
        - Không được kê đơn thuốc mới.
        - Luôn xưng hô là "mình" hoặc "Trợ lý", gọi người dùng bằng tên.
    `;

    try {
        const response = await ai.models.generateContent({
            model: 'gemini-3-flash-preview',
            contents: prompt,
            config: {
                tools: [{ functionDeclarations: tools }],
            }
        });

        // Check for function calls
        const functionCalls = response.candidates?.[0]?.content?.parts?.filter(p => p.functionCall);
        
        // Check for text content
        const textPart = response.candidates?.[0]?.content?.parts?.find(p => p.text);
        let text = textPart?.text || "Được rồi, để mình giúp bạn.";

        let action = undefined;

        if (functionCalls && functionCalls.length > 0) {
            const fc = functionCalls[0].functionCall;
            if (fc) {
                action = fc.name;
                // Nếu model không trả về text mà chỉ gọi function, ta tự thêm text
                if (!textPart) {
                    if (action === 'open_add_medication') text = "Mình sẽ mở form thêm thuốc mới ngay bây giờ.";
                    else if (action === 'scan_prescription') text = "Được, hãy mở camera để quét đơn thuốc nhé.";
                    else if (action === 'open_add_habit') text = "Xây dựng thói quen tốt là rất quan trọng. Mời bạn điền thông tin.";
                    else if (action === 'open_add_dossier') text = "Mình sẽ giúp bạn lưu trữ hồ sơ y tế mới.";
                    else if (action === 'open_add_tracker') text = "Hãy ghi lại chỉ số sức khỏe để theo dõi sát sao hơn.";
                    else if (action === 'open_drug_lookup') text = "Mình đang mở công cụ tra cứu thuốc cho bạn.";
                }
            }
        }

        return { text, action };

    } catch (error) {
        console.error("Chat Error", error);
        return { text: "Xin lỗi, hiện tại mình không thể kết nối với máy chủ." };
    }
};
