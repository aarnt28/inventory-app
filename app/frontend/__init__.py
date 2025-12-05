from pathlib import Path

from fastapi import APIRouter, FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

FRONTEND_DIR = Path(__file__).parent
STATIC_DIR = FRONTEND_DIR / "static"
TEMPLATES_DIR = FRONTEND_DIR / "templates"

router = APIRouter()
templates = Jinja2Templates(directory=str(TEMPLATES_DIR))


@router.get("/", response_class=HTMLResponse)
def serve_index(request: Request):
    """
    Serve the main frontend shell. Assets are mounted under /assets.
    """
    return templates.TemplateResponse("index.html", {"request": request})


def init_frontend(app: FastAPI) -> None:
    """
    Mount static assets and expose the root route without affecting /admin.
    """
    app.mount("/assets", StaticFiles(directory=str(STATIC_DIR)), name="assets")
    app.include_router(router)
