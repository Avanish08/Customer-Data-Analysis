import pandas as pd
import numpy as np
import sqlite3

np.random.seed(7)

n_customers = 800
cities = ["Mumbai", "Delhi", "Bengaluru", "Pune", "Hyderabad", "Chennai", "Kolkata"]
segments = ["Consumer", "Small Business", "Enterprise"]

customers = pd.DataFrame({
    "CustomerID": range(1, n_customers + 1),
    "City": np.random.choice(cities, n_customers, p=[0.22, 0.18, 0.16, 0.12, 0.12, 0.10, 0.10]),
    "Segment": np.random.choice(segments, n_customers, p=[0.65, 0.25, 0.10]),
    "SignupDate": pd.to_datetime("2022-01-01") + pd.to_timedelta(np.random.randint(0, 700, n_customers), unit="D"),
})

# introduce some messiness on purpose, for the "cleaning" step to be real
customers.loc[np.random.choice(n_customers, 8, replace=False), "City"] = None
customers.loc[np.random.choice(n_customers, 10, replace=False), "City"] = "  mumbai "

n_tx = 9000
# Most customers transact a handful of times; a smaller "power user" tail transacts a lot more.
# Lognormal gives a realistic, moderately skewed spread without starving the majority of customers.
weights = np.random.lognormal(mean=0.0, sigma=0.9, size=n_customers)
weights = weights / weights.sum()
cust_ids = np.random.choice(customers.CustomerID, n_tx, p=weights)
tx = pd.DataFrame({
    "TransactionID": range(1, n_tx + 1),
    "CustomerID": cust_ids,
    "TransactionDate": pd.to_datetime("2023-01-01") + pd.to_timedelta(np.random.randint(0, 700, n_tx), unit="D"),
    "Amount": np.round(np.random.gamma(3.5, 28, n_tx), 2),
    "Category": np.random.choice(["Subscription", "One-time Purchase", "Add-on", "Refund"], n_tx, p=[0.5, 0.3, 0.15, 0.05]),
})
tx.loc[tx.Category == "Refund", "Amount"] = -tx.loc[tx.Category == "Refund", "Amount"]
# duplicate a few rows on purpose (realistic messiness)
dupes = tx.sample(25, random_state=1)
tx = pd.concat([tx, dupes], ignore_index=True)
# a few nulls
tx.loc[np.random.choice(tx.index, 20, replace=False), "Amount"] = None

customers.to_csv("customers_raw.csv", index=False)
tx.to_csv("transactions_raw.csv", index=False)

conn = sqlite3.connect("customer_data.db")
customers.to_sql("customers_raw", conn, if_exists="replace", index=False)
tx.to_sql("transactions_raw", conn, if_exists="replace", index=False)
conn.close()
print("customers:", len(customers), "| transactions:", len(tx))
