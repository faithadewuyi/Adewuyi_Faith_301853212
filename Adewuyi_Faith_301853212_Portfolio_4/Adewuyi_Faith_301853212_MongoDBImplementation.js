// Portfolio 4: NoSQL and Advanced Data Models
// Case Study: Abitim Farms Management System
// NoSQL Database: MongoDB
// Database Name: abitim_farms_nosql
// Collection: sales

// This script documents the MongoDB implementation used to model
// sales data for the Abitim Farms Management System.
// ------------------------------------------------------------
// 1. SALES DOCUMENT MODEL
// ------------------------------------------------------------
//
// The relational sales data from PostgreSQL was remodelled as
// MongoDB documents. Customer details and sold items are embedded
// within each sales document.
//
// Example document structure:
//
// {
//   customer: {
//     full_name: "...",
//     phone: "...",
//     email: "..."
//   },
//   sale_date: ISODate("..."),
//   payment_status: "...",
//   items: [
//     {
//       product_name: "...",
//       category: "...",
//       quantity: ...,
//       unit_price: ...,
//       subtotal: ...
//     }
//   ],
//   total_amount: ...
// }

// ------------------------------------------------------------
// 2. SAMPLE SALES DOCUMENTS
// ------------------------------------------------------------
//
// These documents correspond to sales data used in the
// Abitim Farms relational database case study.

// ------------------------------------------------------------
// EXECUTION NOTES
// ------------------------------------------------------------
//
// This file is a MongoDB shell script intended for execution
// using mongosh or the MongoDB Compass embedded shell.
//
// The script explicitly selects the Abitim Farms NoSQL database.
// It should be executed once against an empty sales collection.
//
// Rerunning the insertMany() section without clearing the existing
// sample documents will insert duplicate transactions with new
// automatically generated _id values.

db = db.getSiblingDB("abitim_farms_nosql");

db.sales.insertMany([
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
  },
  {
    customer: {
      full_name: "David Okafor",
      phone: "08023456789",
      email: "david.okafor@example.com"
    },
    sale_date: ISODate("2026-10-20T11:30:00.000Z"),
    payment_status: "pending",
    items: [
      {
        product_name: "Layer Feed 25kg",
        category: "feed",
        quantity: 1,
        unit_price: 18000,
        subtotal: 18000
      }
    ],
    total_amount: 18000
  }
]);