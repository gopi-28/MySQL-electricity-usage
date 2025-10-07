CREATE database PROJ_ELECTRIC;
USE PROJ_ELECTRIC;

SELECT * FROM appliance_usage;
SELECT * FROM billing_info;
SELECT * FROM calculated_metrics;
SELECT * FROM environmental_data;
SELECT * FROM household_info;

-- ---------------------------------------------------------------------------------------------------------
/*
PROJECT TASK 1: UPDATE THE PAYMENT_STATUS IN THE BILLING_INFO TABLE BASED ON THE COST_USD VALUE. USE CASE...END LOGIC.
•	HINT:
COST_USD > 200 SET “HIGH”
COST_USD >  100 AND 200  SET “MEDIUM”
ELSE “LOW”
USE THE UPDATE STATEMENT ALONG WITH CASE TO SET VALUES CONDITIONALLY.
*/

SELECT * FROM billing_info;
UPDATE billing_info
SET payment_status = CASE -- to check
WHEN cost_usd > 200 THEN 'High'
WHEN cost_usd > 100 AND cost_usd <= 200 THEN 'Medium' ELSE 'Low'
END;


-- ---------------------------------------------------------------------------------------------------------

/*
PROJECT TASK 2: (USING GROUP BY) FOR EACH HOUSEHOLD, SHOW THE MONTHLY ELECTRICITY USAGE, 
RANK OF USAGE WITHIN EACH YEAR, AND CLASSIFY USAGE LEVEL.
•	HINT: USE SUM, MONTHNAME, DATE_FORMAT, RANK() OVER, AND CASE.
•	HINT2: UPDATE USAGE LEVEL CRITERIA USING TOTAL KWH
SUM(TOTAL KWH > 500 THEN “HIGH”
ELSE “LOW”
*/

select HOUSEHOLD_ID, MONTH, YEAR ,total_kwh,
 RANK() OVER(PARTITION BY YEAR ORDER BY TOTAL_KWH DESC ) AS RANK_USAGE,
DATE_FORMAT(SUBSTRING_INDEX(BILLING_CYCLE, ' to ', 1),'%Y-%m-%d') AS DATE,
CASE
 WHEN TOTAL_KWH > 500 THEN 'HIGH' ELSE 'LOW' 
 END AS USAGE_LEVEL 
FROM (SELECT HOUSEHOLD_ID, MONTH, YEAR, sum(TOTAL_KWH) as total_kwh, BILLING_CYCLE
FROM BILLING_INFO GROUP BY HOUSEHOLD_ID, MONTH,YEAR, BILLING_CYCLE)  as a ;

-- ---------------------------------------------------------------------------------------------------------
/*
PROJECT TASK 3:
CREATE A MONTHLY USAGE PIVOT TABLE SHOWING USAGE FOR JANUARY, FEBRUARY, AND MARCH.
•	HINT: USE CONDITIONAL AGGREGATION USING PIVOT CONCEPT WITH CASE WHEN.
*/
select * from billing_info;
 select household_id,
 sum(case when month = 'jan' then total_kwh else 0 end ) as jan,
sum(case when month = 'feb'then total_kwh else 0 end) as feb,
 sum(case when month = 'mar' then total_kwh else 0 end ) as march
 from billing_info group by household_id;

-- ---------------------------------------------------------------------------------------------------------

/*
Project Task 4: Show average monthly usage per household with city name.
•	Hint: Use a subquery grouped by household and month.
*/
/*
-- method 1
SELECT h.household_id, h.city, b.month, round((AVG(b.total_kwh)),2) AS avg_monthly_usage   -- (without subquery)
FROM household_info h
INNER JOIN billing_info b ON h.household_id = b.household_id
GROUP BY h.household_id, h.city, b.month
ORDER BY h.household_id, b.month;
*/
-- method 2
select b.*, h.city 
from (select household_id, month, round((AVG(total_kwh)),2) AS avg_monthly_usage 
from billing_info group by household_id , month) as B inner join household_info as h on b.household_id=h.household_id;
SELECT * FROM billing_info;
SELECT * FROM household_info;

-- ---------------------------------------------------------------------------------------------------------
/*
PROJECT TASK 5: RETRIEVE AC USAGE AND OUTDOOR TEMPERATURE FOR HOUSEHOLDS WHERE AC USAGE IS HIGH.
	HINT: USE A SUBQUERY TO FILTER AC USAGE ABOVE 100.(HIGH)
*/
SELECT e.household_id, e.avg_outdoor_temp AS outdoor_temperature , a.kwh_usage_AC AS ac_usage
FROM environmental_data e 
JOIN appliance_usage a ON a.household_id = e.household_id
WHERE a.household_id IN ( SELECT household_id FROM appliance_usage WHERE kwh_usage_AC > 100);

SELECT * FROM appliance_usage;
SELECT * FROM environmental_data;

-- ---------------------------------------------------------------------------------------------------------
/*
PROJECT TASK 6: CREATE A PROCEDURE TO RETURN BILLING INFO FOR A GIVEN REGION.
•	HINT: USE IN parameter in a  CREATE PROCEDURE.
*/
delimiter **
CREATE PROCEDURE billing_info_by_region (IN region_name VARCHAR(10))
BEGIN
SELECT b.household_id, h.region, b.month, b.year, b.billing_cycle, b.payment_status, b.cost_usd, b.total_kwh
 FROM billing_info b 
JOIN household_info h ON b.household_id = h.household_id WHERE h.region = region_name;
END **
DELIMITER ;
DROP PROCEDURE billing_info_by_region;
CALL billing_info_by_region('NORTH');
CALL billing_info_by_region('EAST');
CALL billing_info_by_region('WEST');
CALL billing_info_by_region('SOUTH');

