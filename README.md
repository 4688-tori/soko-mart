# # SokoMart Kenya — Advanced SQL Project

**LuxDevHQ Cohort 9 | Advanced SQL Practical Project**

## 1. Project Overview

SokoMart Kenya is a retail sales database project developed using PostgreSQL. The project applies SQL concepts to retail business operations, including customer analysis, product performance, sales reporting, inventory management, payment processing, data integrity, query optimisation and customer retention.

The objective is to transform transactional retail data into meaningful business insights while demonstrating practical database development and advanced SQL skills.

**Database:** PostgreSQL 18.6  
**Database name:** `luxdevhq_cohort9_advanced_sql`  
**Schema:** `sokomart`  
**SQL environment:** DBeaver  
**Version control:** Git and GitHub

## 2. Project Objectives

- Analyse customer purchasing behaviour and spending patterns.
- Identify premium products and products that have never been ordered.
- Measure monthly revenue, costs, gross profit and profit margins.
- Compare sales performance across counties, customers and product categories.
- Apply window functions, CTEs, subqueries and aggregate functions.
- Implement stored procedures and database triggers.
- Manage inventory and payment transactions.
- Maintain data integrity through constraints and validation.
- Clean duplicate payment staging records.
- Improve query performance through indexing and execution-plan analysis.
- Analyse customer purchasing retention over consecutive months.

## 3. Database Structure

The project uses the `sokomart` schema and includes tables supporting:

- Customers
- Products
- Orders
- Order items
- Payments
- Payment staging
- Product price history
- Audit logs
- Order status history

The database supports customer transactions, product inventory, payment records, order tracking and audit activities.

## 4. Project Structure

All SQL scripts are stored in the `sql/` directory. All project screenshots, covering Days 1–4, are stored directly in the `screenshots/` directory without separate day folders.

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
    └── Project screenshots from Day 1 to Day 4
