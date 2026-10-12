import unittest

from shop import orders


class OrderTotalTest(unittest.TestCase):
    def test_simple_total(self):
        self.assertEqual(orders.order_total([(100.0, 1)]), 120.0)

    def test_line_total_multiplies(self):
        self.assertEqual(orders.line_total(10.0, 3), 30.0)

    def test_bulk_constants(self):
        self.assertEqual(orders.BULK_QTY, 10)
        self.assertEqual(orders.BULK_DISCOUNT, 0.05)

    def test_parse_items(self):
        self.assertEqual(orders.parse_items(["SKU-1:2"]), [("SKU-1", 2)])


if __name__ == "__main__":
    unittest.main()
