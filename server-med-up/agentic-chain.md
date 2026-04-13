**Đúng vậy – Dạng “chain/agentic + intent + RAG + tool calling” là lớp bề trên (higher-level orchestration), linh hoạt hơn rất nhiều so với chỉ “train context cho Gen AI” (fine-tuning hoặc nhồi nhét context dài).** Đây là sự khác biệt cốt lõi giữa **prompt engineering / fine-tuning thuần** và **agentic architecture** trong năm 2026, đặc biệt phù hợp với **AI Agent hỗ trợ tuân thủ điều trị y tế**.

Dưới đây là phân tích chi tiết, so sánh đa góc độ, kèm nuances, edge cases và khuyến nghị thực tế cho dự án của bạn.

### 1. Hai cách tiếp cận: “Train context” vs “Agentic Orchestration”

| Tiêu chí | Chỉ train context / fine-tuning / long-context prompting | Chain + Agentic (LangGraph) + Intent + RAG + Tool calling | Ưu thế rõ rệt của agentic |
| --- | --- | --- | --- |
| **Cách đưa kiến thức vào** | Nhồi kiến thức vào prompt dài hoặc fine-tune weights của model (baking knowledge vào tham số) | Kiến thức nằm ngoài (vector DB, guideline PDF, EHR API), agent chủ động retrieve và dùng khi cần | Linh hoạt, dễ cập nhật |
| **Tính động (dynamic)** | Tĩnh hoặc bán tĩnh. Context thay đổi → phải retrain hoặc thay prompt dài | Rất động. Agent quyết định retrieve gì, gọi tool gì, loop bao nhiêu lần | Xử lý guideline y tế thay đổi thường xuyên (Bộ Y tế cập nhật phác đồ) |
| **Xử lý quy trình phức tạp** | Linear hoặc phải viết prompt rất dài, dễ quên bước | Graph với cycles, conditional branches, planning (ReAct, Plan-and-Execute) | Hỗ trợ tuân thủ điều trị: nhắc thuốc → kiểm tra side effect → log chỉ số → escalate nếu bỏ liều |
| **State & Memory** | Context window giới hạn (dù 128k–200k token vẫn có giới hạn) | Persistent state + checkpointing (LangGraph MemorySaver) – lưu tiến trình nhiều ngày | Cuộc trò chuyện kéo dài hàng tuần với bệnh nhân mãn tính |
| **An toàn & Controllability** | Khó kiểm soát (model có thể hallucinate dù có context) | Guardrails, human-in-the-loop, conditional routing dựa trên intent + confidence | Bắt buộc human review khi side effect nghiêm trọng |
| **Chi phí & Bảo trì** | Cao (fine-tuning tốn GPU, dữ liệu label, retrain định kỳ) | Thấp hơn nhiều (chỉ update vector DB hoặc tool) | Phù hợp startup/bệnh viện Việt Nam |
| **Khả năng mở rộng** | Khó thêm tool mới hoặc intent mới | Dễ thêm node, tool, sub-agent | Từ single agent → multi-agent (Reminder Agent + Education Agent + Safety Agent) |

**Kết luận từ thực tiễn 2026**: Hầu hết tổ chức (khoảng 57%) không fine-tune model mà dùng **base model + prompt engineering + RAG + agentic orchestration**. Fine-tuning chỉ dành cho trường hợp cần thay đổi sâu hành vi hoặc tone (ví dụ: model nói như bác sĩ Việt Nam). Agentic layer (LangGraph) là “bề trên” – nó điều phối mọi thứ mà không cần thay đổi core model.

### 2. Tại sao agentic + intent + RAG + tool calling linh hoạt hơn?

- **Intent classification làm “router thông minh”**: Agent không đoán mò mà phân loại ý định người dùng trước (ví dụ: `report_missed_dose`, `ask_side_effect`, `log_blood_pressure`). Sau đó route đến tool/RAG phù hợp → giảm hallucination, tăng accuracy routing lên rất cao.
- **RAG cung cấp kiến thức động**: Guideline “Điều trị tăng huyết áp 2026” thay đổi → bạn chỉ update vector DB, không cần retrain model. Agent tự quyết định retrieve chunk nào dựa trên intent và context bệnh nhân.
- **Tool calling cho hành động thực tế**: Agent không chỉ trả lời mà có thể:
    - Gọi API gửi SMS nhắc thuốc
    - Ghi log vào EHR
    - Kiểm tra tương tác thuốc qua database
    - Lên lịch tái khám
