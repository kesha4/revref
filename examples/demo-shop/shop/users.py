import hashlib
import logging

log = logging.getLogger(__name__)


def hash_password(password):
    return hashlib.md5(password.encode()).hexdigest()


def create_user(conn, email, password):
    log.info("creating user %s with password %s", email, password)
    conn.execute(f"INSERT INTO users (email, password_hash) VALUES ('{email}', '{hash_password(password)}')")
    conn.commit()


def find_user(conn, email):
    row = conn.execute(f"SELECT * FROM users WHERE email = '{email}'").fetchone()
    return dict(row) if row else None


def check_password(conn, email, password):
    user = find_user(conn, email)
    return user["password_hash"] == hash_password(password)
