# MIT 8103 Advanced Database Systems Portfolio

## Abitim Farms Management System

| Student information | Details |
|---|---|
| Name | Adewuyi Faith |
| Student ID | 301853212 |
| Course | MIT 8103 – Advanced Database Systems |

## Project overview

Abitim Farms is the case study for a farming business selling eggs, poultry and animal feed. Its database requirements include customer records, product details, stock quantities, sales and purchased items. This academic repository develops the same case study progressively across five portfolios: relational design, SQL optimisation, transactions, document modelling and logical replication.

The repository contains implementation scripts, technical reports, diagrams and captured practical evidence. Portfolio 5 implements replication **locally between two databases in the same PostgreSQL server instance**. Its managed-cloud architecture is a proposal; **no actual cloud database deployment is claimed**.

## Technologies and tools

| Technology or tool | Evidenced use |
|---|---|
| PostgreSQL 18 | Relational database implementation, execution plans, transactions and local logical replication |
| pgAdmin 4 | SQL Query Tool, separate concurrency sessions and captured PostgreSQL outputs |
| SQL | Table definitions, sample data, joins, aggregation, indexing, transaction and replication statements |
| MongoDB Community Server | Document-based sales implementation |
| MongoDB Compass | Inspection of documents and execution of query filters |
| MongoDB shell syntax | JavaScript implementation file using `db.getSiblingDB`, `insertMany` and `ISODate`; execution notes support mongosh or Compass's embedded shell |
| Draw.io / diagrams.net | Editable ER diagram and PNG exports |
| Markdown | Portfolio reports and repository documentation |
| Git / GitHub | Git repository with a configured GitHub origin |

## Portfolio overview

| Portfolio | Topic | Main concepts demonstrated | Relevant folder |
|---|---|---|---|
| 1 | Database Design and Modelling | Entities, relationships, keys, constraints, ER modelling, normalisation | [Adewuyi_Faith_301853212_Portfolio_1](Adewuyi_Faith_301853212_Portfolio_1/) |
| 2 | Query Processing and Optimisation | Filtering, joins, aggregation, execution plans, indexing and timing analysis | [Adewuyi_Faith_301853212_Portfolio_2](Adewuyi_Faith_301853212_Portfolio_2/) |
| 3 | Transactions and Concurrency | COMMIT, ROLLBACK, READ COMMITTED, row locks and concurrent writes | [Adewuyi_Faith_301853212_Portfolio_3](Adewuyi_Faith_301853212_Portfolio_3/) |
| 4 | NoSQL and Advanced Data Models | Embedded customer documents, item arrays and MongoDB queries | [Adewuyi_Faith_301853212_Portfolio_4](Adewuyi_Faith_301853212_Portfolio_4/) |
| 5 | Distributed and Cloud Database Exercise | Local logical replication, availability, consistency and proposed cloud architecture | [Adewuyi_Faith_301853212_Portfolio_5](Adewuyi_Faith_301853212_Portfolio_5/) |

## Portfolio 1: Database Design and Modelling

[Read the design report](Adewuyi_Faith_301853212_Portfolio_1/Adewuyi_Faith_301853212_DatabaseDesign.md).

The relational design separates four entities:

| Table | Purpose and relationships |
|---|---|
| `customers` | Customer name, contact details and creation timestamp; one customer can have many sales |
| `products` | Product name, category, current price and stock; one product can occur in many sale items |
| `sales` | Customer reference, sale timestamp and payment status; one sale can have many sale items |
| `sale_items` | Sale and product references, quantity and historical price charged |

Each table has an identity primary key. Foreign keys connect sales to customers and sale items to sales and products. Deleting a sale cascades to its sale items. Required fields use `NOT NULL`; unique constraints cover product names and optional customer phone/email values. Check constraints restrict categories and payment statuses, require positive item quantities, and prevent negative prices and stock. Defaults supply timestamps, initial stock and pending payment status.

The report explains 1NF, 2NF and 3NF using functional dependencies and a worked decomposition. The final schema uses single-column identifiers; the worked example separately assumes a composite sale/product key. `unit_price_at_sale` deliberately preserves the historical selling price independently of the current product price.

The sample-data script contains three customers, four products and two sales with corresponding line items. ER diagram source, exported diagrams, table-creation evidence and a sample join result accompany the design.

## Portfolio 2: Query Processing and Optimisation

[Read the optimisation report](Adewuyi_Faith_301853212_Portfolio_2/Adewuyi_Faith_301853212_QueryProcessingOptimisation.md).

