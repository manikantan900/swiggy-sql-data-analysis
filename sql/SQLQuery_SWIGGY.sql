SELECT * FROM Swiggy_Data 

--Data Validation & Cleaning
--Null Check
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


--Blank or Empty Strings
SELECT *
FROM Swiggy_Data
WHERE
State='' OR City='' OR Order_Date='' OR Restaurant_Name='' OR  Location='' OR  Category='' OR Dish_Name='';

--Duplicate Detection
SELECT 
State,City,Order_Date,Restaurant_Name,Location,Category,Dish_Name,Price_INR,Rating,Rating_Count, count(*) as CNT
FROM Swiggy_Data
GROUP BY
State,City,Order_Date,Restaurant_Name,Location,Category,Dish_Name,Price_INR,Rating,Rating_Count
Having count(*)>1

--Delete Duplication
WITH CTE AS (
SELECT *, ROW_NUMBER() Over(
PARTITION BY State,City,Order_Date,Restaurant_Name,Location,Category,Dish_Name,Price_INR,Rating,Rating_Count
ORDER BY (SELECT NULL)
) AS DD
FROM Swiggy_Data
)
DELETE FROM CTE WHERE DD>1

--CREATING SCHEMA
--DIMENTIONS TABLES
--DATE TABLE
CREATE TABLE dim_date(
	date_id INT IDENTITY(1,1) PRIMARY KEY,
	Full_Date DATE,
	YEAR INT,
	MONTH INT,
	Month_Name varchar(20),
	Quarter INT,
	Day INT,
	Week INT
	)

--dim_location
CREATE TABLE dim_location(
	location_id INT IDENTITY(1,1) PRIMARY KEY,
	State VARCHAR(100),
	City VARCHAR(100),
	Location VARCHAR(100)
)

--dim_restaurant
CREATE TABLE dim_restaurant(
	restaurant_id INT IDENTITY(1,1) PRIMARY KEY,
	Restaurant_Name VARCHAR(100)
)

--dim_category
CREATE TABLE dim_category(
	category_id INT IDENTITY(1,1) PRIMARY KEY,
	Category_Name VARCHAR(100)
)

--dim_dish
CREATE TABLE dim_dish(
	dish_id INT IDENTITY(1,1) PRIMARY KEY,
	Dish_Name VARCHAR(300) 
)

--FACT TABLE
CREATE TABLE fact_swiggy_orders(
	order_id INT IDENTITY(1,1) PRIMARY KEY,

	date_id INT,
	Price_INR DECIMAL(5,2),
	Rating DECIMAL(4,2),
	Rating_Count INT,

	location_id INT,
	restaurant_id INT,
	category_id INT,
	dish_id INT,

	FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
	FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
	FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
	FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
	FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
)
--INSERT DATA IN TABLES
--dim_date
INSERT INTO dim_date (Full_Date,YEAR,MONTH,Month_Name,Quarter,Day,Week)
SELECT DISTINCT
	Order_Date,
	YEAR(Order_Date),
	MONTH(Order_Date),
	DATENAME(MONTH,Order_Date),
	DATEPART(QUARTER,Order_Date),
	DAY(Order_Date),
	DATEPART(WEEK,Order_Date)
FROM Swiggy_Data
WHERE Order_Date IS NOT NULL

--dim_location
INSERT INTO dim_location (State,City,Location)
SELECT DISTINCT
	State,
	City,
	Location
FROM Swiggy_Data

--dim_restaurant
INSERT INTO dim_restaurant (Restaurant_Name)
SELECT DISTINCT
	Restaurant_Name
FROM Swiggy_Data

--dim_category
INSERT INTO dim_category (Category_Name)
SELECT DISTINCT
	Category
FROM Swiggy_Data

ALTER TABLE dim_dish
ALTER COLUMN Dish_Name VARCHAR(255);


--dim_category
INSERT INTO dim_dish (Dish_Name)
SELECT DISTINCT
	Dish_Name
FROM Swiggy_Data

--fact_table
INSERT INTO fact_swiggy_orders
(
    date_id,
    Price_INR,
    Rating,
    Rating_Count,
    location_id,
    restaurant_id,
    category_id,
    dish_id
)
SELECT
    dd.date_id,
    CAST(s.Price_INR AS DECIMAL(10,2)),
    CAST(s.Rating AS DECIMAL(3,2)),
    CAST(s.Rating_Count AS INT),
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id
FROM Swiggy_Data s

JOIN dim_date dd
    ON dd.Full_Date = s.Order_Date

JOIN dim_location dl
    ON dl.State = s.State
   AND dl.City = s.City
   AND dl.Location = s.Location

JOIN dim_restaurant dr
    ON dr.Restaurant_Name = s.Restaurant_Name

JOIN dim_category dc
    ON dc.Category_Name = s.Category

JOIN dim_dish dsh
    ON dsh.Dish_Name = s.Dish_Name;

SELECT * FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
JOIN dim_location l ON f.location_id = l.location_id
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
JOIN dim_category c ON f.category_id = c.category_id
JOIN dim_dish di ON f.dish_id = di.dish_id

--KPI's
--Total Orders
SELECT COUNT(*) AS Total_Orders
FROM fact_swiggy_orders

--Total Revenue
SELECT FORMAT(SUM(CONVERT(FLOAT,Price_INR))/1000000,'N2')+' INR Million'
AS Total_Revenue
FROM fact_swiggy_orders

