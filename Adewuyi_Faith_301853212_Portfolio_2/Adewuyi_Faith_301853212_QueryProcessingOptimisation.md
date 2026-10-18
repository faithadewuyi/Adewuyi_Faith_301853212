# Portfolio 2: Query Processing and Optimisation

## 1. Overview

This portfolio demonstrates query processing and optimisation using the Abitim Farms Management System implemented in PostgreSQL. The exercise examines how PostgreSQL executes SQL queries, how execution plans can be analysed using `EXPLAIN ANALYZE`, and how indexing can influence query execution strategies and performance.

The portfolio uses queries involving filtering, joins, aggregation, execution-plan analysis, and indexing. Performance measurements were obtained directly from PostgreSQL using the implemented Abitim Farms database.

## 2. Test Dataset

The original Abitim Farms database contained a small number of product records, which was insufficient for demonstrating meaningful query optimisation behaviour. Therefore, 5,000 additional test product records were generated using PostgreSQL's `generate_series()` function.

This increased the `PRODUCTS` table to 5,004 records. The test data contained 52 products in the `poultry` category, while the remaining records were distributed across the `eggs`, `feed`, and `other` categories.

The larger dataset provided a more suitable basis for comparing query execution plans before and after indexing.

## 3. Query Execution and Performance Analysis

### 3.1 Query Before Indexing

The following query was used to retrieve products belonging to the `poultry` category:

```sql
SELECT *
FROM products
WHERE category = 'poultry';
```
### 3.2 Index Creation

To optimise searches based on product category, an index was created on the `category` column:

```sql
CREATE INDEX idx_products_category
ON products(category);
```

The index provides PostgreSQL with an alternative access path for locating products by category instead of relying only on a sequential scan.

### 3.3 Query After Indexing

After creating `idx_products_category`, the same query was analysed again using `EXPLAIN ANALYZE`.

PostgreSQL changed the execution strategy from a **Sequential Scan** to a **Bitmap Heap Scan** supported by a **Bitmap Index Scan**.

The two bitmap operations perform different tasks:

- **Bitmap Index Scan:** PostgreSQL uses `idx_products_category` to identify the locations of rows that satisfy `category = 'poultry'`.
- **Bitmap Heap Scan:** PostgreSQL then retrieves the corresponding rows from the `PRODUCTS` table.

This confirms that PostgreSQL's query planner selected the newly created index for the category filter.

The first indexed execution recorded:

- Planning time: 22.109 ms
- Execution time: 2.848 ms

A later indexed execution recorded:

- Planning time: 0.952 ms
- Execution time: 0.194 ms

The later execution also reported `Buffers: shared hit=44`, while the Bitmap Index Scan child reported `shared hit=2`. These buffer statistics should not be added together because PostgreSQL's parent-node buffer values include activity from its child nodes.

### 3.4 Performance Comparison

The original four-product execution was useful for introducing `EXPLAIN ANALYZE`, but it is not used as the main performance baseline because the dataset size was different.

The meaningful comparison uses the same 5,004-product dataset before and after creation of the index.

| Test | Access Method | Planning Time | Execution Time |
|---|---|---:|---:|
| 5,004 products before index | Sequential Scan | 7.447 ms | 1.083 ms |
| 5,004 products, first indexed capture | Bitmap Heap Scan + Bitmap Index Scan | 22.109 ms | 2.848 ms |
| 5,004 products, subsequent indexed capture | Bitmap Heap Scan + Bitmap Index Scan | 0.952 ms | 0.194 ms |

Before indexing, the Sequential Scan returned 52 matching poultry products and removed 4,952 non-matching rows through filtering.

After indexing, PostgreSQL used `idx_products_category` to identify matching row locations through a Bitmap Index Scan and then retrieved the corresponding table rows through a Bitmap Heap Scan.

The first indexed execution was slower than the unindexed execution, while a subsequent indexed execution was faster. Therefore, these individual measurements should not be interpreted as proof that indexing will always produce a specific percentage improvement.

Execution time can vary between runs because of factors such as caching, I/O activity, system activity, and measurement overhead. The strongest evidence of optimisation in this experiment is the change in PostgreSQL's execution strategy and its successful use of the category index.

### 3.5 Planning Time and Execution Time

`EXPLAIN ANALYZE` reports planning time and execution time separately.

**Planning Time** represents the time PostgreSQL spends analysing the query and selecting an execution plan.

