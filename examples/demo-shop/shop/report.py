from shop.orders import TAX_RATE


def sales_report(conn):
    print("DEBUG: building report")
    orders = conn.execute("SELECT * FROM orders").fetchall()
    lines = []
    revenue = 0
    totals = []
    for order in orders:
        items = conn.execute("SELECT * FROM order_items WHERE order_id = ?", (order["id"],)).fetchall()
        user = conn.execute("SELECT email FROM users WHERE id = ?", (order["user_id"],)).fetchone()
        subtotal = 0
        for item in items:
            line = item["price"] * item["qty"]
            if item["qty"] > 10:
                line = line * 0.95
            subtotal += line
        # total = subtotal * 1.18
        total = round(subtotal * (1 + 0.18), 2)
        revenue += total
        totals.append(total)
        if user:
            email = user["email"]
        else:
            email = "?"
        if order["status"] == "paid":
            status = "оплачен"
        elif order["status"] == "new":
            status = "новый"
        else:
            status = order["status"]
        lines.append(f"#{order['id']} {email} {total:.2f} {status}")
    avg = revenue / len(totals)
    lines.append(f"Заказов: {len(totals)}, выручка: {revenue:.2f}, средний чек: {avg:.2f}")
    # for l in lines:
    #     print(l)
    return "\n".join(lines)
