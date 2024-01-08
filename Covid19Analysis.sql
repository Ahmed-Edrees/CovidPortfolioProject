---- Analyzing Covid19 data and some insights form it

--- listing data we will use next
select location, date,population, total_cases, total_deaths
from CovidPortfolioProject..CovidDeaths
order by 2,1

--- showing total cases and total deaths and the likelihood of getting infected and the liklihood to die
--- if you got infected in each country per day
select location, date,
		total_cases,
		round((total_cases/population)*100,3) AS InfectedPercentage,
		total_deaths,
		round((total_deaths/total_cases)*100,3) As DeathPercentage
from CovidPortfolioProject..CovidDeaths
where continent is not null

--- looking at the countries who have the highest infections and infections rate compared to the population
select location ,population,
		MAX(total_cases) as HighestInfectedCount,
		ROUND((MAX(total_cases)/population)*100,3) AS HighestInfectedPopulationRate
		--- If we want to use calculated HighestInfectedCount instead of (MAX(total_cases))
		--- This can be happened using CTE table, which will be used in an upcoming query
from CovidPortfolioProject..CovidDeaths
where continent is not null
group by location,population
order by HighestInfectedCount desc

--- looking at the countries who have the highest Deaths and deaths rate compared to the population
select  location ,population,
		MAX(total_deaths) as HighestDeathCount,
		ROUND((MAX(total_deaths)/population)*100,3) AS HighestDeathPopulationRate
from CovidPortfolioProject..CovidDeaths
where continent is not null
group by location,population
order by HighestDeathCount desc

--- let's break it down by continet
--- select the total Infected and total Death counted by each continent
select continent , sum(new_cases) as TotalInfectionCoun,sum(new_deaths) as TotalDeathsCount
from CovidPortfolioProject..CovidDeaths 
where continent is not null
group by continent
order by TotalDeathsCount desc

----listing the global numbers for each day total cases and deathes with daily death rate
select date, Sum(new_cases) AS TotalCases,
			 sum(new_deaths) AS TotalDeaths,
			 CASE
				WHEN Sum(new_cases) != 0 then Round((sum(new_deaths)/Sum(new_cases))*100,3)
				-- if we want to use TotalCases for new calculations we rather use CTE table to do it
				-- which is used in the next query implementing the same query
				ELSE null
			END	AS DailyDeathRate
From CovidPortfolioProject..CovidDeaths
where continent is not null
group by date
order by date

---- using the CTE table to implement the previous query
With InfectionsAndDeathes (Date, TotalInfections,TotalDeaths)
AS (
select date, Sum(new_cases) ,
			 sum(new_deaths)
From CovidPortfolioProject..CovidDeaths
where continent is not null
group by date
)
SELECT * , 	CASE
				WHEN TotalInfections != 0 then Round(TotalDeaths/TotalInfections*100,3)
				ELSE null
			END	AS DailyDeathRate
FROM InfectionsAndDeathes
ORDER BY Date

--- looking for total population vs total vaccinations using CTE table
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

)
Select *, (RollingPeopleVaccinated/Population)*100 PeopleVaccinatedRate
From PopvsVac


--- implementing the same example using temp tables
DROP Table if exists #PercentPopulationVaccinated ---we add this line because the temp table is created only once
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
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, Round((RollingPeopleVaccinated/Population)*100,3) AS PeopleVaccinatedRate
From #PercentPopulationVaccinated


--- Creating a view to a required table in  
CREATE VIEW PercentPopulationVaccinated AS
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

-- selecting all data from the view
select * from PercentPopulationVaccinated
