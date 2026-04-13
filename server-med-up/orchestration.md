**Tóm tắt Orchestration Agentic cho AI Chat hỗ trợ tuân thủ điều trị (Treatment Adherence Support Agent) – Dùng LangGraph 2026**

**Orchestration agentic** là cách tổ chức toàn bộ workflow của AI agent dưới dạng **State Machine (đồ thị trạng thái)** thay vì chuỗi tuyến tính (chain đơn giản). LangGraph là công cụ mạnh nhất để làm việc này: nó cho phép agent suy nghĩ, gọi tool, retrieve dữ liệu, loop nếu cần, phân nhánh theo điều kiện, và luôn giữ trạng thái lâu dài (stateful + checkpointing).

Đây là cách **linh hoạt, an toàn và production-ready** nhất cho y tế, vì:

- Dễ thêm Human-in-the-Loop (bác sĩ phê duyệt).
- Dễ audit (log mọi bước theo Luật AI 2025).
- Xử lý tốt quy trình dài: nhắc thuốc → theo dõi → giáo dục → escalate nếu bỏ liều nhiều.

### 1. Kiến trúc tổng quát (StateGraph)

**State (Trạng thái chung – Input/Output chính)**

State là một TypedDict hoặc Pydantic model được chia sẻ qua tất cả các node.

Các trường quan trọng thường có:

- `messages`: list[BaseMessage] – lịch sử chat (Human + AI).
- `patient_info`: dict – thông tin bệnh nhân (tuổi, bệnh mãn tính, phác đồ hiện tại, adherence score…).
- `current_intent`: str – intent đã phân loại (ví dụ: "report_missed_dose", "ask_side_effect").
- `retrieved_context`: str – kết quả từ RAG (guideline, dược điển).
- `tool_results`: dict – kết quả sau khi gọi tool.
- `confidence`: float (0-1) – độ tin cậy của quyết định.
- `needs_human_review`: bool – cờ để trigger human-in-the-loop.
- `adherence_metrics`: dict – tỷ lệ tuân thủ, số liều bỏ, chỉ số theo dõi (huyết áp, đường huyết…).
- `next_action`: str – hành động kế tiếp (dùng cho conditional routing).

**Input ban đầu**: {"messages": [HumanMessage(...)] , "patient_info": {...}}

**Output cuối cùng**: Cập nhật state + tin nhắn trả lời cho bệnh nhân + các action (gửi nhắc, log EHR…).

### 2. Các Chain / Nodes chính trong Orchestration (Workflow đề xuất hợp lý)

Dưới đây là thiết kế **hợp lý cho Treatment Adherence Agent** (cân bằng giữa đơn giản và mạnh mẽ). Có thể bắt đầu với single graph, sau nâng lên multi-agent (supervisor + sub-graphs).

1. **Intent Router / Classifier Node** (Node đầu tiên hoặc luôn chạy sau user message)
    - **Input**: messages mới + patient_info.
    - **Hành động**: LLM nhỏ hoặc classifier phân loại intent + tính confidence.
    - **Output**: Cập nhật `current_intent` và `confidence`.
    - **Mục đích**: Quyết định routing chính xác, tránh agent đoán mò.
2. **Perception / Information Gathering Node** (nếu cần)
    - **Input**: intent + messages.
    - **Hành động**: Hỏi thêm thông tin nếu thiếu (ví dụ: triệu chứng cụ thể, chỉ số hôm nay).
    - **Output**: Cập nhật messages và patient_info.
3. **RAG Retrieval Node** (Agentic RAG)
    - **Input**: intent + patient_info + query được tạo động.
    - **Hành động**: Retrieve từ vector DB (guideline Bộ Y tế, dược điển Việt Nam, phác đồ bệnh nhân). Có thể refine query nếu cần.
    - **Output**: `retrieved_context` (kiến thức đáng tin cậy).
