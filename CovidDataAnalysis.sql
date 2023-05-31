select *
from ProjectCovidAnalysis..CovidDeaths
where continent is not null;

-- Data Cleaning
update ProjectCovidAnalysis..CovidDeaths
set total_cases=isnull(total_cases,0)

alter table ProjectCovidAnalysis..CovidDeaths
add DateConverted Date;

alter table ProjectCovidAnalysis..CovidVaccination
add DateConverted Date;


update ProjectCovidAnalysis..CovidDeaths
set DateConverted = convert(date,date);

update ProjectCovidAnalysis..CovidVaccination
set DateConverted = convert(date,date);

alter table ProjectCovidAnalysis..CovidDeaths
drop column date;

alter table ProjectCovidAnalysis..CovidVaccination
drop column date;


select location,DateConverted,total_cases,new_cases,total_deaths,population
from ProjectCovidAnalysis..CovidDeaths
where continent is not null
order by 1,2;

--Looking at total cases vs total deaths
-- This data shows the chances of death if you get affected in your country
select location,DateConverted,total_cases,total_deaths,(convert(float,total_deaths)/convert(float,total_cases))*100 as PercentageofDeaths
from ProjectCovidAnalysis..CovidDeaths
where total_cases is not null and total_deaths is not null and location like '%states%' and continent is not null
order by 1,2 desc;

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

select Location, DateConverted, Population, total_cases,  (total_cases/population)*100 as PercentofPopulationInfected
From ProjectCovidAnalysis..CovidDeaths
where total_cases is not null and total_deaths is not null and continent is not null
order by 1,2 desc;

--countries with highest infection rate v population
select location,population,max(convert(float,total_cases)) as TotalCases,Max((convert(float,total_cases)/population * 100)) as PercentofPopulationInfected
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
select cd.continent,cd.location,cd.DateConverted,cd.population,cv.new_vaccinations,sum(convert(float,cv.new_vaccinations)) over(partition by cd.location order by cd.location,cd.date) as OverallPeopleVaccinated
from ProjectCovidAnalysis..CovidDeaths cd
join ProjectCovidAnalysis..CovidVaccination cv
on cd.DateConverted=cv.DateConverted and cd.location=cv.location
where cd.continent is not null -- and cv.new_vaccinations is not null
order by 2,3;

-- Percentage of people vaccinated per population
with pepvacvspop (continent,location,DateConverted,population,new_vaccinations,OverallPeopleVaccinated)
as
(select cd.continent,cd.location,cd.DateConverted,cd.population,cv.new_vaccinations,sum(convert(float,cv.new_vaccinations)) over(partition by cd.location order by cd.location,cd.date) as OverallPeopleVaccinated
from ProjectCovidAnalysis..CovidDeaths cd
join ProjectCovidAnalysis..CovidVaccination cv
on cd.DateConverted=cv.DateConverted and cd.location=cv.location
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
DateConverted datetime,
Population numeric,
New_vaccinations numeric,
OverallPeopleVaccinated numeric
)
insert into #PercentageofPopulationVaccinated
select cd.continent,cd.location,cd.DateConverted,cd.population,cv.new_vaccinations,sum(convert(float,cv.new_vaccinations)) over(partition by cd.location order by cd.location,cd.date) as OverallPeopleVaccinated
from ProjectCovidAnalysis..CovidDeaths cd
join ProjectCovidAnalysis..CovidVaccination cv
on cd.DateConverted=cv.DateConverted and cd.location=cv.location

select *,(OverallPeopleVaccinated/population)*100 as percentpopvaccinated
from #PercentageofPopulationVaccinated

--Creating view for visualizing later
create view PercentageofPopulationVaccinated as
select cd.continent,cd.location,cd.DateConverted,cd.population,cv.new_vaccinations,sum(convert(float,cv.new_vaccinations)) over(partition by cd.location order by cd.location,cd.date) as OverallPeopleVaccinated
from ProjectCovidAnalysis..CovidDeaths cd
join ProjectCovidAnalysis..CovidVaccination cv
on cd.DateConverted=cv.DateConverted and cd.location=cv.location
where cd.continent is not null

-- 2
select location,sum(convert(float,new_deaths)) as TotalDeathCount -- , sum(convert(float,new_deaths))/sum(convert(float,new_cases)) *100 as DeathPercentage
from ProjectCovidAnalysis..CovidDeaths
where continent is null and location not in ('World','High income','Upper middle income','Lower middle income','European Union','Low income')
group by location
order by TotalDeathCount Desc;
 