```

## 5. SQL Implementation

### Day 1 — Section A: SQL Fundamentals and Business Analysis

**Q1. Big Spenders of 2025**

Identified customers whose completed-order spending in 2025 exceeded the average spending of customers who purchased during that year. Used CTEs and aggregate functions to calculate customer spending and the average.

**Q2. Premium Products**

Identified active products priced above the average unit price within their respective categories. Calculated the price difference between each qualifying product and its category average.

**Q3. Monthly Profit and Loss Analysis**

Calculated monthly revenue, product costs, gross profit and gross profit margin for January–October 2026 using completed orders.

**Q4. Nakuru Cross-Category Shoppers**

Identified customers from Nakuru who purchased from at least three distinct product categories through completed orders. Also calculated their spending and category coverage.

**Q5. Products Never Ordered**

Identified products that have never appeared in the `order_items` table using a `NOT EXISTS` subquery.

### Day 2 — Section B: Advanced SQL and Window Functions

**Q6. County Customer Leaderboards**

Ranked customers within each county according to their lifetime revenue from completed orders. Used `DENSE_RANK()` to identify the top three positions in each county while retaining customers with no completed orders.

**Q7. Best-Selling Products per Category**

Ranked products within each category according to their revenue from completed orders in 2025. Used `ROW_NUMBER()` to identify the top three products per category.

**Q8. Month-over-Month Revenue Growth**

Generated a monthly calendar from January 2025 to October 2026, calculated completed-order revenue and used `LAG()` to compare each month with the previous month. Included months with no sales.

**Q9. Nyeri Customer Order Comparisons**

Analysed completed orders placed by customers from Nyeri during 2026. Used `LAG()` to compare each order's total with the customer's previous order and classified the change as an increase, decrease, unchanged or first order.

**Q10. Year-to-Date Revenue**

Calculated monthly revenue, yearly running totals and an all-time cumulative revenue total. Used window functions with explicit running-total frames.

### Day 3 — Section C: Stored Procedures and Database Operations

Implemented database operations using stored procedures and transaction logic.

The work included:

- Creating and testing stored procedures for order processing.
- Validating customers, products, quantities and available stock.
- Calculating order totals and applicable delivery fees.
- Creating order items and payment records.
- Updating order statuses and associated payment statuses.
- Using transactions to protect database consistency.
- Testing successful and unsuccessful order scenarios.

**Order placement test**

A successful order was placed for customer 177.

| Item | Quantity | Unit price | Line total |
|---|---:|---:|---:|
| Oraimo Bluetooth Speaker Mini | 1 | KSh 3,060 | KSh 3,060 |
| Nzoia Sweet Brown Sugar 1kg | 2 | KSh 205 | KSh 410 |
| Mlima Bora Maize Flour 2kg | 3 | KSh 165 | KSh 495 |
| **Total** | **6** | | **KSh 3,965** |

The order also incurred a Nairobi delivery fee of KSh 200, giving a final order total of **KSh 4,165**.

The order was subsequently completed, and its associated payment was marked successful.

A failed order test involving insufficient stock also demonstrated transaction rollback: the order was not created and the earlier stock deduction was reversed.

### Day 3 — Section D: Triggers, Auditing and Reporting

Implemented database automation and reporting features, including:

- Triggers for recording order status changes.
- Audit logging for relevant database changes.
- Stored procedures for updating order statuses.
- Payment status updates associated with completed orders.
- A monthly category sales materialised view.
- Refreshing the materialised view concurrently.

**November 2026 materialised view results**

| Category | Orders | Units | Revenue | Gross profit |
|---|---:|---:|---:|---:|
| Electronics | 1 | 1 | KSh 3,060 | KSh 641.38 |
| Groceries | 1 | 5 | KSh 905 | KSh 89.35 |
| **Total** | **2** | **6** | **KSh 3,965** | **KSh 730.73** |

### Day 4 — Section E: Performance, Data Integrity and Retention

**Q21. Query Execution Plan Analysis**

Analysed the execution plan for a Kisumu customer sales query covering September 2026.

The query returned 91 customer records and used:

- Hash Join
- Nested Loop
- Index Scan on orders using `idx_orders_order_date`
- Bitmap Heap Scan on customers using `idx_customers_county`

The estimated number of order rows was 2,072 compared with 2,061 actual rows.

Recorded planning time was 6.106 ms and execution time was 10.990 ms.

**Q22. Indexing and Query Optimisation**

Created indexes to improve lookup performance across orders, payments, order items and customers.

The indexes included:

- `idx_orders_customer_date`
- `idx_orders_customer_id`
- `idx_orders_order_date`
- `idx_orders_status_date`
- `idx_payments_order_id`
- `idx_order_items_product_id`
- `idx_customers_county`

Compared execution plans before and after indexing.

| Lookup | Before indexing | After indexing | Approx. execution-time reduction |
|---|---:|---:|---:|
| Customer orders | 8.796 ms | 0.148 ms | 98.3% |
| Payment by order | 22.241 ms | 0.128 ms | 99.4% |
| Order items by product | 28.138 ms | 0.770 ms | 97.3% |

Also created a partial index for pending orders:

`idx_orders_pending_date`

The partial index occupied 32 kB compared with 1,112 kB for the full order-date index, representing approximately 97.1% less storage. The tested pending-order query used `idx_orders_status_date`, rather than the partial index, so the partial index's use by that query was not demonstrated.

**Q23. Transactions, Savepoints and Audit Logging**

Tested transaction behaviour through product price and inventory changes.

The work included:

- Temporarily reducing Beauty product prices by 10%.
- Comparing original, temporary and restored average prices.
- Using transaction rollback to restore the original prices.
- Testing inventory updates and savepoint behaviour.
- Checking audit records for stock changes.
- Testing a constraint violation through an attempted negative-stock update.

The negative-stock update was rejected with SQLSTATE `23514`, confirming that the stock constraint prevented the invalid change.

The final verified stock values were 41 units for product 59 and 1 unit for product 166. The audit log recorded stock changes for product 59.

**Q24. Payment Staging Data Cleaning**

Analysed duplicate payment records in the payment staging table.

| Measure | Result |
|---|---:|
| Initial staging rows | 2,640 |
| Distinct payment IDs | 2,400 |
| Extra duplicate rows | 240 |
| Maximum copies of a payment ID | 3 |
| Rows after deduplication | 2,400 |

Used `ROW_NUMBER()` to identify duplicate records and retained the earliest loaded record for each payment ID, using the staging ID as a tie-breaker.

After deduplication:

- 2,400 staging records remained.
- All 2,400 payment IDs were distinct.
- The staging total was KSh 60,184,108.05.
- The matching payments total was also KSh 60,184,108.05.
- The totals matched successfully.

Created a unique index named `idx_payment_staging_payment_id` and tested duplicate insertion. The duplicate was rejected with SQLSTATE `23505`.

**Q25. Customer Retention Analysis**

Analysed consecutive-month purchasing activity using customer order history.

The results showed:

- The top 10 customers each achieved a longest purchasing streak of 22 consecutive months.
- 1,459 customers had a purchasing streak of at least three consecutive months.
- The longest recorded streak was 22 months.

These findings provide a basis for evaluating repeat purchasing behaviour and customer retention.

## 6. Key Quantified Findings

The following findings were established through the project queries and tests:

1. **Order processing:** A successfully completed test order generated KSh 3,965 in item revenue and KSh 200 in delivery fees.
2. **Gross profit:** The November 2026 test order generated KSh 730.73 in gross profit across Electronics and Groceries.
3. **Query optimisation:** The customer-order lookup execution time decreased by approximately 98.3% after indexing.
4. **Payment lookup optimisation:** The payment lookup execution time decreased by approximately 99.4%.
5. **Product lookup optimisation:** The product-items lookup execution time decreased by approximately 97.3%.
6. **Data quality:** The payment staging table contained 240 extra duplicate rows, which were removed to leave 2,400 unique payment records.
7. **Payment reconciliation:** The cleaned staging total matched the corresponding payments total at KSh 60,184,108.05.
8. **Storage efficiency:** The partial pending-order index occupied 32 kB compared with 1,112 kB for the full order-date index.
9. **Customer retention:** 1,459 customers had at least three consecutive months of purchasing activity.
10. **Longest retention streak:** The top 10 customers each had a 22-month consecutive purchasing streak.

## 7. Business Recommendations

Based on the analysis and database tests:

- **Customer retention:** Use the consecutive-month purchasing analysis to identify loyal customers and develop targeted retention campaigns.
- **Customer segmentation:** Use county-level spending rankings to identify high-value customer segments and tailor marketing activities.
- **Product strategy:** Review premium products and category-level performance when making pricing and product assortment decisions.
- **Inventory management:** Maintain adequate stock levels and use automated validation to prevent orders from exceeding available inventory.
- **Payment data quality:** Retain unique payment identifiers and staging-table validation to reduce duplicate payment records.
- **Database performance:** Continue using execution plans to identify expensive queries and validate whether indexes are being used effectively.
- **Financial monitoring:** Use monthly revenue, cost and gross profit reporting to monitor product-category performance.

## 8. Important Business and Technical Rules

The project applies the following rules in its SQL analysis and database operations:

- Revenue calculations use order-item line totals where specified.
- Completed orders are used for completed-sales reporting.
- Date filters use inclusive start dates and exclusive end dates where appropriate.
- Customers with no completed orders are retained in analyses where a complete customer list is required.
- Monthly calendars include zero-sales months in the relevant reporting queries.
- Inventory updates are validated against available stock.
- Transactions protect multi-step order operations.
- Duplicate payment staging records are identified and removed using a consistent ranking rule.
- Database constraints protect against invalid data, including negative stock quantities.

## 9. How to Run the Project

1. Install PostgreSQL and a SQL client such as DBeaver.
2. Create the database:

   `luxdevhq_cohort9_advanced_sql`

3. Ensure the database contains the required SokoMart tables and data under the `sokomart` schema.
4. Open the SQL scripts in the `sql/` directory using DBeaver.
5. Execute the scripts in the appropriate project sequence, beginning with the practice drills and Sections A–E.
6. Run `05_indexes.sql` to create the performance indexes.
7. Review the outputs and execution plans using the corresponding SQL queries.
8. Refer to the `screenshots/` directory for evidence of the project work and query results.

**Note:** The SQL scripts rely on the SokoMart database schema and its underlying data. They should be executed against a correctly prepared database. Some scripts create or modify database objects, so review their contents before running them again on an existing database.

## 10. Skills Demonstrated

- PostgreSQL and relational database querying
- SQL joins and subqueries
- Common Table Expressions (CTEs)
- Aggregate functions and conditional logic
- Window functions: `ROW_NUMBER()`, `DENSE_RANK()`, `LAG()` and running totals
- Date and time analysis
- Stored procedures and PL/pgSQL
- Transactions, commits, rollbacks and savepoints
- Database triggers and audit logging
- Materialised views
- Index creation and query optimisation
- `EXPLAIN ANALYZE` and execution-plan interpretation
- Data cleaning and deduplication
- Data integrity and constraint validation
- Git, GitHub and project documentation

## 11. Repository

**GitHub repository:** https://github.com/4688-tori/soko-mart

The repository contains the SQL scripts and project screenshots for the SokoMart Kenya Advanced SQL practical project.

## 12. Conclusion

The SokoMart Kenya project demonstrates the practical application of PostgreSQL to retail business analysis and database management. It progresses from fundamental SQL queries to advanced analytical functions, stored procedures, transaction management, triggers, auditing, indexing, data cleaning and customer retention analysis.

The project combines technical SQL implementation with measurable business findings, demonstrating how a relational database can support operational control, data quality, performance improvement and informed business decisions.

**Project completed as part of LuxDevHQ Cohort 9 Advanced SQL training.**
