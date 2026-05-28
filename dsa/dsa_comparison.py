"""
DSA Integration: Linear Search vs Dictionary Lookup
====================================================
Compares the efficiency of two search strategies on the MoMo transaction dataset.

Run:
    python dsa/dsa_comparison.py
"""

import xml.etree.ElementTree as ET
import time
import os
import sys

# ──────────────────────────────────────────────
# Load Data
# ──────────────────────────────────────────────
XML_FILE = os.path.join(os.path.dirname(__file__), "..", "data", "modified_sms_v2.xml")

def load_transactions(filepath):
    transactions = []
    tree = ET.parse(filepath)
    root = tree.getroot()
    for sms in root.findall("sms"):
        transactions.append({
            "id": sms.get("id"),
            "transaction_type": sms.get("transaction_type"),
            "amount": float(sms.get("amount", 0)),
            "sender": sms.get("sender"),
            "receiver": sms.get("receiver"),
            "date": sms.get("date"),
            "currency": sms.get("currency", "RWF"),
            "status": sms.get("status", "completed"),
            "body": sms.get("body"),
        })
    return transactions


# ──────────────────────────────────────────────
# Method 1: Linear Search  O(n)
# ──────────────────────────────────────────────
def linear_search(transactions: list, target_id: str) -> dict | None:
    """
    Scan through every element in the list one by one.
    Time complexity : O(n) – worst case scans all n records
    Space complexity: O(1) – no extra storage needed
    """
    for txn in transactions:
        if txn["id"] == target_id:
            return txn
    return None


# ──────────────────────────────────────────────
# Method 2: Dictionary Lookup  O(1)
# ──────────────────────────────────────────────
def build_dict(transactions: list) -> dict:
    """Build a dictionary mapping id → transaction (one-time O(n) cost)."""
    return {t["id"]: t for t in transactions}

def dict_lookup(txn_dict: dict, target_id: str) -> dict | None:
    """
    Direct key access in a hash map.
    Time complexity : O(1) average – hash function maps key to bucket instantly
    Space complexity: O(n) – stores all records in the dict
    """
    return txn_dict.get(target_id)


# ──────────────────────────────────────────────
# Benchmark
# ──────────────────────────────────────────────
def benchmark(transactions: list, txn_dict: dict, target_id: str, repetitions: int = 100_000):
    """Run each method `repetitions` times and report average time in microseconds."""

    # Warm-up
    linear_search(transactions, target_id)
    dict_lookup(txn_dict, target_id)

    # Linear search timing
    start = time.perf_counter()
    for _ in range(repetitions):
        linear_search(transactions, target_id)
    linear_elapsed = (time.perf_counter() - start) / repetitions * 1_000_000  # µs

    # Dict lookup timing
    start = time.perf_counter()
    for _ in range(repetitions):
        dict_lookup(txn_dict, target_id)
    dict_elapsed = (time.perf_counter() - start) / repetitions * 1_000_000  # µs

    return linear_elapsed, dict_elapsed


# ──────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────
if __name__ == "__main__":
    print("=" * 60)
    print("  MoMo DSA: Linear Search vs Dictionary Lookup")
    print("=" * 60)

    transactions = load_transactions(XML_FILE)
    txn_dict = build_dict(transactions)
    n = len(transactions)
    print(f"\nLoaded {n} transactions.\n")

    test_cases = [
        ("1",   "Best case  (first record)"),
        ("13",  "Middle case (record 13/25)"),
        ("25",  "Worst case (last record)"),
        ("99",  "Miss case  (ID not found)"),
    ]

    print(f"{'Target ID':<12} {'Scenario':<32} {'Linear (µs)':<15} {'Dict (µs)':<15} {'Speedup'}")
    print("-" * 85)

    results = []
    for tid, label in test_cases:
        lin_t, dict_t = benchmark(transactions, txn_dict, tid)
        speedup = lin_t / dict_t if dict_t > 0 else float("inf")
        print(f"{tid:<12} {label:<32} {lin_t:<15.4f} {dict_t:<15.4f} {speedup:.1f}x")
        results.append((tid, label, lin_t, dict_t, speedup))

    print("\n")
    print("=" * 60)
    print("  Verification – results are correct:")
    print("=" * 60)
    for tid, _, _, _, _ in results:
        linear_result = linear_search(transactions, tid)
        dict_result   = dict_lookup(txn_dict, tid)
        match = linear_result == dict_result
        found = f"Found: {linear_result['transaction_type']} {linear_result['amount']} RWF" if linear_result else "Not found"
        print(f"  ID {tid:>3}: {found}  |  Results match: {match}")

    print("\n")
    print("=" * 60)
    print("  Reflection")
    print("=" * 60)
    print("""
WHY DICTIONARY LOOKUP IS FASTER:
─────────────────────────────────
Linear search works by checking each element one at a time until
it finds a match. In the worst case (last element or not found),
it must inspect all n records → O(n) time.

A Python dictionary is implemented as a hash table. When you look
up a key, Python computes a hash of the key in O(1) time and jumps
directly to the correct memory location — no scanning needed.

The trade-off is memory: the dictionary stores all records twice
(once in the list, once in the dict), giving O(n) space complexity.

ALTERNATIVE DATA STRUCTURES:
──────────────────────────────
• Binary Search Tree (BST): O(log n) search on sorted data.
  Useful when records are frequently added/removed in sorted order.

• B-Tree (used in databases): Balanced, handles disk-based storage
  efficiently for very large datasets.

• Trie (Prefix Tree): Excellent for prefix-based searches such as
  finding all transactions by a sender whose number starts with "078".

For this dataset size (25–thousands of records), the dictionary
(hash map) is the optimal choice: O(1) average lookup with very
low overhead.
""")
