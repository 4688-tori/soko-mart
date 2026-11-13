# SokoMart Kenya – Advanced SQL Practical Project

## Project Overview

This project focuses on applying advanced SQL concepts to analyse retail business data for SokoMart Kenya.

The project uses PostgreSQL to explore customer behaviour, sales performance, product revenue and other business-related questions through practical SQL queries.

## Tools and Technologies

- PostgreSQL 18.6
- DBeaver
- Git and GitHub

## Project Progress

### Day 1 – Database Setup and Basic SQL

Completed:
- Database and schema creation.
- Table creation and data loading.
- Index creation.
- Database validation.
- SQL practice drills (D1–D10).
- Section A: Questions 1–5.

### Day 2 – Window Functions

Completed Section B: Questions 6–10.

Concepts applied include:
- Common Table Expressions (CTEs).
- `ROW_NUMBER()` and `DENSE_RANK()`.
- `LAG()` window function.
- `PARTITION BY` and `ORDER BY`.
- Running totals using window frames.
- Month-over-month revenue growth.
- Year-to-date and cumulative revenue analysis.

## Repository Structure

```text
soko-mart/
│
├── sql/
│   ├── 00_practice_drills.sql
│   ├── 01_section_a.sql
│   └── 02_section_b.sql
│
├── screenshots/
│   └── Query result screenshots
│
└── README.md
```

## Project Status

**In Progress**

- [x] Day 1 – Database setup and Section A
- [x] Day 2 – Section B: Window Functions
- [ ] Day 3 – Sections C and D
- [ ] Day 4 – Section E, business insights and final documentation

## Author

**Victoria Suewama Ndei**

LuxDevHQ – Cohort 9
# Day 3 – Advanced SQL Practical Project
## SokoMart Kenya | LuxDevHQ Cohort 9

### Overview
Day 3 focused on applying advanced PostgreSQL concepts to the SokoMart Kenya retail database. The work covered analytical queries, customer segmentation, payment analysis, views, functions, stored procedures, triggers, transaction management, and data integrity.

The project was implemented using **PostgreSQL 18.6** and managed through **DBeaver**.

### Section C: Advanced Analytical Queries (Q11–Q15)

This section focused on extracting business insights using advanced SQL techniques.

| Query | Description | SQL Concepts |
|---|---|---|
| Q11 | Customer segmentation and tiers | CASE expressions, aggregations |
| Q12 | Mombasa customer shopping lists for October 2026 | Joins, filtering, aggregation |
| Q13 | Payment health analysis by payment method | Aggregate FILTER clauses |
| Q14 | Category profitability analysis | CTEs, gross profit calculations, HAVING |
| Q15 | Revenue analysis by shipping county and category | GROUPING SETS |

### Section D: Database Objects and Automation (Q16–Q20)

This section focused on creating reusable database objects and automating business operations.

| Query | Description | SQL Concepts |
|---|---|---|
| Q16 | Customer purchase summary and monthly category sales | Views, materialized views, unique indexes |
| Q17 | Customer spending calculation | PL/pgSQL functions, parameters, exception handling |
| Q18 | Product price update automation | Stored procedures, transactions, audit logging |
| Q19 | Order status management and auditing | Triggers, trigger functions, stored procedures |
| Q20 | Automated order placement | Arrays, loops, conditional stock updates, transaction rollback |

### Key Implementations

**1. Customer and Sales Analytics**
- Segmented customers based on purchasing behaviour.
- Analysed payment performance by payment method.
- Evaluated category-level profitability.
- Used GROUPING SETS to produce multiple aggregation levels.

**2. Views and Functions**
- Created a customer purchase summary view.
- Created a monthly category sales materialized view.
- Implemented a customer spending function with date-range parameters.
- Tested valid and invalid date ranges.

**3. Stored Procedures and Audit Logging**
- Automated product price updates.
- Recorded price changes in product price history.
- Implemented audit logging to capture database changes.
- Created order status management procedures.
- Used triggers to track order status changes.

**4. Automated Order Placement**
Implemented `sokomart.sp_place_order` to:
- Validate customer eligibility and input arrays.
- Create pending orders.
- Check product availability and deduct stock.
- Calculate order subtotals and delivery fees.
- Generate transaction references.
- Create pending payment records.
- Return the generated order ID.

### Testing and Validation

The following tests were performed:

