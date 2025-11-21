from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from .database import init_db
from .admin import init_admin
from .routers import items, transactions
from .utils.paths import resolve_upload_dir

app = FastAPI()

# Ensure upload directory exists and serve it for previews
upload_dir = resolve_upload_dir()
app.mount("/uploads", StaticFiles(directory=upload_dir), name="uploads")


@app.on_event("startup")
def on_startup():
    init_db()
    init_admin(app)


app.include_router(items.router, prefix="/api/items")
app.include_router(transactions.router, prefix="/api/transactions")
