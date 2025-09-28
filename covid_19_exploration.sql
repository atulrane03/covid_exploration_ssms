/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM PortfolioProject..CovidDeaths
where continent is not null
ORDER BY 3,4;


--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4;

-- Select the data that we are going to be using

SELECT continent, location, date,total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
where continent is not null
ORDER BY 1,2 ;


-- Looking at the total cases vs the total deaths
-- shows likelihood of dying if you contract covid in your country
SELECT continent,location, date,total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%India' and continent is not null
ORDER BY 1,2

-- Looking at the Total cases vs Population
-- shows what percentage of population got covid
SELECT location, date,total_cases, population, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location = 'India'
ORDER BY 1,2


-- Looking at countries with highest infection compared to Population

SELECT location, population, Max(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
where continent is not null
--WHERE location = 'India'
Group by  location, population
ORDER BY PercentPopulationInfected desc


-- Showing the Countries with highest Death Count per Population

SELECT location,max(cast(total_deaths as int)) as TotalDeathCounts
FROM PortfolioProject..CovidDeaths
--WHERE location = 'India'
where continent is not null
Group by location
ORDER BY TotalDeathCounts desc


-- Lets Break Things by Continent

-- Showing the Continents with highest Death Count

SELECT continent,max(cast(total_deaths as int)) as TotalDeathCounts
FROM PortfolioProject..CovidDeaths
--WHERE location = 'India'
where continent is not null
Group by continent
ORDER BY TotalDeathCounts desc


-- GLOBAL NUMBERS

SELECT sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths , Sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%India' 
where continent is not null
--group by date
ORDER BY 1,2



-- Looking at Total Population vs Vaccinations
-- Shows percentage of population that has received at least one covid Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location,dea.date) 
as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/ dea.population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- USE CTE to perform calculation on partition By in previous query

With PopvsVac(Continent, Location, Date, Population, New_Vaccinations,RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
Sum(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location order by dea.location,dea.date) 
as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/ dea.population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/ Population) *100
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query



DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 