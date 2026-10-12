import os
import sqlite3

DB_PATH = os.environ.get("SHOP_DB", "shop.db")


def connect(path=None):
    conn = sqlite3.connect(path or DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db(conn):
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY,
            email TEXT,
            password_hash TEXT
        );
        CREATE TABLE IF NOT EXISTS products (
            sku TEXT PRIMARY KEY,
            title TEXT,
            price REAL
        );
        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY,
            user_id INTEGER,
            total REAL,
            status TEXT
        );
        CREATE TABLE IF NOT EXISTS order_items (
            id INTEGER PRIMARY KEY,
            order_id INTEGER,
            sku TEXT,
            qty INTEGER,
            price REAL
        );
        """
    )
    conn.commit()


def seed_products(conn):
    products = [("SKU-1", "Кружка", 450.0), ("SKU-2", "Футболка", 1290.0), ("SKU-3", "Блокнот", 199.9)]
    conn.executemany("INSERT OR IGNORE INTO products VALUES (?, ?, ?)", products)
    conn.commit()