- Successfully placed an order for customer 177.
- Verified order ID 50001 and its order items.
- Confirmed stock deductions for products 6, 73 and 82.
- Verified the order total of KSh 4,165, including a KSh 200 delivery fee.
- Confirmed payment creation with a transaction reference.
- Tested insufficient stock using product 59.
- Verified transaction rollback: stock remained unchanged and no additional order was created.
- Updated order 50001 to completed and confirmed its payment became successful.
- Refreshed the monthly category sales materialized view concurrently.
- Verified November 2026 category sales results.

### November 2026 Sales Results

| Category | Orders | Units Sold | Revenue (KES) | Gross Profit (KES) |
|---|---:|---:|---:|---:|
| Electronics | 1 | 1 | 3,060.00 | 641.38 |
| Groceries | 1 | 5 | 905.00 | 89.35 |
| **Total** | **2** | **6** | **3,965.00** | **730.73** |

*Revenue reflects completed order items and excludes delivery fees.*

### Project Structure

```text
soko-mart-project/
│
├── sql/
│   ├── 03_section_c.sql
│   └── 04_section_d.sql
│
├── screenshots/
│   ├── q11_customer_tiers.png
│   ├── q12_mombasa_shopping_lists.png
│   ├── q13_payment_health.png
│   ├── q14_category_profitability.png
│   ├── q15_grouping_sets.png
│   ├── q16a_customer_summary.png
│   ├── q16b_materialized_view.png
│   ├── q17_function_tests.png
│   ├── q18_successful_price_update.png
│   ├── q19_status_history.png
│   ├── q20_successful_order.png
│   ├── q20_insufficient_stock.png
│   ├── q20_rollback_verified.png
│   └── q20_november_sales.png
│
└── README.md
```

*The screenshots directory contains additional supporting evidence for individual queries and tests.*

### Tools and Technologies
- PostgreSQL 18.6
- DBeaver
- SQL and PL/pgSQL
- Git and GitHub

### Key Learning Outcomes

Through Day 3, I gained practical experience in:
- Writing complex analytical SQL queries.
- Creating reusable views and materialized views.
- Developing parameterized PostgreSQL functions and procedures.
- Implementing triggers and audit mechanisms.
- Managing inventory through conditional updates.
- Handling exceptions and transaction rollbacks.
- Testing database operations and validating business rules.
  ## Day 4: Performance Optimization, Transactions & Data Integrity

### Section E: Advanced SQL (Q21–Q25)

This section covers query execution plans, index optimization, transaction management, payment deduplication, and customer retention analysis.

#### Q21: Query Execution Plan Analysis
- Used `EXPLAIN ANALYZE` to inspect query execution.
- Analysed execution methods, scan types, estimated rows, actual rows, planning time, and execution time.
- The Kisumu customer sales query returned 91 customers for September 2026.

#### Q22: Index Performance Optimization
- Compared query execution before and after creating supporting indexes.
- Tested customer, payment, and product lookups.
- Tested a partial index for pending orders.
- Compared index storage sizes.

| Query | Before | After |
|---|---:|---:|
| Customer lookup | 8.796 ms | 0.148 ms |
| Payment lookup | 22.241 ms | 0.128 ms |
| Product lookup | 28.138 ms | 0.770 ms |

The partial-index query used the composite `idx_orders_status_date` index rather than the partial index.

#### Q23: Transaction Management
- Demonstrated transaction rollback after a temporary Beauty category price reduction.
- Tested SAVEPOINT and partial rollback during product restocking.
- Tested a stock constraint violation and transaction recovery.
- Verified the final stock quantities for products 59 and 166.

#### Q24: Payment Staging Deduplication
- Identified 240 extra duplicate rows among 2,640 staging records.
- Retained 2,400 distinct payment records.
- Verified matching payment totals of KSh 60,184,108.05.
- Created a unique index on `payment_id`.
- Confirmed that PostgreSQL rejects duplicate payment IDs with SQLSTATE `23505`.

#### Q25: Customer Retention Analysis
- Used a gaps-and-islands approach to identify consecutive monthly purchasing activity.
- Identified 1,459 customers with at least three consecutive months of completed orders.
- The longest consecutive-month purchasing streak was 22 months.
- Ranked the top 10 customers by their longest retention streak.


### Repository
GitHub: https://github.com/4688-tori/soko-mart

**Project:** LuxDevHQ Cohort 9 – Advanced SQL Practical Project  
**Database:** SokoMart Kenya  
**Sections Completed:** C and D (Q11–Q20)

