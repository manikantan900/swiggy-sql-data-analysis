-- =============================================
-- File: analysis.sql
-- Project: Swiggy SQL Data Analysis
-- Author: Manikantan
-- Purpose: Analyze Swiggy sales data
-- =============================================

-- 1️⃣ DATA QUALITY CHECKS: Count NULLs in each column
SELECT
    SUM(CASE WHEN State IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN City IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
    SUM(CASE WHEN Restaurant_Name IS NULL THEN 1 ELSE 0 END) AS null_restaurant_name,
    SUM(CASE WHEN Location IS NULL THEN 1 ELSE 0 END) AS null_location,
    SUM(CASE WHEN Category IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN Dish_Name IS NULL THEN 1 ELSE 0 END) AS null_dish_name,
    SUM(CASE WHEN Price_INR IS NULL THEN 1 ELSE 0 END) AS null_price_INR,
    SUM(CASE WHEN Rating IS NULL THEN 1 ELSE 0 END) AS null_rating,
    SUM(CASE WHEN Rating_Count IS NULL THEN 1 ELSE 0 END) AS null_rating_count
FROM Swiggy_Data;


-- 2️⃣ TOTAL SALES
SELECT 
    SUM(Price_INR) AS total_sales
FROM Swiggy_Data;


-- 3️⃣ CITY-WISE SALES
SELECT 
    City,
    SUM(Price_INR) AS total_sales
FROM Swiggy_Data
GROUP BY City
ORDER BY total_sales DESC;


-- 4️⃣ TOP-PERFORMING RESTAURANTS
SELECT 
    Restaurant_Name,
    SUM(Price_INR) AS total_sales
FROM Swiggy_Data
GROUP BY Restaurant_Name
ORDER BY total_sales DESC;
