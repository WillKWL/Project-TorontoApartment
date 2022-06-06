-- load MCI data into database
DROP TABLE IF EXISTS mci_data;

CREATE TABLE mci_data (
    occurrence_unique_id VARCHAR(255),
    occurrence_date TIMESTAMP,
    premises_type VARCHAR(255),
    occurrence_year INT,
    occurrence_month VARCHAR(255),
    occurrence_day INT,
    occurrence_dayofyear INT,
    occurrence_dayofweek VARCHAR(255),
    occurrence_hour INT,
    MCI VARCHAR(255),
    hood_id VARCHAR(255),
    neighbourhood VARCHAR(255),
    longitude NUMERIC,
    latitude NUMERIC,
    x NUMERIC,
    y NUMERIC
);

COPY mci_data
FROM
    'C:/Program Files/PostgreSQL/14/data/Major_Crime_Indicators.csv' DELIMITER ',' CSV HEADER;

ALTER TABLE
    mci_data DROP COLUMN IF EXISTS premises_type,
    DROP COLUMN IF EXISTS x,
    DROP COLUMN IF EXISTS y;

SELECT
    *
FROM
    mci_data
LIMIT
    5;

-- load shootings data
DROP TABLE IF EXISTS shootings;

CREATE TABLE shootings (
    INDEX INT,
    occurrence_unique_id VARCHAR,
    occurrence_date TIMESTAMP,
    occurrence_year INT,
    occurrence_month VARCHAR,
    occurrence_dayofweek VARCHAR,
    occurrence_hour NUMERIC,
    time_range VARCHAR,
    division VARCHAR,
    death VARCHAR,
    injuries VARCHAR,
    hood_id VARCHAR,
    neighbourhood VARCHAR,
    longitude NUMERIC,
    latitude NUMERIC,
    object_id NUMERIC,
    x NUMERIC,
    y NUMERIC
);

COPY shootings
FROM
    'C:/Program Files/PostgreSQL/14/data/Shootings.csv' DELIMITER ',' CSV HEADER;

-- clean columns
ALTER TABLE
    shootings DROP COLUMN IF EXISTS time_range,
    DROP COLUMN IF EXISTS death,
    DROP COLUMN IF EXISTS injuries,
    DROP COLUMN IF EXISTS INDEX,
    DROP COLUMN IF EXISTS division,
    DROP COLUMN IF EXISTS object_id,
    DROP COLUMN IF EXISTS x,
    DROP COLUMN IF EXISTS y,
ADD
    COLUMN IF NOT EXISTS MCI VARCHAR;

UPDATE
    shootings
SET
    neighbourhood = split_part(neighbourhood, ' (', 1),
    MCI = 'Shootings',
    occurrence_hour = occurrence_hour :: int;

SELECT
    *
FROM
    shootings
LIMIT
    5;

-- load homicides data
DROP TABLE IF EXISTS homicide;

CREATE TABLE homicide (
    INDEX INT,
    occurrence_unique_id VARCHAR,
    occurrence_year INT,
    division VARCHAR,
    homicide_type VARCHAR,
    occurrence_date TIMESTAMP,
    hood_id VARCHAR,
    neighbourhood VARCHAR,
    longitude NUMERIC,
    latitude NUMERIC,
    object_id NUMERIC,
    x NUMERIC,
    y NUMERIC
);

COPY homicide
FROM
    'C:/Program Files/PostgreSQL/14/data/Homicide.csv' DELIMITER ',' CSV HEADER;

ALTER TABLE
    homicide DROP COLUMN IF EXISTS homicide_type,
    DROP COLUMN IF EXISTS INDEX,
    DROP COLUMN IF EXISTS division,
    DROP COLUMN IF EXISTS object_id,
    DROP COLUMN IF EXISTS x,
    DROP COLUMN IF EXISTS y,
ADD
    COLUMN IF NOT EXISTS MCI VARCHAR;

-- remove hood_ID from neighbourhoods
UPDATE
    homicide
SET
    neighbourhood = split_part(neighbourhood, ' (', 1),
    MCI = 'Homicide';

SELECT
    *
FROM
    homicide
LIMIT
    5;

-- check number of rows and columns
SELECT
    count(*)
FROM
    shootings;

SELECT
    count(*)
FROM
    homicide;

SELECT
    count(*)
FROM
    information_schema.columns
WHERE
    table_name = 'shootings';

SELECT
    count(*)
FROM
    information_schema.columns
WHERE
    table_name = 'homicide';

-- check that we have similar columns except a few across 3 tables
SELECT
    column_name,
    -- table_name,
    count(*)
FROM
    information_schema.columns
WHERE
    table_name = 'shootings'
    OR table_name = 'homicide'
    OR table_name = 'mci_data'
GROUP BY
    column_name
HAVING
    count(*) < 3
ORDER BY
    count(*);

-- concat the 3 tables together
DROP TABLE IF EXISTS all_df;

CREATE TABLE all_df AS
SELECT
    occurrence_unique_id,
    occurrence_date,
    occurrence_year,
    occurrence_month,
    occurrence_day,
    occurrence_dayofyear,
    occurrence_dayofweek,
    occurrence_hour,
    mci,
    hood_id,
    neighbourhood,
    longitude,
    latitude
FROM
    mci_data
