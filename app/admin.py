import csv
import io
from pathlib import Path
from typing import Dict, Iterable, List, Tuple

from fastapi import Request, UploadFile
from sqladmin import Admin, ModelView, expose
from sqlmodel import Session, select

from .models.inventory_item import InventoryItem
from .models.transaction import Transaction
from .database import engine


class InventoryItemAdmin(ModelView, model=InventoryItem):
    list_template = "sqladmin/inventory_item_list.html"

    _FIELD_ALIASES: Dict[str, Iterable[str]] = {
        "barcode": ("barcode", "bar code", "item barcode"),
        "name": ("name", "item name", "title"),
        "description": ("description", "details", "desc"),
        "quantity": ("quantity", "qty", "stock", "count"),
        "sku": ("sku", "product sku"),
        "image_url": ("image_url", "image url", "image", "image link", "photo"),
    }

    _REQUIRED_FIELDS = {"barcode", "name"}

    def _normalize_header(self, header: str) -> str:
        return header.strip().lower()

    def _header_lookup(self, header: str) -> str | None:
        normalized = self._normalize_header(header)
        for canonical, aliases in self._FIELD_ALIASES.items():
            if normalized in aliases:
                return canonical
        return None

    def _map_headers(self, headers: Iterable[str]) -> Dict[str, str]:
        mapped: Dict[str, str] = {}
        for header in headers:
            canonical = self._header_lookup(header)
            if canonical and canonical not in mapped:
                mapped[canonical] = header

        missing = self._REQUIRED_FIELDS - set(mapped.keys())
        if missing:
            required = ", ".join(sorted(self._REQUIRED_FIELDS))
            raise ValueError(f"CSV must include columns: {required}.")

        return mapped

    def _parse_csv(self, text: str) -> Tuple[List[Dict[str, str | int]], List[str]]:
        buffer = io.StringIO(text)
        reader = csv.DictReader(buffer)

        if not reader.fieldnames:
            raise ValueError("The CSV file is missing a header row.")

        header_map = self._map_headers(reader.fieldnames)

        rows: List[Dict[str, str | int]] = []
        warnings: List[str] = []
        for index, row in enumerate(reader, start=2):
            mapped_row: Dict[str, str | int] = {"_row": index}
            for canonical, raw_header in header_map.items():
                value = row.get(raw_header, "")
                mapped_row[canonical] = value.strip() if isinstance(value, str) else value

            # Skip empty lines
            if all(v == "" for k, v in mapped_row.items() if k != "_row"):
                continue

            quantity_value = mapped_row.get("quantity", "")
            if quantity_value == "":
                mapped_row["quantity"] = 0
            else:
                try:
                    mapped_row["quantity"] = int(quantity_value)  # type: ignore[arg-type]
                except ValueError:
                    mapped_row["quantity"] = 0
                    warnings.append(
                        f"Row {index}: quantity '{quantity_value}' is invalid and was defaulted to 0."
                    )

            rows.append(mapped_row)

        if not rows:
            raise ValueError("No data rows found in the CSV file.")

        return rows, warnings

    @expose("/import", methods=["GET", "POST"])
    async def import_items(self, request: Request):
        errors: List[str] = []
        warnings: List[str] = []
        summary: Dict[str, int] | None = None

        if request.method == "POST":
            form = await request.form()
            upload: UploadFile | None = form.get("file")  # type: ignore[assignment]

            if not upload or not upload.filename:
                errors.append("Please choose a CSV file to upload.")
            else:
                try:
                    content = await upload.read()
                    text = content.decode("utf-8-sig")
                except UnicodeDecodeError:
                    errors.append("Could not decode the CSV file as UTF-8.")
                else:
                    try:
                        parsed_rows, warnings = self._parse_csv(text)
                    except ValueError as exc:  # Header or empty CSV issues
                        errors.append(str(exc))
                    else:
                        created = 0
                        updated = 0
                        skipped = 0

                        with Session(engine) as session:
                            for row in parsed_rows:
                                row_number = row.pop("_row")  # type: ignore[assignment]
                                barcode = str(row.get("barcode", "")).strip()
                                name = str(row.get("name", "")).strip()

                                if not barcode or not name:
                                    skipped += 1
                                    errors.append(
                                        f"Row {row_number}: missing required 'barcode' or 'name', skipped."
                                    )
                                    continue

                                description = row.get("description") or None
                                sku = row.get("sku") or None
                                image_url = row.get("image_url") or None
                                quantity = int(row.get("quantity", 0))

                                existing_item = session.exec(
                                    select(InventoryItem).where(InventoryItem.barcode == barcode)
                                ).first()

                                if existing_item:
                                    existing_item.name = name
                                    existing_item.description = description
                                    existing_item.sku = sku
                                    existing_item.image_url = image_url
                                    existing_item.quantity = quantity
                                    updated += 1
                                else:
                                    item = InventoryItem(
                                        name=name,
                                        barcode=barcode,
                                        description=description,
                                        quantity=quantity,
                                        sku=sku,
                                        image_url=image_url,
                                    )
                                    session.add(item)
                                    created += 1

                            session.commit()

                        summary = {"created": created, "updated": updated, "skipped": skipped}

        context = {
            "request": request,
            "model_view": self,
            "errors": errors,
            "warnings": warnings,
            "summary": summary,
            "required_headers": sorted(self._REQUIRED_FIELDS),
            "optional_headers": sorted(
                key for key in self._FIELD_ALIASES.keys() if key not in self._REQUIRED_FIELDS
            ),
        }

        return await self.templates.TemplateResponse(
            request, "sqladmin/import_inventory_items.html", context
        )


class TransactionAdmin(ModelView, model=Transaction):
    pass


def init_admin(app):
    templates_dir = Path(__file__).resolve().parent / "templates"
    admin = Admin(app, engine, templates_dir=str(templates_dir))

    admin.add_view(InventoryItemAdmin)
    admin.add_view(TransactionAdmin)
