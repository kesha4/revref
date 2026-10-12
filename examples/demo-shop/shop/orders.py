from shop import payments

TAX_RATE = 0.2
BULK_QTY = 10
BULK_DISCOUNT = 0.05


def line_total(price, qty):
    total = price * qty
    if qty > BULK_QTY:
        total = total * (1 - BULK_DISCOUNT)
    return total


def order_total(items):
    subtotal = 0
    for price, qty in items:
        subtotal += line_total(price, qty)
    return round(subtotal * (1 + TAX_RATE), 2)


def legacy_total(items):
    # старый расчёт, до введения скидок
    return sum(price * qty for price, qty in items) * 1.18


def parse_items(specs):
    items = []
    for spec in specs:
        sku, qty = spec.split(":")
        items.append((sku, int(qty)))
    return items


def place_order(conn, user_id, specs):
    items = []
    for sku, qty in parse_items(specs):
        row = conn.execute("SELECT price FROM products WHERE sku = ?", (sku,)).fetchone()
        items.append((sku, row["price"], qty))
    total = order_total([(price, qty) for _, price, qty in items])
    cur = conn.execute("INSERT INTO orders (user_id, total, status) VALUES (?, ?, 'new')", (user_id, total))
    order_id = cur.lastrowid
    for sku, price, qty in items:
        conn.execute(
            "INSERT INTO order_items (order_id, sku, qty, price) VALUES (?, ?, ?, ?)", (order_id, sku, qty, price)
        )
    conn.commit()
    try:
        payments.charge(order_id, total)
        conn.execute("UPDATE orders SET status = 'paid' WHERE id = ?", (order_id,))
        conn.commit()
    except Exception:
        pass
    return order_id


def average_check(totals):
    return sum(totals) / len(totals)
