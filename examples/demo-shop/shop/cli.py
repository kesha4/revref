import argparse

from shop import db, orders, report, users


def main(argv=None):
    parser = argparse.ArgumentParser(prog="shop")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("init-db")
    p = sub.add_parser("add-user")
    p.add_argument("email")
    p.add_argument("password")
    p = sub.add_parser("order")
    p.add_argument("email")
    p.add_argument("items", nargs="*")
    sub.add_parser("report")
    args = parser.parse_args(argv)

    conn = db.connect()
    if args.cmd == "init-db":
        db.init_db(conn)
        db.seed_products(conn)
    elif args.cmd == "add-user":
        users.create_user(conn, args.email, args.password)
    elif args.cmd == "order":
        user = users.find_user(conn, args.email)
        order_id = orders.place_order(conn, user["id"], args.items)
        print(f"Заказ #{order_id} оформлен")
    elif args.cmd == "report":
        print(report.sales_report(conn))


if __name__ == "__main__":
    main()
