# pgAdmin Setup Guide for Kafka-Flink-Commerce Database

## 🚀 Quick Start Guide

### Step 1: Access pgAdmin
1. Open your browser and go to: **http://localhost:5050**
2. Login with these credentials:
   - **Email:** admin@admin.com
   - **Password:** admin

### Step 2: Add PostgreSQL Server Connection

1. **Click "Add New Server"** (or right-click "Servers" → "Register" → "Server")

2. **General Tab:**
   - **Name:** Kafka Commerce DB (or any name you prefer)

3. **Connection Tab:**
   - **Host name/address:** `postgres` ⚠️ **IMPORTANT: Use `postgres` NOT `localhost`!**
   - **Port:** `5432`
   - **Maintenance database:** `kafka_commerce`
   - **Username:** `postgres`
   - **Password:** `Opapa@1292`
   - ✅ Check "Save password"
   
   **Why `postgres` and not `localhost`?**
   - pgAdmin runs inside a Docker container
   - Docker containers use container names as hostnames
   - `postgres` is your PostgreSQL container's name
   - `localhost` would look inside pgAdmin's container (wrong!)

4. Click **Save**

### Step 3: Navigate to Your Database

After connecting, you'll see this hierarchy:
```
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
```

### Step 4: View Real-Time Data

#### Option A: Quick View (Right-click menu)
1. Right-click on any table (e.g., `transactions`)
2. Select **View/Edit Data** → **All Rows**
3. Data refreshes automatically!

#### Option B: Custom Queries
1. Click on **Tools** → **Query Tool** (or click the SQL icon)
2. Write your queries, for example:

```sql
-- View all transactions
SELECT * FROM transactions ORDER BY transactionDate DESC;

-- View sales by category
SELECT * FROM sales_per_category ORDER BY total_sales DESC;

-- View recent transactions with totals
SELECT 
    category,
    COUNT(*) as count,
    SUM(amount) as total_sales
FROM transactions 
GROUP BY category
ORDER BY total_sales DESC;

-- Real-time stats
SELECT 
    COUNT(*) as total_transactions,
    SUM(amount) as total_sales,
    AVG(amount) as avg_transaction_value,
    MIN(transactionDate) as first_transaction,
    MAX(transactionDate) as last_transaction
FROM transactions;
```

3. Click **Execute (F5)** or press the ▶️ button

### Step 5: Set Up Auto-Refresh Dashboard

1. Write your query in the Query Tool
2. Click the **Auto-refresh** button (⟳ icon) in the toolbar
3. Set refresh interval (e.g., 5 seconds)
4. Your data will update automatically!

### Step 6: Create a Custom Dashboard View

1. In Query Tool, write a comprehensive query:

```sql
-- Dashboard Query
SELECT 'Total Transactions' as metric, COUNT(*)::text as value FROM transactions
UNION ALL
SELECT 'Total Sales ($)', ROUND(SUM(amount)::numeric, 2)::text FROM transactions
UNION ALL
SELECT 'Average Transaction ($)', ROUND(AVG(amount)::numeric, 2)::text FROM transactions
UNION ALL
SELECT 'Categories', COUNT(DISTINCT category)::text FROM transactions
UNION ALL
SELECT 'Latest Transaction', MAX(transactionDate)::text FROM transactions;
```

2. Enable auto-refresh for live updates

### 📊 Useful Features

#### View Table Structure
- Right-click table → **Properties**
- See columns, constraints, indexes, etc.

#### Export Data
- Right-click table → **Import/Export**
- Export to CSV, JSON, etc.

#### Visual Explain
- Write a query
- Click **Explain** → **Explain Analyze**
- See query performance visualization

#### Monitor Connections
- Navigate to: **Server** → **Dashboard**
- See active sessions, transactions, database statistics

### 🔄 Auto-Refresh Queries for Monitoring

Create these queries and set them to auto-refresh:

**Query 1: Latest 10 Transactions**
```sql
SELECT 
    transactionId,
    userId,
    transactionType,
    amount,
    currency,
    transactionDate,
    category,
    merchant
FROM transactions 
ORDER BY transactionDate DESC 
LIMIT 10;
```

**Query 2: Sales Summary by Category**
```sql
SELECT * FROM sales_per_category ORDER BY total_sales DESC;
```

**Query 3: Daily Trends**
```sql
SELECT * FROM sales_per_day ORDER BY sale_day DESC;
```

**Query 4: Real-time Statistics**
```sql
SELECT 
    (SELECT COUNT(*) FROM transactions) as total_txns,
    (SELECT COUNT(*) FROM sales_per_category) as categories,
    (SELECT SUM(total_sales) FROM sales_per_category) as total_sales,
    (SELECT MAX(transactionDate) FROM transactions) as last_txn,
    NOW() as refresh_time;
```

### 💡 Tips

1. **Multiple Query Tabs:** Open multiple Query Tool tabs for different views
2. **Save Queries:** File → Save to save your favorite queries
3. **Keyboard Shortcuts:**
   - F5: Execute query
   - F7: Execute single query at cursor
   - Ctrl+Space: Auto-complete
4. **Graph Data:** Use the **Graph** tab to visualize query results
5. **Quick Filter:** In data view, use the filter icon to search data

### 🎯 Quick Access URLs

- **pgAdmin Interface:** http://localhost:5050
- **Flink Dashboard:** http://localhost:8081
- **Kibana (if using):** http://localhost:5601

---

## 🔧 Troubleshooting

**Can't connect to server?**
- Make sure both containers are running: `docker ps`
- Use hostname `postgres` NOT `localhost` (containers communicate via Docker network)

**Password not saving?**
- Try manually entering it each time
- Check "Save password" box

**Data not updating?**
- Check Flink job is running: http://localhost:8081
- Run `python main.py` to produce new transactions
- Verify Kafka has messages: `docker exec broker kafka-console-consumer --bootstrap-server localhost:9092 --topic financial_transactions --from-beginning --max-messages 1`

---

Enjoy monitoring your real-time data pipeline! 🚀
