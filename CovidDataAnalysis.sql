select * 
from ProjectCovidAnalysis..CovidDeaths
where continent is not null
order by 4;

select location,date,total_cases,new_cases,total_deaths,population
from ProjectCovidAnalysis..CovidDeaths
where continent is not null
order by 1,2;

--Looking at total cases vs total deaths
-- This data shows the chances of death if you get affected in your country
select location,date,total_cases,total_deaths,(convert(float,total_deaths)/convert(float,total_cases))*100 as PercentageofDeaths
from ProjectCovidAnalysis..CovidDeaths
where total_cases is not null and total_deaths is not null and location like '%states%' and continent is not null
order by 1,2 desc;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentofPopulationInfected
From ProjectCovidAnalysis..CovidDeaths
where total_cases is not null and total_deaths is not null and continent is not null
order by 1,2 desc;

--countries with highest infection rate v population
select location,population,max(total_cases) as highestinfectioncases,Max((total_cases/population * 100)) as PercentofPopulationInfected
from ProjectCovidAnalysis..CovidDeaths
where continent is not null
group by location,population
order by population desc,PercentofPopulationInfected desc;


-- showing countries with highest death rate
select location,max(population)as population,max(convert(float,total_deaths)) as td,max(convert(float,total_cases)) as tc,max(convert(float,total_deaths))/max(convert(float,total_cases)) *100 as DeathRate
from ProjectCovidAnalysis..CovidDeaths
where total_cases is not null and total_deaths is not null and continent is not null
group by location
order by 5 desc;


--breaking down things by continents to get a larger scale picture
-- showing continents with the highest death rate 
select continent,max(convert(float,total_deaths)) as td,max(convert(float,total_cases)) as tc,max(convert(float,total_deaths))/max(convert(float,total_cases)) *100 as DeathRate
from ProjectCovidAnalysis..CovidDeaths
where total_cases is not null and total_deaths is not null and continent is not null
group by continent
order by 2 desc;

--Worldwide number
select sum(cast(new_cases as float)) as TotalCases,sum(convert(float,new_deaths)) as TotalDeaths, sum(convert(float,new_deaths))/sum(convert(float,new_cases)) *100 as DeathPercentage
from ProjectCovidAnalysis..CovidDeaths
where continent is not null and new_cases !=0
--group by date
--order by 4 desc;


--Total Population vs Vaccinations
select cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,sum(convert(float,cv.new_vaccinations)) over(partition by cd.location order by cd.location,cd.date) as OverallPeopleVaccinated
from ProjectCovidAnalysis..CovidDeaths cd
join ProjectCovidAnalysis..CovidVaccination cv
on cd.date=cv.date and cd.location=cv.location
where cd.continent is not null -- and cv.new_vaccinations is not null
order by 2,3;

-- Percentage of people vaccinated per population
with pepvacvspop (continent,location,date,population,new_vaccinations,OverallPeopleVaccinated)
as
(select cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,sum(convert(float,cv.new_vaccinations)) over(partition by cd.location order by cd.location,cd.date) as OverallPeopleVaccinated
from ProjectCovidAnalysis..CovidDeaths cd
join ProjectCovidAnalysis..CovidVaccination cv
on cd.date=cv.date and cd.location=cv.location
where cd.continent is not null and cv.new_vaccinations is not null
--order by 2,3;
)
select *, (OverallPeopleVaccinated/population) *100 as PercentofpeopleVaccinatedperPopulation
from pepvacvspop
where location like'%states';

--Temp Table
drop table if exists #PercentageofPopulationVaccinated
create table #PercentageofPopulationVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
OverallPeopleVaccinated numeric
)
insert into #PercentageofPopulationVaccinated
select cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,sum(convert(float,cv.new_vaccinations)) over(partition by cd.location order by cd.location,cd.date) as OverallPeopleVaccinated
from ProjectCovidAnalysis..CovidDeaths cd
join ProjectCovidAnalysis..CovidVaccination cv
on cd.date=cv.date and cd.location=cv.location

select *,(OverallPeopleVaccinated/population)*100 as percentpopvaccinated
from #PercentageofPopulationVaccinated

--Creating view for visualizing later
create view PercentageofPopulationVaccinated as
select cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,sum(convert(float,cv.new_vaccinations)) over(partition by cd.location order by cd.location,cd.date) as OverallPeopleVaccinated
from ProjectCovidAnalysis..CovidDeaths cd
join ProjectCovidAnalysis..CovidVaccination cv
on cd.date=cv.date and cd.location=cv.location
where cd.continent is not null
