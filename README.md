# SokoMart Kenya — Advanced SQL Practical Project

**LuxDevHQ | Cohort 9 | Advanced SQL**

## Project Overview

SokoMart Kenya is a retail business database project developed to demonstrate practical and advanced SQL skills using PostgreSQL. The project focuses on querying, analysing, managing, and improving a relational database for a retail business.

The practical work covers foundational SQL, window functions, stored procedures, triggers, materialized views, query optimisation, transaction management, data cleaning, and customer retention analysis.

The project uses a simulated retail dataset containing customers, products, orders, order items, payments, and supporting operational tables.

## Technology Stack

- **Database:** PostgreSQL 18.6
- **SQL environment:** DBeaver
- **Version control:** Git and GitHub
- **Operating system:** Windows
- **Repository:** [4688-tori/soko-mart](https://github.com/4688-tori/soko-mart)

## Database Information

| Item | Details |
|---|---|
| Database | `luxdevhq_cohort9_advanced_sql` |
| Schema | `sokomart` |
| Database engine | PostgreSQL 18.6 |
| SQL client | DBeaver |

### Main Database Tables

- `customers` — customer details and county information.
- `products` — product information, categories, prices, costs, and stock quantities.
- `orders` — customer orders, dates, statuses, and order totals.
- `order_items` — products, quantities, and line totals within orders.
- `payments` — payment information and transaction records.
- `payment_staging` — imported payment records used for data-cleaning exercises.
- `product_price_history` — product price history.
- `audit_logs` — records of database changes.
- `order_status_history` — records changes to order statuses.

## Project Objectives

1. Apply SQL to retrieve, filter, aggregate, and analyse retail data.
2. Use window functions to evaluate customer spending, product performance, and revenue trends.
3. Develop stored procedures and triggers to automate database operations.
4. Create and use materialized views for reporting.
5. Evaluate query execution plans and improve query performance through indexing.
6. Apply transactions, savepoints, commits, and rollbacks to protect data integrity.
7. Identify and remove duplicate records while preserving valid data.
8. Analyse customer purchasing behaviour and retention.
9. Communicate findings through quantified business insights and recommendations.

---

# Project Progress

## Day 1 — Section A: Foundational SQL and Data Analysis

**Questions:** Q1–Q5

Day 1 focused on foundational SQL techniques, including Common Table Expressions (CTEs), subqueries, aggregation, joins, filtering, and `NOT EXISTS`.

The exercises applied these techniques to customer spending, product pricing, monthly profitability, customer purchasing behaviour, and product ordering activity.

### Q1 — Big Spenders of 2025

**Business question:** Which customers spent more than the average amount spent by customers who made completed purchases in 2025?

The query:

- Calculates each customer's total completed-order spending in 2025.
- Combines customer details with order and order-item records.
- Uses a CTE to calculate individual customer spending.
- Calculates the average spending across customers who purchased during 2025.
- Returns customers whose spending exceeded that average.
- Calculates the amount each qualifying customer spent above the average.

A separate summary query reports the number of customers who purchased, the average customer spending, and the number of customers above the average.

**Key SQL concepts:** CTEs, `SUM()`, `AVG()`, `CROSS JOIN`, `ROUND()`, aggregation and filtering.

### Q2 — Premium Products

**Business question:** Which active products are priced above the average price of products in their respective categories?

The query:

- Examines active products.
- Uses correlated subqueries to calculate the average unit price within each product's category.
- Identifies products priced above their category average.
- Calculates the difference between each product's price and its category average.
- Orders the results by category and price gap.

A separate summary query counts the number of premium products in each category.

**Key SQL concepts:** Correlated subqueries, `AVG()`, `ROUND()`, `GROUP BY`, aggregate functions.

### Q3 — Monthly P&L for January to October 2026

**Business question:** What are the monthly revenue, product cost, gross profit, and gross margin for completed orders between January and October 2026?

The query:

- Retrieves completed orders within the specified date range.
- Calculates revenue using order-item line totals.
- Calculates product cost using quantity multiplied by product cost price.
- Aggregates revenue and cost by calendar month.
- Calculates gross profit as revenue minus cost.
- Calculates gross margin as a percentage of revenue.
- Uses `NULLIF()` to protect against division by zero.
- Formats the reporting month as `YYYY-MM`.

**Key SQL concepts:** CTEs, joins, `DATE_TRUNC()`, `SUM()`, `NULLIF()`, `ROUND()` and financial calculations.

### Q4 — Nakuru Cross-Category Shoppers

**Business question:** Which customers from Nakuru have purchased products from at least three distinct product categories?

The query:

- Joins customers, orders, order items, and products.
- Includes completed orders.
- Calculates the number of distinct product categories purchased by each customer.
- Calculates each qualifying customer's total spending.
- Filters for customers whose county is Nakuru and who purchased from at least three categories.
- Orders customers by category count and total spending.

A separate summary query reports the number of qualifying customers and the number who purchased from all five product categories.

**Key SQL concepts:** Subqueries in the `FROM` clause, multi-table joins, `COUNT(DISTINCT ...)`, `GROUP BY`, `HAVING`, conditional aggregation using `FILTER`.

### Q5 — Products Never Ordered

**Business question:** Which products have never appeared in any order item?

The query:

- Examines the products table.
- Uses a correlated `NOT EXISTS` subquery to check whether each product has ever appeared in `order_items`.
- Returns products for which no matching order-item record exists.
- Displays product ID, product name, category, product status, stock quantity, and creation date.
- Orders the results by category and product name.

**Key SQL concepts:** `NOT EXISTS`, correlated subqueries, filtering and sorting.

### Day 1 Learning Outcomes

The exercises demonstrated how SQL can be used to:

- Identify high-value customers through spending comparisons.
- Evaluate product pricing against category averages.
- Produce monthly profit-and-loss summaries.
- Identify customers purchasing across multiple product categories.
- Detect products that have never been ordered.
- Combine CTEs, subqueries, joins, and aggregate functions to answer business questions.

**Deliverables:** Day 1 SQL exercises and supporting screenshots.

---

## Day 2 — Section B: Window Functions

**SQL file:** `sql/02_section_b.sql`

**Questions:** Q6–Q10

Day 2 focused on PostgreSQL window functions and their application to retail business analysis. The queries examined customer rankings, product performance, monthly revenue growth, customer order comparisons, and cumulative revenue.

### Q6 — County Leaderboards

**Business question:** Which three customers have the highest lifetime completed-order revenue in each county?

The query:

- Calculates each customer's lifetime revenue using `SUM(order_items.line_total)`.
- Uses `LEFT JOIN` to retain customers who have no completed orders.
- Uses `COALESCE` to return zero for customers without completed-order revenue.
- Constructs customer names by combining first and last names.
- Applies `DENSE_RANK()` partitioned by county.
- Returns customers with a county rank of three or better.

**Key SQL concepts:** `LEFT JOIN`, `COALESCE`, `SUM()`, `DENSE_RANK()`, `PARTITION BY`.

### Q7 — Best Sellers per Category, 2025

**Business question:** Which three products generated the highest revenue in each product category during 2025?

The query:

- Joins products, order items, and orders.
- Includes completed orders dated from 1 January 2025 up to, but not including, 1 January 2026.
- Calculates product revenue using `SUM(line_total)`.
- Calculates units sold using `SUM(quantity)`.
- Uses `ROW_NUMBER()` partitioned by category.
- Ranks products by revenue in descending order, with `product_id` as the tie-breaker.
- Returns the top three products in each category.

**Key SQL concepts:** Multi-table joins, aggregation, half-open date ranges, `ROW_NUMBER()`, `PARTITION BY`.

### Q8 — Month-over-Month Revenue Growth

**Business question:** How did completed-order revenue change from one month to the next between January 2025 and October 2026?

The query:

- Generates a continuous calendar of months using `GENERATE_SERIES()`.
- Aggregates completed-order revenue by calendar month.
- Uses a `LEFT JOIN` to retain months without sales.
- Uses `COALESCE` to represent months without revenue as zero.
- Applies `LAG()` to retrieve the previous month's revenue.
- Calculates percentage growth using `NULLIF()` to avoid division by zero.
- Formats month labels as `YYYY-MM`.

**Key SQL concepts:** `GENERATE_SERIES()`, `DATE_TRUNC()`, `TO_CHAR()`, `LAG()`, `COALESCE`, `NULLIF()`.

### Q9 — Is Each Order Bigger Than the Last?

**Business question:** Are customers from Nyeri spending more or less on each successive completed order in 2026?

The query:

- Filters customers whose county is Nyeri.
- Includes completed orders dated from 1 January 2026 up to, but not including, 1 January 2027.
- Uses `LAG()` partitioned by customer ID to retrieve each customer's previous order amount.
- Calculates the difference between the current and previous order amounts.
- Classifies each order as `first order`, `up`, `down`, or `same`.

A separate summary query calculates:

- Total order records.
- Number of distinct customers.
- Number of first orders.
- Number of orders larger than the previous order.
- Number of orders smaller than the previous order.

**Key SQL concepts:** `LAG()`, `PARTITION BY`, `CASE`, conditional aggregation using `FILTER`.

### Q10 — Year-to-Date Revenue

**Business question:** What is the monthly revenue, the cumulative revenue within each year, and the cumulative revenue across the entire reporting period?

The query:

- Generates calendar months from January 2025 to October 2026.
- Calculates completed-order revenue for each month.
- Retains months without sales and assigns them zero revenue.
- Uses a windowed `SUM()` partitioned by year to calculate year-to-date revenue.
- Uses a second windowed `SUM()` without a year partition to calculate all-time running revenue.
- Defines explicit window frames using `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`.

**Key SQL concepts:** `GENERATE_SERIES()`, `DATE_TRUNC()`, `EXTRACT()`, `SUM() OVER()`, `PARTITION BY`, explicit window frames.

### Day 2 Learning Outcomes

The exercises demonstrated how window functions can support business analysis without collapsing individual records into a single aggregate row.

The work covered:

- Ranking customers within geographical groups.
- Identifying top-performing products within categories.
- Comparing monthly revenue using previous-period values.
- Evaluating changes in individual customer order values.
- Calculating year-to-date and all-time cumulative revenue.
- Handling missing months and zero revenue safely.

**Deliverables:** `sql/02_section_b.sql` and supporting query-result screenshots.

---

## Day 3 — Sections C and D: Advanced SQL and Database Automation

**SQL files:**
- `sql/03_section_c.sql`
- `sql/04_section_d.sql`

**Questions:** Q11–Q20

Day 3 extended the project from analytical queries to database automation and operational logic.

### Section C — Advanced SQL

Questions Q11–Q15 focused on advanced SQL techniques and database analysis.

The work involved applying advanced query structures and database features to solve retail reporting and operational problems.

### Section D — Stored Procedures, Triggers, and Materialized Views

Questions Q16–Q20 covered database automation and controlled order processing.

The work included:

- Developing stored procedures for database operations.
- Implementing order-processing logic.
- Using triggers to record changes.
- Maintaining order-status history.
- Creating and refreshing materialized views.

### Order Processing Test — Q20

The `sp_place_order` procedure was tested with customer ID `177`.

The order contained:

| Product | Quantity | Unit price | Line total |
|---|---:|---:|---:|
| Oraimo Bluetooth Speaker Mini | 1 | KSh 3,060 | KSh 3,060 |
| Nzoia Sweet Brown Sugar 1kg | 2 | KSh 205 | KSh 410 |
| Mlima Bora Maize Flour 2kg | 3 | KSh 165 | KSh 495 |
| **Total** | **6** | | **KSh 3,965** |

The order also included a Nairobi delivery fee of KSh 200, giving a total order amount of KSh 4,165.

The order was initially created with a pending payment. It was subsequently updated to completed, and the payment was updated to successful.

### Transaction Rollback Test

A second order attempt used customer ID `408` and included a product with insufficient stock.

The procedure correctly rejected the order because the requested quantity exceeded the available stock.

The test demonstrated that the failed operation did not leave behind a partial stock deduction or an additional order.

### Materialized View Refresh

The `mv_monthly_category_sales` materialized view was refreshed and checked.

The November 2026 results were:

| Category | Orders | Units sold | Revenue | Gross profit |
|---|---:|---:|---:|---:|
| Electronics | 1 | 1 | KSh 3,060 | KSh 641.38 |
| Groceries | 1 | 5 | KSh 905 | KSh 89.35 |
| **Total** | **2** | **6** | **KSh 3,965** | **KSh 730.73** |

**Day 3 learning outcomes:**

- Using stored procedures to automate business operations.
- Applying triggers to maintain audit and status-history records.
- Protecting database consistency through transaction logic.
- Handling failed operations without leaving partial changes.
- Using materialized views to support reporting.

**Deliverables:** Section C and D SQL files and supporting screenshots.

---

## Day 4 — Section E: Performance, Transactions, Data Quality, and Retention

**SQL file:** `sql/05_section_e.sql`

**Questions:** Q21–Q25

Day 4 focused on query performance, transaction management, data quality, and customer retention analysis.

### Q21 — Query Execution Plan Analysis

The Kisumu customer revenue dashboard query was analysed using `EXPLAIN ANALYZE`.

The query examined completed orders between 1 September and 30 September 2026.

**Observed results:**

| Metric | Result |
|---|---:|
| Result rows | 91 |
| Estimated order rows | 2,072 |
| Actual order rows | 2,061 |
| Planning time | 6.106 ms |
| Execution time | 10.990 ms |

The execution plan included:

- Hash Join.
- Nested Loop.
- Index Scan on orders using `idx_orders_order_date`.
- Bitmap Heap Scan on customers using `idx_customers_county`.

The exercise demonstrated how PostgreSQL uses execution plans to determine query access methods and join strategies.

### Q22 — Index Performance Testing

The exercise compared query execution plans before and after creating indexes.

The tested lookups covered:

- Customer order history.
- Payment lookup by order ID.
- Order items lookup by product ID.

**Observed performance comparison:**

| Lookup | Before indexing | After indexing |
|---|---:|---:|
| Customer orders | 8.796 ms | 0.148 ms |
| Payment by order ID | 22.241 ms | 0.128 ms |
| Product order items | 28.138 ms | 0.770 ms |

Approximate execution-time reductions:

- Customer order lookup: 98.3%.
- Payment lookup: 99.4%.
- Product order-items lookup: 97.3%.

The exercise also tested a partial index for pending orders.

The partial index occupied 32 kB, compared with 1,112 kB for the full order-date index. However, the tested pending-order query used `idx_orders_status_date`, not the partial index. The partial index's existence and storage size were verified, but its use was not demonstrated by that execution plan.

**Key learning outcome:** Indexes can significantly reduce query execution time, but their effectiveness should be evaluated using actual execution plans rather than assumed.

### Q23 — Transactions, Savepoints, and Rollbacks

This exercise tested how PostgreSQL transactions protect data integrity.

#### Q23(a) — Transaction and Rollback

A temporary 10% reduction was applied to the unit prices of Beauty products.

| Measurement | Average unit price |
|---|---:|
| Original average | KSh 1,243.84 |
| Temporary average after reduction | KSh 1,119.46 |
| Average after rollback | KSh 1,243.84 |

The transaction was rolled back, restoring the original average price.

A total of 45 Beauty products were affected by the temporary update.

#### Q23(b) — Savepoint and Partial Rollback

The exercise involved restocking product 59 by 40 units, recording the change in `audit_logs`, creating a savepoint, and then making an incorrect stock update to product 166.

The transaction was rolled back to the savepoint so that the incorrect update was undone while the earlier restock operation was retained.

The verified final stock quantities were:

| Product ID | Final stock |
|---|---:|
| 59 | 41 |
| 166 | 1 |

The audit log recorded the stock update for product 59.

The testing process involved transaction-management corrections, so not every intermediate execution stage was captured. The final stock values and audit records were checked.

#### Q23(c) — Constraint Violation

An invalid stock quantity was deliberately submitted to test the product stock constraint.

PostgreSQL rejected the operation with SQLSTATE `23514`, demonstrating that the database constraint prevented an invalid stock value from being stored.

The final stock quantity for product 166 remained 1.

### Q24 — Payment Staging Data Cleaning

This exercise focused on identifying and removing duplicate payment records while preserving valid records.

#### Duplicate analysis

| Metric | Result |
|---|---:|
| Total staging rows before cleaning | 2,640 |
| Distinct payment IDs | 2,400 |
| Extra duplicate rows | 240 |
| Maximum copies of a payment ID | 3 |

The duplicate analysis used `ROW_NUMBER()` partitioned by `payment_id`, ordered by `loaded_at` and `staging_id`.

This made it possible to identify which records to retain and which were duplicates.

#### Duplicate removal

The duplicate rows were removed while retaining the earliest loaded record for each payment ID.

The cleaned staging table contained 2,400 unique payment IDs.

The staging payment amount was KSh 60,184,108.05. A comparison with the corresponding records in the payments table produced the same total:

| Validation | Result |
|---|---:|
| Matched payment records | 2,400 |
| Staging amount | KSh 60,184,108.05 |
| Matching payments amount | KSh 60,184,108.05 |
| Totals match | TRUE |

#### Unique index

A unique index was created on `payment_id` to prevent duplicate payment IDs from being inserted into the staging table again.

A duplicate insertion test was rejected with SQLSTATE `23505`, confirming that the unique constraint was enforced.

### Q25 — Customer Retention Analysis

This exercise used customer-month activity and consecutive-month streak analysis to examine customer retention.

#### Q25(a) — Longest Consecutive-Month Streak

The query identified customers with consecutive months of completed orders and calculated their longest activity streak.

The top 10 customers each had a longest streak of 22 months, covering January 2025 to October 2026.

#### Q25(b) — Retention Summary

The summary query identified 1,459 customers with at least three consecutive months of completed-order activity.

The longest observed streak was 22 months.

**Key learning outcomes:**

- Interpreting PostgreSQL execution plans.
- Measuring index performance.
- Applying transactions and savepoints.
- Using rollback to protect database consistency.
- Identifying and removing duplicate records.
- Enforcing uniqueness through indexes.
- Analysing customer retention with consecutive-month streaks.

**Deliverables:** `sql/05_section_e.sql` and supporting screenshots.

---

# Business Insights and Recommendations

The project produced several measurable findings that can inform SokoMart's operational and management decisions.

| No. | Finding | Recommendation |
|---:|---|---|
| 1 | The tested customer-order lookup improved from 8.796 ms to 0.148 ms after indexing, an approximate 98.3% reduction. | Retain and monitor indexes that support frequently used customer-order queries. |
| 2 | The payment lookup improved from 22.241 ms to 0.128 ms, an approximate 99.4% reduction. | Maintain an index on `payments.order_id` to support payment retrieval and reconciliation. |
| 3 | The product order-items lookup improved from 28.138 ms to 0.770 ms, an approximate 97.3% reduction. | Retain the product ID index for product-level sales analysis and reporting. |
| 4 | The payment staging table contained 240 extra duplicate rows among 2,640 records before cleaning. | Apply deduplication during data imports and retain uniqueness enforcement on payment IDs. |
| 5 | The cleaned staging amount and corresponding payment amount both totalled KSh 60,184,108.05 across 2,400 matched records. | Continue validating staging data against payment records before financial reporting. |
| 6 | The top 10 customers each recorded a 22-month consecutive activity streak from January 2025 to October 2026. | Develop loyalty and retention initiatives to maintain long-term customer activity. |
| 7 | A total of 1,459 customers had at least three consecutive months of completed-order activity. | Segment customers by activity streak and use targeted engagement to reduce inactivity. |
| 8 | The failed order-processing test correctly prevented an order with insufficient stock from leaving a partial stock deduction. | Preserve atomic order-processing logic to protect inventory accuracy. |
| 9 | The invalid stock update was rejected with SQLSTATE `23514`. | Retain database-level stock constraints rather than relying only on application-side validation. |
| 10 | The November 2026 category view recorded KSh 3,965 in revenue and KSh 730.73 in gross profit across two orders. | Monitor category-level revenue and gross profit together when evaluating product performance. |

*Performance reductions are calculated from the observed execution times in the Q22 tests. Other findings are based on the recorded query outputs and validation tests described above.*

---

# Business Rules and Analytical Assumptions

The following rules were applied throughout the project:

1. **Revenue calculation:** Revenue is calculated using `SUM(order_items.line_total)` for completed orders only.
2. **Excluded order statuses:** Pending, cancelled, and returned orders are excluded from completed-order revenue calculations.
3. **Delivery fees:** Delivery fees are excluded from the revenue measure used in the analytical exercises.
4. **Cost calculation:** Product cost is calculated using `SUM(quantity * products.cost_price)`.
5. **Gross profit:** Gross profit is revenue minus product cost.
6. **Gross margin:** Gross margin is calculated as gross profit divided by revenue, multiplied by 100.
7. **Monthly reporting:** Calendar months are used, with reporting labels formatted as `YYYY-MM`.
8. **Date filtering:** Half-open date ranges are used to include the start date and exclude the next period's boundary.
9. **Customer county:** Customer county is taken from the customer record unless a shipping county is explicitly specified.
10. **Customer names:** Full names are constructed by combining `first_name` and `last_name`.
11. **Financial precision:** Monetary calculations use `NUMERIC` rather than floating-point types.
12. **Percentage formatting:** Percentages are rounded to two decimal places.

---

# Project Structure

The repository is organised around the SQL exercises, supporting documentation, and evidence screenshots.

```text
## Project Structure

```text
soko-mart/
│
├── README.md
│
├── sql/
│   ├── 00_practice_drills.sql
│   ├── 01_section_a.sql
│   ├── 02_section_b.sql
│   ├── 03_section_c.sql
│   ├── 04_section_d.sql
│   ├── 05_section_e.sql
│   └── 05_indexes.sql
│
└── screenshots/
    └── All project screenshots (Day 1–Day 4)
```
]
```

*The directory tree is a high-level representation. Check the repository for the exact names and locations of additional setup files and screenshots.*

---

# How to Run the Project

## Requirements

Before running the SQL files, ensure that you have:

- PostgreSQL installed.
- DBeaver or another PostgreSQL-compatible SQL client.
- Git installed if you intend to clone the repository.

## Step 1 — Clone the Repository

```bash
git clone https://github.com/4688-tori/soko-mart.git
```

Navigate into the project directory:

```bash
cd soko-mart
```

## Step 2 — Connect to PostgreSQL

Open DBeaver and connect to your PostgreSQL server.

Use the project database:

```text
luxdevhq_cohort9_advanced_sql
```

The project schema is:

```text
sokomart
```

## Step 3 — Prepare the Database

Prepare the database tables and data using the database setup instructions and scripts included in the repository.

Ensure the database is loaded before executing the analytical SQL files.

Where a reset is required, use the project's reset instructions before reloading the database. Some Day 3 and Day 4 exercises modify database records, so a clean database state may be necessary when reproducing the original test results.

## Step 4 — Execute the SQL Files

Open the relevant SQL file in DBeaver and execute the queries in the required order.

The main exercise files are:

| File | Description |
|---|---|
| `sql/02_section_b.sql` | Section B: Window functions |
| `sql/03_section_c.sql` | Section C: Advanced SQL |
| `sql/04_section_d.sql` | Section D: Stored procedures, triggers, and materialized views |
| `sql/05_section_e.sql` | Section E: Performance, transactions, data cleaning, and retention |

Execute the scripts against the `sokomart` schema.

**Important:** Some exercises intentionally modify data, create indexes, test constraint violations, or use transactions. Read the comments in each SQL file before executing it. Do not rerun data-changing tests blindly on an already modified database.

## Step 5 — Review and Validate Results

Review the query outputs and compare them with the expected business rules.

For performance exercises, use `EXPLAIN ANALYZE` to inspect actual execution plans.

For transaction exercises, verify the final database state after commits and rollbacks.

For data-cleaning exercises, verify record counts, uniqueness, and reconciliation totals.

---

# Skills Demonstrated

The project demonstrates practical experience in:

- PostgreSQL database querying.
- Relational database joins.
- Aggregation and grouping.
- Common table expressions (CTEs).
- Subqueries and correlated subqueries.
- Window functions.
- Ranking and analytical functions.
- Date and time functions.
- Running totals and cumulative analysis.
- Stored procedures.
- PL/pgSQL.
- Database triggers.
- Materialized views.
- Index creation and performance analysis.
- Query execution plans.
- Transactions, savepoints, commits, and rollbacks.
- Constraints and data integrity.
- Data cleaning and deduplication.
- Customer retention analysis.
- Git and GitHub version control.
- Technical documentation and reporting.

---

# Conclusion

The SokoMart Kenya Advanced SQL Practical Project demonstrates the use of PostgreSQL to solve retail data-management and business-analysis problems.

Across the project stages, SQL was applied not only to retrieve information but also to automate business processes, maintain data integrity, improve query performance, clean imported records, and analyse customer behaviour.

The exercises show how a well-structured relational database and carefully designed SQL queries can support more reliable reporting and better operational decisions.

**Repository:** [https://github.com/4688-tori/soko-mart](https://github.com/4688-tori/soko-mart)

**Project:** SokoMart Kenya — Advanced SQL Practical Project  
**Cohort:** LuxDevHQ Cohort 9

