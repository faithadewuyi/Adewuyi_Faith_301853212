# Portfolio 5: Distributed and Cloud Database Exercise

**Case Study:** Abitim Farms Management System  
**Database System:** PostgreSQL 18  
**Primary Database:** `abitim_farms_primary`  
**Replica Database:** `abitim_farms_replica`  
**Replication Method:** PostgreSQL Logical Replication

## 1. Introduction

This portfolio demonstrates distributed database concepts using the Abitim Farms Management System case study. PostgreSQL logical replication was configured to replicate changes from a primary database, `abitim_farms_primary`, to a replica database, `abitim_farms_replica`.

A `products` table was created in both databases. The primary database was configured as the source of changes through a PostgreSQL publication, while the replica database subscribed to those changes through a subscription and logical replication slot.

The implementation was tested by inserting a product into the primary database and confirming that the record appeared automatically in the replica database. A second test updated the product stock quantity on the primary database from 100 to 85, and the same change was subsequently observed on the replica.

The practical exercise demonstrates the mechanism of database replication and provides a basis for discussing distributed database concepts including replication, availability, consistency, and cloud deployment.

The primary and replica databases used for this practical exercise were hosted within the same local PostgreSQL server instance. Therefore, the exercise demonstrates the logical replication mechanism but does not represent a production high-availability architecture. In a production environment, database replicas would normally be deployed on separate infrastructure to reduce the risk of a single point of failure.

## 2. Replication Architecture

The Portfolio 5 implementation uses PostgreSQL logical replication with a publisher-subscriber architecture.

The replication flow is represented as follows:

```text
Abitim Farms Management System

┌─────────────────────────────┐
│ abitim_farms_primary        │
│                             │
│ products table              │
│                             │
│ Publication:                │
│ abitim_farms_publication    │
└──────────────┬──────────────┘
               │
               │ Logical Replication
               │
               │ Slot:
               │ abitim_farms_slot
               ▼
┌─────────────────────────────┐
│ abitim_farms_replica        │
│                             │
│ products table              │
│                             │
│ Subscription:               │
│ abitim_farms_subscription   │
└─────────────────────────────┘
```

### 2.1 Primary Database

The `abitim_farms_primary` database acts as the publisher in the replication setup. The `products` table on this database represents product inventory maintained by Abitim Farms.

A publication named `abitim_farms_publication` was created for the `products` table. This publication makes changes to the table available for logical replication.

### 2.2 Logical Replication Slot

A logical replication slot named `abitim_farms_slot` was created on the primary database using PostgreSQL's `pgoutput` logical replication plugin.

The replication slot allows PostgreSQL to retain the required Write-Ahead Log (WAL) information until it has been consumed by the subscriber. During the practical exercise, the slot was observed as active.

### 2.3 Replica Database

The `abitim_farms_replica` database acts as the subscriber. A matching `products` table was created manually because PostgreSQL logical replication replicates data changes but does not automatically create the destination table structure.

A subscription named `abitim_farms_subscription` was created on the replica and connected to `abitim_farms_publication` through `abitim_farms_slot`.

The subscription was configured with `copy_data = false` because both product tables were initially empty. This allowed the practical exercise to demonstrate the replication of new changes made after the replication relationship had been established.
## 3. Replication Testing and Evidence

The logical replication setup was tested using the `products` table. The tests were designed to confirm that changes made on the primary database were propagated automatically to the replica database.

### 3.1 Initial State

Before testing replication, the `products` tables in both `abitim_farms_primary` and `abitim_farms_replica` contained zero rows. The subscription was configured with `copy_data = false`, so the test focused on changes made after replication had been established.

### 3.2 Insert Replication Test

A product was inserted only into the `products` table of `abitim_farms_primary`:

```sql
INSERT INTO products (
    product_name,
    category,
    unit_price,
    quantity_in_stock
)
VALUES (
    'Crate of Eggs',
    'eggs',
    4500.00,
    100
);
```

A query on the primary database confirmed that the new product had been inserted successfully.

The `products` table on `abitim_farms_replica` was then queried without manually inserting the product into the replica. The `Crate of Eggs` record appeared automatically, confirming that the insert operation had been propagated through logical replication.

**Primary evidence:** `Adewuyi_Faith_301853212_PrimaryReplicationSource.png`

**Replica evidence:** `Adewuyi_Faith_301853212_ReplicaReplicationResult.png`

### 3.3 Update Replication Test

