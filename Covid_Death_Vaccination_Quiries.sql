-- Select statement to retrieve detailed COVID-19 case and population data for analysis, ordered by location and date.
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM PortfolioProject.covid_deaths
ORDER BY location, date;

-- Calculate the percentage of deaths among confirmed cases to assess the likelihood of dying from COVID-19 in various locations containing "states" in their names.
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage 
FROM PortfolioProject.covid_deaths
WHERE location like '%states%'
ORDER BY location, date;

-- Calculate the percentage of the population that contracted COVID-19, focusing on locations with "states" in their names.
SELECT Location, date, total_cases, total_deaths, population, (total_cases/population)*100 as population_contraction_percentage
FROM PortfolioProject.covid_deaths
WHERE location like '%states%'
ORDER BY location, date;

-- Identify countries with the highest infection rate relative to their population.
SELECT location, population, MAX(total_cases) as max_total_infections, MAX((total_cases/population))*100 as population_contraction_percentage
FROM PortfolioProject.covid_deaths
GROUP BY location, population
ORDER BY population_contraction_percentage DESC;

-- Identify countries with the highest total deaths relative to their population, filtering out entries without a continent.
SELECT location, MAX(total_deaths) as max_total_deaths, population, MAX((total_deaths/population))*100 as population_death_percentage
FROM PortfolioProject.covid_deaths
WHERE continent != ''
GROUP BY location, population 
ORDER BY max_total_deaths DESC;

-- Calculate global and continent-specific statistics, focusing on total deaths and death percentages across the population, excluding continents.
SELECT location, MAX(total_deaths) as max_total_deaths, MAX((total_deaths/population))*100 as population_death_percentage
FROM PortfolioProject.covid_deaths
WHERE continent = ''
GROUP BY location 
ORDER BY max_total_deaths DESC;

-- Aggregate continent statistics to determine the maximum total deaths and death percentages across populations.
SELECT continent, MAX(total_deaths) as max_total_deaths, MAX((total_deaths/population))*100 as population_death_percentage
FROM PortfolioProject.covid_deaths
WHERE continent != ''
GROUP BY continent 
ORDER BY max_total_deaths DESC;

-- Calculate daily global statistics for new cases and deaths, deriving the percentage of deaths relative to new cases per day.
SELECT 
	date
	,SUM(new_cases) AS total_new_cases_per_day
	,SUM(new_deaths) AS total_deaths_per_day
	,SUM(new_deaths)/SUM(new_cases)*100 AS daily_death_percentage
FROM PortfolioProject.covid_deaths
WHERE continent != ''
GROUP BY date 
ORDER BY total_deaths_per_day desc;

-- Calculate global totals for new cases and deaths, including the daily death percentage, without grouping by date.
SELECT 
	SUM(new_cases) AS total_new_cases_per_day
	,SUM(new_deaths) AS total_deaths_per_day
	,SUM(new_deaths)/SUM(new_cases)*100 AS daily_death_percentage
FROM PortfolioProject.covid_deaths
WHERE continent != '' 
ORDER BY total_deaths_per_day desc;

-- Analyze the percentage of population vaccinated using a CTE to calculate cumulative vaccinations for each location.
WITH PopulationVsVaccination (
	continent
	,location
	,date
	,population
	,new_vaccinations
	,cumulative_vaccinations
) 
AS
(
SELECT
    cd.continent
    ,cd.location
    ,cd.`date`
    ,cd.population
    ,cv.new_vaccinations
    ,SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS cumulative_vaccinations
FROM PortfolioProject.covid_deaths cd
JOIN PortfolioProject.covid_vaccinations cv
    ON cd.location = cv.location 
    AND cd.`date` = cv.`date`
WHERE cd.continent != ''
)
SELECT 
	*
	,(cumulative_vaccinations/population)*100 AS percent_vaccinated
FROM PopulationVsVaccination;

-- Create and populate a temporary table to store the percentage of the population vaccinated data, including cumulative vaccinations.
DROP TEMPORARY TABLE IF EXISTS percent_population_vaccinated;
CREATE TEMPORARY TABLE percent_population_vaccinated (
	continent VARCHAR(255)
	,location VARCHAR(255)
	,`date` DATETIME
	,population NUMERIC
	,new_vaccinations VARCHAR(255)
	,cumulative_vaccinations NUMERIC
);

-- Insert data into the temporary table, calculating cumulative vaccinations for each location.
INSERT INTO percent_population_vaccinated (
	continent
	,location
	,`date`
	,population
	,new_vaccinations
	,cumulative_vaccinations
)
SELECT
    cd.continent
    ,cd.location
    ,cd.`date`
    ,cd.population
    ,cv.new_vaccinations
    ,SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.`date`) AS cumulative_vaccinations
FROM PortfolioProject.covid_deaths cd
JOIN PortfolioProject.covid_vaccinations cv
    ON cd.location = cv.location 
    AND cd.`date` = cv.`date`
WHERE cd.continent != '';

-- Query the temporary table to calculate the percentage of the population that has been vaccinated.
SELECT 
	*
	,(cumulative_vaccinations/population)*100 AS percent_vaccinated
FROM percent_population_vaccinated;

-- Create a view to store the percentage of population vaccinated data for later visualization.
CREATE VIEW percent_population_vaccinated AS
SELECT
    cd.continent
    ,cd.location
    ,cd.`date`
    ,cd.population
    ,cv.new_vaccinations
    ,SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS cumulative_vaccinations
FROM PortfolioProject.covid_deaths cd
JOIN PortfolioProject.covid_vaccinations cv
    ON cd.location = cv.location 
    AND cd.`date` = cv.`date`
WHERE cd.continent != ''
ORDER BY cd.location, cd.`date`;
