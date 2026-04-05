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


class ChatResponse(BaseModel):
    reply: str
    session_id: str | None = Field(
        default=None,
        description="UUID phiên chat (khi đã lưu DB); gửi lại ở request tiếp theo",
    )
    suggested_actions: list[SuggestedAction] = Field(default_factory=list)
    tool_calls: list[ToolCall] = Field(
        default_factory=list,
        description="Thao tác đã quyết định; app sẽ thực hiện phía client.",
    )
