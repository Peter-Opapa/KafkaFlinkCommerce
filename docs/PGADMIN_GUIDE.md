# pgAdmin Setup Guide for Kafka-Flink-Commerce Database

## Quick Start

1) Open pgAdmin at http://localhost:5050
2) Login:
- Email: admin@admin.com
- Password: admin

3) Register the Postgres server
- General > Name: Kafka Commerce DB
- Connection tab:
  - Host name/address: postgres
  - Port: 5432
  - Maintenance database: kafka_commerce
  - Username: postgres
  - Password: password
  - Save password: checked

Why use postgres and not localhost?
- pgAdmin runs in its own container; containers resolve each other by service/container name on the Docker network. localhost would reference the pgAdmin container itself.

## Browse the database

Servers
└── Kafka Commerce DB
    └── Databases
        └── kafka_commerce
            └── Schemas
                └── public
                    └── Tables
                        ├── transactions
                        ├── sales_per_category
                        ├── sales_per_day
                        └── sales_per_month

## Quick data views
- Right-click a table > View/Edit Data > All Rows

## Useful queries

-- All transactions (most recent first)
SELECT * FROM transactions ORDER BY "transactionDate" DESC;

-- Sales by category
SELECT * FROM sales_per_category ORDER BY total_sales DESC;

-- Recent summary
SELECT category, COUNT(*) AS cnt, SUM(amount) AS total_sales
FROM transactions
GROUP BY category
ORDER BY total_sales DESC;

-- Pipeline stats
SELECT
  (SELECT COUNT(*) FROM transactions) AS total_transactions,
  (SELECT SUM(total_sales) FROM sales_per_category) AS total_sales,
  (SELECT MAX("transactionDate") FROM transactions) AS latest_txn;

## Auto-refresh
- In Query Tool, click the circular arrow icon and set an interval (e.g., 5s) to auto-refresh results.

## Troubleshooting
- Cannot connect: ensure containers are up (docker ps) and host is postgres, not localhost.
- No data: verify Flink job is running (http://localhost:8081) and run python main.py to produce events.