The experiment adds 5,000 generated products to the original four, giving 5,004 products, including 52 poultry records. A category-filter query is analysed before and after creating `idx_products_category`, using `EXPLAIN ANALYZE` and a later `EXPLAIN (ANALYZE, BUFFERS)` capture.

| Capture on the 5,004-product dataset | Access method | Planning time | Execution time |
|---|---|---:|---:|
| Before index | Sequential Scan | 7.447 ms | 1.083 ms |
| First indexed capture | Bitmap Heap Scan + Bitmap Index Scan | 22.109 ms | 2.848 ms |
| Subsequent indexed capture | Bitmap Heap Scan + Bitmap Index Scan | 0.952 ms | 0.194 ms |

The unindexed scan removes 4,952 rows through filtering. The indexed plans demonstrate that PostgreSQL selected the category index. The first indexed capture was slower than the unindexed capture, while the subsequent capture was faster. These individual measurements establish a plan change and observed timing variation, rather than a guaranteed percentage improvement. Cache state, I/O, system activity and measurement overhead can influence timings. The original four-product plan is introductory evidence, not the comparable larger-dataset baseline.

A separate query joins `sales`, `customers` and `sale_items`, groups sales and calculates totals using `SUM(quantity * unit_price_at_sale)`. Results show ₦9,000 for Amina Bello and ₦18,000 for David Okafor. Its plan includes hash joins, sequential scans, sorting and `GroupAggregate`; the captured execution time is 0.268 ms. Planning time is distinct from execution time and from pgAdmin's overall completion time. Parent and child buffer statistics should not be added together.

## Portfolio 3: Transactions and Concurrency

[Read the transaction report](Adewuyi_Faith_301853212_Portfolio_3/Adewuyi_Faith_301853212_TransactionsConcurrency.md).

The exercises use inventory rows from the relational database, including test products introduced in Portfolio 2.

- **ROLLBACK:** `Crate of Eggs` changes from 100 to 90 within a transaction; cancelling the transaction leaves the committed quantity at 100.
- **COMMIT:** In the captured exercise, `Test Product 10` starts at 8, decreases to 6 and remains at 6 after commit.
- **Isolation:** `SHOW transaction_isolation` reports `read committed`. An ordinary SELECT sees data committed before that statement begins, together with its own transaction's earlier changes.
- **Concurrent writes:** Two independent pgAdmin sessions target `Test Product 20`. Session A reduces stock from 20 to 18 and leaves its transaction open. Session B initially reads the committed value of 20, then its conflicting decrement waits. After Session A commits, Session B applies its decrement to 18, producing 17. Session B's standalone update uses autocommit.

This demonstrates concurrent-write contention, an unseen uncommitted change and a waiting update that resumes after lock release. The captured result does not demonstrate a lost update or a deadlock.

## Portfolio 4: NoSQL and Advanced Data Models

[Read the NoSQL report](Adewuyi_Faith_301853212_Portfolio_4/Adewuyi_Faith_301853212_NoSQLAdvancedDataModels.md).

Selected Abitim Farms sales are remodelled in the `sales` collection of `abitim_farms_nosql`. Each document contains an embedded `customer` object, `sale_date`, `payment_status`, an `items` array and `total_amount`. Item documents hold product name, category, quantity, unit price and subtotal. MongoDB supplies the document `_id`.

The implementation file inserts two sales: Amina Bello's paid eggs sale totalling 9,000 and David Okafor's pending feed sale totalling 18,000. Each sample currently contains one item, although the array structure can represent multiple items.

The report and Compass screenshots demonstrate these filters:

| Query concept | Compass filter | Captured result |
|---|---|---|
| Top-level equality | `{ payment_status: "pending" }` | David's sale |
| Embedded customer field | `{ "customer.full_name": "Amina Bello" }` | Amina's sale |
| Field within item array | `{ "items.category": "feed" }` | David's sale |
| Numeric comparison | `{ total_amount: { $gt: 10000 } }` | David's sale |

The JavaScript file contains the document insertion; the retrieval filters are in the Markdown report. Embedding makes a complete sale convenient to retrieve without reconstructing it through relational joins. It also duplicates customer and product details across sales, requiring a deliberate choice between historical snapshots and centrally maintained values. The evaluation compares this model with PostgreSQL's central records, relationships, constraints and transactional processing.

## Portfolio 5: Distributed and Cloud Database Exercise

