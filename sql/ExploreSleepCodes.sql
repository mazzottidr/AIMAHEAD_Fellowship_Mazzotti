
-- Identify types of encounters and other characteristics of encounters where there were sleep disorders codes

-- OSA (Keenan et al). Observations: 294,535; unique encounters: 247,525; unique patients: 111,577
select count(*)
--select count(distinct ENCOUNTER_NUM)
--select count(distinct PATIENT_NUM)
from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD IN ('ICD9CM:327.20', 'ICD9CM:327.23', 'ICD9CM:327.29', 'ICD9CM:780.51', 'ICD9CM:780.53', 'ICD9CM:780.57', 'ICD10CM:G47.30', 'ICD10CM:G47.33', 'ICD10CM:G47.39');


-- Create patient level tables with first and last encounter with OSA code, number of codes, dates and encounter.
-- The table below shows how many types of diagnosis exist in TVAL_CHAR among the observations where OSA was recorded
with temp as (
select
	PATIENT_NUM,
	ENCOUNTER_NUM,
	START_DATE,
	TVAL_CHAR,
	CONCEPT_CD,
	HEALTH_SYSTEM_ID
from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD IN ('ICD9CM:327.20', 'ICD9CM:327.23', 'ICD9CM:327.29', 'ICD9CM:780.51', 'ICD9CM:780.53', 'ICD9CM:780.57', 'ICD10CM:G47.30', 'ICD10CM:G47.33', 'ICD10CM:G47.39')
--order by PATIENT_NUM, ENCOUNTER_NUM
)
select TVAL_CHAR, count(TVAL_CHAR) from temp
group by TVAL_CHAR;

----------
-- Most observations are Encounter Diagnosis, with some being Medical History or Problem List
----------

-- Create patient level tables for ANY OSA
with temp as (
  select
    PATIENT_NUM,
	min(START_DATE) as earliest_OSA_date,
    max(START_DATE) as latest_OSA_date,
	count(PATIENT_NUM) as N_OSA_codes_anydate
  from FellowsSample.S19.OBSERVATION_FACT
  where CONCEPT_CD IN ('ICD9CM:327.20','ICD9CM:327.23', 'ICD9CM:327.29', 'ICD9CM:780.51', 'ICD9CM:780.53', 'ICD9CM:780.57', 'ICD10CM:G47.30', 'ICD10CM:G47.33', 'ICD10CM:G47.39')
  GROUP BY PATIENT_NUM
),
clean_ObsFact as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE,
		CONCEPT_CD,
		TVAL_CHAR
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD9CM:327.20','ICD9CM:327.23', 'ICD9CM:327.29', 'ICD9CM:780.51', 'ICD9CM:780.53', 'ICD9CM:780.57', 'ICD10CM:G47.30', 'ICD10CM:G47.33', 'ICD10CM:G47.39')
)
select
	distinct 
  --count(distinct t.PATIENT_NUM)
  	clean_ObsFact.PATIENT_NUM as PATIENT_NUM,
	clean_ObsFact.ENCOUNTER_NUM as earliest_OSA_encounter_num,
	t.earliest_OSA_date as earliest_OSA_date,
	clean_ObsFact.CONCEPT_CD as earliest_OSA_code,
	t.latest_OSA_date as latest_OSA_date,
	t.N_OSA_codes_anydate,
	case
		when t.earliest_OSA_date = t.latest_OSA_date THEN 0
		ELSE 1
	end as OSA_ComputablePhenotype -- OSA_ComputablePhenotype is defined as positive when is more than one OSA code in different dates.
into S19.dbo.OSA_all_types
from clean_ObsFact
INNER JOIN temp t on t.PATIENT_NUM = clean_ObsFact.PATIENT_NUM AND t.earliest_OSA_date = clean_ObsFact.START_DATE;





-- Create patient level tables for OSA based on Encounter Diagnosis only (N=74,702)
with temp as (
  select
    PATIENT_NUM,
	min(START_DATE) as earliest_OSA_date,
    max(START_DATE) as latest_OSA_date,
	count(PATIENT_NUM) as N_OSA_codes_anydate
  from FellowsSample.S19.OBSERVATION_FACT
  where TVAL_CHAR = 'Encounter Diagnosis' and CONCEPT_CD IN ('ICD9CM:327.20','ICD9CM:327.23', 'ICD9CM:327.29', 'ICD9CM:780.51', 'ICD9CM:780.53', 'ICD9CM:780.57', 'ICD10CM:G47.30', 'ICD10CM:G47.33', 'ICD10CM:G47.39')
  GROUP BY PATIENT_NUM
),
clean_ObsFact as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE,
		CONCEPT_CD,
		TVAL_CHAR
	from FellowsSample.S19.OBSERVATION_FACT
	where TVAL_CHAR = 'Encounter Diagnosis' and CONCEPT_CD IN ('ICD9CM:327.20','ICD9CM:327.23', 'ICD9CM:327.29', 'ICD9CM:780.51', 'ICD9CM:780.53', 'ICD9CM:780.57', 'ICD10CM:G47.30', 'ICD10CM:G47.33', 'ICD10CM:G47.39')
)
select
	distinct 
  --count(distinct t.PATIENT_NUM)
  	clean_ObsFact.PATIENT_NUM as PATIENT_NUM,
	--clean_ObsFact.ENCOUNTER_NUM as earliest_OSA_encounter_num,
	t.earliest_OSA_date as earliest_OSA_date,
	clean_ObsFact.CONCEPT_CD as earliest_OSA_code,
	t.latest_OSA_date as latest_OSA_date,
	t.N_OSA_codes_anydate,
	case
		when t.earliest_OSA_date = t.latest_OSA_date THEN 0
		ELSE 1
	end as OSA_ComputablePhenotype -- OSA_ComputablePhenotype is defined as positive when is more than one OSA code in different dates.
into S19.dbo.OSA_only_ED
from clean_ObsFact
INNER JOIN temp t on t.PATIENT_NUM = clean_ObsFact.PATIENT_NUM AND t.earliest_OSA_date = clean_ObsFact.START_DATE;

-- So far, create OSA minitables, both for all types and for ED only
-- Next time do the same for other phenotypes (e.g., Insomnia, MACE)