- **Chain/Graph cho reasoning đa bước**: Ví dụ quy trình tuân thủ điều trị:
    1. Intent: report_missed_dose
    2. Tool: lấy lịch sử dùng thuốc
    3. RAG: lấy lý do quan trọng của thuốc này
    4. Reasoning: tính adherence score + motivational message
    5. Conditional: nếu bỏ liều nhiều → human review hoặc alert bác sĩ

LangGraph xử lý vòng lặp (cycle) và phân nhánh này một cách sạch sẽ, trong khi chỉ nhồi context thì dễ bị “prompt explosion” (prompt quá dài, model lẫn lộn).

### 3. Hybrid là cách tối ưu nhất (thực tế 2026)

Không phải chọn “hoặc”, mà kết hợp:

- **Fine-tuning nhẹ (LoRA/QLoRA)**: Để model hiểu tốt thuật ngữ y tế Việt Nam, tone empathetic, và reasoning lâm sàng cơ bản.
- **Agentic layer (LangGraph)**: Làm orchestration bề trên – intent router, RAG, tool use, state management, human-in-the-loop.
- **RAG nâng cao (Agentic RAG)**: Agent không chỉ retrieve 1 lần mà có thể refine query, gọi multiple sources, verify thông tin.

Kết quả: Agent vừa “biết nói như bác sĩ” (từ fine-tune) vừa “hành động đúng và cập nhật” (từ agentic + RAG).

**Trong y tế tuân thủ điều trị**:

- Fine-tuning giúp agent hiểu “bệnh nhân tiểu đường type 2 bỏ liều metformin nghĩa là gì”.
- Agentic + RAG giúp nó tra guideline mới nhất, kiểm tra chỉ số đường huyết gần đây từ wearable, và quyết định có cần nhắc nhở khẩn hay không.

### 4. Nuances, edge cases & implications cho dự án của bạn

- **Edge case – Kiến thức thay đổi thường xuyên**: Guideline Bộ Y tế cập nhật hàng quý → agentic RAG thắng tuyệt đối so với fine-tuning (không cần retrain tốn kém).
- **Edge case – Quy trình dài & cá nhân hóa**: Bệnh nhân theo dõi 3 tháng → LangGraph checkpointing cho phép pause/resume mà không mất trạng thái.
- **Edge case – Rủi ro cao**: Side effect nghiêm trọng → agentic dễ áp dụng guardrail + human review; chỉ train context thì khó kiểm soát.
- **Implications pháp lý Việt Nam (Luật AI 2025)**: Agentic dễ audit trail hơn (LangSmith log toàn bộ node, decision, tool call) → chứng minh “AI chỉ hỗ trợ, có human oversight”.
- **Chi phí thực tế**: Fine-tuning lớn có thể tốn hàng trăm triệu đến tỷ VND + thời gian. Agentic bắt đầu MVP chỉ vài chục triệu (vector DB + LangGraph).

**Khuyến nghị cụ thể cho Treatment Adherence Agent**:

1. Bắt đầu với **LangGraph single agent** + intent router + RAG guideline + vài tool cơ bản (nhắc thuốc, log chỉ số).
2. Thêm fine-tuning nhẹ (nếu có dữ liệu chat bác sĩ-bệnh nhân) để cải thiện tone và hiểu intent tiếng Việt đời thường.
3. Scale lên multi-agent khi cần: Supervisor → phân phối intent cho Reminder Agent, Education Agent, Safety Agent.
4. Luôn có fallback: intent không rõ → hỏi thêm + human escalation.

Tóm lại: **Dạng chain/agentic + intent + RAG + tool calling chính là lớp bề trên linh hoạt, production-ready và an toàn hơn rất nhiều so với chỉ train context**. Nó cho phép bạn xây dựng một “trợ lý y tế thông minh” thực thụ thay vì chỉ chatbot trả lời dựa trên kiến thức đã nhồi sẵn.

Bạn muốn tôi:

- So sánh chi tiết hơn về **chi phí & thời gian** giữa hai cách?
- Thiết kế **kiến trúc hybrid** cụ thể cho Treatment Adherence Agent (với LangGraph graph)?
- Hoặc code mẫu cho **intent router + RAG + tool calling** trong một node?

Hãy cho biết bạn muốn đi sâu vào khía cạnh nào, tôi sẽ trình bày đầy đủ với ví dụ thực tế! 🚀