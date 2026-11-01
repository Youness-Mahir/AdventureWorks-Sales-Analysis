-- ============================================================================
-- PHASE 4: BUSINESS ANALYSIS & PERFORMANCE DEEP-DIVE
-- Database: AdventureWorks2025
-- Description: Targeted business queries analyzing performance across customer
--              segmentation, product margins, territory drivers, and promotion efficiency.
-- ============================================================================


-- ============================================================================
-- SECTION 1: CUSTOMER PERFORMANCE & RFM SEGMENTATION
-- Purpose: Evaluate customer purchasing patterns across Recency, Frequency, and
--          Monetary value (RFM) to segment accounts, identify churn risk, and calculate lifetime value.
-- ============================================================================

-- 1. Customer Recency, Frequency, and Monetary (RFM) Metrics
-- Why: Calculate the baseline RFM scores for every customer to evaluate active vs. dormant accounts.
with MaxDate as (
    select max(orderdate) as ReferenceDate
    from sales.vw_cleansalesorderheader
),
CustomerRFM as (
    select 
        h.customerid,
        datediff(day, max(h.orderdate), (select ReferenceDate from MaxDate)) as RecencyDays,
        count(distinct h.salesorderid) as FrequencyOrders,
        sum(h.totaldue) as MonetarySpend
    from sales.vw_cleansalesorderheader h
    group by h.customerid
)
select 
    Customerid,
    RecencyDays,
    FrequencyOrders,
    round(MonetarySpend, 2) as MonetarySpend
from CustomerRFM
order by MonetarySpend desc;

-- 2. Customer Value Tier Segmentation
-- Why: Categorize customers into actionable spending tiers (VIP, High Value, Mid Value, Low Value) based on lifetime spend.
with CustomerTotals as (
    select 
        customerid,
        sum(totaldue) as LifetimeSpend,
        count(salesorderid) as LifetimeOrders
    from sales.vw_cleansalesorderheader
    group by customerid
)
select 
    case 
        when LifetimeSpend >= 100000 then '1. VIP ($100k+)'
        when LifetimeSpend between 25000 and 9999.99 then '2. High Value ($25k-$100k)'
        when LifetimeSpend between 5000 and 24999.99 then '3. Mid Value ($5k-$25k)'
        else '4. Low Value (<$5k)'
    end as CustomerTier,
    count(customerid) as CustomerCount,
    round(sum(LifetimeSpend), 2) as TotalTierRevenue,
    round(avg(LifetimeSpend), 2) as AvgTierSpend
from CustomerTotals
group by 
    case 
        when LifetimeSpend >= 100000 then '1. VIP ($100k+)'
        when LifetimeSpend between 25000 and 9999.99 then '2. High Value ($25k-$100k)'
        when LifetimeSpend between 5000 and 24999.99 then '3. Mid Value ($5k-$25k)'
        else '4. Low Value (<$5k)'
    end
order by CustomerTier;

-- 3. Customer Retention and Churn Risk Analysis
-- Why: Flag high-value accounts that have not placed an order in over 180 days relative to dataset end date.
with AnchorDate as (
    select max(orderdate) as MaxOrderDate 
    from sales.vw_cleansalesorderheader
),
CustomerActivity as (
    select 
        customerid,
        max(orderdate) as LastOrderDate,
        datediff(day, max(orderdate), (select MaxOrderDate from AnchorDate)) as DaysSinceLastOrder,
        sum(totaldue) as TotalSpend
    from sales.vw_cleansalesorderheader
    group by customerid
)
select 
    customerid,
    LastOrderDate,
    DaysSinceLastOrder,
    round(TotalSpend, 2) as LifetimeSpend
from CustomerActivity
where DaysSinceLastOrder > 180 and TotalSpend > 10000
order by TotalSpend desc;


-- ============================================================================
-- SECTION 2: PRODUCT PERFORMANCE & PROFITABILITY DEEP-DIVE
-- Purpose: Analyze product revenue velocity, calculate estimated gross margins,
--          and identify slow-moving or underperforming catalog items.
-- ============================================================================

-- 1. Product Margin and Profitability Analysis
-- Why: Join detail lines with standard cost data to evaluate estimated gross profit dollars and profit margins per product line.
select top 15
    p.productid,
    p.name as ProductName,
    sum(d.orderqty) as TotalUnitsSold,
    round(sum(d.orderqty * d.unitprice * (1 - d.unitpricediscount)), 2) as TotalGrossRevenue,
    round(sum(d.orderqty * p.standardcost), 2) as TotalEstimatedCost,
    round(sum(d.orderqty * d.unitprice * (1 - d.unitpricediscount)) - sum(d.orderqty * p.standardcost), 2) as EstimatedGrossProfit,
    round(100.0 * (sum(d.orderqty * d.unitprice * (1 - d.unitpricediscount)) - sum(d.orderqty * p.standardcost)) / nullif(sum(d.orderqty * d.unitprice * (1 - d.unitpricediscount)), 0), 2) as ProfitMarginPct
from sales.salesorderdetail d
join production.product p on d.productid = p.productid
group by p.productid, p.name
order by EstimatedGrossProfit desc;

