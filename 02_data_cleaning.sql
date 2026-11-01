-- ============================================================================
-- PROJECT  : AdventureWorks Sales Analysis
-- FILE     : 02_data_cleaning.sql
-- PURPOSE  : Investigate data quality, profile missing values, and construct 
--            standardized analytical views before business analysis.
-- DATABASE : AdventureWorks2025
-- AUTHOR   : Youness Mahir
-- ============================================================================


-- =====================================================
-- SECTION 1: ANALYSIS SCOPE AND TABLE PROFILING
-- Purpose: Establish the scope, size, keys, and grain
--          of the tables selected for sales analysis.
-- =====================================================

-- 1. Exact Row Counts across the core analytical scope
select 
	'SalesOrderHeader' as TableName,
	count(*) as TotalRows
from Sales.salesorderheader
union all
select
	'SalesOrderDetail',
	count(*)
from sales.salesorderdetail
union all
select
	'SalesCustomers',
	count(*)
from sales.customer
union all
select
	'ProductionProduct',
	count(*)
from production.product
union all
select
	'SalesTerritory',
	count(*)
from sales.salesterritory
order by totalrows desc;

-- =====================================================
-- SECTION 2: MISSING VALUE PROFILE (NULL ANALYSIS)
-- Purpose: Measure NULL counts and percentages across critical columns in the core sales scope to assess data quality.
-- =====================================================

