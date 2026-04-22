# Enterprise Accounting System

A complete, production-ready financial management platform built on Microsoft SQL Server.

## Overview

This is a real accounting system that handles double-entry bookkeeping, inventory tracking, customer management, and financial reporting. It's been used in production environments and follows proper accounting principles.

I built this because most small business accounting solutions either cost too much or don't give you direct database access. This system gives you full control while maintaining all the professional accounting features you need.

## What's Inside

The system handles everything from sales invoices to inventory movements to financial statements. Every transaction follows double-entry accounting rules - debits always equal credits. Nothing gets posted without proper balancing.

**Key capabilities:**
- Full double-entry accounting with chart of accounts
- Inventory tracking with movement history (not just current stock)
- Customer, supplier, and employee management in one place
- Document management for invoices, purchase orders, receipts
- Cash register and shift management for retail
- Pricing rules that change based on customer type or quantity
- Complete audit trail of every change

## Database Structure

The database uses separate schemas to keep things organized. Here's what each one does:

**accounting** - Chart of accounts, journal entries, trial balance
**inventory** - Stock movements, locations, current quantities
**master** - Company info, branches, currencies, fiscal periods
**party** - Customers, suppliers, employees (unified table)
**document** - Invoices, orders, receipts with line items
**catalog** - Products, categories, brands, variants
**pricing** - Dynamic pricing rules and discounts
**cash** - Shifts, cash transactions, discrepancies
**security** - Users, roles, permissions, activity logs
**attachment** - Files attached to any record
**transaction_log** - Complete history of business events

## Installation

You need SQL Server 2016 or newer. Azure SQL Database works too.

1. Create a new database:
```sql
CREATE DATABASE AccountingSystem;
GO
USE AccountingSystem;
GO