-- load MCI data into database
DROP TABLE IF EXISTS collision_data;

CREATE TABLE collision_data (
    occurrence_unique_id VARCHAR(255),
    occurrence_date TIMESTAMP,
    occurrence_month VARCHAR(255),
    occurrence_dayofweek VARCHAR(255),
    occurrence_year INT,
    occurrence_hour INT,
    hood_id VARCHAR(255),
    neighbourhood VARCHAR(255),
    fatalities INT,
    injury_collisions VARCHAR(255),
    ftr_collisions VARCHAR(255),
    pd_collisions VARCHAR(255),
    longitude NUMERIC,
    latitude NUMERIC,
    x NUMERIC,
    y NUMERIC
);

COPY collision_data
FROM
    'C:/Program Files/PostgreSQL/14/data/Traffic_Collisions.csv' DELIMITER ',' CSV HEADER;

ALTER TABLE
    collision_data DROP COLUMN IF EXISTS premises_type,
    DROP COLUMN IF EXISTS x,
    DROP COLUMN IF EXISTS y;

SELECT
    *
FROM
    collision_data
LIMIT
    5;

-- check number of rows and columns
SELECT
    count(*)
FROM
    collision_data;

SELECT
    count(*)
FROM
    information_schema.columns
WHERE
    table_name = 'collision_data';

-- check number of missing data for each column
SELECT
    count(*) - count(occurrence_unique_id) AS occurrence_unique_id,
    count(*) - count(occurrence_date) AS occurrence_date,
    count(*) - count(occurrence_month) AS occurrence_month,
    count(*) - count(occurrence_dayofweek) AS occurrence_dayofweek,
    count(*) - count(occurrence_year) AS occurrence_year,
    count(*) - count(occurrence_hour) AS occurrence_hour,
    count(*) - count(hood_id) AS hood_id,
    count(*) - count(neighbourhood) AS neighbourhood,
    count(*) - count(fatalities) AS fatalities,
    count(*) - count(injury_collisions) AS injury_collisions,
    count(*) - count(ftr_collisions) AS ftr_collisions,
    count(*) - count(pd_collisions) AS pd_collisions,
    count(*) - count(longitude) AS longitude,
    count(*) - count(latitude) AS latitude
FROM
    collision_data;

-- split hood_id from neighbourhood
SELECT
    hood_id,
    neighbourhood
FROM
    collision_data
GROUP BY
    hood_id,
    neighbourhood;

UPDATE
    collision_data
SET
    neighbourhood = split_part(neighbourhood, ' (', 1);

-- check NSA is unique
SELECT
    neighbourhood
FROM
    collision_data
WHERE
    hood_id = 'NSA'
GROUP BY
    neighbourhood;

SELECT
    neighbourhood,
    hood_id
FROM
    collision_data
WHERE
    neighbourhood = 'NSA'
GROUP BY
    neighbourhood,
    hood_id;

UPDATE
    collision_data
SET
    hood_id = 'NSA'
WHERE
    neighbourhood = 'NSA';

-- add occurrence_day and occurrence_dayofyear to be consistent with mci data
ALTER TABLE
    collision_data
ADD
    COLUMN occurrence_day INT,
ADD
    COLUMN occurrence_dayofyear INT;

UPDATE
    collision_data
SET
    occurrence_day = date_part('day', occurrence_date),
    occurrence_dayofyear = date_part('doy', occurrence_date);

-- Check for inconsistencies among date columns
-- occurrence_year is fine
SELECT
    occurrence_date,
    occurrence_year
FROM
    collision_data
WHERE
    date_part('year', occurrence_date) != occurrence_year;

-- occurrence_month is fine
SELECT
    occurrence_date,
    occurrence_month
FROM
    collision_data
WHERE
    to_char(occurrence_date, 'FMMonth') != occurrence_month;

-- occurrence_day is fine
SELECT
    date_part('day', occurrence_date),
    occurrence_day
FROM
    collision_data
WHERE
    date_part('day', occurrence_date) != occurrence_day;

-- , occurrence_dayofyear is fine
SELECT
    date_part('doy', occurrence_date),
    occurrence_dayofyear
FROM
    collision_data
WHERE
    date_part('doy', occurrence_date) != occurrence_dayofyear;

-- occurrence_dayofweek is fine
SELECT
    to_char(occurrence_date, 'FMDay'),
    occurrence_dayofweek
FROM
    collision_data
WHERE
    to_char(occurrence_date, 'FMDay') != occurrence_dayofweek;

