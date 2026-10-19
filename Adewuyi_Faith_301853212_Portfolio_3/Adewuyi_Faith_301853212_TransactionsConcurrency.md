# Portfolio 3: Transactions and Concurrency

**Case Study:** Abitim Farms Management System  
**Database Management System:** PostgreSQL

## 1. Introduction

This portfolio demonstrates transaction management and concurrency control in the Abitim Farms Management System. The implementation uses the existing PostgreSQL database developed for the case study.

The practical exercises demonstrate the use of COMMIT and ROLLBACK, transaction isolation, and PostgreSQL concurrency control when multiple database sessions attempt to access and modify the same data.

The exercises were performed using product inventory records in the `products` table. Transaction behaviour was tested using separate pgAdmin Query Tool sessions where required.

## 2. Implementation Prerequisites

The transaction exercises use the PostgreSQL database created for the Abitim Farms case study. `Crate of Eggs` originates from the original sample data, while `Test Product 10` and `Test Product 20` are part of the additional test-product records generated during Portfolio 2.

For the documented execution, the relevant starting quantities were:

- `Crate of Eggs`: **100**
- `Test Product 10`: **8**
- `Test Product 20`: **20**

The COMMIT and concurrency demonstrations intentionally modify the test-product records. Therefore, rerunning these operations without first restoring the documented starting values will produce different numerical results. The quantities reported in this portfolio correspond to the captured implementation evidence.

## 3. ROLLBACK Demonstration

A transaction was used to demonstrate how PostgreSQL can cancel an uncommitted database modification.

The initial quantity in stock for `Crate of Eggs` was **100**. A transaction was started using `BEGIN`, and the stock quantity was reduced by 10 using an `UPDATE` statement. Within the transaction, this changed the quantity from **100 to 90**.

The transaction was then cancelled using `ROLLBACK`. A subsequent query showed that the quantity in stock was **100**, demonstrating that the uncommitted change had been discarded.

```sql
BEGIN;

UPDATE products
SET quantity_in_stock = quantity_in_stock - 10
WHERE product_name = 'Crate of Eggs';

SELECT
    product_name,
    quantity_in_stock AS stock_before_rollback
FROM products
WHERE product_name = 'Crate of Eggs';

ROLLBACK;

SELECT
    product_name,
    quantity_in_stock AS stock_after_rollback
FROM products
WHERE product_name = 'Crate of Eggs';
```

### Evidence

- `Adewuyi_Faith_301853212_TransactionInitialStock.png`
- `Adewuyi_Faith_301853212_RollbackBefore.png`
- `Adewuyi_Faith_301853212_RollbackDemonstration.png`

## 4. COMMIT Demonstration

A transaction was used to demonstrate how `COMMIT` permanently saves changes made within a transaction.

`Test Product 10` had a quantity in stock of **8** before the transaction. A transaction was started using `BEGIN`, and the stock quantity was reduced by 2 using an `UPDATE` statement. This changed the quantity from **8 to 6**.

The transaction was then completed using `COMMIT`. A subsequent query showed that the quantity remained **6**, confirming that the change had been permanently saved.

```sql
BEGIN;

UPDATE products
SET quantity_in_stock = quantity_in_stock - 2
WHERE product_name = 'Test Product 10'
RETURNING
    product_name,
    quantity_in_stock;

COMMIT;

SELECT
    product_name,
    quantity_in_stock AS stock_after_commit
FROM products
WHERE product_name = 'Test Product 10';
```

### Result

- Stock before the transaction: **8**
- Stock after the update: **6**
- Stock after `COMMIT`: **6**

Unlike the ROLLBACK demonstration, the updated value remained in the database after the transaction was completed. This demonstrates that `COMMIT` makes the changes performed within a transaction permanent.

### Evidence

- `Adewuyi_Faith_301853212_CommitBefore.png`
- `Adewuyi_Faith_301853212_CommitAfter.png`
## 5. Transaction Isolation

PostgreSQL transaction isolation was examined to determine the isolation level used by the database session.

The following statement was executed:

```sql
SHOW transaction_isolation;
```

The result was:

```text
read committed
```

This shows that the session was operating at the **READ COMMITTED** isolation level.

Under PostgreSQL's READ COMMITTED isolation level, each ordinary `SELECT` statement sees a snapshot of data committed before that statement began, together with changes previously made by its own transaction. Successive statements within the same transaction may therefore observe newly committed changes made by other transactions.

This behaviour was also observed during the concurrency test. Session A changed the stock of `Test Product 20` from **20 to 18** without immediately committing the transaction. While Session A remained uncommitted, Session B queried the same product and continued to see the last committed value of **20**, rather than the uncommitted value of 18.

### Evidence

- `Adewuyi_Faith_301853212_IsolationLevel.png`