A second test was performed to confirm that subsequent changes were also replicated. The stock quantity of `Crate of Eggs` was changed only on the primary database:

```sql
UPDATE products
SET quantity_in_stock = 85
WHERE product_name = 'Crate of Eggs';
```

The update changed the quantity from 100 to 85 on the primary database. When the replica was queried afterwards, its copy of the record also showed a quantity of 85 without a manual update being performed on the replica.

This confirmed that the logical replication relationship continued to propagate changes after the initial insert.

**Update replication evidence:** `Adewuyi_Faith_301853212_UpdateReplicationResult.png`

### 3.4 Replication Status Verification

The PostgreSQL `pg_stat_subscription` system view was queried on the replica to inspect the subscription status. The subscription `abitim_farms_subscription` had an active worker process, and the observed received_lsn and latest_end_lsn values were equal at the time of verification, showing that the subscriber had received WAL data through the latest end position reported in that subscription status. This comparison alone does not prove zero replication lag or confirm that every received change has already been applied; the separate replica queries were used to verify that the tested product changes were visible.

**Subscription status evidence:** `Adewuyi_Faith_301853212_SubscriptionStatus.png`

On the primary database, the publication and replication slot were also inspected. The results showed `abitim_farms_publication`, the `abitim_farms_slot` logical replication slot, the `pgoutput` plugin, and an active slot.

**Publication and replication slot evidence:** `Adewuyi_Faith_301853212_PublicationReplicationSlot.png`

## 4. Availability and Consistency

### 4.1 Availability

Database replication can contribute to improved availability by maintaining copies of data on more than one database instance. In a production architecture, a replica hosted on separate infrastructure can provide an additional copy of the data if the primary server experiences a failure.

The Portfolio 5 implementation demonstrates the replication mechanism but does not provide true high availability because `abitim_farms_primary` and `abitim_farms_replica` are hosted within the same local PostgreSQL server instance. A failure of the PostgreSQL service or the host computer would therefore affect both databases.

For a production deployment of the Abitim Farms Management System, the primary and replica should be placed on separate database servers or infrastructure. Additional failover mechanisms would also be required if the replica were expected to take over automatically when the primary becomes unavailable.

### 4.2 Consistency

Consistency in a replicated database environment concerns whether replicas reflect the current state of the primary database.

The practical tests showed that the replica received both the new `Crate of Eggs` record and the subsequent stock update from 100 to 85. 
During the status check, the observed received_lsn and latest_end_lsn values were equal. This provided information about the WAL positions reported by the subscription but was not treated as proof of zero replication lag. The successful replica queries provided direct evidence that the tested insert and update had become visible on the replica.

PostgreSQL logical replication is asynchronous by default. Therefore, a replica may temporarily lag behind the primary while changes are being transmitted and applied. This means an application reading from a replica immediately after a write to the primary may temporarily observe older data.

For Abitim Farms, this trade-off could be acceptable for operations such as reporting or inventory monitoring where a small replication delay may be tolerable. Operations that require the latest confirmed data should continue to use the primary database or otherwise use an architecture designed to provide the required consistency guarantees.

## 5. Cloud Database Deployment

The logical replication exercise was implemented locally using PostgreSQL 18. However, the same general primary-and-replica concept can be applied when deploying the Abitim Farms Management System using managed cloud database infrastructure.

In a cloud deployment, the primary PostgreSQL database could be hosted on a managed database service, while additional database instances or replicas could be deployed on separate cloud infrastructure. This would reduce dependence on a single physical host and could improve resilience and availability compared with the local demonstration.

A possible cloud architecture for Abitim Farms would be:

```text
Abitim Farms Application
          |
          v
+-----------------------------+
| Cloud PostgreSQL Primary    |
| Read and Write Operations   |
+-------------+---------------+
              |
              | Replication
              v
+-----------------------------+
| Cloud PostgreSQL Replica    |
| Replica / Read Workloads    |
+-----------------------------+
```

Managed PostgreSQL services offered by major cloud platforms can provide infrastructure capabilities such as automated backups, monitoring, maintenance, replication options, and high-availability configurations. The exact replication and failover features depend on the selected cloud provider and service configuration.

For Abitim Farms, a managed cloud database architecture could provide benefits such as:

1. **Improved resilience:** Database copies can be hosted on separate infrastructure rather than on one local computer.
2. **Scalability:** Database resources can be adjusted as the number of customers, products and sales increases.
3. **Backup and recovery support:** Managed services can simplify scheduled backups and recovery processes.
4. **Monitoring:** Cloud database services commonly provide tools for monitoring database health and performance.
5. **Reduced infrastructure management:** The cloud provider manages parts of the underlying database infrastructure, allowing the application team to focus more on the application and data.

