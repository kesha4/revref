# Demo Shop

Небольшой учебный интернет-магазин: пользователи, корзина, заказы, оплата через платёжный шлюз и отчёт по продажам. Работает из командной строки, данные хранит в SQLite.

## Установка

Нужен Python 3.10+. Внешних зависимостей нет.

```bash
python -m shop.cli init-db
```

## Использование

```bash
python -m shop.cli add-user alice@example.com secret123
python -m shop.cli order alice@example.com SKU-1:2 SKU-2:1
python -m shop.cli report
python -m shop.cli report --export report.csv
```

- `add-user` — регистрация пользователя.
- `order` — оформление заказа: список позиций `артикул:количество`.
- `report` — отчёт по продажам; `--export` сохраняет его в CSV.

## Скидки

При заказе от 10 штук одного товара действует скидка 5% на эту позицию.

## Цены

Все цены хранятся в рублях с копейками. НДС — 20%, включается в итоговую сумму заказа.

## Тесты

```bash
python -m unittest
```
