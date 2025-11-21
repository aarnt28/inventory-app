from datetime import datetime
from typing import Optional, TYPE_CHECKING

from sqlmodel import SQLModel, Field, Relationship

if TYPE_CHECKING:
    from .inventory_item import InventoryItem


class Transaction(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    item_id: int = Field(foreign_key="inventoryitem.id")
    type: str  # e.g. "add", "use", "adjust"
    amount: float
    unit_cost: Optional[float] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    device_id: Optional[str] = None
    vendor_client: Optional[str] = None
    notes: Optional[str] = None
    trans_source: Optional[str] = None  # for your shortcut-based entries

    item: "InventoryItem" = Relationship(back_populates="transactions")