The local Portfolio 5 implementation should therefore be viewed as a practical demonstration of the replication mechanism that could form part of a larger distributed or cloud database architecture. A production deployment would require additional decisions relating to security, networking, backup strategy, failover, geographic placement, cost, monitoring, and recovery objectives.
## 6. Limitations and Trade-offs

The Portfolio 5 implementation successfully demonstrated PostgreSQL logical replication, but the following limitations and trade-offs should be considered:

1. **Same-server deployment:** Both the primary and replica databases were hosted within the same PostgreSQL server instance. This is suitable for demonstrating logical replication but does not protect against failure of the PostgreSQL service or host computer.

2. **Asynchronous replication:** Logical replication is asynchronous by default, so there can be a delay between a change being committed on the primary and becoming visible on the replica.

3. **No automatic failover:** The implementation does not automatically promote the replica if the primary becomes unavailable. Production high-availability architectures require additional failover mechanisms.

4. **Schema management:** PostgreSQL logical replication does not automatically replicate schema changes. Compatible table structures must therefore be maintained on the publisher and subscriber.

5. **Selected-table replication:** The exercise replicated only the `products` table. This was sufficient to demonstrate the replication mechanism without unnecessarily reproducing the complete Abitim Farms database.

6. **Local rather than cloud deployment:** The practical implementation was performed locally. The cloud architecture discussed in this portfolio represents how the approach could be extended to separate managed infrastructure rather than evidence of an actual cloud deployment.

## 7. Summary

Portfolio 5 demonstrated distributed database concepts using PostgreSQL logical replication within the Abitim Farms Management System case study.

The implementation included:

- Configuring PostgreSQL to support logical replication using `wal_level = logical`.
- Creating separate `abitim_farms_primary` and `abitim_farms_replica` databases.
- Creating matching `products` tables on the primary and replica.
- Creating `abitim_farms_publication` on the primary database.
- Creating the logical replication slot `abitim_farms_slot` using the `pgoutput` plugin.
- Creating `abitim_farms_subscription` on the replica database.
- Testing replication by inserting `Crate of Eggs` into the primary and confirming that it appeared automatically on the replica.
- Testing continued replication by changing the stock quantity from 100 to 85 on the primary and confirming the same change on the replica.
- Inspecting the subscription, publication and logical replication slot to verify the replication setup.
- Evaluating the implications of replication for availability and consistency.
- Discussing how the local implementation could be extended to a managed cloud database architecture.

The exercise demonstrated that PostgreSQL logical replication can propagate selected data changes between databases. It also highlighted that replication alone does not provide complete high availability. Production deployment would require separate infrastructure, appropriate failover mechanisms, security, monitoring, backups and recovery planning.

## 8. Evidence Summary

The following screenshots provide evidence of the Portfolio 5 implementation:

1. `Adewuyi_Faith_301853212_PrimaryReplicationSource.png`  
   Shows the `Crate of Eggs` record in the `products` table of `abitim_farms_primary`.

2. `Adewuyi_Faith_301853212_ReplicaReplicationResult.png`  
   Shows the same record on `abitim_farms_replica` after it was inserted only on the primary.

3. `Adewuyi_Faith_301853212_UpdateReplicationResult.png`  
   Shows the replica containing the updated stock quantity of 85 after the change was made on the primary.

4. `Adewuyi_Faith_301853212_SubscriptionStatus.png`  
   Shows the PostgreSQL subscription worker and the observed replication LSN information on the replica.

5. `Adewuyi_Faith_301853212_PublicationReplicationSlot.png`  
   Shows the publication and active logical replication slot using the `pgoutput` plugin on the primary.

## 9. AI Use Declaration

- **AI Tool Used:** ChatGPT
- **Purpose:** ChatGPT was used as a learning aid to explain PostgreSQL logical replication concepts, provide step-by-step guidance during the practical implementation, assist with SQL syntax, explain replication settings and status information, and support the organisation and refinement of the technical documentation.
- **Verification:** The PostgreSQL configuration, databases, tables, publication, replication slot and subscription were configured and checked practically using PostgreSQL 18 and pgAdmin. Replication was verified by inserting and updating data on the primary database and independently querying the replica to confirm that the changes had propagated. The documented results were checked against the outputs and screenshots obtained during the practical exercise.