-- 2. Category Margin Contribution
-- Why: Measure profit contributions across parent product categories to see which product lines drive overall company profitability.
select 
    c.name as CategoryName,
    sum(d.orderqty) as UnitsSold,
    round(sum(d.orderqty * d.unitprice * (1 - d.unitpricediscount)), 2) as TotalRevenue,
    round(sum(d.orderqty * p.standardcost), 2) as TotalCost,
    round(sum(d.orderqty * d.unitprice * (1 - d.unitpricediscount)) - sum(d.orderqty * p.standardcost), 2) as TotalGrossProfit,
    round(100.0 * (sum(d.orderqty * d.unitprice * (1 - d.unitpricediscount)) - sum(d.orderqty * p.standardcost)) / nullif(sum(d.orderqty * d.unitprice * (1 - d.unitpricediscount)), 0), 2) as ProfitMarginPct
from sales.salesorderdetail d
join production.product p on d.productid = p.productid
left join production.productsubcategory s on p.productsubcategoryid = s.productsubcategoryid
left join production.productcategory c on s.productcategoryid = c.productcategoryid
group by c.name
order by TotalGrossProfit desc;

-- 3. Underperforming and Zero-Sales Products
-- Why: Identify active catalog items that have zero recorded sales or very low sales velocity to pinpoint inventory drag.
select 
    p.productid,
    p.name as ProductName,
    p.productnumber,
    p.listprice,
    p.standardcost,
    coalesce(sum(d.orderqty), 0) as TotalUnitsSold
from production.product p
left join sales.salesorderdetail d on p.productid = d.productid
where p.finishedgoodsflag = 1
group by p.productid, p.name, p.productnumber, p.listprice, p.standardcost
having coalesce(sum(d.orderqty), 0) < 10
order by TotalUnitsSold asc, p.name;


-- ============================================================================
-- SECTION 3: TERRITORY & SALES CHANNEL PERFORMANCE
-- Purpose: Evaluate regional revenue density, compare B2B reseller rep channels
--          against online e-commerce, and measure rep quota attainment.
-- ============================================================================

-- 1. Sales Channel Comparison (Online vs. Reseller Revenue Performance)
-- Why: Compare transaction volumes, total revenue, and average order size between online sales and offline sales reps.
select 
    saleschannel,
    count(salesorderid) as OrderVolume,
    round(sum(totaldue), 2) as TotalRevenue,
    round(avg(totaldue), 2) as AverageOrderValue,
    round(100.0 * sum(totaldue) / (select sum(totaldue) from sales.vw_cleansalesorderheader), 2) as RevenueSharePct
from sales.vw_cleansalesorderheader
group by saleschannel;

-- 2. Regional Sales Growth and YoY Comparison
-- Why: Measure year-over-year growth across geographic territories to identify expanding vs. contracting markets.
with YearlyTerritorySales as (
    select 
        st.name as TerritoryName,
        year(h.orderdate) as SalesYear,
        sum(h.totaldue) as YearlyRevenue
    from sales.vw_cleansalesorderheader h
    join sales.salesterritory st on h.territoryid = st.territoryid
    group by st.name, year(h.orderdate)
)
select 
    TerritoryName,
    SalesYear,
    round(YearlyRevenue, 2) as CurrentYearRevenue,
    round(lag(YearlyRevenue, 1) over (partition by TerritoryName order by SalesYear), 2) as PreviousYearRevenue,
    round(YearlyRevenue - lag(YearlyRevenue, 1) over (partition by TerritoryName order by SalesYear), 2) as YoYAbsoluteGrowth
from YearlyTerritorySales
order by TerritoryName, SalesYear;

-- 3. Sales Representative Quota Attainment
-- Why: Evaluate individual sales rep performance against assigned quota benchmarks to isolate top performers.
select 
    sp.businessentityid as SalesPersonID,
    sp.salesquota as AnnualQuota,
    round(sp.salesytd, 2) as SalesYTD,
    round(sp.saleslastyear, 2) as SalesLastYear,
    case 
        when sp.salesquota is null then 'No Quota Set'
        when sp.salesytd >= sp.salesquota then 'Quota Met/Exceeded'
        else 'Below Quota'
    end as QuotaStatus,
    round(100.0 * sp.salesytd / nullif(sp.salesquota, 0), 2) as QuotaAttainmentPct
from sales.salesperson sp
order by SalesYTD desc;


-- ============================================================================
-- SECTION 4: PROMOTION & DISCOUNT EFFECTIVENESS
-- Purpose: Measure the commercial impact of discounts on order volume and evaluate
--          whether price reductions generate incremental revenue or margin erosion.
-- ============================================================================

-- 1. Promotional Offer Revenue Breakdown
-- Why: Evaluate total revenue generated under specific promotional special offers versus standard sales.
select 
    so.specialofferid,
    so.description as PromotionDescription,
    so.type as DiscountType,
    so.discountpct as DiscountPercentage,
    count(distinct d.salesorderid) as OrderCount,
    sum(d.orderqty) as TotalUnitsSold,
    round(sum(d.orderqty * d.unitprice * (1 - d.unitpricediscount)), 2) as TotalDiscountedRevenue
from sales.salesorderdetail d
join sales.specialoffer so on d.specialofferid = so.specialofferid
group by so.specialofferid, so.description, so.type, so.discountpct
order by TotalDiscountedRevenue desc;

-- 2. Discount Level Impact on Average Order Volume
-- Why: Assess whether higher discount percentages result in larger order quantities per line item.
select 
    d.unitpricediscount as DiscountRate,
    count(*) as LineItemCount,
    sum(d.orderqty) as TotalQuantitySold,
    round(avg(cast(d.orderqty as decimal(10,2))), 2) as AvgQuantityPerLine,
    round(sum(d.orderqty * d.unitprice * (1 - d.unitpricediscount)), 2) as TotalRevenueGenerated
from sales.salesorderdetail d
group by d.unitpricediscount
order by DiscountRate asc;