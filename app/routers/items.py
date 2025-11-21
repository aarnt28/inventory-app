import shutil
from pathlib import Path
from uuid import uuid4
from typing import Optional, List

from fastapi import (
    APIRouter,
    UploadFile,
    File,
    Form,
    HTTPException,
    Request,
    status,
    Depends,
)
from sqlmodel import Session, select

from ..database import engine, get_session
from ..models.inventory_item import InventoryItem
from ..schemas.item import ItemRead, ItemUpdate
from ..utils.paths import resolve_upload_dir

router = APIRouter(prefix="/api/items", tags=["items"])

UPLOAD_DIR = resolve_upload_dir()


def _save_upload(image_file: UploadFile) -> str:
    suffix = Path(image_file.filename or "").suffix
    filename = f"{uuid4().hex}{suffix}"
    destination = UPLOAD_DIR / filename
    with destination.open("wb") as buffer:
        shutil.copyfileobj(image_file.file, buffer)
    return filename


def _preview_url(item: InventoryItem, request: Request) -> Optional[str]:
    if item.image_url:
        return item.image_url
    if item.image_path:
        return str(request.url_for("uploads", path=item.image_path))
    return None


def _serialize_item(item: InventoryItem, request: Request) -> dict:
    data = item.dict()
    data["preview_url"] = _preview_url(item, request)
    return data


@router.get("/", response_model=List[ItemRead])
def list_items(request: Request, session: Session = Depends(get_session)):
    items = session.exec(select(InventoryItem)).all()
    # FastAPI will coerce dicts to ItemRead; this keeps preview_url in the payload
    return [_serialize_item(item, request) for item in items]


@router.post("/", status_code=status.HTTP_201_CREATED, response_model=ItemRead)
async def create_item(
    request: Request,
    name: str = Form(...),
    barcode: str = Form(...),
    description: Optional[str] = Form(None),
    quantity: int = Form(0),
    sku: Optional[str] = Form(None),
    image_url: Optional[str] = Form(None),
    image_file: Optional[UploadFile] = File(None),
) -> dict:
    if image_file and image_url:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provide either an image upload or an image URL, not both.",
        )

    image_path = None
    if image_file:
        image_path = _save_upload(image_file)

    item = InventoryItem(
        name=name,
        barcode=barcode,
        description=description,
        quantity=quantity,
        sku=sku,
        image_url=image_url,
        image_path=image_path,
    )

    with Session(engine) as session:
        # Optional app-level duplicate check for nicer errors
        existing = session.exec(
            select(InventoryItem).where(InventoryItem.barcode == barcode)
        ).first()
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Barcode already exists",
            )

        session.add(item)
        session.commit()
        session.refresh(item)
        return _serialize_item(item, request)


@router.get("/{barcode}", response_model=ItemRead)
def get_item(barcode: str, request: Request, session: Session = Depends(get_session)):
    item = session.exec(
        select(InventoryItem).where(InventoryItem.barcode == barcode)
    ).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")
    return _serialize_item(item, request)


@router.patch("/{barcode}", response_model=ItemRead)
def update_item(
    barcode: str,
    payload: ItemUpdate,
    request: Request,
    session: Session = Depends(get_session),
):
    item = session.exec(
        select(InventoryItem).where(InventoryItem.barcode == barcode)
    ).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")

    data = payload.dict(exclude_unset=True)
    for field, value in data.items():
        setattr(item, field, value)

    session.add(item)
    session.commit()
    session.refresh(item)
    return _serialize_item(item, request)


@router.delete("/{barcode}", status_code=status.HTTP_204_NO_CONTENT)
def delete_item(barcode: str, session: Session = Depends(get_session)):
    item = session.exec(
        select(InventoryItem).where(InventoryItem.barcode == barcode)
    ).first()
    if not item:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item not found")

    session.delete(item)
    session.commit()
    # No body for 204
    return {}
