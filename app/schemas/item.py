from typing import Optional

from sqlmodel import SQLModel


class ItemBase(SQLModel):
    barcode: str
    name: str
    description: Optional[str] = None
    quantity: int = 0
    sku: Optional[str] = None
    image_url: Optional[str] = None
    image_path: Optional[str] = None


class ItemCreate(ItemBase):
    pass


class ItemUpdate(SQLModel):
    name: Optional[str] = None
    description: Optional[str] = None
    quantity: Optional[int] = None
    sku: Optional[str] = None
    image_url: Optional[str] = None


class ItemRead(ItemBase):
    id: int
