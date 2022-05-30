-- load MCI data
DROP TABLE IF EXISTS mci_data;

CREATE TABLE mci_data (
    occurrence_unique_id VARCHAR,
    occurrence_date TIMESTAMP,
    premises_type VARCHAR,
    occurrence_year INT,
    occurrence_month VARCHAR,
    occurrence_day INT,
    occurrence_dayofyear INT,
    occurrence_dayofweek VARCHAR,
    occurrence_hour INT,
    MCI VARCHAR,
    hood_id VARCHAR,
    neighbourhood VARCHAR,
    longitude NUMERIC,
    latitude NUMERIC,
    x NUMERIC,
    y NUMERIC
);

COPY mci_data
FROM
    'C:/Users/willi/github/Project - Toronto Police/data/raw/Major_Crime_Indicators.csv' DELIMITER ',' CSV HEADER;

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
    'C:/Users/willi/github/Project - Toronto Police/data/raw/Shootings.csv' DELIMITER ',' CSV HEADER;

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

-- remove hood_ID from neighbourhoods
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
    'C:/Users/willi/github/Project - Toronto Police/data/raw/Homicide.csv' DELIMITER ',' CSV HEADER;

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

-- check that we have similar columns across 3 tables
SELECT
    column_name,
    count(*)
FROM
    information_schema.columns
WHERE
    table_name = 'shootings'
    OR table_name = 'homicide'
    OR table_name = 'mci_data'
GROUP BY
    column_name
ORDER BY
    count(*);

-- concat the 3 tables together
DROP TABLE IF EXISTS mci_df;
CREATE TABLE mci_df AS
SELECT
    occurrence_unique_id,
    occurrence_date,
    occurrence_year,
    occurrence_month,
    occurrence_day,
    occurrence_dayofweek,
    occurrence_hour,
    MCI,
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
    occurrence_dayofweek,
    occurrence_hour,
    MCI,
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
    NULL :: VARCHAR AS occurrence_dayofweek,
    NULL :: INT AS occurrence_hour,
    MCI,
    hood_id,
    neighbourhood,
    longitude,
    latitude
FROM
    homicide;

SELECT
    count(occurrence_unique_id),
    count(occurrence_date),
    count(occurrence_year),
    count(occurrence_month),
    count(occurrence_day),
    count(occurrence_dayofweek),
    count(occurrence_hour),
    count(MCI),
    count(hood_id),
    count(neighbourhood),
    count(longitude),
    count(latitude)
FROM
    mci_df;

SELECT * from mci_df limit 5;