## 6. Concurrency Control

A concurrency test was performed using two separate pgAdmin Query Tool sessions, referred to as **Session A** and **Session B**. The purpose was to observe how PostgreSQL handles concurrent attempts to modify the same database row.
The concurrency issue demonstrated was concurrent write contention, where two database sessions attempted to update the same product row at approximately the same time.

`Test Product 20` had an initial quantity in stock of **20**.

### Session A

Session A started a transaction and reduced the stock quantity by 2:

```sql
BEGIN;

UPDATE products
SET quantity_in_stock = quantity_in_stock - 2
WHERE product_name = 'Test Product 20'
RETURNING
    product_name,
    quantity_in_stock;
```

Within Session A, the quantity became **18**. The transaction was deliberately left uncommitted.

### Session B

While Session A remained uncommitted, Session B queried the same product and still saw the last committed quantity of **20**.

Session B then attempted to update the same row:

```sql
UPDATE products
SET quantity_in_stock = quantity_in_stock - 1
WHERE product_name = 'Test Product 20'
RETURNING
    product_name,
    quantity_in_stock;
```

The UPDATE in Session B did not complete immediately because Session A was still holding a row-level lock on the product record.

### Releasing the Lock

Session A then completed its transaction:

```sql
COMMIT;
```

After Session A committed, its change from **20 to 18** became visible and the row lock was released.
Session B used pgAdmin's autocommit behaviour for the standalone `UPDATE`. Therefore, once the waiting UPDATE was allowed to complete, its change was committed automatically without requiring a separate `COMMIT` statement in Session B.
The waiting UPDATE in Session B then continued automatically. It applied its reduction of 1 to the newly committed value of 18, producing a final quantity of **17**.

### Result

- Initial committed stock: **20**
- Session A uncommitted stock: **18**
- Session B initially observed: **20**
- Session B's conflicting UPDATE waited
- Session A committed: **18**
- Session B then completed its UPDATE: **17**

This demonstrates PostgreSQL's concurrency control. The row-level lock prevented two conflicting updates to the same row from proceeding simultaneously. Combined with the READ COMMITTED isolation behaviour observed earlier, Session B did not read Session A's uncommitted modification and its conflicting update waited until Session A completed its transaction.

### Evidence


- `Adewuyi_Faith_301853212_ConcurrencyWaiting.png`
- `Adewuyi_Faith_301853212_ConcurrencyAfterRelease.png`

## 7. Summary

This portfolio demonstrated transaction management and concurrency control using the Abitim Farms Management System.

The practical exercises showed that:

- `ROLLBACK` discarded an uncommitted stock update and restored the previous value.
- `COMMIT` permanently saved a stock update.
- The PostgreSQL session used the `READ COMMITTED` transaction isolation level.
- A second database session could not see an uncommitted change made by another transaction.
- A conflicting UPDATE in Session B waited while Session A held a row-level lock on the same record.
- After Session A committed and released the lock, the waiting UPDATE in Session B completed using the newly committed value.

These exercises demonstrate how transactions, isolation, and locking help maintain data consistency when multiple database operations occur concurrently.

## 8. Evidence Summary

The following screenshots were captured during the implementation:

- `Adewuyi_Faith_301853212_TransactionInitialStock.png` — initial stock of Crate of Eggs at 100.
- `Adewuyi_Faith_301853212_RollbackBefore.png` — Crate of Eggs temporarily reduced to 90 within the transaction before rollback.
- `Adewuyi_Faith_301853212_RollbackDemonstration.png` — verification that ROLLBACK restored the stock to 100.
- `Adewuyi_Faith_301853212_CommitBefore.png` — Test Product 10 stock at 8 before the committed transaction.
- `Adewuyi_Faith_301853212_CommitAfter.png` — Test Product 10 stock remaining at 6 after COMMIT.
- `Adewuyi_Faith_301853212_IsolationLevel.png` — PostgreSQL READ COMMITTED isolation level.
- `Adewuyi_Faith_301853212_ConcurrencyWaiting.png` — Session B waiting while Session A held a row-level lock.
- `Adewuyi_Faith_301853212_ConcurrencyAfterRelease.png` — Session B completing its update after Session A committed.

## 9. AI Use Declaration

- **AI Tool Used:** ChatGPT
- **Purpose:** ChatGPT was used as a learning aid for guidance on PostgreSQL transaction concepts, structuring the transaction and concurrency exercises, troubleshooting during implementation, and refining the technical documentation.
- **Verification:** The SQL statements were executed and tested in PostgreSQL using pgAdmin. COMMIT, ROLLBACK, transaction isolation, and two-session concurrency behaviour were observed directly. Query outputs and database values were checked during implementation, and identified issues were corrected before the final portfolio evidence was documented.