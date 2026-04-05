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


class ChatResponse(BaseModel):
    reply: str
    suggested_actions: list[SuggestedAction] = Field(default_factory=list)
    tool_calls: list[ToolCall] = Field(
        default_factory=list,
        description="Thao tác đã quyết định; app sẽ thực hiện phía client.",
    )