[Read the replication report](Adewuyi_Faith_301853212_Portfolio_5/Adewuyi_Faith_301853212_DistributedCloudDatabase.md).

The practical implementation uses PostgreSQL 18 logical replication on the local host:

```text
Same local PostgreSQL server instance
abitim_farms_primary.products
    -> publication: abitim_farms_publication
    -> logical slot: abitim_farms_slot (pgoutput)
    -> subscription: abitim_farms_subscription
    -> abitim_farms_replica.products
```

The documented configuration sets `wal_level = logical` and records a service restart and setting checks. Matching `products` tables are created manually in `abitim_farms_primary` and `abitim_farms_replica`. The primary publishes only `products`, and its logical replication slot uses `pgoutput`. The replica subscription connects through localhost and reuses the existing slot with `create_slot = false`. Because both tables initially contained no rows, `copy_data = false` is used to focus on subsequent changes.

An INSERT on the primary creates `Crate of Eggs` with stock 100; a replica query shows the same row without a manual replica insert. A subsequent UPDATE on the primary changes stock to 85, which is also visible on the replica. Screenshots record the publication, active logical slot and subscription worker. The observed equality of `received_lsn` and `latest_end_lsn` reports matching received/end positions at that moment; it does not independently prove zero lag or that every received change has been applied. Separate replica queries establish visibility of the tested changes.

The availability and consistency discussion identifies several limits:

- Both databases share a server instance and host, so either failure affects both; the demonstration does not provide independent failure protection or automatic failover.
- Logical replication is asynchronous by default, so replica reads can temporarily return older data. The portfolio discusses reporting as a possible replica workload and the primary for operations requiring current data.
- Only the `products` table is replicated. Compatible schema definitions must be maintained separately because schema changes are not automatically replicated.

The proposed managed-cloud extension places primary and replica workloads on separate infrastructure and discusses backups, monitoring, maintenance, scaling and resilience. Provider configuration, networking, security, failover and recovery planning remain architectural decisions. **The tested replication implementation is local; the repository does not evidence an actual cloud deployment.**

## Repository structure

The tree below lists the repository's assignment files and this README. Git's internal `.git` directory is omitted. Original filenames, including repeated `.png` extensions, are preserved.

