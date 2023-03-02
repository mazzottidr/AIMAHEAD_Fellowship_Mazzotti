-- Determine latest visit to the health system and create table S19.dbo.LastEncounter
with temp_VISIT as (
	select
		PATIENT_NUM,
		max(START_DATE) as last_encounter_date
		from FellowsSample.S19.VISIT_DIMENSION
	group by PATIENT_NUM
)
select 
	visit.PATIENT_NUM,
	visit.ENCOUNTER_NUM,
	t.last_encounter_date
into S19.dbo.LastEncounter
from FellowsSample.S19.VISIT_DIMENSION visit
INNER JOIN temp_VISIT t ON t.PATIENT_NUM = visit.PATIENT_NUM AND t.last_encounter_date = visit.START_DATE;

select count(ENCOUNTER_NUM) from S19.dbo.LastEncounter; --3467344
select count(distinct ENCOUNTER_NUM) from S19.dbo.LastEncounter; --3467344 (ensure these are unique encounters)