-- occurrence_hour does not match with hour implied from occurrence_date
SELECT
    date_part('hour', occurrence_date),
    occurrence_hour
FROM
    collision_data
WHERE
    date_part('hour', occurrence_date) != occurrence_hour;

-- hour implied from occurrence_date is wrong, traffic collisiosn cannot only happen within 12:00 and 13:00
SELECT
    min(HOUR),
    avg(HOUR),
    max(HOUR)
FROM
    (
        SELECT
            date_part('hour', occurrence_date) AS HOUR
        FROM
            collision_data
    ) AS hour_implied;

-- occurrence hour looks okay
SELECT
    min(occurrence_hour),
    avg(occurrence_hour),
    max(occurrence_hour)
FROM
    (
        SELECT
            occurrence_hour
        FROM
            collision_data
    ) AS hour_ready;

-- let's update the hour in occurrence_date with occurrence_hour
UPDATE
    collision_data
SET
    occurrence_date = make_timestamp(
        date_part('year', occurrence_date) :: int,
        date_part('month', occurrence_date) :: int,
        date_part('day', occurrence_date) :: int,
        occurrence_hour :: int,
        0 :: int,
        0
    );

-- check inconsistency among date columns again
SELECT
    count(*) AS year
FROM
    collision_data
WHERE
    date_part('year', occurrence_date) != occurrence_year;

SELECT
    count(*) AS MONTH
FROM
    collision_data
WHERE
    to_char(occurrence_date, 'FMMonth') != occurrence_month;

SELECT
    count(*) AS DAY
FROM
    collision_data
WHERE
    date_part('day', occurrence_date) != occurrence_day;

SELECT
    count(*) AS dayofyear
FROM
    collision_data
WHERE
    date_part('doy', occurrence_date) != occurrence_dayofyear;

SELECT
    count(*) AS dayofweek
FROM
    collision_data
WHERE
    to_char(occurrence_date, 'FMDay') != occurrence_dayofweek;

SELECT
    count(*)
FROM
    collision_data
WHERE
    date_part('hour', occurrence_date) != occurrence_hour;

-- check inconsistency between hood_id and neighbourhood
-- distinct count of hood_id
SELECT
    count(*)
FROM
    (
        SELECT
            hood_id
        FROM
            collision_data
        GROUP BY
            hood_id
    ) AS id_count;

-- distinct count of neighbourhood
SELECT
    count(*)
FROM
    (
        SELECT
            neighbourhood
        FROM
            collision_data
        GROUP BY
            neighbourhood
    ) AS hood_count;

-- no duplicate neighbourhood since all combinations have only 1 row
SELECT
    neighbourhood,
    hood_id,
    row_number() OVER (
        PARTITION BY neighbourhood
        ORDER BY
            neighbourhood
    ) AS row_count
FROM
    collision_data
GROUP BY
    neighbourhood,
    hood_id
ORDER BY
    row_count DESC;

-- no duplicate hood_id since all combinations have only 1 row
SELECT
    neighbourhood,
    hood_id,
    row_number() OVER (
        PARTITION BY hood_id
        ORDER BY
            hood_id
    ) AS row_count
FROM
    collision_data
GROUP BY
    neighbourhood,
    hood_id
ORDER BY
    row_count DESC;

-- issue was that there are extra punctuation in neighbourhood
SELECT
    neighbourhood,
    hood_id
FROM
    collision_data
WHERE
    hood_id = '54'
    OR hood_id = '118'
    OR hood_id = '117'
GROUP BY
    neighbourhood,
    hood_id
ORDER BY
    hood_id;

-- fixing the 3 neighbourhoods
UPDATE
    collision_data
SET
    neighbourhood = 'L ''Amoreaux'
WHERE
    hood_id = '117';

UPDATE
    collision_data
SET
    neighbourhood = 'Tam O ''Shanter-Sullivan'
WHERE
    hood_id = '118';

UPDATE
    collision_data
SET
    neighbourhood = 'O ''Connor-Parkview'
WHERE
    hood_id = '54';

-- consistent with neighbourhoods.geojson
UPDATE
    collision_data
SET
    neighbourhood = 'Mimico (includes Humber Bay Shores)'
WHERE
    hood_id = '17';

-- add occurrence_quarter column
ALTER TABLE
    collision_data
ADD
    COLUMN occurrence_quarter INT;

UPDATE
    collision_data
SET
    occurrence_quarter = date_part('quarter', occurrence_date);

SELECT
    occurrence_date,
    occurrence_quarter
FROM
    collision_data
LIMIT
    5;