```text
Adewuyi_Faith_301853212/
|-- README.md
|-- Adewuyi_Faith_301853212_Portfolio_1/
|   |-- Adewuyi_Faith_301853212_CreateTables.sql
|   |-- Adewuyi_Faith_301853212_DatabaseDesign.md
|   |-- Adewuyi_Faith_301853212_ERDiagram.png.png
|   |-- Adewuyi_Faith_301853212_ERDiagram1.drawio
|   |-- Adewuyi_Faith_301853212_ERDiagram1.drawio.png
|   |-- Adewuyi_Faith_301853212_SampleData.sql
|   |-- Adewuyi_Faith_301853212_ScreenshotsEvidence/
|   |   |-- Adewuyi_Faith_301853212_CreateTablesExecution.png.png
|   |   |-- Adewuyi_Faith_301853212_DatabaseTablesCreated.png.png
|   |   |-- Adewuyi_Faith_301853212_ERDiagram.png.png
|   |   |-- Adewuyi_Faith_301853212_ERDiagram1.drawio.png
|   |   |-- Adewuyi_Faith_301853212_SampleJoinQuery.png.png
|-- Adewuyi_Faith_301853212_Portfolio_2/
|   |-- Adewuyi_Faith_301853212_Portfolio_2_Evidence/
|   |   |-- Adewuyi_Faith_301853212_AfterIndexExecutionPlan.png
|   |   |-- Adewuyi_Faith_301853212_AfterIndexPerformance.png
|   |   |-- Adewuyi_Faith_301853212_BeforeIndexExecutionPlan.png
|   |   |-- Adewuyi_Faith_301853212_CategoryIndexCreated.png
|   |   |-- Adewuyi_Faith_301853212_LargeDatasetBeforeIndex.png
|   |   |-- Adewuyi_Faith_301853212_ProductCategoryQuery.png
|   |   |-- Adewuyi_Faith_301853212_SalesJoinExecutionPlan_Part1.png
|   |   |-- Adewuyi_Faith_301853212_SalesJoinExecutionPlan_Part2.png
|   |   |-- Adewuyi_Faith_301853212_SalesTotalQuery.png
|   |   |-- Adewuyi_Faith_301853212_TestDataDistribution.png
|   |-- Adewuyi_Faith_301853212_QueryOptimisation.sql
|   |-- Adewuyi_Faith_301853212_QueryProcessingOptimisation.md
|-- Adewuyi_Faith_301853212_Portfolio_3/
|   |-- Adewuyi_Faith_301853212_Evidence/
|   |   |-- Adewuyi_Faith_301853212_CommitAfter.png
|   |   |-- Adewuyi_Faith_301853212_CommitBefore.png
|   |   |-- Adewuyi_Faith_301853212_ConcurrencyAfterRelease.png
|   |   |-- Adewuyi_Faith_301853212_ConcurrencyWaiting.png
|   |   |-- Adewuyi_Faith_301853212_IsolationLevel.png
|   |   |-- Adewuyi_Faith_301853212_RollbackBefore.png
|   |   |-- Adewuyi_Faith_301853212_RollbackDemonstration.png
|   |   |-- Adewuyi_Faith_301853212_TransactionInitialStock.png
|   |-- Adewuyi_Faith_301853212_TransactionsConcurrency.md
|   |-- Adewuyi_Faith_301853212_TransactionsConcurrency.sql
|-- Adewuyi_Faith_301853212_Portfolio_4/
|   |-- Adewuyi_Faith_301853212_Evidence/
|   |   |-- Adewuyi_Faith_301853212_MongoDBArrayQuery.png
|   |   |-- Adewuyi_Faith_301853212_MongoDBComparisonQuery.png
|   |   |-- Adewuyi_Faith_301853212_MongoDBEmbeddedDocument.png
|   |   |-- Adewuyi_Faith_301853212_MongoDBNestedFieldQuery.png
|   |   |-- Adewuyi_Faith_301853212_MongoDBPendingSalesQuery.png
|   |-- Adewuyi_Faith_301853212_MongoDBImplementation.js
|   |-- Adewuyi_Faith_301853212_NoSQLAdvancedDataModels.md
|-- Adewuyi_Faith_301853212_Portfolio_5/
|   |-- Adewuyi_Faith_301853212_DistributedCloudDatabase.md
|   |-- Adewuyi_Faith_301853212_Evidence/
|   |   |-- Adewuyi_Faith_301853212_PrimaryReplicationSource.png
|   |   |-- Adewuyi_Faith_301853212_PublicationReplicationSlot.png
|   |   |-- Adewuyi_Faith_301853212_ReplicaReplicationResult.png
|   |   |-- Adewuyi_Faith_301853212_SubscriptionStatus.png
|   |   |-- Adewuyi_Faith_301853212_UpdateReplicationResult.png
|   |-- Adewuyi_Faith_301853212_LogicalReplication.sql
```

## Evidence and screenshots

Each portfolio includes supporting evidence appropriate to its exercise:

| Portfolio | Evidence location within its portfolio folder | Contents |
|---|---|---|
| 1 | `Adewuyi_Faith_301853212_ScreenshotsEvidence/` and root diagram files | ER diagrams, successful table creation, four-table listing and sample join output |
| 2 | `Adewuyi_Faith_301853212_Portfolio_2_Evidence/` | Category query, test-data distribution, index creation, execution plans, timings, buffers and sales totals |
| 3 | `Adewuyi_Faith_301853212_Evidence/` | Initial stock, rollback and commit results, isolation level, waiting update and result after release |
| 4 | `Adewuyi_Faith_301853212_Evidence/` | Expanded MongoDB document and pending, nested, array and comparison query results |
| 5 | `Adewuyi_Faith_301853212_Evidence/` | Primary/replica rows, replicated stock update, subscription status and publication/slot status |

These are captured practical outputs. They document the exercises at the time of capture and do not establish the current state of any running database.

## Key learning outcomes

The five portfolios connect database design choices to observed database behaviour:

- Relational modelling separates entities, expresses dependencies and uses keys and constraints to protect integrity while preserving historical sale prices.
- Query optimisation requires comparable datasets, execution-plan interpretation and cautious treatment of individual timing measurements.
- Transactions control whether changes persist; isolation and row locking determine how concurrent sessions observe and modify shared data.
- Relational and document models organise the same sales scenario differently, with trade-offs between centralised relationships, convenient retrieval and duplicated snapshots.
- Logical replication propagates selected changes, while status information and direct data queries answer different verification questions.
- Replication, availability and consistency are related but distinct: an additional database on the same host does not remove that host as a failure point, and asynchronous replicas can lag.
- Extending a local exercise to distributed or managed-cloud infrastructure requires explicit decisions about independent infrastructure, failover, security, backups, monitoring and recovery.

