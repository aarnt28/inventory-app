from datetime import datetime
from typing import Optional

from sqlmodel import SQLModel


class TransactionBase(SQLModel):
    amount: float
    type: str
    unit_cost: Optional[float] = None
    device_id: Optional[str] = None
    vendor_client: Optional[str] = None
    notes: Optional[str] = None
    trans_source: Optional[str] = None


class TransactionCreate(TransactionBase):
    barcode: str  # not item_id


class TransactionUpdate(SQLModel):
    amount: Optional[float] = None
    type: Optional[str] = None
    unit_cost: Optional[float] = None
    device_id: Optional[str] = None
    vendor_client: Optional[str] = None
    notes: Optional[str] = None
    trans_source: Optional[str] = None
    barcode: Optional[str] = None


class TransactionRead(TransactionBase):
    id: int
    item_id: int
    barcode: str
    timestamp: datetime
