-- Flink SQL Pipeline: Kafka to PostgreSQL
-- This script defines the entire pipeline from source to sinks and executes the streaming inserts.

-- =============================================================================
--  1. Define Kafka Source Table
-- =============================================================================
CREATE TABLE financial_transactions_src (
    transactionId STRING,
    userId STRING,
    transactionType STRING,
    amount DOUBLE,
    currency STRING,
    transactionDate STRING, -- Keep as STRING to handle ISO 8601 format from producer
    category STRING,
    merchant STRING,
    location STRING,
    ts AS TO_TIMESTAMP(transactionDate, 'yyyy-MM-dd''T''HH:mm:ss'), -- computed event-time attribute
    WATERMARK FOR ts AS ts - INTERVAL '5' SECOND
) WITH (
    'connector' = 'kafka',
    'topic' = 'financial_transactions',
    'properties.bootstrap.servers' = 'broker:29092',
    'properties.group.id' = 'flink_consumer_group',
    'scan.startup.mode' = 'latest-offset',
    'format' = 'json',
    'json.ignore-parse-errors' = 'true'
);

-- =============================================================================
--  2. Define PostgreSQL Sink Tables
-- =============================================================================

-- Sink for raw transactions
CREATE TABLE transactions_sink (
    transactionId STRING,
    userId STRING,
    transactionType STRING,
    amount DOUBLE,
    currency STRING,
    transactionDate TIMESTAMP(3), -- Store as SQL TIMESTAMP for JDBC/Postgres compatibility
    category STRING,
    merchant STRING,
    location STRING,
    PRIMARY KEY (transactionId) NOT ENFORCED
) WITH (
   'connector' = 'jdbc',
   'url' = 'jdbc:postgresql://postgres:5432/kafka_commerce',
   'table-name' = 'transactions',
   'username' = 'postgres',
   'password' = 'password'
);

-- Sink for sales per category aggregation
CREATE TABLE sales_per_category_sink (
    category STRING,
    total_sales DOUBLE,
    PRIMARY KEY (category) NOT ENFORCED
) WITH (
   'connector' = 'jdbc',
   'url' = 'jdbc:postgresql://postgres:5432/kafka_commerce',
   'table-name' = 'sales_per_category',
   'username' = 'postgres',
   'password' = 'password'
);

-- Sink for sales per day aggregation
CREATE TABLE sales_per_day_sink (
    sale_day DATE,
    total_sales DOUBLE,
    PRIMARY KEY (sale_day) NOT ENFORCED
) WITH (
   'connector' = 'jdbc',
   'url' = 'jdbc:postgresql://postgres:5432/kafka_commerce',
   'table-name' = 'sales_per_day',
   'username' = 'postgres',
   'password' = 'password'
);

-- Sink for sales per month aggregation
CREATE TABLE sales_per_month_sink (
    year_num INT,
    month_num INT,
    total_sales DECIMAL(10, 2),
    PRIMARY KEY (year_num, month_num) NOT ENFORCED
) WITH (
    'connector' = 'jdbc',
    'url' = 'jdbc:postgresql://postgres:5432/kafka_commerce',
    'table-name' = 'sales_per_month',
    'username' = 'postgres',
    'password' = 'password'
);



-- =============================================================================
--  3. Define and Execute Streaming Insert Statements
-- =============================================================================
EXECUTE STATEMENT SET
BEGIN
    -- Insert raw, parsed transactions into the 'transactions' table
    INSERT INTO transactions_sink
    SELECT
        transactionId,
        userId,
        transactionType,
        amount,
        currency,
        TO_TIMESTAMP(transactionDate, 'yyyy-MM-dd''T''HH:mm:ss') AS transactionDate, -- parse STRING to TIMESTAMP for JDBC sink
        category,
        merchant,
        location
    FROM financial_transactions_src;

    -- Insert aggregated sales per category
    INSERT INTO sales_per_category_sink
    SELECT
        category,
        SUM(amount) AS total_sales
    FROM financial_transactions_src
    GROUP BY category;

    -- Insert aggregated sales per day
    INSERT INTO sales_per_day_sink
    SELECT
        CAST(ts AS DATE) AS sale_day,
        SUM(amount) AS total_sales
    FROM financial_transactions_src
    GROUP BY CAST(ts AS DATE);

    -- Insert aggregated sales per month
    INSERT INTO sales_per_month_sink
    SELECT
        CAST(EXTRACT(YEAR FROM ts) AS INT) AS year_num,
        CAST(EXTRACT(MONTH FROM ts) AS INT) AS month_num,
        CAST(SUM(amount) AS DECIMAL(10, 2)) AS total_sales
    FROM financial_transactions_src
    GROUP BY
        EXTRACT(YEAR FROM ts),
        EXTRACT(MONTH FROM ts);

    
END;