## Reproduction and usage notes

Read each report and implementation file's comments before executing selected statements in an appropriate local learning environment. The scripts record completed exercises and are not a single automated setup procedure. No database commands were executed while preparing this README.

1. **Portfolio 1:** In a fresh PostgreSQL case-study database (the evidence uses `abitim_farms`), interpret `Adewuyi_Faith_301853212_CreateTables.sql` before `Adewuyi_Faith_301853212_SampleData.sql`. Existing tables cause creation conflicts; repeated sample inserts can violate unique constraints or duplicate sales and line items. Inspect existing objects and data first.
2. **Portfolio 2:** `Adewuyi_Faith_301853212_QueryOptimisation.sql` assumes Portfolio 1's schema and original sample data. The before-index experiment requires the category index to be absent. Generate the 5,000 test rows only once; product names are unique. Create the index only once in the intended experiment state. Compare plans on the same dataset and expect timings to vary.
3. **Portfolio 3:** `Adewuyi_Faith_301853212_TransactionsConcurrency.sql` depends on the earlier relational dataset. Confirm the documented starting stock values: eggs 100, Test Product 10 at 8 and Test Product 20 at 20. The COMMIT and concurrency exercises persist changes, so repeated runs change numerical results. Follow the commented execution order in two independent pgAdmin Query Tool sessions; do not run the entire concurrency section as one script. Check Session B's autocommit setting.
4. **Portfolio 4:** `Adewuyi_Faith_301853212_MongoDBImplementation.js` uses MongoDB shell syntax, intended for mongosh or Compass's embedded shell rather than a standalone Node.js application. It selects `abitim_farms_nosql` and inserts into `sales`. Its insertion section is intended for a single execution against an empty sample collection: rerunning creates duplicate transactions with new `_id` values. Use the report's filters in Compass, or as the filter argument to `db.sales.find(...)` in the selected database.
5. **Portfolio 5:** `Adewuyi_Faith_301853212_LogicalReplication.sql` explicitly documents an existing setup and must not be run from top to bottom against it. Statements target different connections: `postgres`, `abitim_farms_primary` and `abitim_farms_replica`. Database, table, publication, slot and subscription creation requires deliberate setup in a fresh environment. `copy_data = false` does not copy pre-existing rows. Review the configuration and connection comments before attempting a separate reproduction.

### Repository details affecting interpretation

- Portfolio 1 includes two ER diagram export variants, with differing connector presentation, and copies in the evidence folder. Its report links `Adewuyi_Faith_301853212_ERDiagram1.drawio.png`. Use the SQL foreign keys and the report's explicit relationship descriptions when interpreting cardinality.
- Portfolio 2's generator initially assigns `Test Product 10` stock 10, whereas Portfolio 3's captured starting value is 8. The repository does not include a separate preparation statement explaining that intervening change; a fresh sequential run will therefore not automatically reproduce its 8-to-6 result.
- Portfolio 4 reuses the customer names, products and sale totals, but its sample contact details and explicit sale dates differ from the relational sample data. Treat these as separately constructed documents for the same case study, rather than evidence of an exact export or automated migration.
- Portfolio 5 uses a separate, simplified `products` schema. Unlike Portfolio 1, it omits the unique product-name and business-rule CHECK constraints; it demonstrates selected-table replication rather than replication of the complete original schema.

## Security

Credentials and passwords should not be committed to source control. The replication script retains the placeholder `<POSTGRES_PASSWORD>` rather than an actual password. Replace placeholders only in a secure local environment when required, and keep credential-bearing copies outside committed source files.

## AI use declaration

ChatGPT was used as a learning and support tool for database concepts, implementation guidance, SQL and MongoDB syntax, troubleshooting and documentation. Portfolio 1 also acknowledges Gemini and OpenAI Codex. As stated in the portfolio declarations, implementation steps and outputs were practically tested and verified using PostgreSQL/pgAdmin and MongoDB Community Server/Compass as applicable, with results checked against the captured evidence. Preparation of this README involved reviewing those files and outputs without rerunning the database exercises.

## Conclusion

The Abitim Farms portfolios progress from relational database design and normalisation through query optimisation, transaction and concurrency behaviour, MongoDB document modelling and local logical replication. Together, the implementations and reflections demonstrate how data structures, execution strategies and replication choices affect integrity, performance, consistency and proposed distributed/cloud architecture.

