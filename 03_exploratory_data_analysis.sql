-- ============================================================================
-- PROJECT  : AdventureWorks Sales Analysis
-- FILE     : 03_exploratory_data_analysis.sql
-- PURPOSE  : Execute exploratory data analysis to evaluate revenue baselines, 
--            order volume patterns, customer behavior, and sales velocity.
-- DATABASE : AdventureWorks2025
-- AUTHOR   : Youness Mahir
-- ============================================================================


-- ============================================================================
-- SECTION 1: EXECUTIVE BASELINE & OVERALL SCOPE
-- Purpose: Combine time coverage, order volumes, customer reach, revenue, 
--          average order value, and channel splits into a single executive view.
-- ============================================================================

-- 1. Sales Date Range (Time Coverage)
-- Why: Establish the exact historical timeline and total date range covered by the dataset.
select 
    min(orderdate) as EarliestOrderDate,
    max(orderdate) as LatestOrderDate,
    datediff(day, min(orderdate), max(orderdate)) as TotalDaysCovered
from sales.vw_cleansalesorderheader;

-- 2. Total Orders
-- Why: Determine the absolute volume of completed transactions across the entire operational history.
select 
    count(distinct salesorderid) as TotalOrders
from sales.vw_cleansalesorderheader;

-- 3. Total Order-Detail Lines
-- Why: Measure granular line-item activity to understand total individual product transactions.
select 
    count(*) as TotalDetailLines
from sales.salesorderdetail;

-- 4. Customer Coverage (Distinct Customers)
-- Why: Quantify unique purchasing entities (b2b and b2c) present in the order history.
select 
    count(distinct customerid) as DistinctCustomers
from sales.vw_cleansalesorderheader;

-- 5. Overall Revenue Totals & Average Order Value
-- Why: Calculate gross subtotal, tax, freight, final revenue, and overall average spend per order.
select 
    sum(subtotal) as TotalSubTotal,
    sum(taxamt) as TotalTax,
    sum(freight) as TotalFreight,
    sum(totaldue) as TotalDue,
    avg(subtotal) as AverageOrderValue
from sales.vw_cleansalesorderheader;

-- 6. Online vs. Offline Orders (Channel Split)
-- Why: Evaluate transaction volume and percentage distribution between e-commerce and corporate reseller channels.
select 
    saleschannel,
    count(*) as OrderCount,
    round(100.0 * count(*) / (select count(*) from sales.vw_cleansalesorderheader), 2) as PctOfTotal
from sales.vw_cleansalesorderheader
group by saleschannel;


-- ============================================================================
-- SECTION 2: REVENUE AND ORDER VALUES
-- Purpose: Analyze transaction monetary sizes, order value distributions, line item quantities, and discount impacts.
-- ============================================================================

-- 1. Top 10 Largest Orders (Highest Value)
-- Why: Identify peak individual sales transactions to isolate outlier high-value orders.
select top 10
    Salesorderid,
    Orderdate,
    Customerid,
    totaldue as TotalDue
from sales.vw_cleansalesorderheader
order by totaldue desc;

-- 2. Order-Value Distribution (Spending Bands)
-- Why: Categorize orders into spending tiers to observe customer spending behavior and transaction density.
select 
    case 
        when subtotal < 100 then '1. Under $100'
        when subtotal between 100 and 499.99 then '2. $100 - $499'
        when subtotal between 500 and 999.99 then '3. $500 - $999'
        when subtotal between 1000 and 4999.99 then '4. $1,000 - $4,999'
        else '5. $5,000+'
    end as OrderValueBand,
    count(*) as OrderCount,
    sum(subtotal) as TotalRevenue
from sales.vw_cleansalesorderheader
group by 
    case 
        when subtotal < 100 then '1. Under $100'
        when subtotal between 100 and 499.99 then '2. $100 - $499'
        when subtotal between 500 and 999.99 then '3. $500 - $999'
        when subtotal between 1000 and 4999.99 then '4. $1,000 - $4,999'
        else '5. $5,000+'
    end
order by OrderValueBand;

-- 3. Order Quantity Analysis (Line Items)
-- Why: Measure baseline product unit volume metrics across line items, including averages, minimums, and maximums.
select 
    sum(orderqty) as TotalQuantitySold,
    avg(cast(orderqty as decimal(10,2))) as AverageQuantityPerLine,
    max(orderqty) as MaxQuantityPerLine,
    min(orderqty) as MinQuantityPerLine
from sales.salesorderdetail;

-- 4. Discounts and Special Offers Analysis
-- Why: Evaluate price reduction prevalence across detail lines and aggregate total promotional revenue impact.
select 
    count(*) as TotalDetailLines,
    sum(case when unitpricediscount > 0 then 1 else 0 end) as DiscountedLinesCount,
    round(100.0 * sum(case when unitpricediscount > 0 then 1 else 0 end) / count(*), 2) as PctDiscountedLines,
    sum(unitprice * orderqty * unitpricediscount) as TotalDiscountAmountDollars
from sales.salesorderdetail;


