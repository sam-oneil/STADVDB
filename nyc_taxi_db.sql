/*
GROUP 8 - S19

Members:
Chynna Mae Tria
Heisel Janine Lazaro
Samantha O'Neil 
Caryl Nadine Roxas
*/

USE nyc_taxi_db;
SET SQL_SAFE_UPDATES = 0;

-- Ensure that DimDate does not exist
DROP TABLE IF EXISTS DimDate;

-- Task 3: Build a Date Dimension Table
CREATE TABLE DimDate (
    date_id INT AUTO_INCREMENT PRIMARY KEY,
    full_datetime VARCHAR(45),  
    full_date DATE,
    full_time TIME,
    year INT,
    month INT,
    day INT,
    hour INT
);

-- Add all pickup and dropoff dates/times to DimDate without duplicates
INSERT INTO DimDate (full_datetime, full_date, full_time, year, month, day, hour)
SELECT
	DATE_FORMAT(dt, '%c/%e/%Y %l:%i %p') AS full_datetime,
    DATE(dt) AS full_date,
    TIME(dt) AS full_time,
    YEAR(dt) AS year,
    MONTH(dt) AS month,
    DAY(dt) AS day,
    HOUR(dt) AS hour
FROM (
	SELECT STR_TO_DATE(tpep_pickup_datetime, '%c/%e/%Y %l:%i %p') AS dt FROM taxi_route_details
	UNION ALL
    SELECT STR_TO_DATE(tpep_dropoff_datetime, '%c/%e/%Y %l:%i %p') AS dt FROM taxi_route_details
	) AS all_times
GROUP BY dt;

-- Checker queries after building a date dimension table
SELECT * 
FROM DimDate;

-- Connect back to the main table by linking
ALTER TABLE taxi_route_details
ADD COLUMN pickup_date_id INT,
ADD COLUMN dropoff_date_id INT;

-- Create indexes to make joins faster 
CREATE INDEX idx_pickup_dt ON taxi_route_details (tpep_pickup_datetime);
CREATE INDEX idx_dropoff_dt ON taxi_route_details (tpep_dropoff_datetime);
CREATE INDEX idx_full_datetime ON DimDate (full_datetime);

-- Update table
UPDATE taxi_route_details t
JOIN DimDate d 
  ON tpep_pickup_datetime = d.full_datetime
SET t.pickup_date_id = d.date_id;

UPDATE taxi_route_details t
JOIN DimDate d 
  ON tpep_dropoff_datetime = d.full_datetime
SET t.dropoff_date_id = d.date_id;

-- Task 4: Use SQL to answer the following questions:
-- 1. Parse the date and time of tpep_pickup_datetime and tpep_dropoff_datetime 
SELECT 
    t.tripID,
    t.VendorID,
    
    -- Pickup 
    pickup.full_datetime AS pickup_datetime,
    pickup.full_date     AS pickup_date,
    pickup.full_time     AS pickup_time,
    pickup.year          AS pickup_year,
    pickup.month         AS pickup_month,
    pickup.day           AS pickup_day,
    pickup.hour          AS pickup_hour,
    
    -- Dropoff 
    dropoff.full_datetime AS dropoff_datetime,
    dropoff.full_date     AS dropoff_date,
    dropoff.full_time     AS dropoff_time,
    dropoff.year          AS dropoff_year,
    dropoff.month         AS dropoff_month,
    dropoff.day           AS dropoff_day,
    dropoff.hour          AS dropoff_hour

FROM taxi_route_details t
JOIN DimDate pickup  ON t.pickup_date_id  = pickup.date_id
JOIN DimDate dropoff ON t.dropoff_date_id = dropoff.date_id;

-- 2. Which vendor got the most trips per month? 
SELECT year, month, VendorID, trip_count
FROM (
    SELECT 
        d.year,
        d.month,
        t.VendorID,
        COUNT(*) AS trip_count,
        ROW_NUMBER() OVER (PARTITION BY d.year, d.month ORDER BY COUNT(*) DESC) AS row_num
    FROM taxi_route_details t
    JOIN DimDate d ON t.pickup_date_id = d.date_id
    GROUP BY d.year, d.month, t.VendorID
) ranked
WHERE row_num = 1;

-- 3. Are taxis earning more if they have more passengers? 

-- 4. Count the number of trips per vendor per month per pickup location? 

-- 5. What are the peak hours per vendor per month? 

-- 6. What is the top mode of payment per pickup location? 

-- Task 6: Come up with an interesting question that can be answered from the data (one per member)
-- Task 7: Create a query that will answer your question
-- 1. What is the average tip amount per vendor per month? (Chynna Mae Tria)
SELECT 
    d.year,
    d.month,
    r.VendorID,
    AVG(p.tip_amount) AS avg_tip
FROM taxi_route_details r
JOIN DimDate d 
    ON r.pickup_date_id = d.date_id
JOIN taxi_payment_details p 
    ON r.tripID = p.tripID
GROUP BY d.year, d.month, r.VendorID
ORDER BY d.year, d.month, avg_tip DESC;

-- 2. What is the average trip distance per vendor per month? (Heisel Janine Lazaro)
SELECT 
    d.year,
    d.month,
    r.VendorID,
    AVG(r.trip_distance) AS avg_trip_distance
FROM taxi_route_details r
JOIN DimDate d 
    ON r.pickup_date_id = d.date_id
GROUP BY d.year, d.month, r.VendorID
ORDER BY d.year, d.month, avg_trip_distance DESC;

-- 3. (Samantha O'Neil)

-- 4. (Caryl Nadine Roxas)