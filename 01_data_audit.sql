-- ============================================================================
-- PROJECT  : AdventureWorks Sales Analysis
-- FILE     : 01_data_audit.sql
-- PURPOSE  : Inspect database structure, audit schemas, and evaluate baseline 
--            data quality prior to business analysis.
-- DATABASE : AdventureWorks2025
-- AUTHOR   : Youness Mahir
-- ============================================================================


-- =====================================================
-- SECTION 1: DATABASE AND SCHEMA INVENTORY
-- Purpose: Identify the schemas and count their tables.
-- =====================================================
select
	s.Name,
	count(t.name) as TablesCount
from sys.schemas s
join sys.tables t
on s.schema_id=t.schema_id
group by s.name
Order by s.name;

-- =====================================================
-- Section 2: Table Inventory
-- Purpose: List all user tables in the database along with their respective schemas to establish a complete structural mapping.
-- =====================================================
select
	s.name as Schemas,
	t.name as Tables
from sys.schemas s
join sys.tables t
on s.schema_id=t.schema_id
order by schemas, tables
;

-- =====================================================
-- Section 3: Column Inventory
-- Purpose: Inventory all columns, data types, lengths, and nullability across schemas.
-- =====================================================
select
	s.name as SchemaNames,
	t.name as TableNames,
	c.name as ColumnNames,
	ty.name as DataType,
	c.max_length,
	c.is_nullable as IsNullable
from sys.schemas s
join sys.tables t
on s.schema_id=t.schema_id
join sys.columns c
on t.object_id=c.object_id
join sys.types ty
on c.user_type_id=ty.user_type_id
order by schemanames, tablenames, columnnames
;

-- =====================================================
-- Section 4: Keys and relationships
-- Purpose: Identify primary keys, foreign keys, and column mappings to understand database constraints, entity integrity, and table joins.
-- =====================================================

-- PRIMARY KEYS
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    k.name AS KeyName,
    'PRIMARY KEY' AS KeyType,
    c.name AS ColumnName,
    ic.key_ordinal AS ColumnOrdinal,
    CAST(NULL AS sysname) AS ReferencedSchema,
    CAST(NULL AS sysname) AS ReferencedTable,
    CAST(NULL AS sysname) AS ReferencedColumn
FROM sys.schemas s
JOIN sys.tables t 
    ON s.schema_id = t.schema_id
JOIN sys.key_constraints k 
    ON t.object_id = k.parent_object_id 
   AND k.type = 'PK'
JOIN sys.index_columns ic 
    ON k.parent_object_id = ic.object_id 
   AND k.unique_index_id = ic.index_id
JOIN sys.columns c 
    ON ic.object_id = c.object_id 
   AND ic.column_id = c.column_id

UNION ALL

-- FOREIGN KEYS
SELECT 
    s_parent.name AS SchemaName,
    t_parent.name AS TableName,
    fk.name AS KeyName,
    'FOREIGN KEY' AS KeyType,
    c_parent.name AS ColumnName,
    fkc.constraint_column_id AS ColumnOrdinal,
    s_ref.name AS ReferencedSchema,
    t_ref.name AS ReferencedTable,
    c_ref.name AS ReferencedColumn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables t_parent 
    ON fkc.parent_object_id = t_parent.object_id
JOIN sys.schemas s_parent 
    ON t_parent.schema_id = s_parent.schema_id
JOIN sys.columns c_parent 
    ON fkc.parent_object_id = c_parent.object_id 
   AND fkc.parent_column_id = c_parent.column_id
JOIN sys.tables t_ref 
    ON fkc.referenced_object_id = t_ref.object_id
JOIN sys.schemas s_ref 
    ON t_ref.schema_id = s_ref.schema_id
JOIN sys.columns c_ref 
    ON fkc.referenced_object_id = c_ref.object_id 
   AND fkc.referenced_column_id = c_ref.column_id

ORDER BY SchemaName, TableName, KeyType, KeyName, ColumnOrdinal;