--Average Dish Price
SELECT FORMAT(AVG(CONVERT(FLOAT,Price_INR)),'N2')+' INR'
AS Average_Revenue
FROM fact_swiggy_orders 

--Average Rating
SELECT AVG(Rating) AS Average_Rating
FROM fact_swiggy_orders 

--Deep-Dive Business Analysis
--Monthly Order Trends
SELECT 
d.Year,
d.Month,
d.Month_Name,
count(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year,d.Month,d.Month_Name
ORDER BY count(*) DESC

--Monthly Total Revenue
SELECT 
d.Year,
d.Month,
d.Month_Name,
FORMAT(SUM(CONVERT(FLOAT,Price_INR))/1000000,'N2')+' INR Million' AS Total_Revenue
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year,d.Month,d.Month_Name
ORDER BY SUM(Price_INR) DESC

--Monthly Average Revenue
SELECT 
d.Year,
d.Month,
d.Month_Name,
FORMAT(AVG(CONVERT(FLOAT,Price_INR)),'N2')+' INR' AS Average_Revenue
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year,d.Month,d.Month_Name
ORDER BY AVG(Price_INR) DESC

--Quarterly Trend
SELECT 
d.Year,
d.Quarter,
count(*) as Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year,d.Quarter
ORDER BY COUNT(*) DESC

--Yearly Trend
SELECT 
d.Year,
count(*) as Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY d.Year
ORDER BY COUNT(*) DESC

--Orders by Day of Week (Mon-Sun)
SELECT
	DATENAME(WEEKDAY, d.full_date) AS day_name,
	COUNT(*) AS Total_Orders
FROM fact_swiggy_orders f
JOIN dim_date d ON f.date_id = d.date_id
GROUP BY DATENAME(WEEKDAY, d.Full_Date),DATEPART(WEEKDAY,d.full_date)
ORDER BY COUNT(*) DESC

--Top 10 Cities by Order Volume
SELECT TOP 10
l.city,
COUNT(*) AS Total_Orders FROM fact_swiggy_orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.city
ORDER BY COUNT(*) DESC

--Top 10 Cities by Total Revenue
SELECT TOP 10
l.city,
'INR ' + FORMAT(SUM(CONVERT(FLOAT,f.Price_INR))/1000000,'N2')+' Million' AS Total_Revenue FROM fact_swiggy_orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.city
ORDER BY SUM(f.Price_INR) DESC

--Top 10 Revenue Contribution by States
SELECT TOP 10
l.state,
'INR ' + FORMAT(SUM(CONVERT(FLOAT,f.Price_INR))/1000000,'N2')+' Million' AS Total_Revenue FROM fact_swiggy_orders f
JOIN dim_location l
ON l.location_id = f.location_id
GROUP BY l.state
ORDER BY SUM(f.Price_INR) DESC

--Top 10 Restaurants by Orders Volume
SELECT TOP 10
r.Restaurant_Name,
COUNT(*) AS Total_Orders FROM fact_swiggy_orders f
JOIN dim_restaurant r
ON r.restaurant_id = f.restaurant_id
GROUP BY r.Restaurant_Name
ORDER BY COUNT(*) DESC

--Top 10 Categories by Orders Volume
SELECT TOP 10
c.Category_Name,
COUNT(*) AS Total_Orders FROM fact_swiggy_orders f
JOIN dim_category c
ON c.category_id = f.category_id
GROUP BY c.Category_Name
ORDER BY COUNT(*) DESC

--Most Ordered Dishes
SELECT TOP 10
d.Dish_Name,
COUNT(*) AS Order_Count FROM fact_swiggy_orders f
JOIN dim_dish d
ON d.dish_id = f.dish_id
GROUP BY d.Dish_Name
ORDER BY COUNT(*) DESC

--Cuisine Performance (Orders + Total Rating)
SELECT TOP 10
	c.Category_Name,
	COUNT(*) AS Total_Orders,
	SUM(f.rating) AS Total_Rating
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.Category_Name
ORDER BY Total_Rating DESC

--Total Orders by Price Range
SELECT
	CASE
		WHEN price_INR < 100 THEN 'Under 100'
		WHEN price_INR BETWEEN 100 AND 199 THEN '100-199'
		WHEN price_INR BETWEEN 200 AND 299 THEN '200-299'
		WHEN price_INR BETWEEN 300 AND 399 THEN '300-399'
		WHEN price_INR BETWEEN 400 AND 499 THEN '400-499'
		ELSE '500+'
	END AS price_range,
	COUNT(*) AS Total_Orders
FROM fact_swiggy_orders
GROUP BY
	CASE
		WHEN price_INR < 100 THEN 'Under 100'
		WHEN price_INR BETWEEN 100 AND 199 THEN '100-199'
		WHEN price_INR BETWEEN 200 AND 299 THEN '200-299'
		WHEN price_INR BETWEEN 300 AND 399 THEN '300-399'
		WHEN price_INR BETWEEN 400 AND 499 THEN '400-499'
		ELSE '500+'
	END
ORDER BY Total_Orders DESC

--Rating Count Distribution (1-5)
SELECT
	Rating,
	COUNT(*) AS Rating_Count
FROM fact_swiggy_orders
GROUP BY Rating
ORDER BY COUNT(*) DESC

--





