**Execution Time** represents the time spent executing the selected plan and producing the result.

These measurements are different from the overall completion time displayed by pgAdmin, which may include additional client and communication overhead. Because the measured queries execute very quickly, small timing differences between individual runs should be interpreted carefully.
## 4. Query Processing with Joins and Aggregation

A second query was used to demonstrate how PostgreSQL processes a more complex operation involving multiple tables, joins, grouping, and aggregation.

The query calculates the total value of each sale by combining records from the `SALES`, `CUSTOMERS`, and `SALE_ITEMS` tables.

```sql
SELECT
    s.sale_id,
    c.full_name AS customer,
    s.sale_date,
    s.payment_status,
    SUM(si.quantity * si.unit_price_at_sale) AS total_amount
FROM sales s
JOIN customers c
    ON c.customer_id = s.customer_id
JOIN sale_items si
    ON si.sale_id = s.sale_id
GROUP BY
    s.sale_id,
    c.full_name,
    s.sale_date,
    s.payment_status
ORDER BY s.sale_id;
```

The query returned two existing sales records. The calculated total for Amina Bello's sale was ₦9,000, while David Okafor's sale had a total value of ₦18,000.

### 4.1 Execution Plan Analysis

`EXPLAIN ANALYZE` was used to examine how PostgreSQL processed the sales query.

The execution plan showed that PostgreSQL performed several operations to produce the final result.

First, PostgreSQL used hash-based join operations to combine the related tables. One Hash Join matched `SALE_ITEMS` with `SALES` using the condition `si.sale_id = s.sale_id`. Another Hash Join matched the resulting records with `CUSTOMERS` using `s.customer_id = c.customer_id`.

Sequential scans were used on the small `SALES` and `CUSTOMERS` tables. This is reasonable because these tables contain very few records, and PostgreSQL estimated that scanning them directly was an efficient strategy.

After joining the records, PostgreSQL used a Sort operation with the sort key `s.sale_id, c.full_name`. The execution plan reported that the sort used the `quicksort` method.

A `GroupAggregate` operation was then used to group the joined records by `s.sale_id` and `c.full_name` and calculate the sales totals using:

`SUM(si.quantity * si.unit_price_at_sale)`

The execution plan therefore demonstrates several stages of query processing, including table scanning, hash joins, sorting, and aggregation.

The recorded statistics were:

- Planning time: 9.955 ms
- Execution time: 0.268 ms

The planning time represents the time PostgreSQL spent analysing the query and selecting an execution strategy, while the execution time represents the time spent carrying out the selected plan.

This demonstrates that PostgreSQL's query planner can combine different processing strategies within a single query rather than using one access method for every operation.

## 5. Implementation Evidence

The following screenshots provide evidence of the query processing and optimisation activities performed in PostgreSQL:

1. `Adewuyi_Faith_301853212_ProductCategoryQuery.png`  
   Shows the initial query used to retrieve products in the poultry category.

2. `Adewuyi_Faith_301853212_BeforeIndexExecutionPlan.png`  
   Shows the execution plan when the original database contained only a small number of product records.

3. `Adewuyi_Faith_301853212_TestDataDistribution.png`  
   Shows the distribution of the 5,004 product records used for the larger optimisation experiment.

4. `Adewuyi_Faith_301853212_LargeDatasetBeforeIndex.png`  
   Shows the Sequential Scan performed before creating the category index, including 4,952 rows removed by the filter.

5. `Adewuyi_Faith_301853212_CategoryIndexCreated.png`  
   Shows the creation of `idx_products_category` on the product category column.

6. `Adewuyi_Faith_301853212_AfterIndexExecutionPlan.png`  
   Shows PostgreSQL using a Bitmap Index Scan after the index was created.

7. `Adewuyi_Faith_301853212_AfterIndexPerformance.png`  
   Shows a subsequent indexed execution, including buffer information and an execution time of 0.194 ms.

8. `Adewuyi_Faith_301853212_SalesTotalQuery.png`  
   Shows the multi-table JOIN and aggregation query used to calculate sales totals.

9. `Adewuyi_Faith_301853212_SalesJoinExecutionPlan_Part1.png`  
   Shows the upper portion of the sales execution plan, including the GroupAggregate, Sort, and Hash Join operations.

10. `Adewuyi_Faith_301853212_SalesJoinExecutionPlan_Part2.png`  
    Shows the lower portion of the sales execution plan, including hash operations, sequential scans, planning time, and execution time.