4. **Reasoning / Decision Node** (Core LLM call – ReAct style)
    - **Input**: messages + intent + retrieved_context + tool_results.
    - **Hành động**: LLM suy nghĩ (Chain-of-Thought), quyết định cần gọi tool gì, tính adherence score, soạn thảo câu trả lời empathetic.
    - **Output**: Cập nhật messages (AI response tạm), confidence, next_action.
5. **Tool Calling / Action Node** (có thể là ToolNode hoặc custom)
    - **Input**: Quyết định từ Reasoning.
    - **Hành động**: Gọi các tool thực tế:
        - Gửi nhắc nhở (SMS/Notification).
        - Log chỉ số vào EHR.
        - Kiểm tra tương tác thuốc.
        - Lên lịch tái khám.
        - Tính toán adherence percentage.
    - **Output**: `tool_results`.
6. **Safety / Guardrail & Human Review Node** (rất quan trọng trong y tế)
    - **Input**: confidence + intent + proposed action.
    - **Hành động**: Kiểm tra rủi ro (side effect nghiêm trọng, bỏ liều nhiều, thay đổi liều…). Nếu cần → interrupt (pause graph) và gửi alert cho bác sĩ.
    - **Output**: Cập nhật `needs_human_review` hoặc approve action.
7. **Response Generation & Feedback Node** (Node cuối trước END)
    - **Input**: Toàn bộ state sau các bước trên.
    - **Hành động**: Tạo tin nhắn cuối cùng (thân thiện, rõ ràng, có disclaimer “Không thay thế bác sĩ”).
    - **Output**: Messages hoàn chỉnh + log adherence update.

**Conditional Edges (Phân nhánh)**:

- Sau Intent Router: nếu intent rõ & confidence cao → đi RAG → Reasoning.
- Sau Reasoning: nếu cần tool → Tool Node; nếu rủi ro cao → Human Review; nếu hoàn thành → Response → END.
- Sau Tool: quay lại Reasoning (cycle – ReAct loop).
- Sau Human Review: resume graph.

**Cycles (Vòng lặp)**: Cho phép agent hỏi thêm → retrieve → suy nghĩ lại nhiều lần nếu cần.

### 3. Lợi ích của orchestration này

- **Linh hoạt**: Dễ thêm node mới (ví dụ: Motivational Interviewing sub-node).
- **An toàn**: Human-in-the-Loop bắt buộc ở bước rủi ro.
- **Stateful**: Nhớ toàn bộ lịch sử bệnh nhân nhiều ngày/tuần nhờ checkpointing.
- **Dễ debug & audit**: LangSmith theo dõi từng node, edge, tool call.
- **Scalable**: Từ single agent → multi-agent (Supervisor phân phối cho Reminder Agent, Education Agent, Safety Agent).

### Khuyến nghị triển khai

- Bắt đầu với **7 nodes** trên cho MVP.
- Sử dụng `MemorySaver` hoặc PostgreSQL checkpointer cho production.
- Luôn giữ state **minimal** (chỉ những gì cần thiết) để tránh phức tạp.
- Test với nhiều edge case: bệnh nhân bỏ liều, side effect, intent mơ hồ, guideline thay đổi.

**Tóm tắt ngắn gọn nhất**:

Orchestration = **State** (shared memory) + **Nodes** (Intent → RAG → Reasoning → Tool → Safety → Response) + **Conditional Edges + Cycles** (điều khiển flow động).

Input: Tin nhắn người dùng + patient context.

Output: Trả lời hữu ích + hành động thực tế (nhắc thuốc, log dữ liệu) + trạng thái cập nhật.

Bạn muốn tôi:

- Vẽ sơ đồ Mermaid code để visualize graph này?
- Cung cấp **code mẫu Python** đầy đủ cho State + các node chính?
- Hoặc điều chỉnh orchestration cho multi-agent (supervisor + sub-agents)?

Hãy cho biết bạn cần chi tiết phần nào để tôi hỗ trợ sâu hơn!