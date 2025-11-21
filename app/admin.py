from sqladmin import Admin, ModelView
from .models.inventory_item import InventoryItem
from .models.transaction import Transaction
from .database import engine


class InventoryItemAdmin(ModelView, model=InventoryItem):
    pass


class TransactionAdmin(ModelView, model=Transaction):
    pass


def init_admin(app):
    admin = Admin(app, engine)

    admin.add_view(InventoryItemAdmin)
    admin.add_view(TransactionAdmin)
