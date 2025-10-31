-- Create PostgreSQL tables for Kafka-Flink Commerce pipeline

-- Raw transactions table
CREATE TABLE IF NOT EXISTS transactions (
    transactionId VARCHAR(255) PRIMARY KEY,
    userId VARCHAR(255),
    transactionType VARCHAR(50),
    amount DOUBLE PRECISION,
    currency VARCHAR(10),
    transactionDate TIMESTAMP,
    category VARCHAR(100),
    merchant VARCHAR(255),
    location VARCHAR(255)
);

-- Sales per category aggregation
CREATE TABLE IF NOT EXISTS sales_per_category (
    category VARCHAR(100) PRIMARY KEY,
    total_sales DOUBLE PRECISION
);

-- Sales per day aggregation
CREATE TABLE IF NOT EXISTS sales_per_day (
    sale_day DATE PRIMARY KEY,
    total_sales DOUBLE PRECISION
);

-- Sales per month aggregation
CREATE TABLE IF NOT EXISTS sales_per_month (
    year_num INTEGER,
    month_num INTEGER,
    total_sales DECIMAL(10, 2),
    PRIMARY KEY (year_num, month_num)
);
