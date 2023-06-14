-- Phecode Mapping
-- Requires important phecode map from https://phewascatalog.org/phecodes

select
	o.PATIENT_NUM,
	o.ENCOUNTER_NUM,
	o.CONCEPT_CD,
	o.START_DATE,
	p.phecode
into S19.dbo.ICD_Phecode_OBS_FACT
from FellowsSample.S19.OBSERVATION_FACT o
left join S19.dbo.phecode_map p on o.CONCEPT_CD = p.CONCEPT_CD
where o.CONCEPT_CD LIKE 'ICD%';

select top 100 * from S19.dbo.ICD_Phecode_OBS_FACT;
select count(*) from S19.dbo.ICD_Phecode_OBS_FACT; -- 153026231
select count(distinct PATIENT_NUM) from S19.dbo.ICD_Phecode_OBS_FACT; -- 3384497

with temp as (
select distinct
	PATIENT_NUM,
	ENCOUNTER_NUM,
	START_DATE,
	phecode
from S19.dbo.ICD_Phecode_OBS_FACT
)
select count(*) from temp; --139296835

with temp as (
select distinct
	PATIENT_NUM,
	ENCOUNTER_NUM,
	START_DATE,
	phecode
from S19.dbo.ICD_Phecode_OBS_FACT
)
select count(distinct PATIENT_NUM) from temp; --3384497