-- 1. Profile NULLs in Sales.SalesOrderHeader
SELECT 
    'SalesOrderHeader' AS TableName,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS Null_CustomerID,
    SUM(CASE WHEN TerritoryID IS NULL THEN 1 ELSE 0 END) AS Null_TerritoryID,
    SUM(CASE WHEN SalesPersonID IS NULL THEN 1 ELSE 0 END) AS Null_SalesPersonID,
    ROUND(100.0 * SUM(CASE WHEN SalesPersonID IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS PctNull_SalesPersonID
FROM Sales.SalesOrderHeader;

-- 2. Profile NULLs in Sales.SalesOrderDetail
SELECT 
    'SalesOrderDetail' AS TableName,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN SalesOrderID IS NULL THEN 1 ELSE 0 END) AS Null_SalesOrderID,
    SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS Null_ProductID,
    SUM(CASE WHEN OrderQty IS NULL THEN 1 ELSE 0 END) AS Null_OrderQty,
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS Null_UnitPrice,
    SUM(CASE WHEN LineTotal IS NULL THEN 1 ELSE 0 END) AS Null_LineTotal
FROM Sales.SalesOrderDetail;

-- 3. Profile NULLs in Sales.Customer
SELECT 
    'Customer' AS TableName,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN PersonID IS NULL THEN 1 ELSE 0 END) AS Null_PersonID,
    ROUND(100.0 * SUM(CASE WHEN PersonID IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS PctNull_PersonID,
    SUM(CASE WHEN StoreID IS NULL THEN 1 ELSE 0 END) AS Null_StoreID,
    ROUND(100.0 * SUM(CASE WHEN StoreID IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS PctNull_StoreID,
    SUM(CASE WHEN TerritoryID IS NULL THEN 1 ELSE 0 END) AS Null_TerritoryID
FROM Sales.Customer;

-- 4. Profile NULLs in Production.Product
SELECT 
    'Product' AS TableName,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN Name IS NULL THEN 1 ELSE 0 END) AS Null_Name,
    SUM(CASE WHEN StandardCost IS NULL THEN 1 ELSE 0 END) AS Null_StandardCost,
    SUM(CASE WHEN ListPrice IS NULL THEN 1 ELSE 0 END) AS Null_ListPrice,
    SUM(CASE WHEN ProductSubcategoryID IS NULL THEN 1 ELSE 0 END) AS Null_SubcategoryID,
    ROUND(100.0 * SUM(CASE WHEN ProductSubcategoryID IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS PctNull_SubcategoryID
FROM Production.Product;

-- 5. Profile NULLs in Sales.SalesTerritory
SELECT 
    'SalesTerritory' AS TableName,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN TerritoryID IS NULL THEN 1 ELSE 0 END) AS Null_TerritoryID,
    SUM(CASE WHEN Name IS NULL THEN 1 ELSE 0 END) AS Null_Name,
    SUM(CASE WHEN CountryRegionCode IS NULL THEN 1 ELSE 0 END) AS Null_CountryRegionCode,
    SUM(CASE WHEN [Group] IS NULL THEN 1 ELSE 0 END) AS Null_Group,
    SUM(CASE WHEN SalesYTD IS NULL THEN 1 ELSE 0 END) AS Null_SalesYTD
FROM Sales.SalesTerritory;

-- ============================================================================
-- SECTION 3: DUPLICATES AND UNIQUENESS PROFILING
-- Purpose: Verify primary key integrity and check for duplicate business entries.
-- ============================================================================

-- 3.1: Check Primary Key Uniqueness - Sales.SalesOrderHeader (SalesOrderID)
SELECT 
    SalesOrderID, 
    COUNT(*) AS OccurrenceCount
FROM Sales.SalesOrderHeader
GROUP BY SalesOrderID
HAVING COUNT(*) > 1;

-- 3.2: Check Composite Primary Key Uniqueness - Sales.SalesOrderDetail
SELECT 
    SalesOrderID, 
    SalesOrderDetailID, 
    COUNT(*) AS OccurrenceCount
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID, SalesOrderDetailID
HAVING COUNT(*) > 1;

-- 3.3: Check Primary Key Uniqueness - Sales.Customer (CustomerID)
SELECT 
    CustomerID, 
    COUNT(*) AS OccurrenceCount
FROM Sales.Customer
GROUP BY CustomerID
HAVING COUNT(*) > 1;

-- 3.4: Check Primary Key Uniqueness - Production.Product (ProductID)
SELECT 
    ProductID, 
    COUNT(*) AS OccurrenceCount
FROM Production.Product
GROUP BY ProductID
HAVING COUNT(*) > 1;

-- 3.5: Check Business Key Integrity - Duplicate Product Numbers
SELECT 
    ProductNumber, 
    COUNT(*) AS DuplicateCount
FROM Production.Product
GROUP BY ProductNumber
HAVING COUNT(*) > 1;


-- ============================================================================
-- SECTION 4: BUSINESS RULE VALIDATION & VALUE INTEGRITY
-- Purpose: Audit numeric bounds, chronological logic, and financial math.
-- ============================================================================

-- 4.1: Financial Bounds Audit - SalesOrderDetail (Negative/Zero Prices or Quantities)
SELECT 
    'SalesOrderDetail Invalid Values' AS AuditType,
    COUNT(*) AS ViolationCount
FROM Sales.SalesOrderDetail
WHERE OrderQty <= 0 
   OR UnitPrice < 0 
   OR LineTotal < 0;

-- 4.2: Chronological Sequence Audit - SalesOrderHeader (Invalid Date Sequences)
SELECT 
    'Invalid Chronology (Ship Before Order)' AS AuditType,
    COUNT(*) AS ViolationCount
FROM Sales.SalesOrderHeader
WHERE ShipDate < OrderDate 
   OR DueDate < OrderDate;

-- 4.3: Financial Line-Item Math Reconciliation
-- Checks if stored LineTotal differs from calculated LineTotal by more than $0.01 (float rounding margin)
SELECT 
    SalesOrderID,
    SalesOrderDetailID,
    OrderQty,
    UnitPrice,
    UnitPriceDiscount,
    LineTotal AS StoredLineTotal,
    ROUND((OrderQty * UnitPrice * (1.0 - UnitPriceDiscount)), 4) AS CalculatedLineTotal,
    ABS(LineTotal - ROUND((OrderQty * UnitPrice * (1.0 - UnitPriceDiscount)), 4)) AS Variance
FROM Sales.SalesOrderDetail
WHERE ABS(LineTotal - ROUND((OrderQty * UnitPrice * (1.0 - UnitPriceDiscount)), 4)) > 0.01;

-- 4.4: Catalog Pricing Audit - Production.Product (List Price vs Standard Cost)
SELECT 
    ProductID,
    Name,
    StandardCost,
    ListPrice,
    (ListPrice - StandardCost) AS Margin
FROM Production.Product
WHERE ListPrice < StandardCost AND ListPrice > 0;


-- ============================================================================
-- SECTION 5: REFERENTIAL INTEGRITY AND JOIN SAFETY
-- Purpose: Identify orphaned records and demonstrate join inflation mechanics.
-- ============================================================================

-- 5.1: Orphan Check - SalesOrderDetail rows without matching SalesOrderHeader
SELECT 
    COUNT(*) AS OrphanedLineItems
FROM Sales.SalesOrderDetail sod
LEFT JOIN Sales.SalesOrderHeader soh 
    ON sod.SalesOrderID = soh.SalesOrderID
WHERE soh.SalesOrderID IS NULL;

-- 5.2: Orphan Check - SalesOrderDetail rows pointing to non-existent Products
SELECT 
    COUNT(*) AS LineItemsWithMissingProduct
FROM Sales.SalesOrderDetail sod
LEFT JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
WHERE p.ProductID IS NULL;

-- 5.3: DEMONSTRATION OF JOIN INFLATION (Fan-Out Risk)
-- Correct Aggregate (Header Level)
SELECT 
    SUM(TotalDue) AS CorrectTotalRevenue
FROM Sales.SalesOrderHeader;

-- Inflated Aggregate (Header Joined to Detail without Grouping)
-- Each OrderHeader TotalDue is summed repeatedly for every detail line item!
SELECT 
    SUM(soh.TotalDue) AS InflatedTotalRevenue,
    SUM(soh.TotalDue) - (SELECT SUM(TotalDue) FROM Sales.SalesOrderHeader) AS OvercountedAmount
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesOrderDetail sod 
    ON soh.SalesOrderID = sod.SalesOrderID;

-- ============================================================================
-- SECTION 6: DATA PREPARATION & CLEANING VIEWS
-- Purpose: Create clean, production-ready views that handle NULLs, classify 
--          customer/order types, and prevent join inflation.
-- ============================================================================

-- 6.1: Clean Sales Order Header View
-- Fixes: Maps NULL SalesPersonID to 'Online Web Sales', derives SalesChannel
CREATE OR ALTER VIEW Sales.vw_CleanSalesOrderHeader AS 
SELECT 
    SalesOrderID,
    OrderDate,
    DueDate,
    ShipDate,
    Status,
    CustomerID,
    TerritoryID,
    -- Handle NULL SalesPersonID by assigning 'Online Web Sales' vs 'Corporate Reseller'
    COALESCE(CAST(SalesPersonID AS VARCHAR(10)), 'Online Web Sales') AS SalesPersonID_Cleaned,
    CASE 
        WHEN SalesPersonID IS NULL THEN 'Online Web' 
        ELSE 'Corporate Reseller' 
    END AS SalesChannel,
    SubTotal,
    TaxAmt,
    Freight,
    TotalDue
FROM Sales.SalesOrderHeader;
GO

-- 6.2: Clean Customer View
-- Fixes: Resolves mutually exclusive NULLs between PersonID and StoreID
CREATE OR ALTER VIEW Sales.vw_CleanCustomer AS
SELECT 
    CustomerID,
    PersonID,
    StoreID,
    TerritoryID,
    -- Derive explicit Customer Type
    CASE 
        WHEN PersonID IS NOT NULL THEN 'Individual Consumer'
        WHEN StoreID IS NOT NULL THEN 'Reseller Store'
        ELSE 'Unknown'
    END AS CustomerType
FROM Sales.Customer;
GO

-- 6.3: Clean Product View
-- Fixes: Handles NULL subcategories and labels non-salable inventory parts
CREATE OR ALTER VIEW Production.vw_CleanProduct AS
SELECT 
    ProductID,
    Name AS ProductName,
    ProductNumber,
    StandardCost,
    ListPrice,
    -- Label zero-price items (internal components/assembly parts)
    CASE 
        WHEN ListPrice = 0.00 THEN 'Internal Component / Assembly'
        ELSE 'Finished Salable Product'
    END AS ProductSalesCategory,
    -- Handle NULL Subcategories
    COALESCE(CAST(ProductSubcategoryID AS VARCHAR(10)), 'Uncategorized') AS ProductSubcategoryID_Cleaned
FROM Production.Product;
GO

-- 6.4: Verification Query
-- Test our clean views to ensure all NULLs and business categories are resolved
SELECT TOP 5 * FROM Sales.vw_CleanSalesOrderHeader;
SELECT TOP 5 * FROM Sales.vw_CleanCustomer;
SELECT TOP 5 * FROM Production.vw_CleanProduct;


-- ============================================================================
-- DATA QUALITY AUDIT REPORT: AdventureWorks2025 Core Sales Scope
-- ============================================================================
-- Project: Portfolio Data Engine & Quality Audit
-- Scope  : Core Sales Scope ('SalesOrderHeader', 'SalesOrderDetail', 'Customer', 'Product', 'SalesTerritory')
-- Status : Completed & Validated
-- ============================================================================
-- EXECUTIVE SUMMARY:
-- A comprehensive data quality profiling audit was conducted on the core sales 
-- tables within the 'AdventureWorks2025' database. The objective was to validate 
-- data grain, referential integrity, and business logic consistency.
-- 
-- The dataset exhibits high technical data cleanliness, zero primary key 
-- violations, and complete referential integrity. Identified anomalies 
-- (such as missing salesperson identifiers) have been normalized via production views.
-- ============================================================================
-- SUMMARY MATRIX OF AUDIT RESULTS:
-- ----------------------------------------------------------------------------
-- Audit Category              | Verification Method              | Pass/Fail
-- ----------------------------------------------------------------------------
-- 1. Entity Grain & Row Count | UNION ALL Row Profiling          | PASS
-- 2. Uniqueness & PKs         | GROUP BY ... HAVING COUNT(*) > 1 | PASS
-- 3. Completeness (NULLs)     | SUM(CASE WHEN ... IS NULL)       | PASS
-- 4. Business Logic Integrity | Bounds & Chronology Checks       | PASS
-- 5. Referential Integrity    | LEFT JOIN Orphan Detection       | PASS
-- 6. Join Mechanics Safety    | Aggregate Reconciliation         | PASS
-- ============================================================================
-- KEY DATA INSIGHTS & DOWNSTREAM GUIDELINES:
-- 1. Sales Channel Segmentation:
--    - 'SalesPersonID IS NULL' identifies direct consumer online orders.
--    - 'SalesPersonID IS NOT NULL' identifies corporate/reseller orders.
-- 2. Customer Entity Resolution:
--    - Customer records must be categorized using CASE statements for PersonID vs StoreID.
-- 3. Join Aggregation Guardrails:
--    - Financial reporting must aggregate exclusively from 'SalesOrderHeader'.
--    - Product-level sales analysis must aggregate from 'SalesOrderDetail.LineTotal'.
-- ============================================================================