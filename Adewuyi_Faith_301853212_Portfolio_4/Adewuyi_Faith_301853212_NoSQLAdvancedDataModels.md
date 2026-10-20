# Portfolio 4: NoSQL and Advanced Data Models

**Case Study:** Abitim Farms Management System  
**NoSQL Database:** MongoDB  
**Database Name:** `abitim_farms_nosql`  
**Collection:** `sales`

## 1. Introduction

This portfolio extends the Abitim Farms Management System by implementing a NoSQL document model using MongoDB.

The earlier relational implementation used PostgreSQL, where sales information was distributed across related tables including `customers`, `sales`, `sale_items`, and `products`. For the NoSQL implementation, selected sales data was remodelled as MongoDB documents.

Each sales document contains customer information, transaction details, and an array of purchased items. This approach demonstrates the use of embedded documents and arrays in a document-oriented database while maintaining the same Abitim Farms case study used throughout the database portfolio.
## 2. NoSQL Data Model Design

MongoDB uses a document-oriented data model in which data is stored as flexible BSON documents. For the Abitim Farms NoSQL implementation, the `sales` collection was designed so that information required to represent a sale is grouped within a single document.

The main structure of a sales document is:

```text
sales
├── _id
├── customer
│   ├── full_name
│   ├── phone
│   └── email
├── sale_date
├── payment_status
├── items
│   └── [
│       ├── product_name
│       ├── category
│       ├── quantity
│       ├── unit_price
│       └── subtotal
│      ]
└── total_amount
```

## 3. MongoDB Implementation

A MongoDB database named `abitim_farms_nosql` was created using MongoDB Community Server and accessed through MongoDB Compass. A collection named `sales` was created to store the document-based representation of sales transactions.

Two sample sales documents based on the existing Abitim Farms case study were inserted into the collection.

### Sample Document

One of the inserted documents represents a sale made to Amina Bello:

```javascript
{
  customer: {
    full_name: "Amina Bello",
    phone: "08012345678",
    email: "amina.bello@example.com"
  },
  sale_date: ISODate("2026-10-20T10:00:00.000Z"),
  payment_status: "paid",
  items: [
    {
      product_name: "Crate of Eggs",
      category: "eggs",
      quantity: 2,
      unit_price: 4500,
      subtotal: 9000
    }
  ],
  total_amount: 9000
}
```

The document stores the customer details and purchased items within the sales record. MongoDB automatically generated an `_id` value to uniquely identify the document.

A second document was inserted for David Okafor. This transaction contained one `Layer Feed 25kg` item with a total amount of 18,000 and a payment status of `pending`.

### Implementation Evidence

The implemented document was viewed in MongoDB Compass with the embedded `customer` object and `items` array expanded.

**Evidence:** `Adewuyi_Faith_301853212_MongoDBEmbeddedDocument.png`
The implementation was completed progressively. The embedded-document evidence was captured after the first sales document was inserted, while the query evidence was captured after the second sample sales document had been added to the collection.

## 4. MongoDB Queries and Results

Several queries were executed in MongoDB Compass to demonstrate retrieval of data from the `sales` collection, including queries on top-level fields, embedded documents, arrays, and numeric values.

### Query 1: Find Pending Sales

```javascript
{ payment_status: "pending" }
```

The query returned one document: David Okafor's sale with a payment status of `pending` and a total amount of 18,000.

**Evidence:** `Adewuyi_Faith_301853212_MongoDBPendingSalesQuery.png`

### Query 2: Query an Embedded Customer Field

```javascript
{ "customer.full_name": "Amina Bello" }
```

MongoDB dot notation was used to query the `full_name` field inside the embedded `customer` document. The query returned Amina Bello's sales document with a total amount of 9,000.

**Evidence:** `Adewuyi_Faith_301853212_MongoDBNestedFieldQuery.png`

### Query 3: Query a Field Within the Items Array

```javascript
{ "items.category": "feed" }
```

The query searched the embedded documents contained within the `items` array. It returned David Okafor's transaction containing the `Layer Feed 25kg` product in the `feed` category.

**Evidence:** `Adewuyi_Faith_301853212_MongoDBArrayQuery.png`

### Query 4: Find Sales Above a Specified Amount

