from typing import Any

from pydantic import BaseModel, Field


class SuggestedAction(BaseModel):
    """Một nút gợi ý sau câu trả lời AI."""

    label: str = Field(..., description="Nhãn hiển thị trên chip")
    prompt: str = Field(
        default="",
        description="Nội dung gửi lên chat khi user chọn (nếu rỗng dùng label)",
    )


class ToolCall(BaseModel):
    """Lệnh agent — client thực thi & lưu cục bộ (sync server làm sau)."""

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
