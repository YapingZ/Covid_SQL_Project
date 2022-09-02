-- Covid dataset exploring by Yaping 2022/8/30

-- 1. Looking at the data
SELECT *
FROM Covid..CovidDeath
-- WHERE continent = 'Asia'
-- WHERE location = 'world' or location =  'africa'
-- WHERE continent is NUll
WHERE new_cases = 0
ORDER BY 3,4


-- 2.Select the important columns
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid.dbo.CovidDeath
ORDER BY 1,2

-- 3.Caculate the death rate: total_deaths vs total_cases
SELECT location, date, total_cases, new_cases, total_deaths
, (total_deaths/ CAST(total_cases as float))*100 as deathe_rate
FROM Covid.dbo.CovidDeath
WHERE location like '%China%'
ORDER BY 1,2

-- 4.Showing the likelihood of get covid
SELECT location, date, total_cases, new_cases, total_deaths, 
(total_cases/ CAST(population as float))*100 as infection_rate
FROM Covid.dbo.CovidDeath
WHERE continent is not null
-- WHERE location like '%Austra%' or location like '%state%'
ORDER BY 1,2

-- 5.Looking at the country with the highest infection count, and highest infection rate
SELECT location, population, MAX(total_cases) AS HighestInfectionCount,
MAX(total_cases/CAST(population as float))*100 AS HighestInfectionRate
FROM Covid..CovidDeath
WHERE continent is not null
GROUP BY location, population
ORDER BY HighestInfectionRate DESC

-- 6.Looking at the country with the highest death count, and highest death rate
SELECT location, population,  MAX(total_deaths) AS HighestDeathCount,
MAX(total_deaths/CAST(total_cases as float))*100 AS HighestDeathRate
FROM Covid..CovidDeath
WHERE continent is not null
GROUP BY location, population
ORDER BY HighestDeathRate DESC

-- 7.Find North korea's highestdeathrate is wrong, check it out:
Select date, location, population, total_deaths, total_cases
From Covid..CovidDeath
Where location = 'North Korea'
-- Result: some numbers go wrong.

-- 8.Using population to caculate the death rate
SELECT location, population, MAX(total_deaths) as HighestDeath,
MAX(total_deaths/CAST(population as float))*100 as HighestDeathRate
FROM Covid..CovidDeath
WHERE continent is not NUll
GROUP BY location, population
ORDER BY HighestDeathRate DESC

-- 9.From the view of continent, check the highest deaths
SELECT continent, MAX(total_deaths) AS HighestDeathCount,
MAX(total_deaths/CAST(population as float))*100 AS HighestDeathRate
FROM Covid..CovidDeath
WHERE continent is not null
GROUP BY continent
ORDER BY HighestDeathCount DESC

-- SELECT the locations when the cotinet is null
SELECT location, MAX(total_deaths) AS HighestDeathCount,
MAX(total_deaths/CAST(population as float))*100 AS HighestDeathRate
FROM Covid..CovidDeath
WHERE continent is  null
GROUP BY location
ORDER BY HighestDeathCount DESC

-- Looking at globle stastic numbers
SELECT  date, SUM(new_cases) AS TotalCases,
SUM(new_deaths) AS TotalDeaths,
SUM(new_deaths)/NULLIF(SUM(CAST(new_cases as float)), 0)*100 AS TotalDeathRate
FROM Covid..CovidDeath
WHERE continent is not null
GROUP BY date
ORDER BY date

-- Have a more generl overview of the total cases and total deaths
SELECT  SUM(new_cases) AS TotalCases,
SUM(new_deaths) AS TotalDeaths,
SUM(new_deaths)/NULLIF(SUM(CAST(new_cases as float)), 0)*100 AS TotalDeathRate
FROM Covid..CovidDeath
--check and find this is not the real number, then add this condition, everything is good now.
WHERE continent is not null


-- Overview the vaccination data
SELECT *
FROM Covid..CovidVaccinations

-- Looking at the vaccination vs population
-- We will join the two table which cotains vaccination and population on each of them 
SELECT vac.continent, vac.location, vac.date, dea.population, vac.new_vaccinations
FROM Covid..CovidVaccinations  vac
JOIN Covid..CovidDeath dea
ON vac.location = dea.location
AND vac.date = dea.date
WHERE vac.continent is not NULL
ORDER BY 2,3

-- Looking at the total vaccinations and total cases and total deaths in each country
SELECT  dea.location,
SUM(vac.new_vaccinations) AS TotalVaccinations
, SUM(dea.new_cases) AS TotalCases
, SUM(dea.new_deaths) AS TotalDeaths
FROM Covid..CovidDeath  dea
JOIN Covid..CovidVaccinations  vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not NULL
GROUP BY dea.location
ORDER BY dea.location

-- Caculate the rolling up of new_vaccinations every day
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by vac.location ORDER BY dea.location, dea.date) AS RollingVaccinations
-- , RollingVaccination/dea.population
FROM Covid..CovidDeath  dea
JOIN Covid..CovidVaccinations  vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not NULL

ORDER BY dea.location, dea.date

-- Using CTE(common table expression)
WITH Vacvspop (Continent, Location, Date, Population, New_vaccination, RollingVaccinations)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM Covid..CovidDeath dea
JOIN Covid..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not NUll
-- ORDER BY 2,3
)

SELECT *, (RollingVaccinations/CONVERT(float, Population))*100
FROM Vacvspop

-- Using Temp table
Drop table if exists #VaccinationVSPopulation
Create TABLE #VaccinationVSPopulation
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccination NUMERIC,
    RollingVaccinations NUMERIC

)

INSERT Into #VaccinationVSPopulation
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM Covid..CovidDeath dea
JOIN Covid..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not NUll

SELECT *, (RollingVaccinations/Population)*100 AS VaccinationRate
FROM #VaccinationVSPopulation
ORDER BY location, date


-- Creat view for later visualization
CREATE VIEW VaccinationVSPopulation AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS RollingVaccinations
FROM Covid..CovidDeath dea
JOIN Covid..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent is not NUll

SELECT *
From VaccinationVSPopulation