-- ============================================================================
-- SECTION 3: SALES TRENDS OVER TIME
-- Purpose: Track business trajectory, seasonal cycles, and growth rates across annual, quarterly, and monthly intervals.
-- ============================================================================

-- 1. Annual Performance (Orders and Revenue by Year)
-- Why: Compare high-level macro growth across multi-year operational periods.
select 
    year(orderdate) as OrderYear,
    count(salesorderid) as TotalOrders,
    sum(totaldue) as TotalRevenue,
    avg(totaldue) as AverageOrderValue
from sales.vw_cleansalesorderheader
group by year(orderdate)
order by OrderYear;

-- 2. Monthly Performance (Chronological Breakdown)
-- Why: Plot continuous monthly revenue trajectory to observe short-term trends and seasonality patterns.
select 
    format(orderdate, 'yyyy-MM') as YearMonth,
    count(salesorderid) as TotalOrders,
    sum(totaldue) as TotalRevenue
from sales.vw_cleansalesorderheader
group by format(orderdate, 'yyyy-MM')
order by YearMonth;

-- 3. Month-over-Month (MoM) Growth using a CTE
-- Why: Calculate exact absolute and percentage revenue growth between consecutive months using window functions.
with MonthlySales as (
    select 
        format(orderdate, 'yyyy-MM') as YearMonth,
        sum(totaldue) as TotalRevenue
    from sales.vw_cleansalesorderheader
    group by format(orderdate, 'yyyy-MM')
)
select 
    YearMonth,
    TotalRevenue,
    lag(TotalRevenue, 1) over (order by YearMonth) as PreviousMonthRevenue,
    TotalRevenue - lag(TotalRevenue, 1) over (order by YearMonth) as AbsoluteChange,
    round(100.0 * (TotalRevenue - lag(TotalRevenue, 1) over (order by YearMonth)) / lag(TotalRevenue, 1) over (order by YearMonth), 2) as PctGrowth
from MonthlySales
order by YearMonth;

-- 4. Quarterly Performance Comparison
-- Why: Examine performance by calendar quarter to detect repeating seasonal demand trends.
select 
    year(orderdate) as OrderYear,
    datepart(quarter, orderdate) as OrderQuarter,
    count(salesorderid) as TotalOrders,
    sum(totaldue) as TotalRevenue
from sales.vw_cleansalesorderheader
group by year(orderdate), datepart(quarter, orderdate)
order by OrderYear, OrderQuarter;


-- ============================================================================
-- SECTION 4: CUSTOMER ANALYSIS
-- Purpose: Evaluate customer spending concentration, purchase frequency, loyalty metrics, and acquisition cohorts over time.
-- ============================================================================

-- 1. Top 10 Customers by Revenue
-- Why: Identify primary accounts driving revenue concentration and assess average order spend per top account.
select top 10
    customerid,
    count(salesorderid) as TotalOrders,
    sum(totaldue) as TotalSpend,
    avg(totaldue) as AverageOrderValue
from sales.vw_cleansalesorderheader
group by customerid
order by TotalSpend desc;

-- 2. Customer Purchase Frequency Distribution
-- Why: Map order frequency counts to analyze how many orders individual customers place across their lifecycle.
with CustomerOrderCounts as (
    select 
        customerid,
        count(salesorderid) as OrderCount
    from sales.vw_cleansalesorderheader
    group by customerid
)
select 
    OrderCount,
    count(customerid) as CustomerCount
from CustomerOrderCounts
group by OrderCount
order by OrderCount asc;

-- 3. Repeat vs. One-Time Customer Summary
-- Why: Calculate baseline customer retention metrics by separating one-time buyers from repeat purchasers.
with CustomerOrders as (
    select 
        customerid,
        count(salesorderid) as TotalOrders
    from sales.vw_cleansalesorderheader
    group by customerid
)
select 
    sum(case when TotalOrders > 1 then 1 else 0 end) as RepeatCustomersCount,
    sum(case when TotalOrders = 1 then 1 else 0 end) as OneTimeCustomersCount,
    count(*) as TotalDistinctCustomers,
    round(100.0 * sum(case when TotalOrders > 1 then 1 else 0 end) / count(*), 2) as PctRepeatCustomers
from CustomerOrders;

-- 4. New vs. Returning Customer Activity Over Time
-- Why: Determine new customer acquisition volume per calendar year based on initial purchase dates.
with FirstOrders as (
    select 
        customerid,
        min(year(orderdate)) as FirstOrderYear
    from sales.vw_cleansalesorderheader
    group by customerid
)
select 
    FirstOrderYear,
    count(customerid) as NewCustomersAcquired
from FirstOrders
group by FirstOrderYear
order by FirstOrderYear;


-- ============================================================================
-- SECTION 5: PRODUCT ANALYSIS
-- Purpose: Determine top-performing items by volume and revenue, and analyze performance across category hierarchies.
-- ============================================================================

