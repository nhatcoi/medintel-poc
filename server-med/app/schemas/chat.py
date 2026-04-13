from typing import Any, Literal

from pydantic import BaseModel, Field, field_validator

WelcomeHintsSource = Literal["llm", "template"]

SuggestedActionCategory = Literal["app", "knowledge", "other"]


class SuggestedAction(BaseModel):
    """Một nút gợi ý sau câu trả lời AI."""

    label: str = Field(..., description="Nhãn hiển thị trên chip")
    prompt: str = Field(
        default="",
        description="Nội dung gửi lên chat khi user chọn (nếu rỗng dùng label)",
    )
    category: SuggestedActionCategory = Field(
        default="other",
        description="app = thao tác trong ứng dụng; knowledge = tra cứu kiến thức (RAG/search); other = còn lại",
    )

    @field_validator("category", mode="before")
    @classmethod
    def _coerce_category(cls, v: object) -> str:
        s = str(v or "other").strip().lower()
        if s in ("app", "knowledge", "other"):
            return s
        return "other"


class ToolCall(BaseModel):
    """Lệnh agent — client thực thi & lưu database (đồng bộ server)."""

    tool: str
    args: dict[str, Any] = Field(default_factory=dict)


class Citation(BaseModel):
    """Nguồn tham chiếu cho câu trả lời."""

    title: str = Field(..., description="Tên nguồn ngắn gọn")
    url: str | None = Field(default=None, description="URL nguồn (nếu có)")
    source_type: str = Field(
        default="internal",
        description="Loại nguồn: internal | external | model",
    )


class ChatRequest(BaseModel):
    text: str
    profile_id: str | None = Field(
        default=None,
        description="UUID profile — nếu có, lưu lượt chat + agentic payload vào DB",
    )
    session_id: str | None = Field(
        default=None,
        description="UUID phiên chat có sẵn; bỏ trống sẽ tạo chat_sessions mới",
    )
    include_medication_context: bool = Field(
        default=False,
        description="Nếu true và có profile_id hợp lệ: ghép danh sách thuốc đã lưu trên server vào system prompt",
    )
    include_patient_context_chunks: bool = Field(
        default=False,
        description=(
            "Nếu true và có profile_id: ghép thêm bối cảnh snapshot (hồ sơ, tủ thuốc, log, tuân thủ…) "
            "đã chunk — bổ sung cho medication_context; không chứa UUID trong prompt."
        ),
    )
    patient_context_use_stored_md: bool = Field(
        default=True,
        description=(
            "Khi include_patient_context_chunks=true: ưu tiên đọc markdown đã lưu (bảng patient_agent_context); "
            "false = luôn ghép trực tiếp từ SQL mỗi lượt (nặng hơn)."
        ),
    )


class WelcomeHintsResponse(BaseModel):
    """Gợi ý dòng chữ chào màn chat — từ LLM + dữ liệu DB hoặc template."""

    hints: list[str] = Field(default_factory=list)
    source: WelcomeHintsSource = Field(
        default="template",
        description="llm = sinh từ AI; template = cá nhân hóa theo DB không qua LLM",
    )


SuggestedQuestionsSource = Literal["llm", "template"]


class SuggestedQuestionsResponse(BaseModel):
    """Câu hỏi / chip gợi ý sau welcome hoặc trong khay chat."""

    questions: list[str] = Field(default_factory=list)
    source: SuggestedQuestionsSource = Field(
        default="template",
        description="llm = sinh từ AI theo snapshot đã chunk; template = rule-based",
    )


class ChatResponse(BaseModel):
    reply: str
    source_type: str = Field(
        default="internal",
        description="Nguồn chính tạo câu trả lời: internal | external | mixed | model",
    )
    confidence: float = Field(
        default=0.6,
        ge=0.0,
        le=1.0,
        description="Độ tin cậy tự ước lượng của hệ thống trong khoảng [0,1]",
    )
    citations: list[Citation] = Field(
        default_factory=list,
        description="Danh sách nguồn tham chiếu dùng để trả lời",
    )
    session_id: str | None = Field(
        default=None,
        description="UUID phiên chat (khi đã lưu DB); gửi lại ở request tiếp theo",
    )
    suggested_actions: list[SuggestedAction] = Field(default_factory=list)
    tool_calls: list[ToolCall] = Field(
        default_factory=list,
        description="Thao tác đã quyết định; app sẽ thực hiện phía client.",
    )
