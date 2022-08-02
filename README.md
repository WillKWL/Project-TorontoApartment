# Framing the business problem
> **Objective: Where should I rent an apartment in the City of Toronto now / in the coming future?**
- Tangible output
  - An interactive map ([Tableau dashboard](https://public.tableau.com/app/profile/willkwl/viz/TTC_stations_area/Overview)) where I can quickly locate the ideal areas to search for rental listings
  - <img src="../master/data/image/2022-08-01-22-04-46.png">
- Assumptions
  - **Ideal location = safe + cheap + nearby** (more details on the 3 factors below)
  - As an international student without a driving license, I would have to rely on TTC to move around the city and that implies I do not live outside the City of Toronto
  - All apartments within a neighbourhood are considered as homogeneous as we view each of the 140 Toronto neighbourhoods as the smallest unit

# 3 factors for tenants to consider include:
1. **Safety**
    - Existing solution:
        - Toronto Police Services [Power BI dashboard](https://app.powerbi.com/view?r=eyJrIjoiNTAwOTNkMTYtOWQwNS00Y2M3LWJkODAtNDU1NjNkZTg1YWVkIiwidCI6Ijg1MjljMjI1LWFjNDMtNDc0Yy04ZmI0LTBmNDA5NWFlOGQ1ZCIsImMiOjN9)
    - Data sources
        - Toronto Police Services - [Public Safety Data Portal](https://data.torontopolice.on.ca/)
        - City of Toronto - [Open Data Portal](https://open.toronto.ca/)
        - All data is licensed under the [Open Government License - Toronto](https://open.toronto.ca/open-data-license/)
2. **Accessibility**
    - Existing Solution:
        - Realtor.CA neighbourhood [overview](https://www.realtor.ca/)
    - We can measure the commute time and / or distance to a destination with the help of 
        - Google map or other location services
    - Limitation: 
        - Requesting commute time between locations requires access to Google's API services
        - Commute time can vary depending on the time of departure and mode of transit,
            - e.g. it may only take 45min to take the train departing at 8:30am but if you miss the train, the shortest route can become 1hr30min on bus
    - Solution: measure **distance** between locations instead (by using longitude and latitude)
3. **Affordability**
    - Existing Solution:
        - Toronto Regional Real Estate Board (TRREB) [search engine](https://onlistings.trreb.ca/searchlistings#search/d17c8105b8d19ca9a20f2d67/filters)
    - Limitation: scraping information from the **search engine** on real estate websites is often *prohibited by the copyright clause* under the terms of use
    > E.g. Realtor.ca's [terms of use](https://www.realtor.ca/terms-of-use) explicitly states that **scraping** and any other activity intended to collect, store, reorganize or manipulate data on the pages produced by, or displayed on the CREA websites are prohibited
    - Solution: scraping information from **public quarterly reports** published by Toronto Regional Real Estate Board (TRREB)
        - Loss in granularity: data is only available per MLS district and per quarter but not per transaction or per listing

# Limitations of existing solutions
**Existing solutions put emphasis on 1 angle only**
- e.g. rental websites focus on price -> you can then filter based on types of apartment and click into the listings to view other information such as transportation and neighbourhood safety
- e.g. police website focuses on safety -> you can then look at the lease rates of the listings in that neighbourhood
- **what if I want to look for the ideal locations based on the 3 factors simultaneously?**

Toronto Regional Real Estate Board (TRREB) [search engine](https://onlistings.trreb.ca/searchlistings#search/d17c8105b8d19ca9a20f2d67/filters)
- <img src='../master/data/image/2022-04-02-17-52-51.png'>
Realtor.CA neighbourhood [overview](https://www.realtor.ca/)
- <img src='../master/data/image/2022-04-02-17-54-06.png'>
Toronto Police Services [Power BI dashboard](https://app.powerbi.com/view?r=eyJrIjoiNTAwOTNkMTYtOWQwNS00Y2M3LWJkODAtNDU1NjNkZTg1YWVkIiwidCI6Ijg1MjljMjI1LWFjNDMtNDc0Yy04ZmI0LTBmNDA5NWFlOGQ1ZCIsImMiOjN9)
- <img src='../master/data/image/2022-04-02-17-54-34.png'>

# How to use this repository
- Folder structure
  - env.yml file to reproduce working environment with required packages
  - source folder
    - jupyter notebooks to run 
- data folder
  - image: screenshot attached in markdown
  - processed: data cleaned and ready for analysis
  - raw: data extracted from various sources
- ETL pipeline (import data from raw folder, export data to processed folder)
  - source/0: crime and traffic collision data from Toronto Police Services API
  - source/1a: location and other information of TTC stations from TTC website
  - source/1b: 140 neighbourhood boundary from Toronto Police Services
  - source/1c: apartment rental information from Toronto Regional Real Estate Board (TRREB)
  - source/1d: crime data 
    - SQL alternative: load_mci.sql
  - source/1e: traffic collision data
    - SQL alternative: load_collision.sql
- Exploratory Data Analysis
  - source/2a: population and distance from UofT for 140 Toronto neighbourhoods defined by Toronto Police Services
  - source/2b: yearly and quarterly trend in apartment lease rates
  - source/2c: time trend and distribution among 140 neighbourhoods in crime rates 
  - source/2d: time trend and distribution among 140 neighbourhoods in traffic collisions
  - source/2e: all layers combined (rent + crime + traffic collision + distance from UofT)
- Statistical analysis (panel data regression and ARMA modelling)
  - source/3a: 
    - panel data regression for rent
    - ARMA modelling for rent, crime, traffic collision
  - source/3b:
    - plot with predicted results for 140 neighbourhoods