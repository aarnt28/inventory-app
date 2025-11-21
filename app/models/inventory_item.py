from typing import Optional, TYPE_CHECKING, List

from sqlmodel import SQLModel, Field, Relationship, UniqueConstraint

if TYPE_CHECKING:
    from .transaction import Transaction


class InventoryItem(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    name: str
    barcode: str = Field(index=True, unique=True)
    description: Optional[str] = None
    quantity: int = 0
    sku: Optional[str] = None
    # Either an externally hosted URL or a locally uploaded file name (stored under /uploads)
    image_url: Optional[str] = None
    image_path: Optional[str] = None

    # Relationship to transactions (item.transactions)
    transactions: List["Transaction"] = Relationship(back_populates="item")

    class Config:
        arbitrary_types_allowed = True

    __table_args__ = (
        # Enforce uniqueness at the DB level for barcode
        UniqueConstraint("barcode", name="uq_inventory_item_barcode"),
    )
