-- Challenge By: Carl Allchin, Jenny Martin & Lorna Brown
-- This challenge comes to you live from the first ever DataFam Europe!
-- We've teamed up with the Workout Wednesday team to bring you a special challenge. 
-- Since we're in London and very close to one of the most popular attractions (St Paul's Cathedral),
-- we thought we could centre the challenge around popular London Attractions and their nearest Tube Stations. 

------------------------------------------------------------------------------------------------------------------------

-- REQUIREMENTS :

-- Input the data
-- For the London Tube Stations table:
-- There are a lot of unnecessary fields, only keep information about the station name and location
-- Clean up the field names
-- There are a lot of duplicate rows. Make sure each row is unique (help)

-----------------------------------------------------------------------------------------------------------------------------

-- For the Attraction Footfall table:
-- Filter out attractions with missing data
-- Reshape the data so there is a row for each year, for each attraction
-- The footfall values need to be multiplied by 1000 to give their true values
-- Calculate the average footfall for each attraction, whilst keeping all the detail of individual years. Call the new field 5 Year Avg Footfall (help)
-- Rank the attractions based on this 5 Year Avg Footfall (help)

-------------------------------------------------------------------------------------------------------------------------------

-- For the Location Lat Longs table
-- The information about the latitude and longitude is contained in a single field, split these values into 2 separate fields 
-- Output the data as an Excel File, having each table as a separate sheet

---------------------------------------------------------------------------------------------------------
-- 1)

SELECT *
FROM london_tube_stations;

CREATE TABLE cleaned_london_tube_station AS

SELECT DISTINCT Station AS station_name, Right_Longitude AS longitutude, Right_Latitude as latitude
FROM london_tube_stations;

SELECT *
FROM cleaned_london_tube_station;

------------------------------------------------------------------------------------------------------------

-- 2)


SELECT *
FROM attraction_footfall;

CREATE TABLE cleaned_attraction_footfall AS
WITH CTE AS(
SELECT Characteristic AS attractions, '2019' AS year, `2019` AS footfall
FROM attraction_footfall
UNION
SELECT Characteristic AS attractions, '2020' AS year, `2020` AS footfall
FROM attraction_footfall
UNION ALL 
SELECT Characteristic AS attractions, '2021' AS year, `2021` AS footfall
FROM attraction_footfall
UNION ALL 
SELECT Characteristic AS attractions, '2022' AS year, `2022` AS footfall
FROM attraction_footfall
UNION ALL 
SELECT Characteristic AS attractions, '2023' AS year, `2023` AS footfall
FROM attraction_footfall
)
SELECT *
FROM CTE WHERE attractions NOT IN (SELECT attractions FROM CTE WHERE footfall ='-');

UPDATE cleaned_attraction_footfall
SET footfall = REPLACE(footfall, ',', '')*1000;

ALTER TABLE cleaned_attraction_footfall
MODIFY footfall INT;

DESCRIBE cleaned_attraction_footfall;

SELECT *
FROM cleaned_attraction_footfall;

WITH CTE AS (
SELECT attractions,year, 
       ROUND(AVG(footfall) OVER(PARTITION BY attractions),0) AS 5_year_avg_footfall,
	   footfall AS attraction_footfall
FROM cleaned_attraction_footfall
ORDER BY attractions ASC)

SELECT DENSE_RANK() OVER(ORDER BY 5_year_avg_footfall DESC) AS attraction_rank,
       attractions, year, 5_year_avg_footfall, attraction_footfall
FROM CTE 
ORDER BY attraction_rank;

CREATE TABLE cleaned_attraction_footfall_final
WITH CTE AS (
SELECT attractions,year, 
       ROUND(AVG(footfall) OVER(PARTITION BY attractions),0) AS 5_year_avg_footfall,
	   footfall AS attraction_footfall
FROM cleaned_attraction_footfall
ORDER BY attractions ASC)

SELECT DENSE_RANK() OVER(ORDER BY 5_year_avg_footfall DESC) AS attraction_rank,
       attractions, year, 5_year_avg_footfall, attraction_footfall
FROM CTE 
ORDER BY attraction_rank;


SELECT *
FROM cleaned_attraction_footfall_final ;


------------------------------------------------------------------------------------------------------
-- 3)

SELECT *
FROM location;

DESCRIBE location;

ALTER TABLE location
CHANGE COLUMN coordinates lat_longs VARCHAR(250),
ADD COLUMN latitude1 DECIMAL(11,8),
ADD COLUMN longitude1 DECIMAL(12,8);

UPDATE location
SET latitude1 = TRIM(SUBSTRING_INDEX(coordinates,',',1)),
    longitude1 = TRIM(SUBSTRING_INDEX(coordinates, ',', -1));

ALTER TABLE location
DROP COLUMN coordinates;





----------------------------------------------------------------------------------------------------------------