select * from household_info;
select * from billing_info;
-- ---------------------------------------------------------------------------------------------------------
/*
Project Task 7: Create a procedure to calculate total usage for a household and return it.
•	Hint: Use INOUT parameter and assign with SELECT INTO.
*/
select * from billing_info;
 DELIMITER **
CREATE PROCEDURE tot_use_of_household( IN hh_id VARCHAR(10) , INOUT tot_usage VARCHAR(20))
BEGIN
SELECT SUM(total_kwh) INTO tot_usage
FROM billing_info WHERE hh_id = household_id;
END **
DELIMITER ;
DROP PROCEDURE tot_use_of_household;
CALL tot_use_of_household('H0001', @tot_usage);
CALL tot_use_of_household('H0003', @tot_usage);
CALL tot_use_of_household('H0008', @tot_usage);
SELECT @tot_usage ;

/*
Project Task 8: Automatically calculate cost_usd before inserting into billing_info.
•	Hint: Use BEFORE INSERT trigger and assign NEW.cost_usd.
*/

CREATE TABLE cost_usd(
household_id text ,
month text,
year int,
billing_cycle text ,
payment_status text ,
rate_per_kwh double ,
cost_usd double ,
total_kwh double
);
select * from billing_info;

DELIMITER **
CREATE TRIGGER cal_cost_usd BEFORE INSERT ON cost_usd FOR EACH ROW
BEGIN
SET NEW.cost_usd = NEW.rate_per_kwh * NEW.total_kwh;
END **
DELIMITER ;

INSERT INTO cost_usd (household_id, month, year, billing_cycle, payment_status, rate_per_kwh, total_kwh)
VALUES ('HH101', 'August', 2025, 'Monthly', 'Pending', 0.15, 250);

INSERT INTO cost_usd (household_id, month, year, billing_cycle, payment_status, rate_per_kwh, total_kwh)
VALUES('H0001', 'Jan', 2025, '2025-01-01 to 2025-01-30', 'Unpaid', 0.18,  1885.95),
('H0002', 'Feb', 2025, '2025-02-01 to 2025-02-30', 'Paid', 0.18,  1681.53),
('H0003', 'Mar', 2025, '2025-03-01 to 2025-03-30', 'Unpaid', 0.18,  1835.22),
('H0004', 'Apr', 2025, '2025-04-01 to 2025-04-30', 'Unpaid', 0.18, 1348.03);
SELECT * FROM cost_usd;
-- ----------------------------------------------------------------------------------------------------------

/*
-- TASK 9
PROJECT TASK 9 : AFTER A NEW BILLING ENTRY, INSERT CALCULATED METRICS INTO CALCULATED_METRICS.
•	HINT1: USE AFTER INSERT TRIGGER AND NEW KEYWORD.
•	HINT 2:  CALCULATIONS(METRICS)
HOUSE HOLD_ID = NEW.HOUSE_HOLD_ID
KWG PER_OCCUPANT = TOTAL_KWH /NUM_OCCUPANTS
USAGE CATEGORY = TOTAL_KWH > 600 SET “HIGH” ELSE “MODERATE”
*/
-- calculated_metrics table
use proj_electric;

CREATE TABLE billing_entry (
    household_id TEXT,
    month TEXT,
    year INT,
    billing_cycle TEXT,
    payment_status TEXT,
    rate_per_kwh DOUBLE,
    cost_usd DOUBLE,
    total_kwh DOUBLE
);
CREATE TABLE  cal_metric(
    household_id TEXT,
    kwh_per_occupant DOUBLE,
    usage_category TEXT
);
drop table billing_entry;
drop table cal_metric ;

delimiter //
create trigger after_insert_billing AFTER INSERT ON billing_entry FOR EACH ROW  
begin
declare KWH_PER_OCCUPANT double default 0 ;
declare usage_category text default null ;

select n.TOTAL_KWH /h.NUM_OCCUPANTS into kwh_per_occupant from billing_entry
 as n inner join household_info as h 
on n.household_id= h.household_id where n.household_id = new.household_id ;


select case when total_kwh > 600 then 'HIGH' ELSE 'MODERATE' end into usage_category from 
 billing_entry where household_id = new.HOUSEHOLD_ID;


insert into cal_metric (household_id  ,kwh_per_occupant,usage_category )
values (new.household_id  ,KWH_PER_OCCUPANT ,usage_category );
end //
delimiter ;

drop trigger after_insert_billing;

select * from billing_info;

insert into billing_entry (household_id  ,month  ,year  ,billing_cycle  ,payment_status  ,rate_per_kwh  ,cost_usd  ,total_kwh )
values 
('H0001', 'Jan', 2025, '2025-01-01 to 2025-01-30', 'HIGH', 0.18, 339.47, 1885.95),
('H0002', 'Feb', 2025, '2025-02-01 to 2025-02-30', 'HIGH', 0.18, 302.68, 1681.53),
('H0003', 'Mar', 2025, '2025-03-01 to 2025-03-30', 'HIGH', 0.18, 330.34, 1835.22),
('H0004', 'Apr', 2025, '2025-04-01 to 2025-04-30', 'HIGH', 0.18, 242.65, 1348.03),
('H0005', 'May', 2025, '2025-05-01 to 2025-05-30', 'HIGH', 0.18, 260.32, 1446.23);
delete from billing_entry;
delete from cal_metric;
select * from billing_entry ; -- dummy table
select * from cal_metric;-- dummy table
select * from household_info;