-- 1. Top 10 Products by Quantity Sold
-- Why: Identify physical inventory movers and high-volume product items.
select top 10
    p.name as ProductName,
    sum(d.orderqty) as TotalQuantitySold,
    count(distinct d.salesorderid) as OrderCount
from sales.salesorderdetail d
join production.product p on d.productid = p.productid
group by p.name
order by TotalQuantitySold desc;

-- 2. Top 10 Products by Sales Value
-- Why: Isolate top revenue-generating individual products net of line discounts.
select top 10
    p.name as ProductName,
    sum(d.orderqty * d.unitprice * (1 - d.unitpricediscount)) as TotalSalesValue,
    sum(d.orderqty) as TotalQuantitySold
from sales.salesorderdetail d
join production.product p on d.productid = p.productid
group by p.name
order by TotalSalesValue desc;

-- 3. Product Category and Subcategory Performance
-- Why: Roll up product metrics to analyze broader catalog performance across parent categories and subcategories.
select 
    c.name as CategoryName,
    s.name as SubCategoryName,
    sum(d.orderqty * d.unitprice * (1 - d.unitpricediscount)) as TotalSalesValue,
    sum(d.orderqty) as TotalQuantitySold,
    count(distinct d.salesorderid) as OrderCount
from sales.salesorderdetail d
join production.product p on d.productid = p.productid
left join production.productsubcategory s on p.productsubcategoryid = s.productsubcategoryid
left join production.productcategory c on s.productcategoryid = c.productcategoryid
group by c.name, s.name
order by TotalSalesValue desc;


-- ============================================================================
-- SECTION 6: TERRITORY AND GEOGRAPHY
-- Purpose: Evaluate geographic revenue distribution, regional contribution shares, and global order performance.
-- ============================================================================

-- 1. Sales by Territory (Revenue and Order Volume)
-- Why: Compare primary sales territories by order volume, total revenue, and average order value.
select 
    territoryid,
    count(salesorderid) as TotalOrders,
    sum(totaldue) as TotalRevenue,
    avg(totaldue) as AverageOrderValue
from sales.vw_cleansalesorderheader
group by territoryid
order by TotalRevenue desc;

-- 2. Territory Contribution Percentage
-- Why: Calculate exact revenue contribution shares for each territory relative to global company revenue.
with TerritoryRevenue as (
    select 
        territoryid,
        sum(totaldue) as TerritoryRevenue
    from sales.vw_cleansalesorderheader
    group by territoryid
)
select 
    Territoryid,
    TerritoryRevenue,
    round(100.0 * TerritoryRevenue / (select sum(totaldue) from sales.vw_cleansalesorderheader), 2) as PctOfTotalRevenue
from TerritoryRevenue
order by TerritoryRevenue desc;

-- 3. Geographic Activity by Country/Region
-- Why: Map sales territory identifiers to explicit country codes to inspect country-level performance.
select 
    st.name as TerritoryName,
    st.countryregioncode as CountryCode,
    count(h.salesorderid) as TotalOrders,
    sum(h.totaldue) as TotalRevenue
from sales.vw_cleansalesorderheader h
join sales.salesterritory st on h.territoryid = st.territoryid
group by st.name, st.countryregioncode
order by TotalRevenue desc;


-- ============================================================================
-- SECTION 7: SALES REPRESENTATIVES ANALYSIS
-- Purpose: Assess corporate sales representative contribution, order distribution, and year-to-date quota targets.
-- ============================================================================

-- 1. Sales Performance by Representative
-- Why: Measure individual sales rep output across order counts, total sales dollars, and average deal sizes.
select 
    SalesPersonID_Cleaned,
    count(salesorderid) as TotalOrders,
    sum(totaldue) as TotalRevenue,
    avg(totaldue) as AverageOrderValue
from sales.vw_cleansalesorderheader
group by salespersonid_cleaned
order by TotalRevenue desc;

-- 2. Sales Representative Quota and Performance Targets
-- Why: Inspect sales quotas, commission structures, and year-to-date performance figures in the sales person table.
select top 10
    businessentityid as SalesPersonID,
    SalesQuota,
    Bonus,
    CommissionPct,
    SalesYTD,
    SalesLastYear
from sales.salesperson
order by salesytd desc;


-- ============================================================================
-- SECTION 8: ORDER STATUS AND SHIPPING ANALYSIS
-- Purpose: Inspect operational order execution statuses and regional freight logistics expenditures.
-- ============================================================================

-- 1. Breakdown of Orders by Status Code
-- Why: Verify operational pipeline distribution across order status categories (e.g., pending, shipped, cancelled).
select 
    status,
    count(salesorderid) as OrderCount,
    sum(totaldue) as TotalRevenue
from sales.vw_cleansalesorderheader
group by status
order by OrderCount desc;

-- 2. Freight Costs by Territory
-- Why: Analyze average and total shipping expenses across geographic territories to assess logistical overhead.
select 
    territoryid,
    avg(freight) as AverageFreight,
    sum(freight) as TotalFreight
from sales.vw_cleansalesorderheader
group by territoryid
order by TotalFreight desc;