from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlmodel import Session, select

from ..database import get_session
from ..models.inventory_item import InventoryItem
from ..models.transaction import Transaction
from ..schemas.transaction import (
    TransactionCreate,
    TransactionRead,
    TransactionUpdate,
)

router = APIRouter(tags=["transactions"])


def _serialize_transaction(tx: Transaction) -> TransactionRead:
    # Ensure related item is loaded for barcode
    item = tx.item
    return TransactionRead(
        id=tx.id,
        item_id=tx.item_id,
        barcode=item.barcode if item else "",
        amount=tx.amount,
        type=tx.type,
        unit_cost=tx.unit_cost,
        device_id=tx.device_id,
        vendor_client=tx.vendor_client,
        notes=tx.notes,
        trans_source=tx.trans_source,
        timestamp=tx.timestamp,
    )


@router.post("/", response_model=TransactionRead, status_code=status.HTTP_201_CREATED)
def create_transaction(
    payload: TransactionCreate,
    session: Session = Depends(get_session),
):
    item = session.exec(
        select(InventoryItem).where(InventoryItem.barcode == payload.barcode)
    ).first()
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item with this barcode not found",
        )

    tx = Transaction(
        item_id=item.id,
        amount=payload.amount,
        type=payload.type,
        unit_cost=payload.unit_cost,
        device_id=payload.device_id,
        vendor_client=payload.vendor_client,
        notes=payload.notes,
        trans_source=payload.trans_source or "shortcut",
    )
    session.add(tx)
    session.commit()
    session.refresh(tx)

    return _serialize_transaction(tx)


@router.get("/", response_model=List[TransactionRead])
def list_transactions(session: Session = Depends(get_session)):
    transactions = session.exec(select(Transaction)).all()
    return [_serialize_transaction(tx) for tx in transactions]


@router.get("/{transaction_id}", response_model=TransactionRead)
def get_transaction(transaction_id: int, session: Session = Depends(get_session)):
    tx = session.get(Transaction, transaction_id)
    if not tx:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found",
        )
    return _serialize_transaction(tx)


@router.patch("/{transaction_id}", response_model=TransactionRead)
def update_transaction(
    transaction_id: int,
    payload: TransactionUpdate,
    session: Session = Depends(get_session),
):
    tx = session.get(Transaction, transaction_id)
    if not tx:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found",
        )

    data = payload.dict(exclude_unset=True)

    # Handle barcode changes by updating item_id
    new_barcode = data.pop("barcode", None)
    if new_barcode is not None:
        item = session.exec(
            select(InventoryItem).where(InventoryItem.barcode == new_barcode)
        ).first()
        if not item:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Item with this barcode not found",
            )
        tx.item_id = item.id

    for field, value in data.items():
        setattr(tx, field, value)

    session.add(tx)
    session.commit()
    session.refresh(tx)

    return _serialize_transaction(tx)


@router.delete("/{transaction_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_transaction(transaction_id: int, session: Session = Depends(get_session)):
    tx = session.get(Transaction, transaction_id)
    if not tx:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Transaction not found",
        )

    session.delete(tx)
    session.commit()
    return {}