UNION
SELECT
    occurrence_unique_id,
    occurrence_date,
    occurrence_year,
    occurrence_month,
    NULL :: INT AS occurrence_day,
    NULL :: INT AS occurrence_dayofyear,
    occurrence_dayofweek,
    occurrence_hour,
    mci,
    hood_id,
    neighbourhood,
    longitude,
    latitude
FROM
    shootings
UNION
SELECT
    occurrence_unique_id,
    occurrence_date,
    occurrence_year,
    NULL :: VARCHAR AS occurrence_month,
    NULL :: INT AS occurrence_day,
    NULL :: INT AS occurrence_dayofyear,
    NULL :: VARCHAR AS occurrence_dayofweek,
    NULL :: INT AS occurrence_hour,
    MCI,
    hood_id,
    neighbourhood,
    longitude,
    latitude
FROM
    homicide;

SELECT count(*) from mci_data limit 1;
SELECT count(*) from shootings limit 1;
select count(*) from homicide limit 1;
select count(*) from all_df;

-- check number of missing data for each column
SELECT
    count(*) - count(occurrence_unique_id) AS occurrence_unique_id,
    count(*) - count(occurrence_date) AS occurrence_date,
    count(*) - count(occurrence_year) AS occurrence_year,
    count(*) - count(occurrence_month) AS occurrence_month,
    count(*) - count(occurrence_day) AS occurrence_day,
    count(*) - count(occurrence_dayofyear) AS occurrence_dayofyear,
    count(*) - count(occurrence_dayofweek) AS occurrence_dayofweek,
    count(*) - count(occurrence_hour) AS occurrence_hour,
    count(*) - count(MCI) AS mci,
    count(*) - count(hood_id) AS hood_id,
    count(*) - count(neighbourhood) AS neighbourhood,
    count(*) - count(longitude) AS longitude,
    count(*) - count(latitude) AS latitude
FROM
    all_df;

-- can we use occurrence_date to imply the missing data in other date columns?
-- hour implied from occurrence_date looks wrong as crime cannot only happen between 12:00 and 13:00
WITH describe_dates AS (
    SELECT
        date_part('day', occurrence_date) :: int AS dayofmonth,
        date_part('doy', occurrence_date) :: int AS dayofyear,
        date_part('month', occurrence_date) :: int AS MONTH,
        date_part('dow', occurrence_date) :: int AS weekday,
        date_part('hour', occurrence_date) :: int AS HOUR
    FROM
        all_df
)
SELECT
    'dayofmonth',
    min(dayofmonth),
    avg(dayofmonth),
    max(dayofmonth)
FROM
    describe_dates
UNION
SELECT
    'dayofyear',
    min(dayofyear),
    avg(dayofyear),
    max(dayofyear)
FROM
    describe_dates
UNION
SELECT
    'month',
    min(MONTH),
    avg(MONTH),
    max(MONTH)
FROM
    describe_dates
UNION
SELECT
    'weekday',
    min(weekday),
    avg(weekday),
    max(weekday)
FROM
    describe_dates
UNION
SELECT
    'hour',
    min(HOUR),
    avg(HOUR),
    max(HOUR)
FROM
    describe_dates; 
    
-- if we cannot imply the missing hour, can we drop rows with missing occurrence_hour?
-- dropping rows with missing occurrence_hour would mean dropping all homicide records
SELECT
    mci,
    count(*)
FROM
    all_df
WHERE
    occurrence_hour IS NULL
GROUP BY
    mci;

-- instead let's drop occurrence_hour column
ALTER TABLE
    all_df DROP COLUMN IF EXISTS occurrence_hour;

-- imply the other missing data with occurrence_date
-- occurrence_month, occurrence_day, occurrence_dayofyear, occurrence_dayofweek
UPDATE 
    all_df
SET
    occurrence_month = date_part('month', occurrence_date)
WHERE
    occurrence_month IS NULL;
UPDATE 
    all_df
SET
    occurrence_day = date_part('day', occurrence_date)
WHERE
    occurrence_day IS NULL;
UPDATE
    all_df
SET
    occurrence_dayofyear = date_part('doy', occurrence_date)
WHERE
    occurrence_dayofyear IS NULL;
UPDATE
    all_df
SET
    occurrence_dayofweek = date_part('dow', occurrence_date)
WHERE
    occurrence_dayofweek IS NULL;

-- check number of missing data for each column
SELECT
    count(*) - count(occurrence_unique_id) AS occurrence_unique_id,
    count(*) - count(occurrence_date) AS occurrence_date,
    count(*) - count(occurrence_year) AS occurrence_year,
    count(*) - count(occurrence_month) AS occurrence_month,
    count(*) - count(occurrence_day) AS occurrence_day,
    count(*) - count(occurrence_dayofyear) AS occurrence_dayofyear,
    count(*) - count(occurrence_dayofweek) AS occurrence_dayofweek,
    count(*) - count(MCI) AS mci,
    count(*) - count(hood_id) AS hood_id,
    count(*) - count(neighbourhood) AS neighbourhood,
    count(*) - count(longitude) AS longitude,
    count(*) - count(latitude) AS latitude
FROM
    all_df;

-- let's drop the rows with missing occurrence_date
select * from all_df where occurrence_date is null;

DELETE from all_df
WHERE
    occurrence_date IS NULL;
