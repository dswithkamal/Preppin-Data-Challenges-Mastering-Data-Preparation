-- 2024: Week 48 - Cross Sport League Table Ranks
-- Challenge by: Eden Thiede-Palmer
-- Eden created the challenge for this week. As a Data School Consultant who finishes training this week,
-- it's a great example of how your data skills can help you dive deeper into your favourite topics - like sports! Over to Eden:
-- Who the best team/athlete in sports is always a debate amongst fans,
-- and one of the challenges of the debate is that it's difficult to compare across sports.

-- I had the idea of creating one large league table across a few major sports,
-- by creating a normalised score across different leagues.

---------------------------------------------------------------------------------------------------------------------------------
-- Requirements
-- Input the data
-- Name the field used to rank each league table ‘Ranking Field’
-- Wins for NBA and NFL
-- Points for Rugby Aviva Premiership and Premier League
-- Name and / or calculate First and Second Tie Breaking Fields For each sport.
-- Premier League: Tie Breaker 1 = Wins, Tie Breaker 2 = Goals Scored
-- NFL: Tie Breaker 1 = Points Differential, Tie Breaker 2 = Points For
-- Points Differential = Points For - Points Against
-- NBA: Tie Breaker 1 = Games Behind, Tie Breaker 2 = Conference Wins
-- The Conference Record Field is structured Wins-Losses
-- Rugby: Tie Breaker 1 = Wins (W), Tie Breaker 2 = Points Differential (PD)
-- Make sure all the data types are accurate
-- Bring all the tables together into one dataset
-- Use the Table Names to create a field for the Sport
-- Removing the word Results
-- Calculate the Rank of each team within their own sport using the tie breaking fields to ensure unique ranks
-- Calculate the z-score for each team within their sport

-- x=Ranking Field
-- u=Mean of Ranking Field within sport
-- o=Standard Deviation of Ranking Field within sport
-- Calculate a Sport Specific Percentile Rank 

-- Create a Cross Sport Rank based on the z-scores and using the Sport Specific Percentile Rank to break ties
-- Remove unnecessary fields
-- Output the data
-- Create a second output that averages the Cross Sport Rank for each sport, to see which sport had the best season in 2023/24

----------------------------------------------------------------------------------------------------------------------------
SELECT *
FROM `fa premier league`;

SELECT *
FROM `nba league`;

SELECT *
FROM `nfl league`;

SELECT *
FROM `rugby aviva league`;

--------------------------------------------------------------------------------------------------------------------------------
-- 1)

ALTER TABLE `fa premier league`
CHANGE COLUMN PtsPoints ranking_field INT;

ALTER TABLE `nba league` 
CHANGE COLUMN WWins ranking_field INT;

ALTER TABLE `nfl league`
CHANGE COLUMN Wwins ranking_field INT;

ALTER TABLE `rugby aviva league` 
CHANGE COLUMN PTS ranking_field INT;

----------------------------------------------------------------------------------------------------------------------------------
-- 2)

ALTER TABLE `fa premier league` 
ADD COLUMN tie_breaker_1 INT,
ADD COLUMN tie_breaker_2 INT;

UPDATE `fa premier league`
SET tie_breaker_1 = `WWins`,
    tie_breaker_2 = `GFGoals scored`;
    
ALTER TABLE `nba league` 
CHANGE COLUMN tie_breaker_1 tie_breaker_1 VARCHAR(50),
CHANGE COLUMN tie_breaker_2 tie_breaker_2 VARCHAR(50);

UPDATE `nba league` 
SET tie_breaker_1 = `GBGames behind`,
    tie_breaker_2 = TRIM(SUBSTRING_INDEX(`ConfConference record`,'-',1));

UPDATE `nba league` 
SET tie_breaker_1 = REPLACE(tie_breaker_1,'-',0),
    tie_breaker_2 = REPLACE(tie_breaker_2,'-',0);
    
ALTER TABLE `nba league` 
CHANGE COLUMN tie_breaker_1 tie_breaker_1 INT,
CHANGE COLUMN tie_breaker_2 tie_breaker_2 INT;

ALTER TABLE `nfl league`
ADD COLUMN tie_breaker_1 INT,
ADD COLUMN tie_breaker_2 INT;

UPDATE `nfl league` 
SET tie_breaker_1 = `PFPoints for` - `PAPoints against`,
    tie_breaker_2 = `PFPoints for`;
    

ALTER TABLE `rugby aviva league` 
ADD COLUMN tie_breaker_1 INT,
ADD COLUMN tie_breaker_2 INT;

UPDATE `rugby aviva league` 
SET tie_breaker_1 = W,
    tie_breaker_2 = W-L;
    
------------------------------------------------------------------------------------------------------------------

-- 3)

DESCRIBE `fa premier league`;
DESCRIBE `nba league`;
DESCRIBE `nfl league`;
DESCRIBE `rugby aviva league`;


--------------------------------------------------------------------------------------------------------------------

-- 4)

CREATE TABLE cross_sport_league AS
SELECT 'premier_league' as sport, Club as team, ranking_field, tie_breaker_1, tie_breaker_2
FROM `fa premier league`
UNION ALL
SELECT 'nba_league' as sport, Team as team, ranking_field, tie_breaker_1, tie_breaker_2
FROM `nba league`
UNION ALL
SELECT 'nfl_league' as sport, Team as team, ranking_field, tie_breaker_1, tie_breaker_2
FROM `nfl league`
UNION ALL 
SELECT 'rugby_aviva_league' as sport, Team as team, ranking_field, tie_breaker_1, tie_breaker_2
FROM `rugby aviva league`;

SELECT *
FROM cross_sport_league;

---------------------------------------------------------------------------------------------------------------------------

-- 5)

SELECT *,
RANK() OVER(PARTITION BY sport ORDER BY ranking_field DESC, tie_breaker_1 DESC, tie_breaker_2 DESC) AS sport_rank
FROM cross_sport_league;

----------------------------------------------------------------------------------------------------------------------------

-- 6) OUTPUT 1


CREATE TABLE final_cross_sport_league  AS
WITH CTE AS(
SELECT sport,
team, ranking_field,
(ranking_field - AVG(ranking_field) OVER(PARTITION BY sport))/
STDDEV(ranking_field) OVER(PARTITION BY sport) AS z_score,
ROUND(1 - (RANK() OVER(PARTITION BY sport ORDER BY ranking_field DESC, tie_breaker_1 DESC, tie_breaker_2 DESC)/
COUNT(team) OVER(PARTITION BY sport) ) ,2)AS sport_specific_percentile_rank
FROM cross_sport_league)

SELECT sport, RANK() OVER(ORDER BY z_score DESC, sport_specific_percentile_rank DESC) as cross_sport_rank,
       ranking_field, z_score, sport_specific_percentile_rank
FROM CTE ;


----------------------------------------------------------------------------------------------------------------------

-- 7) OUTPUT 2

SELECT sport, AVG(cross_sport_rank) AS avg_cross_sport_rank
FROM final_cross_sport_league
GROUP BY sport


--------------------------------------------------------------------------------------------------------------------------