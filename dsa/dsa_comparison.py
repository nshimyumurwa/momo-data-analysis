"""
DSA Integration: Linear Search vs Dictionary Lookup
====================================================
Compares the efficiency of two search strategies on the MoMo transaction dataset.

Run:
    python dsa/dsa_comparison.py
"""

import os
import sys
import time
import xml.etree.ElementTree as ET


# ──────────────────────────────────────────────
# Load Data
# ──────────────────────────────────────────────
XML_FILE = os.path.join(os.path.dirname(__file__), "..", "data", "modified_sms_v2.xml")


def load_transactions(filepath: str) -> list[dict]:
    """Parse the XML file and return a list of transaction dictionaries."""
    tree = ET.parse(filepath)
    root = tree.getroot()
    transactions: list[dict] = []

    for sms in root.findall("sms"):
        transactions.append(
            {
                "id": sms.get("id"),
                "transaction_type": sms.get("transaction_type"),
                "amount": float(sms.get("amount", 0)),
                "sender": sms.get("sender"),
                "receiver": sms.get("receiver"),
                "date": sms.get("date"),
                "currency": sms.get("currency", "RWF"),
                "status": sms.get("status", "completed"),
                "body": sms.get("body"),
            }
        )

    return transactions


# ──────────────────────────────────────────────────
# Method 1: Linear Search  O(n)
# ──────────────────────────────────────────────────

def linear_search(transactions: list[dict], transaction_id: str) -> dict | None:
    """
    Search a list of transactions sequentially.

    Time complexity: O(n) in the worst case because every transaction
    must be inspected until the matching ID is found or the list ends.
    """
    for transaction in transactions:
        if transaction["id"] == transaction_id:
            return transaction
    return None


# ──────────────────────────────────────────────────
# Method 2: Dictionary Lookup  O(1)
# ──────────────────────────────────────────────────

def build_transaction_dict(transactions: list[dict]) -> dict[str, dict]:
    """Build a dictionary keyed by transaction ID from the parsed list."""
    return {transaction["id"]: transaction for transaction in transactions}


def dictionary_lookup(transaction_dict: dict[str, dict], transaction_id: str) -> dict | None:
    """
    Retrieve the transaction directly by dictionary key.

    Average time complexity is O(1) because dictionary access uses hashing.
    """
    return transaction_dict.get(transaction_id)


# ──────────────────────────────────────────────────
# Benchmark
# ──────────────────────────────────────────────────

def benchmark(
    transactions: list[dict],
    transaction_dict: dict[str, dict],
    transaction_id: str,
    repetitions: int = 100_000,
) -> tuple[float, float]:
    """Benchmark both search methods and return average microsecond timings."""
    linear_search(transactions, transaction_id)
    dictionary_lookup(transaction_dict, transaction_id)

    start = time.perf_counter()
    for _ in range(repetitions):
        linear_search(transactions, transaction_id)
    linear_time = (time.perf_counter() - start) / repetitions * 1_000_000

    start = time.perf_counter()
    for _ in range(repetitions):
        dictionary_lookup(transaction_dict, transaction_id)
    dict_time = (time.perf_counter() - start) / repetitions * 1_000_000

    return linear_time, dict_time


def format_transaction(transaction: dict | None) -> str:
    """Format a transaction record for display, handling missing values."""
    if transaction is None:
        return "Transaction not found"

    return (
        f"ID={transaction['id']}, type={transaction['transaction_type']}, "
        f"amount={transaction['amount']} {transaction['currency']}, "
        f"sender={transaction['sender']}, receiver={transaction['receiver']}"
    )


def main() -> None:
    transactions = load_transactions(XML_FILE)
    transaction_dict = build_transaction_dict(transactions)
    target_id = sys.argv[1] if len(sys.argv) > 1 else "25"
    repetitions = 100_000

    print("=" * 68)
    print("  MoMo DSA Comparison: Linear Search vs Dictionary Lookup")
    print("=" * 68)
    print(f"Loaded {len(transactions)} transactions from XML dataset.")
    print(f"Benchmarking each search method {repetitions} times for transaction ID: {target_id}\n")

    linear_time, dict_time = benchmark(transactions, transaction_dict, target_id, repetitions)

    print("Search Complexity:")
    print("  Linear search     : O(n)")
    print("  Dictionary lookup : O(1) average")
    print()

    print("Benchmark Results (average time per lookup):")
    print(f"  Linear search       : {linear_time:.4f} µs")
    print(f"  Dictionary lookup   : {dict_time:.4f} µs")
    print(f"  Speedup             : {linear_time / dict_time:.1f}x")

    print("\nLookup output:")
    print(f"  Linear search       : {format_transaction(linear_search(transactions, target_id))}")
    print(f"  Dictionary lookup   : {format_transaction(dictionary_lookup(transaction_dict, target_id))}")

    print("\nConclusion:")
    if dict_time < linear_time:
        print("  Dictionary lookup performs better because it avoids scanning the entire list.")
    else:
        print("  Linear search may appear competitive on this small dataset, but dictionary lookup scales far better.")
    print("  For repeated transaction retrieval by ID, dictionary lookup is the preferred approach.")


if __name__ == "__main__":
    main()
