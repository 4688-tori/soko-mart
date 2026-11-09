# SokoMart – Advanced SQL Project

## Day 1 – Advanced SQL

### Project Overview

This project is part of the LuxDevHQ Cohort 9 Advanced SQL programme. It uses PostgreSQL to practise database management, SQL querying, subqueries, Common Table Expressions (CTEs), functions and stored procedures.

### Database Details

- **Database:** `luxdevhq_cohort9_advanced_sql`
- **Schema:** `sokomart`
- **DBMS:** PostgreSQL 18.6
- **SQL Client:** DBeaver

### Database Setup

The PostgreSQL database, schema and tables were created and populated locally.

The database validation script (`06_validation.sql`) was executed successfully, with all 41 checks passing.

### Day 1 SQL Exercises

#### Practice Drills

**File:** `sql/00_practice_drills.sql`

Contains ten practice exercises (D1–D10) covering:

- Scalar and correlated subqueries
- `IN` and `EXISTS`
- Derived tables
- Common Table Expressions (CTEs)
- Aggregate functions
- SQL functions
- Stored procedures
- Transaction management and rollback

#### Section A – CTEs and Subqueries

**File:** `sql/01_section_a.sql`

Contains Questions 1–5 covering:

- Customer spending analysis
- Premium product identification
- Monthly profit and loss analysis
- Cross-category customer analysis
- Products that have never been ordered

### Screenshots

Execution evidence for the Day 1 exercises is stored in the `screenshots/` directory.

The screenshots document the results of the practice drills and Section A exercises.

### How to Run the SQL Files

1. Install and start PostgreSQL.
2. Connect to the `luxdevhq_cohort9_advanced_sql` database using DBeaver.
3. Ensure the active schema is `sokomart`.
4. Open the relevant SQL file from the `sql/` directory.
5. Execute the SQL statements and inspect the results in the DBeaver results grid.

### Project Structure

```text
soko-mart-project/
│
├── sql/
│   ├── 00_practice_drills.sql
│   └── 01_section_a.sql
│
├── screenshots/
│   └── Day 1 exercise screenshots
│
└── README.md
```

### Technologies Used

- PostgreSQL
- SQL
- DBeaver
- Git and GitHub