```javascript
{ total_amount: { $gt: 10000 } }
```

The `$gt` comparison operator was used to retrieve sales with a total amount greater than 10,000. The query returned David Okafor's sale with a total amount of 18,000.

**Evidence:** `Adewuyi_Faith_301853212_MongoDBComparisonQuery.png`

## 5. Suitability of MongoDB for Abitim Farms

MongoDB is suitable for representing selected Abitim Farms data because sales transactions naturally contain related information that can be grouped together as a document. A sale can contain customer details, transaction information, and multiple purchased items within a single document.

### Advantages of the Document Model

**1. Related data can be stored together**

Embedding the customer details and purchased items within a sales document allows information required to describe a transaction to be retrieved together without performing multiple relational joins.

**2. Support for multiple purchased items**

The `items` array allows a sales document to contain one or more products. Each item can store its product name, category, quantity, unit price, and subtotal.

**3. Flexible document structure**

MongoDB documents can accommodate additional fields when application requirements change. For example, future sales documents could include delivery information or other transaction-specific attributes where required.

**4. Convenient querying of nested data**

MongoDB supports dot notation for querying fields within embedded documents and arrays. This was demonstrated by querying `customer.full_name` and `items.category` in the implementation.

### Trade-offs and Limitations

The document model also introduces trade-offs. Embedding customer and product information may duplicate data across multiple sales documents. For example, the same customer's name and contact information could appear in several transactions.

If a customer's contact information changes, updating the central customer record would not automatically change historical values embedded in previous sales documents. This may be desirable when the embedded values represent a historical snapshot, but it requires deliberate data-modelling decisions.

The relational PostgreSQL model remains useful where strong relationships, centralised records, constraints, and structured transactional processing are important. Therefore, the MongoDB implementation is not presented as a replacement for the relational database. It demonstrates how selected Abitim Farms sales data can alternatively be represented using a document-oriented model.

### Suitability Conclusion

For transaction-oriented views where a complete sale and its associated details are frequently retrieved together, MongoDB's embedded document and array model provides a practical representation. It is therefore suitable for demonstrating a NoSQL approach to the Abitim Farms sales data while highlighting both the benefits and trade-offs of document-oriented database design.
## 6. Summary

This portfolio implemented a NoSQL document model for the Abitim Farms Management System using MongoDB.

A MongoDB database named `abitim_farms_nosql` and a `sales` collection were created. Sales transactions were modelled as documents containing embedded customer information and an array of purchased items.

The implementation demonstrated:

- Creation of a MongoDB document-based sales model.
- Use of embedded documents and arrays.
- Storage of sample sales transactions based on the existing Abitim Farms case study.
- Filtering using top-level document fields.
- Querying fields within embedded documents using dot notation.
- Querying fields within arrays of embedded documents.
- Use of the `$gt` comparison operator.
- Evaluation of the benefits and limitations of the document-oriented approach.

The exercise demonstrates how the same case-study data can be represented differently in relational and NoSQL database systems.

## 7. Evidence Summary

The following screenshots were captured during the MongoDB implementation:

- `Adewuyi_Faith_301853212_MongoDBEmbeddedDocument.png` — MongoDB sales document showing the embedded customer object and items array.
- `Adewuyi_Faith_301853212_MongoDBPendingSalesQuery.png` — query returning a sale with `payment_status` equal to `pending`.
- `Adewuyi_Faith_301853212_MongoDBNestedFieldQuery.png` — query of the embedded `customer.full_name` field.
- `Adewuyi_Faith_301853212_MongoDBArrayQuery.png` — query of the `category` field within the embedded `items` array.
- `Adewuyi_Faith_301853212_MongoDBComparisonQuery.png` — `$gt` query returning sales with a total amount greater than 10,000.

## 8. AI Use Declaration

- **AI Tool Used:** ChatGPT
- **Purpose:** ChatGPT was used as a learning aid for guidance on MongoDB installation and configuration, NoSQL document modelling, MongoDB query syntax, structuring the implementation exercise, and refining the technical documentation.
- **Verification:** The MongoDB database, collection, documents, and queries were implemented and tested using MongoDB Community Server and MongoDB Compass. Query results and document structures were observed directly, and the documented implementation was checked against the practical results obtained during the exercise.