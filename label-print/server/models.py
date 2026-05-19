from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
from enum import Enum


class FontSize(str, Enum):
    AUTO = "auto"
    SMALL = "small"
    MEDIUM = "medium"
    LARGE = "large"


class PrintJob(BaseModel):
    id: Optional[str] = None
    lines: List[str] = Field(..., min_items=1, max_items=4, description="1-4 lines of text")
    font_size: FontSize = FontSize.AUTO
    created_at: Optional[datetime] = None


class PrintJobCreate(BaseModel):
    lines: List[str] = Field(..., min_items=1, max_items=4)
    font_size: FontSize = FontSize.AUTO


class Template(BaseModel):
    id: str
    name: str
    lines: List[str]
    font_size: FontSize = FontSize.AUTO
    created_at: datetime


class TemplateCreate(BaseModel):
    name: str = Field(..., min_length=1)
    lines: List[str] = Field(..., min_items=1, max_items=4)
    font_size: FontSize = FontSize.AUTO


class QRCodeRequest(BaseModel):
    data: str = Field(..., min_length=1, description="Data to encode in QR code")
    label_text: Optional[str] = None
    font_size: FontSize = FontSize.AUTO


class PreviewRequest(BaseModel):
    lines: List[str] = Field(..., min_items=1, max_items=4)
    font_size: FontSize = FontSize.AUTO
    force_tape_width: Optional[int] = Field(None, ge=1, description="Force tape width in pixels (for preview without printer)")


class PrepreviewRequest(BaseModel):
    line_count: int = Field(..., ge=1, le=4, description="Number of lines (1-4) to distribute jobs across")


class PrintHistory(BaseModel):
    id: str
    jobs: List[PrintJob]
    printed_at: datetime
    success: bool
    error: Optional[str] = None


class JobQueueResponse(BaseModel):
    jobs: List[PrintJob]
    total: int


class MessageResponse(BaseModel):
    message: str