-- =====================================================
-- Section 5: Sales Data Discovery
-- Purpose: Inspect core sales domain tables, evaluate row counts, and trace line-item, customer, and territory relationships for analysis.
-- =====================================================

--Sales Tables Row Counts:
SELECT 
    s.name AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS TotalRows
FROM sys.tables t
JOIN sys.schemas s 
ON t.schema_id = s.schema_id
JOIN sys.partitions p 
ON t.object_id = p.object_id
WHERE s.name = 'Sales' AND p.index_id IN (0, 1) -- 0: Heap, 1: Clustered Index
GROUP BY s.name, t.name
ORDER BY TotalRows DESC;

--Key Relationships & Column Mappings:
SELECT 
    s_parent.name AS SchemaName,
    t_parent.name AS TableName,
    fk.name AS ForeignKeyName,
    c_parent.name AS SourceColumn,
    s_ref.name AS ReferencedSchema,
    t_ref.name AS ReferencedTable,
    c_ref.name AS ReferencedColumn
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
JOIN sys.tables t_parent 
    ON fkc.parent_object_id = t_parent.object_id
JOIN sys.schemas s_parent 
    ON t_parent.schema_id = s_parent.schema_id
JOIN sys.columns c_parent 
    ON fkc.parent_object_id = c_parent.object_id 
   AND fkc.parent_column_id = c_parent.column_id
JOIN sys.tables t_ref 
    ON fkc.referenced_object_id = t_ref.object_id
JOIN sys.schemas s_ref 
    ON t_ref.schema_id = s_ref.schema_id
JOIN sys.columns c_ref 
    ON fkc.referenced_object_id = c_ref.object_id 
   AND fkc.referenced_column_id = c_ref.column_id
WHERE s_parent.name = 'Sales'
  AND t_parent.name IN ('SalesOrderHeader', 'SalesOrderDetail', 'Customer', 'SalesTerritory', 'SpecialOfferProduct')
ORDER BY TableName, ForeignKeyName;

-- ============================================================================
-- SECTION 6: AUDIT NOTES AND FINDINGS
-- Purpose: Record core observations, data structures, and assumptions.
-- ============================================================================

/*
1. DATABASE STRUCTURE & COVERAGE
   - Schemas & Tables: The database contains multiple functional schemas (Sales, Production, 
     HumanResources, Person, Purchasing).
   - Primary Keys: Every core table utilizes defined Primary Keys, ensuring entity integrity.
   - Foreign Keys: Relationships are well-enforced via foreign keys across tables, maintaining 
     referential integrity.

2. SALES MODULE GRANULARITY & RELATIONSHIPS
   - Header vs. Detail: Sales.SalesOrderHeader records order-level metadata (OrderDate, 
     CustomerID, TerritoryID, TotalDue), while Sales.SalesOrderDetail records line-item detail 
     (ProductID, OrderQty, UnitPrice, LineTotal).
   - Relationship Link: Joined via SalesOrderID (1-to-Many).
   - Customer Link: SalesOrderHeader links to Sales.Customer via CustomerID.
   - Territory Link: SalesOrderHeader links to Sales.SalesTerritory via TerritoryID.
   - Product & Promotion: SalesOrderDetail links to Sales.SpecialOfferProduct via a composite 
     foreign key (SpecialOfferID, ProductID).

3. ASSUMPTIONS & WORKING CONSTANTS
   - Currency: Currency metrics in SalesOrderHeader and SalesOrderDetail are assumed to be in 
     USD unless joined with Sales.CurrencyRate.
   - Net Sales vs. Gross: Total due calculations on order headers include Freight and TaxAmt. 
     Line-item analysis using SubTotal reflects pre-tax product sales.

4. OPEN QUESTIONS / POTENTIAL DATA QUALITY CHECKS FOR NEXT STEPS
   - Are there any orphaned records (e.g., SalesOrderHeader records without corresponding details)?
   - Are there NULL values in critical FK fields like TerritoryID or SalesPersonID in historical orders?
   - Do returned orders or cancellations impact LineTotal calculations in SalesOrderDetail?
*/