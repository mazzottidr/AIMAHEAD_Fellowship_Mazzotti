-- Identify types of encounters and other characteristics of encounters where there were sleep disorders codes


--- See computable phenotype definitions here: https://raw.githubusercontent.com/RWD2E/phecdm/main/res/valueset_curated/vs-osa-comorb.json


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

-- EncounterSpan
-- Earliest encounter + N_encounters
with temp as (
  select
    PATIENT_NUM,
	min(START_DATE) as earliest_encounter_date,
    --max(START_DATE) as latest_encounter_date,
	count(PATIENT_NUM) as N_encounters
	--DATEDIFF(day, min(START_DATE), max(START_DATE)) as time_span_days
  from FellowsSample.S19.VISIT_DIMENSION
  GROUP BY PATIENT_NUM
),
clean_VisitDimension as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE
	from FellowsSample.S19.VISIT_DIMENSION
)
select 
	distinct
	--top 100
	--count(distinct t.PATIENT_NUM) -- 3396945
  	clean_VisitDimension.PATIENT_NUM as PATIENT_NUM,
	clean_VisitDimension.ENCOUNTER_NUM as earliest_encounter_num,
	t.earliest_encounter_date as earliest_encounter_date,
	--t.latest_encounter_date as latest_encounter_date,
	t.N_encounters
	--t.time_span_days
into S19.dbo.Earliest_Encounter
from clean_VisitDimension
INNER JOIN temp t on t.PATIENT_NUM = clean_VisitDimension.PATIENT_NUM AND t.earliest_encounter_date = clean_VisitDimension.START_DATE
order by PATIENT_NUM;

-- Latest encounter + time_span_days
with temp as (
  select
    PATIENT_NUM,
	--min(START_DATE) as earliest_encounter_date,
    max(START_DATE) as latest_encounter_date,
	count(PATIENT_NUM) as N_encounters,
	DATEDIFF(day, min(START_DATE), max(START_DATE)) as time_span_days
  from FellowsSample.S19.VISIT_DIMENSION
  GROUP BY PATIENT_NUM
),
clean_VisitDimension as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE
	from FellowsSample.S19.VISIT_DIMENSION
)
select 
	distinct
	--top 100
	--count(distinct t.PATIENT_NUM) -- 3396945
  	clean_VisitDimension.PATIENT_NUM as PATIENT_NUM,
	clean_VisitDimension.ENCOUNTER_NUM as latest_encounter_num,
	--t.earliest_encounter_date as earliest_encounter_date,
	t.latest_encounter_date as latest_encounter_date,
	--t.N_encounters
	t.time_span_days
into S19.dbo.Latest_Encounter
from clean_VisitDimension
INNER JOIN temp t on t.PATIENT_NUM = clean_VisitDimension.PATIENT_NUM AND t.latest_encounter_date = clean_VisitDimension.START_DATE
order by PATIENT_NUM;

-- Combine both

select top 100 * from S19.dbo.Earliest_Encounter;
select count(distinct PATIENT_NUM) from S19.dbo.Earliest_Encounter;
select top 100 * from S19.dbo.Latest_Encounter;
select count(distinct PATIENT_NUM) from S19.dbo.Latest_Encounter;

select 
	e.PATIENT_NUM,
	e.earliest_encounter_num,
	e.earliest_encounter_date,
	l.latest_encounter_num,
	l.latest_encounter_date,
	e.N_encounters,
	l.time_span_days
into S19.dbo.EncounterSpan
from S19.dbo.Earliest_Encounter e
left join S19.dbo.Latest_Encounter l on e.PATIENT_NUM = l.PATIENT_NUM
order by PATIENT_NUM;

select top 100 * from S19.dbo.EncounterSpan;
select count(distinct PATIENT_NUM) from S19.dbo.EncounterSpan;

-- CAD
select distinct earliest_CAD_code from S19.dbo.CAD_CompPheno
order by earliest_CAD_code;

with temp_aggregated as ( 	

	select
		PATIENT_NUM,
		min(START_DATE) as earliest_CAD_date,
		max(START_DATE) as latest_CAD_date,
		count(distinct START_DATE) as N_CAD_codes_diffdates
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:I25',
							'ICD10CM:I25.1',
							'ICD10CM:I25.10',
							'ICD10CM:I25.11',
							'ICD10CM:I25.110',
							'ICD10CM:I25.111',
							'ICD10CM:I25.118',
							'ICD10CM:I25.119',
							'ICD10CM:I25.2',
							'ICD10CM:I25.3',
							'ICD10CM:I25.41',
							'ICD10CM:I25.42',
							'ICD10CM:I25.5',
							'ICD10CM:I25.6',
							'ICD10CM:I25.70',
							'ICD10CM:I25.700',
							'ICD10CM:I25.701',
							'ICD10CM:I25.708',
							'ICD10CM:I25.709',
							'ICD10CM:I25.71',
							'ICD10CM:I25.710',
							'ICD10CM:I25.711',
							'ICD10CM:I25.718',
							'ICD10CM:I25.719',
							'ICD10CM:I25.72',
							'ICD10CM:I25.720',
							'ICD10CM:I25.721',
							'ICD10CM:I25.728',
							'ICD10CM:I25.729',
							'ICD10CM:I25.730',
							'ICD10CM:I25.731',
							'ICD10CM:I25.738',
							'ICD10CM:I25.739',
							'ICD10CM:I25.758',
							'ICD10CM:I25.759',
							'ICD10CM:I25.760',
							'ICD10CM:I25.761',
							'ICD10CM:I25.768',
							'ICD10CM:I25.769',
							'ICD10CM:I25.79',
							'ICD10CM:I25.790',
							'ICD10CM:I25.791',
							'ICD10CM:I25.798',
							'ICD10CM:I25.799',
							'ICD10CM:I25.8',
							'ICD10CM:I25.81',
							'ICD10CM:I25.810',
							'ICD10CM:I25.811',
							'ICD10CM:I25.812',
							'ICD10CM:I25.82',
							'ICD10CM:I25.83',
							'ICD10CM:I25.84',
							'ICD10CM:I25.89',
							'ICD10CM:I25.9',
							'ICD9CM:411.0',
							'ICD9CM:411.1',
							'ICD9CM:411.89',
							'ICD9CM:414',
							'ICD9CM:414.0',
							'ICD9CM:414.00',
							'ICD9CM:414.01',
							'ICD9CM:414.02',
							'ICD9CM:414.03',
							'ICD9CM:414.04',
							'ICD9CM:414.05',
							'ICD9CM:414.06',
							'ICD9CM:414.07',
							'ICD9CM:414.1',
							'ICD9CM:414.10',
							'ICD9CM:414.11',
							'ICD9CM:414.12',
							'ICD9CM:414.19',
							'ICD9CM:414.2',
							'ICD9CM:414.3',
							'ICD9CM:414.4',
							'ICD9CM:414.8',
							'ICD9CM:414.9')
  GROUP BY PATIENT_NUM
),
clean_ObsFact as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE,
		CONCEPT_CD,
		TVAL_CHAR,
		ROW_NUMBER() over(PARTITION BY PATIENT_NUM ORDER BY START_DATE) as rn
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:I25',
							'ICD10CM:I25.1',
							'ICD10CM:I25.10',
							'ICD10CM:I25.11',
							'ICD10CM:I25.110',
							'ICD10CM:I25.111',
							'ICD10CM:I25.118',
							'ICD10CM:I25.119',
							'ICD10CM:I25.2',
							'ICD10CM:I25.3',
							'ICD10CM:I25.41',
							'ICD10CM:I25.42',
							'ICD10CM:I25.5',
							'ICD10CM:I25.6',
							'ICD10CM:I25.70',
							'ICD10CM:I25.700',
							'ICD10CM:I25.701',
							'ICD10CM:I25.708',
							'ICD10CM:I25.709',
							'ICD10CM:I25.71',
							'ICD10CM:I25.710',
							'ICD10CM:I25.711',
							'ICD10CM:I25.718',
							'ICD10CM:I25.719',
							'ICD10CM:I25.72',
							'ICD10CM:I25.720',
							'ICD10CM:I25.721',
							'ICD10CM:I25.728',
							'ICD10CM:I25.729',
							'ICD10CM:I25.730',
							'ICD10CM:I25.731',
							'ICD10CM:I25.738',
							'ICD10CM:I25.739',
							'ICD10CM:I25.758',
							'ICD10CM:I25.759',
							'ICD10CM:I25.760',
							'ICD10CM:I25.761',
							'ICD10CM:I25.768',
							'ICD10CM:I25.769',
							'ICD10CM:I25.79',
							'ICD10CM:I25.790',
							'ICD10CM:I25.791',
							'ICD10CM:I25.798',
							'ICD10CM:I25.799',
							'ICD10CM:I25.8',
							'ICD10CM:I25.81',
							'ICD10CM:I25.810',
							'ICD10CM:I25.811',
							'ICD10CM:I25.812',
							'ICD10CM:I25.82',
							'ICD10CM:I25.83',
							'ICD10CM:I25.84',
							'ICD10CM:I25.89',
							'ICD10CM:I25.9',
							'ICD9CM:411.0',
							'ICD9CM:411.1',
							'ICD9CM:411.89',
							'ICD9CM:414',
							'ICD9CM:414.0',
							'ICD9CM:414.00',
							'ICD9CM:414.01',
							'ICD9CM:414.02',
							'ICD9CM:414.03',
							'ICD9CM:414.04',
							'ICD9CM:414.05',
							'ICD9CM:414.06',
							'ICD9CM:414.07',
							'ICD9CM:414.1',
							'ICD9CM:414.10',
							'ICD9CM:414.11',
							'ICD9CM:414.12',
							'ICD9CM:414.19',
							'ICD9CM:414.2',
							'ICD9CM:414.3',
							'ICD9CM:414.4',
							'ICD9CM:414.8',
							'ICD9CM:414.9')
)
select
	distinct 
  --count(distinct t.PATIENT_NUM)
  	clean_ObsFact.PATIENT_NUM as PATIENT_NUM,
	clean_ObsFact.ENCOUNTER_NUM as earliest_CAD_encounter_num,
	t.earliest_CAD_date as earliest_CAD_date,
	t.latest_CAD_date as latest_CAD_date,
	t.N_CAD_codes_diffdates,
	clean_ObsFact.CONCEPT_CD as earliest_CAD_code,
	clean_ObsFact.TVAL_CHAR as earliest_CAD_TVAL_CHAR,
	1 as CAD_ComputablePhenotype
into S19.dbo.CAD_CompPheno
from clean_ObsFact
INNER JOIN temp_aggregated t on t.PATIENT_NUM = clean_ObsFact.PATIENT_NUM AND t.earliest_CAD_date = clean_ObsFact.START_DATE
WHERE rn = 1
ORDER BY PATIENT_NUM, earliest_CAD_date;

select top 100 * from S19.dbo.CAD_CompPheno;
select count(PATIENT_NUM) from S19.dbo.CAD_CompPheno;
select count(distinct PATIENT_NUM) from S19.dbo.CAD_CompPheno;

-- CerebroVD
select distinct earliest_CerebroVD_code from S19.dbo.CerebroVD_CompPheno
order by earliest_CerebroVD_code;

with temp_aggregated as ( 	

	select
		PATIENT_NUM,
		min(START_DATE) as earliest_CerebroVD_date,
		max(START_DATE) as latest_CerebroVD_date,
		count(distinct START_DATE) as N_CerebroVD_codes_diffdates
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:I60',
							'ICD10CM:I60.00',
							'ICD10CM:I60.01',
							'ICD10CM:I60.10',
							'ICD10CM:I60.11',
							'ICD10CM:I60.12',
							'ICD10CM:I60.2',
							'ICD10CM:I60.22',
							'ICD10CM:I60.3',
							'ICD10CM:I60.30',
							'ICD10CM:I60.31',
							'ICD10CM:I60.32',
							'ICD10CM:I60.4',
							'ICD10CM:I60.51',
							'ICD10CM:I60.6',
							'ICD10CM:I60.7',
							'ICD10CM:I60.8',
							'ICD10CM:I60.9',
							'ICD10CM:I61',
							'ICD10CM:I61.0',
							'ICD10CM:I61.1',
							'ICD10CM:I61.2',
							'ICD10CM:I61.3',
							'ICD10CM:I61.4',
							'ICD10CM:I61.5',
							'ICD10CM:I61.6',
							'ICD10CM:I61.8',
							'ICD10CM:I61.9',
							'ICD10CM:I62',
							'ICD10CM:I62.0',
							'ICD10CM:I62.00',
							'ICD10CM:I62.01',
							'ICD10CM:I62.02',
							'ICD10CM:I62.03',
							'ICD10CM:I62.1',
							'ICD10CM:I62.9',
							'ICD10CM:I63',
							'ICD10CM:I63.00',
							'ICD10CM:I63.011',
							'ICD10CM:I63.012',
							'ICD10CM:I63.013',
							'ICD10CM:I63.019',
							'ICD10CM:I63.02',
							'ICD10CM:I63.03',
							'ICD10CM:I63.031',
							'ICD10CM:I63.032',
							'ICD10CM:I63.033',
							'ICD10CM:I63.039',
							'ICD10CM:I63.09',
							'ICD10CM:I63.10',
							'ICD10CM:I63.111',
							'ICD10CM:I63.112',
							'ICD10CM:I63.113',
							'ICD10CM:I63.119',
							'ICD10CM:I63.12',
							'ICD10CM:I63.13',
							'ICD10CM:I63.131',
							'ICD10CM:I63.132',
							'ICD10CM:I63.133',
							'ICD10CM:I63.139',
							'ICD10CM:I63.19',
							'ICD10CM:I63.2',
							'ICD10CM:I63.20',
							'ICD10CM:I63.211',
							'ICD10CM:I63.212',
							'ICD10CM:I63.213',
							'ICD10CM:I63.219',
							'ICD10CM:I63.22',
							'ICD10CM:I63.23',
							'ICD10CM:I63.231',
							'ICD10CM:I63.232',
							'ICD10CM:I63.233',
							'ICD10CM:I63.239',
							'ICD10CM:I63.29',
							'ICD10CM:I63.30',
							'ICD10CM:I63.311',
							'ICD10CM:I63.312',
							'ICD10CM:I63.313',
							'ICD10CM:I63.319',
							'ICD10CM:I63.321',
							'ICD10CM:I63.322',
							'ICD10CM:I63.323',
							'ICD10CM:I63.329',
							'ICD10CM:I63.331',
							'ICD10CM:I63.332',
							'ICD10CM:I63.333',
							'ICD10CM:I63.339',
							'ICD10CM:I63.341',
							'ICD10CM:I63.342',
							'ICD10CM:I63.343',
							'ICD10CM:I63.349',
							'ICD10CM:I63.39',
							'ICD10CM:I63.4',
							'ICD10CM:I63.40',
							'ICD10CM:I63.411',
							'ICD10CM:I63.412',
							'ICD10CM:I63.413',
							'ICD10CM:I63.419',
							'ICD10CM:I63.421',
							'ICD10CM:I63.422',
							'ICD10CM:I63.423',
							'ICD10CM:I63.429',
							'ICD10CM:I63.431',
							'ICD10CM:I63.432',
							'ICD10CM:I63.433',
							'ICD10CM:I63.439',
							'ICD10CM:I63.441',
							'ICD10CM:I63.442',
							'ICD10CM:I63.443',
							'ICD10CM:I63.449',
							'ICD10CM:I63.49',
							'ICD10CM:I63.5',
							'ICD10CM:I63.50',
							'ICD10CM:I63.511',
							'ICD10CM:I63.512',
							'ICD10CM:I63.513',
							'ICD10CM:I63.519',
							'ICD10CM:I63.521',
							'ICD10CM:I63.522',
							'ICD10CM:I63.529',
							'ICD10CM:I63.531',
							'ICD10CM:I63.532',
							'ICD10CM:I63.533',
							'ICD10CM:I63.539',
							'ICD10CM:I63.541',
							'ICD10CM:I63.542',
							'ICD10CM:I63.543',
							'ICD10CM:I63.549',
							'ICD10CM:I63.59',
							'ICD10CM:I63.6',
							'ICD10CM:I63.8',
							'ICD10CM:I63.81',
							'ICD10CM:I63.89',
							'ICD10CM:I63.9',
							'ICD10CM:I65',
							'ICD10CM:I65.0',
							'ICD10CM:I65.01',
							'ICD10CM:I65.02',
							'ICD10CM:I65.03',
							'ICD10CM:I65.09',
							'ICD10CM:I65.1',
							'ICD10CM:I65.2',
							'ICD10CM:I65.21',
							'ICD10CM:I65.22',
							'ICD10CM:I65.23',
							'ICD10CM:I65.29',
							'ICD10CM:I65.8',
							'ICD10CM:I65.9',
							'ICD10CM:I66',
							'ICD10CM:I66.01',
							'ICD10CM:I66.02',
							'ICD10CM:I66.03',
							'ICD10CM:I66.09',
							'ICD10CM:I66.11',
							'ICD10CM:I66.12',
							'ICD10CM:I66.19',
							'ICD10CM:I66.21',
							'ICD10CM:I66.22',
							'ICD10CM:I66.29',
							'ICD10CM:I66.3',
							'ICD10CM:I66.8',
							'ICD10CM:I66.9',
							'ICD10CM:I67',
							'ICD10CM:I67.0',
							'ICD10CM:I67.1',
							'ICD10CM:I67.2',
							'ICD10CM:I67.3',
							'ICD10CM:I67.4',
							'ICD10CM:I67.5',
							'ICD10CM:I67.6',
							'ICD10CM:I67.7',
							'ICD10CM:I67.81',
							'ICD10CM:I67.82',
							'ICD10CM:I67.83',
							'ICD10CM:I67.841',
							'ICD10CM:I67.848',
							'ICD10CM:I67.850',
							'ICD10CM:I67.858',
							'ICD10CM:I67.89',
							'ICD10CM:I67.9',
							'ICD9CM:433.01',
							'ICD9CM:433.11',
							'ICD9CM:433.21',
							'ICD9CM:433.81',
							'ICD9CM:433.91',
							'ICD9CM:434.01',
							'ICD9CM:434.11',
							'ICD9CM:434.91',
							'ICD9CM:435.9',
							'ICD9CM:436',
							'ICD9CM:438.1',
							'ICD9CM:438.10',
							'ICD9CM:438.11',
							'ICD9CM:438.12',
							'ICD9CM:438.13',
							'ICD9CM:438.14',
							'ICD9CM:438.19',
							'ICD9CM:438.2',
							'ICD9CM:438.20',
							'ICD9CM:438.21',
							'ICD9CM:438.22',
							'ICD9CM:438.30',
							'ICD9CM:438.31',
							'ICD9CM:438.32',
							'ICD9CM:438.40',
							'ICD9CM:438.41',
							'ICD9CM:438.50',
							'ICD9CM:438.51',
							'ICD9CM:438.52',
							'ICD9CM:438.53',
							'ICD9CM:438.8',
							'ICD9CM:438.81',
							'ICD9CM:438.82',
							'ICD9CM:438.83',
							'ICD9CM:438.84',
							'ICD9CM:438.85',
							'ICD9CM:438.89',
							'ICD9CM:438.9',
							'ICD9CM:V12.54')
  GROUP BY PATIENT_NUM
),
clean_ObsFact as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE,
		CONCEPT_CD,
		TVAL_CHAR,
		ROW_NUMBER() over(PARTITION BY PATIENT_NUM ORDER BY START_DATE) as rn
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:I60',
							'ICD10CM:I60.00',
							'ICD10CM:I60.01',
							'ICD10CM:I60.10',
							'ICD10CM:I60.11',
							'ICD10CM:I60.12',
							'ICD10CM:I60.2',
							'ICD10CM:I60.22',
							'ICD10CM:I60.3',
							'ICD10CM:I60.30',
							'ICD10CM:I60.31',
							'ICD10CM:I60.32',
							'ICD10CM:I60.4',
							'ICD10CM:I60.51',
							'ICD10CM:I60.6',
							'ICD10CM:I60.7',
							'ICD10CM:I60.8',
							'ICD10CM:I60.9',
							'ICD10CM:I61',
							'ICD10CM:I61.0',
							'ICD10CM:I61.1',
							'ICD10CM:I61.2',
							'ICD10CM:I61.3',
							'ICD10CM:I61.4',
							'ICD10CM:I61.5',
							'ICD10CM:I61.6',
							'ICD10CM:I61.8',
							'ICD10CM:I61.9',
							'ICD10CM:I62',
							'ICD10CM:I62.0',
							'ICD10CM:I62.00',
							'ICD10CM:I62.01',
							'ICD10CM:I62.02',
							'ICD10CM:I62.03',
							'ICD10CM:I62.1',
							'ICD10CM:I62.9',
							'ICD10CM:I63',
							'ICD10CM:I63.00',
							'ICD10CM:I63.011',
							'ICD10CM:I63.012',
							'ICD10CM:I63.013',
							'ICD10CM:I63.019',
							'ICD10CM:I63.02',
							'ICD10CM:I63.03',
							'ICD10CM:I63.031',
							'ICD10CM:I63.032',
							'ICD10CM:I63.033',
							'ICD10CM:I63.039',
							'ICD10CM:I63.09',
							'ICD10CM:I63.10',
							'ICD10CM:I63.111',
							'ICD10CM:I63.112',
							'ICD10CM:I63.113',
							'ICD10CM:I63.119',
							'ICD10CM:I63.12',
							'ICD10CM:I63.13',
							'ICD10CM:I63.131',
							'ICD10CM:I63.132',
							'ICD10CM:I63.133',
							'ICD10CM:I63.139',
							'ICD10CM:I63.19',
							'ICD10CM:I63.2',
							'ICD10CM:I63.20',
							'ICD10CM:I63.211',
							'ICD10CM:I63.212',
							'ICD10CM:I63.213',
							'ICD10CM:I63.219',
							'ICD10CM:I63.22',
							'ICD10CM:I63.23',
							'ICD10CM:I63.231',
							'ICD10CM:I63.232',
							'ICD10CM:I63.233',
							'ICD10CM:I63.239',
							'ICD10CM:I63.29',
							'ICD10CM:I63.30',
							'ICD10CM:I63.311',
							'ICD10CM:I63.312',
							'ICD10CM:I63.313',
							'ICD10CM:I63.319',
							'ICD10CM:I63.321',
							'ICD10CM:I63.322',
							'ICD10CM:I63.323',
							'ICD10CM:I63.329',
							'ICD10CM:I63.331',
							'ICD10CM:I63.332',
							'ICD10CM:I63.333',
							'ICD10CM:I63.339',
							'ICD10CM:I63.341',
							'ICD10CM:I63.342',
							'ICD10CM:I63.343',
							'ICD10CM:I63.349',
							'ICD10CM:I63.39',
							'ICD10CM:I63.4',
							'ICD10CM:I63.40',
							'ICD10CM:I63.411',
							'ICD10CM:I63.412',
							'ICD10CM:I63.413',
							'ICD10CM:I63.419',
							'ICD10CM:I63.421',
							'ICD10CM:I63.422',
							'ICD10CM:I63.423',
							'ICD10CM:I63.429',
							'ICD10CM:I63.431',
							'ICD10CM:I63.432',
							'ICD10CM:I63.433',
							'ICD10CM:I63.439',
							'ICD10CM:I63.441',
							'ICD10CM:I63.442',
							'ICD10CM:I63.443',
							'ICD10CM:I63.449',
							'ICD10CM:I63.49',
							'ICD10CM:I63.5',
							'ICD10CM:I63.50',
							'ICD10CM:I63.511',
							'ICD10CM:I63.512',
							'ICD10CM:I63.513',
							'ICD10CM:I63.519',
							'ICD10CM:I63.521',
							'ICD10CM:I63.522',
							'ICD10CM:I63.529',
							'ICD10CM:I63.531',
							'ICD10CM:I63.532',
							'ICD10CM:I63.533',
							'ICD10CM:I63.539',
							'ICD10CM:I63.541',
							'ICD10CM:I63.542',
							'ICD10CM:I63.543',
							'ICD10CM:I63.549',
							'ICD10CM:I63.59',
							'ICD10CM:I63.6',
							'ICD10CM:I63.8',
							'ICD10CM:I63.81',
							'ICD10CM:I63.89',
							'ICD10CM:I63.9',
							'ICD10CM:I65',
							'ICD10CM:I65.0',
							'ICD10CM:I65.01',
							'ICD10CM:I65.02',
							'ICD10CM:I65.03',
							'ICD10CM:I65.09',
							'ICD10CM:I65.1',
							'ICD10CM:I65.2',
							'ICD10CM:I65.21',
							'ICD10CM:I65.22',
							'ICD10CM:I65.23',
							'ICD10CM:I65.29',
							'ICD10CM:I65.8',
							'ICD10CM:I65.9',
							'ICD10CM:I66',
							'ICD10CM:I66.01',
							'ICD10CM:I66.02',
							'ICD10CM:I66.03',
							'ICD10CM:I66.09',
							'ICD10CM:I66.11',
							'ICD10CM:I66.12',
							'ICD10CM:I66.19',
							'ICD10CM:I66.21',
							'ICD10CM:I66.22',
							'ICD10CM:I66.29',
							'ICD10CM:I66.3',
							'ICD10CM:I66.8',
							'ICD10CM:I66.9',
							'ICD10CM:I67',
							'ICD10CM:I67.0',
							'ICD10CM:I67.1',
							'ICD10CM:I67.2',
							'ICD10CM:I67.3',
							'ICD10CM:I67.4',
							'ICD10CM:I67.5',
							'ICD10CM:I67.6',
							'ICD10CM:I67.7',
							'ICD10CM:I67.81',
							'ICD10CM:I67.82',
							'ICD10CM:I67.83',
							'ICD10CM:I67.841',
							'ICD10CM:I67.848',
							'ICD10CM:I67.850',
							'ICD10CM:I67.858',
							'ICD10CM:I67.89',
							'ICD10CM:I67.9',
							'ICD9CM:433.01',
							'ICD9CM:433.11',
							'ICD9CM:433.21',
							'ICD9CM:433.81',
							'ICD9CM:433.91',
							'ICD9CM:434.01',
							'ICD9CM:434.11',
							'ICD9CM:434.91',
							'ICD9CM:435.9',
							'ICD9CM:436',
							'ICD9CM:438.1',
							'ICD9CM:438.10',
							'ICD9CM:438.11',
							'ICD9CM:438.12',
							'ICD9CM:438.13',
							'ICD9CM:438.14',
							'ICD9CM:438.19',
							'ICD9CM:438.2',
							'ICD9CM:438.20',
							'ICD9CM:438.21',
							'ICD9CM:438.22',
							'ICD9CM:438.30',
							'ICD9CM:438.31',
							'ICD9CM:438.32',
							'ICD9CM:438.40',
							'ICD9CM:438.41',
							'ICD9CM:438.50',
							'ICD9CM:438.51',
							'ICD9CM:438.52',
							'ICD9CM:438.53',
							'ICD9CM:438.8',
							'ICD9CM:438.81',
							'ICD9CM:438.82',
							'ICD9CM:438.83',
							'ICD9CM:438.84',
							'ICD9CM:438.85',
							'ICD9CM:438.89',
							'ICD9CM:438.9',
							'ICD9CM:V12.54')
)
select
	distinct 
  --count(distinct t.PATIENT_NUM)
  	clean_ObsFact.PATIENT_NUM as PATIENT_NUM,
	clean_ObsFact.ENCOUNTER_NUM as earliest_CerebroVD_encounter_num,
	t.earliest_CerebroVD_date as earliest_CerebroVD_date,
	t.latest_CerebroVD_date as latest_CerebroVD_date,
	t.N_CerebroVD_codes_diffdates,
	clean_ObsFact.CONCEPT_CD as earliest_CerebroVD_code,
	clean_ObsFact.TVAL_CHAR as earliest_CerebroVD_TVAL_CHAR,
	1 as CerebroVD_ComputablePhenotype
into S19.dbo.CerebroVD_CompPheno
from clean_ObsFact
INNER JOIN temp_aggregated t on t.PATIENT_NUM = clean_ObsFact.PATIENT_NUM AND t.earliest_CerebroVD_date = clean_ObsFact.START_DATE
WHERE rn = 1
ORDER BY PATIENT_NUM, earliest_CerebroVD_date;

--drop table S19.dbo.CerebroVD_CompPheno;
--drop table S19.dbo.TEST;


select top 100 * from S19.dbo.CerebroVD_CompPheno
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.CerebroVD_CompPheno;
select count(distinct PATIENT_NUM) from S19.dbo.CerebroVD_CompPheno;

-- COPD
select distinct earliest_COPD_code from S19.dbo.COPD_CompPheno
order by earliest_COPD_code;

with temp_aggregated as ( 	

	select
		PATIENT_NUM,
		min(START_DATE) as earliest_COPD_date,
		max(START_DATE) as latest_COPD_date,
		count(distinct START_DATE) as N_COPD_codes_diffdates
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:J44',
							'ICD10CM:J44.0',
							'ICD10CM:J44.1',
							'ICD10CM:J44.9',
							'ICD9CM:496')
  GROUP BY PATIENT_NUM
),
clean_ObsFact as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE,
		CONCEPT_CD,
		TVAL_CHAR,
		ROW_NUMBER() over(PARTITION BY PATIENT_NUM ORDER BY START_DATE) as rn
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:J44',
							'ICD10CM:J44.0',
							'ICD10CM:J44.1',
							'ICD10CM:J44.9',
							'ICD9CM:496')
)
select
	distinct 
  --count(distinct t.PATIENT_NUM)
  	clean_ObsFact.PATIENT_NUM as PATIENT_NUM,
	clean_ObsFact.ENCOUNTER_NUM as earliest_COPD_encounter_num,
	t.earliest_COPD_date as earliest_COPD_date,
	t.latest_COPD_date as latest_COPD_date,
	t.N_COPD_codes_diffdates,
	clean_ObsFact.CONCEPT_CD as earliest_COPD_code,
	clean_ObsFact.TVAL_CHAR as earliest_COPD_TVAL_CHAR,
	1 as COPD_ComputablePhenotype
into S19.dbo.COPD_CompPheno
from clean_ObsFact
INNER JOIN temp_aggregated t on t.PATIENT_NUM = clean_ObsFact.PATIENT_NUM AND t.earliest_COPD_date = clean_ObsFact.START_DATE
WHERE rn = 1
ORDER BY PATIENT_NUM, earliest_COPD_date;

--drop table S19.dbo.COPD_TEST;
--drop table S19.dbo.COPD_CompPheno;


select top 100 * from S19.dbo.COPD_CompPheno
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.COPD_CompPheno;
select count(distinct PATIENT_NUM) from S19.dbo.COPD_CompPheno;

-- HF
select distinct earliest_HF_code from S19.dbo.HF_CompPheno
order by earliest_HF_code;

with temp_aggregated as ( 	

	select
		PATIENT_NUM,
		min(START_DATE) as earliest_HF_date,
		max(START_DATE) as latest_HF_date,
		count(distinct START_DATE) as N_HF_codes_diffdates
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:I50',
							'ICD10CM:I50.1',
							'ICD10CM:I50.2',
							'ICD10CM:I50.20',
							'ICD10CM:I50.21',
							'ICD10CM:I50.22',
							'ICD10CM:I50.23',
							'ICD10CM:I50.3',
							'ICD10CM:I50.30',
							'ICD10CM:I50.31',
							'ICD10CM:I50.32',
							'ICD10CM:I50.33',
							'ICD10CM:I50.4',
							'ICD10CM:I50.40',
							'ICD10CM:I50.41',
							'ICD10CM:I50.42',
							'ICD10CM:I50.43',
							'ICD10CM:I50.81',
							'ICD10CM:I50.810',
							'ICD10CM:I50.811',
							'ICD10CM:I50.812',
							'ICD10CM:I50.813',
							'ICD10CM:I50.814',
							'ICD10CM:I50.82',
							'ICD10CM:I50.83',
							'ICD10CM:I50.84',
							'ICD10CM:I50.89',
							'ICD10CM:I50.9',
							'ICD9CM:428.0',
							'ICD9CM:428.1',
							'ICD9CM:428.2',
							'ICD9CM:428.20',
							'ICD9CM:428.21',
							'ICD9CM:428.22',
							'ICD9CM:428.23',
							'ICD9CM:428.3',
							'ICD9CM:428.30',
							'ICD9CM:428.31',
							'ICD9CM:428.32',
							'ICD9CM:428.33',
							'ICD9CM:428.40',
							'ICD9CM:428.41',
							'ICD9CM:428.42',
							'ICD9CM:428.43',
							'ICD9CM:428.9')
  GROUP BY PATIENT_NUM
),
clean_ObsFact as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE,
		CONCEPT_CD,
		TVAL_CHAR,
		ROW_NUMBER() over(PARTITION BY PATIENT_NUM ORDER BY START_DATE) as rn
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:I50',
							'ICD10CM:I50.1',
							'ICD10CM:I50.2',
							'ICD10CM:I50.20',
							'ICD10CM:I50.21',
							'ICD10CM:I50.22',
							'ICD10CM:I50.23',
							'ICD10CM:I50.3',
							'ICD10CM:I50.30',
							'ICD10CM:I50.31',
							'ICD10CM:I50.32',
							'ICD10CM:I50.33',
							'ICD10CM:I50.4',
							'ICD10CM:I50.40',
							'ICD10CM:I50.41',
							'ICD10CM:I50.42',
							'ICD10CM:I50.43',
							'ICD10CM:I50.81',
							'ICD10CM:I50.810',
							'ICD10CM:I50.811',
							'ICD10CM:I50.812',
							'ICD10CM:I50.813',
							'ICD10CM:I50.814',
							'ICD10CM:I50.82',
							'ICD10CM:I50.83',
							'ICD10CM:I50.84',
							'ICD10CM:I50.89',
							'ICD10CM:I50.9',
							'ICD9CM:428.0',
							'ICD9CM:428.1',
							'ICD9CM:428.2',
							'ICD9CM:428.20',
							'ICD9CM:428.21',
							'ICD9CM:428.22',
							'ICD9CM:428.23',
							'ICD9CM:428.3',
							'ICD9CM:428.30',
							'ICD9CM:428.31',
							'ICD9CM:428.32',
							'ICD9CM:428.33',
							'ICD9CM:428.40',
							'ICD9CM:428.41',
							'ICD9CM:428.42',
							'ICD9CM:428.43',
							'ICD9CM:428.9')
)
select
	distinct 
  --count(distinct t.PATIENT_NUM)
  	clean_ObsFact.PATIENT_NUM as PATIENT_NUM,
	clean_ObsFact.ENCOUNTER_NUM as earliest_HF_encounter_num,
	t.earliest_HF_date as earliest_HF_date,
	t.latest_HF_date as latest_HF_date,
	t.N_HF_codes_diffdates,
	clean_ObsFact.CONCEPT_CD as earliest_HF_code,
	clean_ObsFact.TVAL_CHAR as earliest_HF_TVAL_CHAR,
	1 as HF_ComputablePhenotype
into S19.dbo.HF_CompPheno
from clean_ObsFact
INNER JOIN temp_aggregated t on t.PATIENT_NUM = clean_ObsFact.PATIENT_NUM AND t.earliest_HF_date = clean_ObsFact.START_DATE
WHERE rn = 1
ORDER BY PATIENT_NUM, earliest_HF_date;

--drop table S19.dbo.HF_TEST;
--drop table S19.dbo.HF_CompPheno;

select top 100 * from S19.dbo.HF_TEST
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.HF_TEST;
select count(distinct PATIENT_NUM) from S19.dbo.HF_TEST;

select top 100 * from S19.dbo.HF_CompPheno
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.HF_CompPheno;
select count(distinct PATIENT_NUM) from S19.dbo.HF_CompPheno;



-- HTN
select distinct earliest_HTN_code from S19.dbo.HTN_CompPheno
order by earliest_HTN_code;

with temp_aggregated as ( 	

	select
		PATIENT_NUM,
		min(START_DATE) as earliest_HTN_date,
		max(START_DATE) as latest_HTN_date,
		count(distinct START_DATE) as N_HTN_codes_diffdates
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:I10',
							'ICD10CM:I11',
							'ICD10CM:I11.0',
							'ICD10CM:I11.9',
							'ICD10CM:I12',
							'ICD10CM:I12.0',
							'ICD10CM:I12.9',
							'ICD10CM:I13.0',
							'ICD10CM:I13.10',
							'ICD10CM:I13.11',
							'ICD10CM:I13.2',
							'ICD10CM:R03',
							'ICD10CM:R03.0',
							'ICD10CM:R03.1',
							'ICD9CM:401',
							'ICD9CM:401.0',
							'ICD9CM:401.1',
							'ICD9CM:401.9',
							'ICD9CM:402',
							'ICD9CM:402.0',
							'ICD9CM:402.00',
							'ICD9CM:402.01',
							'ICD9CM:402.1',
							'ICD9CM:402.10',
							'ICD9CM:402.11',
							'ICD9CM:402.9',
							'ICD9CM:402.90',
							'ICD9CM:402.91',
							'ICD9CM:403',
							'ICD9CM:403.00',
							'ICD9CM:403.01',
							'ICD9CM:403.1',
							'ICD9CM:403.10',
							'ICD9CM:403.11',
							'ICD9CM:403.9',
							'ICD9CM:403.90',
							'ICD9CM:403.91',
							'ICD9CM:404',
							'ICD9CM:404.0',
							'ICD9CM:404.00',
							'ICD9CM:404.02',
							'ICD9CM:404.03',
							'ICD9CM:404.1',
							'ICD9CM:404.10',
							'ICD9CM:404.11',
							'ICD9CM:404.12',
							'ICD9CM:404.13',
							'ICD9CM:404.9',
							'ICD9CM:404.90',
							'ICD9CM:404.91',
							'ICD9CM:404.92',
							'ICD9CM:404.93',
							'ICD9CM:405.0',
							'ICD9CM:405.01',
							'ICD9CM:405.09',
							'ICD9CM:405.1',
							'ICD9CM:405.11',
							'ICD9CM:405.19',
							'ICD9CM:405.91',
							'ICD9CM:405.99')
  GROUP BY PATIENT_NUM
),
clean_ObsFact as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE,
		CONCEPT_CD,
		TVAL_CHAR,
		ROW_NUMBER() over(PARTITION BY PATIENT_NUM ORDER BY START_DATE) as rn
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:I10',
							'ICD10CM:I11',
							'ICD10CM:I11.0',
							'ICD10CM:I11.9',
							'ICD10CM:I12',
							'ICD10CM:I12.0',
							'ICD10CM:I12.9',
							'ICD10CM:I13.0',
							'ICD10CM:I13.10',
							'ICD10CM:I13.11',
							'ICD10CM:I13.2',
							'ICD10CM:R03',
							'ICD10CM:R03.0',
							'ICD10CM:R03.1',
							'ICD9CM:401',
							'ICD9CM:401.0',
							'ICD9CM:401.1',
							'ICD9CM:401.9',
							'ICD9CM:402',
							'ICD9CM:402.0',
							'ICD9CM:402.00',
							'ICD9CM:402.01',
							'ICD9CM:402.1',
							'ICD9CM:402.10',
							'ICD9CM:402.11',
							'ICD9CM:402.9',
							'ICD9CM:402.90',
							'ICD9CM:402.91',
							'ICD9CM:403',
							'ICD9CM:403.00',
							'ICD9CM:403.01',
							'ICD9CM:403.1',
							'ICD9CM:403.10',
							'ICD9CM:403.11',
							'ICD9CM:403.9',
							'ICD9CM:403.90',
							'ICD9CM:403.91',
							'ICD9CM:404',
							'ICD9CM:404.0',
							'ICD9CM:404.00',
							'ICD9CM:404.02',
							'ICD9CM:404.03',
							'ICD9CM:404.1',
							'ICD9CM:404.10',
							'ICD9CM:404.11',
							'ICD9CM:404.12',
							'ICD9CM:404.13',
							'ICD9CM:404.9',
							'ICD9CM:404.90',
							'ICD9CM:404.91',
							'ICD9CM:404.92',
							'ICD9CM:404.93',
							'ICD9CM:405.0',
							'ICD9CM:405.01',
							'ICD9CM:405.09',
							'ICD9CM:405.1',
							'ICD9CM:405.11',
							'ICD9CM:405.19',
							'ICD9CM:405.91',
							'ICD9CM:405.99')
)
select
	distinct 
  --count(distinct t.PATIENT_NUM)
  	clean_ObsFact.PATIENT_NUM as PATIENT_NUM,
	clean_ObsFact.ENCOUNTER_NUM as earliest_HTN_encounter_num,
	t.earliest_HTN_date as earliest_HTN_date,
	t.latest_HTN_date as latest_HTN_date,
	t.N_HTN_codes_diffdates,
	clean_ObsFact.CONCEPT_CD as earliest_HTN_code,
	clean_ObsFact.TVAL_CHAR as earliest_HTN_TVAL_CHAR,
	1 as HTN_ComputablePhenotype
into S19.dbo.HTN_CompPheno
from clean_ObsFact
INNER JOIN temp_aggregated t on t.PATIENT_NUM = clean_ObsFact.PATIENT_NUM AND t.earliest_HTN_date = clean_ObsFact.START_DATE
WHERE rn = 1
ORDER BY PATIENT_NUM, earliest_HTN_date;

--drop table S19.dbo.HTN_TEST;
--drop table S19.dbo.HTN_CompPheno;

select top 100 * from S19.dbo.HTN_TEST
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.HTN_TEST;
select count(distinct PATIENT_NUM) from S19.dbo.HTN_TEST;

select top 100 * from S19.dbo.HTN_CompPheno
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.HTN_CompPheno;
select count(distinct PATIENT_NUM) from S19.dbo.HTN_CompPheno;


-- Insomnia
select distinct earliest_Insomnia_code from S19.dbo.Insomnia_CompPheno
order by earliest_Insomnia_code;

with temp_aggregated as ( 	

	select
		PATIENT_NUM,
		min(START_DATE) as earliest_Insomnia_date,
		max(START_DATE) as latest_Insomnia_date,
		count(distinct START_DATE) as N_Insomnia_codes_diffdates
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:F51.01',
							'ICD10CM:F51.02',
							'ICD10CM:F51.09',
							'ICD10CM:G47.0',
							'ICD10CM:G47.00',
							'ICD10CM:G47.01',
							'ICD10CM:G47.09',
							'ICD9CM:307.41',
							'ICD9CM:307.42',
							'ICD9CM:327.0',
							'ICD9CM:327.00',
							'ICD9CM:327.01',
							'ICD9CM:327.02',
							'ICD9CM:327.09',
							'ICD9CM:780.52')
  GROUP BY PATIENT_NUM
),
clean_ObsFact as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE,
		CONCEPT_CD,
		TVAL_CHAR,
		ROW_NUMBER() over(PARTITION BY PATIENT_NUM ORDER BY START_DATE) as rn
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:F51.01',
							'ICD10CM:F51.02',
							'ICD10CM:F51.09',
							'ICD10CM:G47.0',
							'ICD10CM:G47.00',
							'ICD10CM:G47.01',
							'ICD10CM:G47.09',
							'ICD9CM:307.41',
							'ICD9CM:307.42',
							'ICD9CM:327.0',
							'ICD9CM:327.00',
							'ICD9CM:327.01',
							'ICD9CM:327.02',
							'ICD9CM:327.09',
							'ICD9CM:780.52')
)
select
	distinct 
  --count(distinct t.PATIENT_NUM)
  	clean_ObsFact.PATIENT_NUM as PATIENT_NUM,
	clean_ObsFact.ENCOUNTER_NUM as earliest_Insomnia_encounter_num,
	t.earliest_Insomnia_date as earliest_Insomnia_date,
	t.latest_Insomnia_date as latest_Insomnia_date,
	t.N_Insomnia_codes_diffdates,
	clean_ObsFact.CONCEPT_CD as earliest_Insomnia_code,
	clean_ObsFact.TVAL_CHAR as earliest_Insomnia_TVAL_CHAR,
	1 as Insomnia_ComputablePhenotype
into S19.dbo.Insomnia_CompPheno
from clean_ObsFact
INNER JOIN temp_aggregated t on t.PATIENT_NUM = clean_ObsFact.PATIENT_NUM AND t.earliest_Insomnia_date = clean_ObsFact.START_DATE
WHERE rn = 1
ORDER BY PATIENT_NUM, earliest_Insomnia_date;

--drop table S19.dbo.Insomnia_TEST;
--drop table S19.dbo.Insomnia_CompPheno;

select top 100 * from S19.dbo.Insomnia_TEST
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.Insomnia_TEST;
select count(distinct PATIENT_NUM) from S19.dbo.Insomnia_TEST;

select top 100 * from S19.dbo.Insomnia_CompPheno
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.Insomnia_CompPheno;
select count(distinct PATIENT_NUM) from S19.dbo.Insomnia_CompPheno;

-- Insomnia ED Only
select distinct earliest_Insomnia_code from S19.dbo.Insomnia_CompPheno
order by earliest_Insomnia_code;

with temp_aggregated as ( 	

	select
		PATIENT_NUM,
		min(START_DATE) as earliest_Insomnia_date,
		max(START_DATE) as latest_Insomnia_date,
		count(distinct START_DATE) as N_Insomnia_codes_diffdates
	from FellowsSample.S19.OBSERVATION_FACT
	where TVAL_CHAR = 'Encounter Diagnosis' and CONCEPT_CD IN ('ICD10CM:F51.01',
							'ICD10CM:F51.02',
							'ICD10CM:F51.09',
							'ICD10CM:G47.0',
							'ICD10CM:G47.00',
							'ICD10CM:G47.01',
							'ICD10CM:G47.09',
							'ICD9CM:307.41',
							'ICD9CM:307.42',
							'ICD9CM:327.0',
							'ICD9CM:327.00',
							'ICD9CM:327.01',
							'ICD9CM:327.02',
							'ICD9CM:327.09',
							'ICD9CM:780.52')
  GROUP BY PATIENT_NUM
),
clean_ObsFact as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE,
		CONCEPT_CD,
		TVAL_CHAR,
		ROW_NUMBER() over(PARTITION BY PATIENT_NUM ORDER BY START_DATE) as rn
	from FellowsSample.S19.OBSERVATION_FACT
	where TVAL_CHAR = 'Encounter Diagnosis' and CONCEPT_CD IN ('ICD10CM:F51.01',
							'ICD10CM:F51.02',
							'ICD10CM:F51.09',
							'ICD10CM:G47.0',
							'ICD10CM:G47.00',
							'ICD10CM:G47.01',
							'ICD10CM:G47.09',
							'ICD9CM:307.41',
							'ICD9CM:307.42',
							'ICD9CM:327.0',
							'ICD9CM:327.00',
							'ICD9CM:327.01',
							'ICD9CM:327.02',
							'ICD9CM:327.09',
							'ICD9CM:780.52')
)
select
	distinct 
  --count(distinct t.PATIENT_NUM)
  	clean_ObsFact.PATIENT_NUM as PATIENT_NUM,
	clean_ObsFact.ENCOUNTER_NUM as earliest_Insomnia_encounter_num,
	t.earliest_Insomnia_date as earliest_Insomnia_date,
	t.latest_Insomnia_date as latest_Insomnia_date,
	t.N_Insomnia_codes_diffdates,
	clean_ObsFact.CONCEPT_CD as earliest_Insomnia_code,
	clean_ObsFact.TVAL_CHAR as earliest_Insomnia_TVAL_CHAR,
	1 as Insomnia_ED_only_ComputablePhenotype
into S19.dbo.Insomnia_ED_only_CompPheno
from clean_ObsFact
INNER JOIN temp_aggregated t on t.PATIENT_NUM = clean_ObsFact.PATIENT_NUM AND t.earliest_Insomnia_date = clean_ObsFact.START_DATE
WHERE rn = 1
ORDER BY PATIENT_NUM, earliest_Insomnia_date;

--drop table S19.dbo.Insomnia_TEST;
--drop table S19.dbo.Insomnia_ED_only_CompPheno;

select top 100 * from S19.dbo.Insomnia_ED_only_CompPheno
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.Insomnia_ED_only_CompPheno;
select count(distinct PATIENT_NUM) from S19.dbo.Insomnia_ED_only_CompPheno;

select top 100 * from S19.dbo.Insomnia_CompPheno
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.Insomnia_CompPheno;
select count(distinct PATIENT_NUM) from S19.dbo.Insomnia_CompPheno;



-- MI
select distinct earliest_MI_code from S19.dbo.MI_CompPheno
order by earliest_MI_code;

with temp_aggregated as ( 	

	select
		PATIENT_NUM,
		min(START_DATE) as earliest_MI_date,
		max(START_DATE) as latest_MI_date,
		count(distinct START_DATE) as N_MI_codes_diffdates
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:I21',
							'ICD10CM:I21.0',
							'ICD10CM:I21.01',
							'ICD10CM:I21.02',
							'ICD10CM:I21.09',
							'ICD10CM:I21.1',
							'ICD10CM:I21.11',
							'ICD10CM:I21.19',
							'ICD10CM:I21.2',
							'ICD10CM:I21.21',
							'ICD10CM:I21.29',
							'ICD10CM:I21.3',
							'ICD10CM:I21.4',
							'ICD10CM:I21.9',
							'ICD10CM:I21.A1',
							'ICD10CM:I21.A9',
							'ICD10CM:I22.0',
							'ICD10CM:I22.1',
							'ICD10CM:I22.2',
							'ICD10CM:I22.8',
							'ICD10CM:I22.9',
							'ICD10CM:I23',
							'ICD10CM:I23.1',
							'ICD10CM:I23.2',
							'ICD10CM:I23.3',
							'ICD10CM:I23.5',
							'ICD10CM:I23.6',
							'ICD10CM:I23.7',
							'ICD10CM:I23.8',
							'ICD9CM:410',
							'ICD9CM:410.00',
							'ICD9CM:410.01',
							'ICD9CM:410.02',
							'ICD9CM:410.10',
							'ICD9CM:410.11',
							'ICD9CM:410.12',
							'ICD9CM:410.20',
							'ICD9CM:410.21',
							'ICD9CM:410.22',
							'ICD9CM:410.30',
							'ICD9CM:410.31',
							'ICD9CM:410.32',
							'ICD9CM:410.40',
							'ICD9CM:410.41',
							'ICD9CM:410.42',
							'ICD9CM:410.50',
							'ICD9CM:410.52',
							'ICD9CM:410.60',
							'ICD9CM:410.62',
							'ICD9CM:410.7',
							'ICD9CM:410.70',
							'ICD9CM:410.71',
							'ICD9CM:410.72',
							'ICD9CM:410.8',
							'ICD9CM:410.80',
							'ICD9CM:410.81',
							'ICD9CM:410.82',
							'ICD9CM:410.9',
							'ICD9CM:410.90',
							'ICD9CM:410.91',
							'ICD9CM:410.92',
							'ICD9CM:412')
  GROUP BY PATIENT_NUM
),
clean_ObsFact as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE,
		CONCEPT_CD,
		TVAL_CHAR,
		ROW_NUMBER() over(PARTITION BY PATIENT_NUM ORDER BY START_DATE) as rn
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:I21',
							'ICD10CM:I21.0',
							'ICD10CM:I21.01',
							'ICD10CM:I21.02',
							'ICD10CM:I21.09',
							'ICD10CM:I21.1',
							'ICD10CM:I21.11',
							'ICD10CM:I21.19',
							'ICD10CM:I21.2',
							'ICD10CM:I21.21',
							'ICD10CM:I21.29',
							'ICD10CM:I21.3',
							'ICD10CM:I21.4',
							'ICD10CM:I21.9',
							'ICD10CM:I21.A1',
							'ICD10CM:I21.A9',
							'ICD10CM:I22.0',
							'ICD10CM:I22.1',
							'ICD10CM:I22.2',
							'ICD10CM:I22.8',
							'ICD10CM:I22.9',
							'ICD10CM:I23',
							'ICD10CM:I23.1',
							'ICD10CM:I23.2',
							'ICD10CM:I23.3',
							'ICD10CM:I23.5',
							'ICD10CM:I23.6',
							'ICD10CM:I23.7',
							'ICD10CM:I23.8',
							'ICD9CM:410',
							'ICD9CM:410.00',
							'ICD9CM:410.01',
							'ICD9CM:410.02',
							'ICD9CM:410.10',
							'ICD9CM:410.11',
							'ICD9CM:410.12',
							'ICD9CM:410.20',
							'ICD9CM:410.21',
							'ICD9CM:410.22',
							'ICD9CM:410.30',
							'ICD9CM:410.31',
							'ICD9CM:410.32',
							'ICD9CM:410.40',
							'ICD9CM:410.41',
							'ICD9CM:410.42',
							'ICD9CM:410.50',
							'ICD9CM:410.52',
							'ICD9CM:410.60',
							'ICD9CM:410.62',
							'ICD9CM:410.7',
							'ICD9CM:410.70',
							'ICD9CM:410.71',
							'ICD9CM:410.72',
							'ICD9CM:410.8',
							'ICD9CM:410.80',
							'ICD9CM:410.81',
							'ICD9CM:410.82',
							'ICD9CM:410.9',
							'ICD9CM:410.90',
							'ICD9CM:410.91',
							'ICD9CM:410.92',
							'ICD9CM:412')
)
select
	distinct 
  --count(distinct t.PATIENT_NUM)
  	clean_ObsFact.PATIENT_NUM as PATIENT_NUM,
	clean_ObsFact.ENCOUNTER_NUM as earliest_MI_encounter_num,
	t.earliest_MI_date as earliest_MI_date,
	t.latest_MI_date as latest_MI_date,
	t.N_MI_codes_diffdates,
	clean_ObsFact.CONCEPT_CD as earliest_MI_code,
	clean_ObsFact.TVAL_CHAR as earliest_MI_TVAL_CHAR,
	1 as MI_ComputablePhenotype
into S19.dbo.MI_CompPheno
from clean_ObsFact
INNER JOIN temp_aggregated t on t.PATIENT_NUM = clean_ObsFact.PATIENT_NUM AND t.earliest_MI_date = clean_ObsFact.START_DATE
WHERE rn = 1
ORDER BY PATIENT_NUM, earliest_MI_date;

--drop table S19.dbo.MI_TEST;
--drop table S19.dbo.MI_CompPheno;

select top 100 * from S19.dbo.MI_TEST
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.MI_TEST;
select count(distinct PATIENT_NUM) from S19.dbo.MI_TEST;

select top 100 * from S19.dbo.MI_CompPheno
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.MI_CompPheno;
select count(distinct PATIENT_NUM) from S19.dbo.MI_CompPheno;

-- Obesity
select distinct earliest_Obesity_code from S19.dbo.Obesity_CompPheno
order by earliest_Obesity_code;

with temp_aggregated as ( 	

	select
		PATIENT_NUM,
		minn(START_DATE) as earliest_Obesity_date,
		max(START_DATE) as latest_Obesity_date,
		count(distinct START_DATE) as N_Obesity_codes_diffdates
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:I21',
							'ICD10CM:I21.0',
							'ICD10CM:I21.01',
							'ICD10CM:I21.02',
							'ICD10CM:I21.09',
							'ICD10CM:I21.1',
							'ICD10CM:I21.11',
							'ICD10CM:I21.19',
							'ICD10CM:I21.2',
							'ICD10CM:I21.21',
							'ICD10CM:I21.29',
							'ICD10CM:I21.3',
							'ICD10CM:I21.4',
							'ICD10CM:I21.9',
							'ICD10CM:I21.A1',
							'ICD10CM:I21.A9',
							'ICD10CM:I22.0',
							'ICD10CM:I22.1',
							'ICD10CM:I22.2',
							'ICD10CM:I22.8',
							'ICD10CM:I22.9',
							'ICD10CM:I23',
							'ICD10CM:I23.1',
							'ICD10CM:I23.2',
							'ICD10CM:I23.3',
							'ICD10CM:I23.5',
							'ICD10CM:I23.6',
							'ICD10CM:I23.7',
							'ICD10CM:I23.8',
							'ICD9CM:410',
							'ICD9CM:410.00',
							'ICD9CM:410.01',
							'ICD9CM:410.02',
							'ICD9CM:410.10',
							'ICD9CM:410.11',
							'ICD9CM:410.12',
							'ICD9CM:410.20',
							'ICD9CM:410.21',
							'ICD9CM:410.22',
							'ICD9CM:410.30',
							'ICD9CM:410.31',
							'ICD9CM:410.32',
							'ICD9CM:410.40',
							'ICD9CM:410.41',
							'ICD9CM:410.42',
							'ICD9CM:410.50',
							'ICD9CM:410.52',
							'ICD9CM:410.60',
							'ICD9CM:410.62',
							'ICD9CM:410.7',
							'ICD9CM:410.70',
							'ICD9CM:410.71',
							'ICD9CM:410.72',
							'ICD9CM:410.8',
							'ICD9CM:410.80',
							'ICD9CM:410.81',
							'ICD9CM:410.82',
							'ICD9CM:410.9',
							'ICD9CM:410.90',
							'ICD9CM:410.91',
							'ICD9CM:410.92',
							'ICD9CM:412')
  GROUP BY PATIENT_NUM
),
clean_ObsFact as (
	select
		PATIENT_NUM,
		ENCOUNTER_NUM,
		START_DATE,
		CONCEPT_CD,
		TVAL_CHAR,
		ROW_NUMBER() over(PARTITION BY PATIENT_NUM ORDER BY START_DATE) as rn
	from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD IN ('ICD10CM:I21',
							'ICD10CM:I21.0',
							'ICD10CM:I21.01',
							'ICD10CM:I21.02',
							'ICD10CM:I21.09',
							'ICD10CM:I21.1',
							'ICD10CM:I21.11',
							'ICD10CM:I21.19',
							'ICD10CM:I21.2',
							'ICD10CM:I21.21',
							'ICD10CM:I21.29',
							'ICD10CM:I21.3',
							'ICD10CM:I21.4',
							'ICD10CM:I21.9',
							'ICD10CM:I21.A1',
							'ICD10CM:I21.A9',
							'ICD10CM:I22.0',
							'ICD10CM:I22.1',
							'ICD10CM:I22.2',
							'ICD10CM:I22.8',
							'ICD10CM:I22.9',
							'ICD10CM:I23',
							'ICD10CM:I23.1',
							'ICD10CM:I23.2',
							'ICD10CM:I23.3',
							'ICD10CM:I23.5',
							'ICD10CM:I23.6',
							'ICD10CM:I23.7',
							'ICD10CM:I23.8',
							'ICD9CM:410',
							'ICD9CM:410.00',
							'ICD9CM:410.01',
							'ICD9CM:410.02',
							'ICD9CM:410.10',
							'ICD9CM:410.11',
							'ICD9CM:410.12',
							'ICD9CM:410.20',
							'ICD9CM:410.21',
							'ICD9CM:410.22',
							'ICD9CM:410.30',
							'ICD9CM:410.31',
							'ICD9CM:410.32',
							'ICD9CM:410.40',
							'ICD9CM:410.41',
							'ICD9CM:410.42',
							'ICD9CM:410.50',
							'ICD9CM:410.52',
							'ICD9CM:410.60',
							'ICD9CM:410.62',
							'ICD9CM:410.7',
							'ICD9CM:410.70',
							'ICD9CM:410.71',
							'ICD9CM:410.72',
							'ICD9CM:410.8',
							'ICD9CM:410.80',
							'ICD9CM:410.81',
							'ICD9CM:410.82',
							'ICD9CM:410.9',
							'ICD9CM:410.90',
							'ICD9CM:410.91',
							'ICD9CM:410.92',
							'ICD9CM:412')
)
select
	distinct 
  --count(distinct t.PATIENT_NUM)
  	clean_ObsFact.PATIENT_NUM as PATIENT_NUM,
	clean_ObsFact.ENCOUNTER_NUM as earliest_Obesity_encounter_num,
	t.earliest_Obesity_date as earliest_Obesity_date,
	t.latest_Obesity_date as latest_Obesity_date,
	t.N_Obesity_codes_diffdates,
	clean_ObsFact.CONCEPT_CD as earliest_Obesity_code,
	clean_ObsFact.TVAL_CHAR as earliest_Obesity_TVAL_CHAR,
	1 as Obesity_ComputablePhenotype
into S19.dbo.Obesity_CompPheno
from clean_ObsFact
INNER JOIN temp_aggregated t on t.PATIENT_NUM = clean_ObsFact.PATIENT_NUM AND t.earliest_Obesity_date = clean_ObsFact.START_DATE
WHERE rn = 1
ORDER BY PATIENT_NUM, earliest_Obesity_date;

--drop table S19.dbo.Obesity_TEST;
--drop table S19.dbo.Obesity_CompPheno;

select top 100 * from S19.dbo.Obesity_TEST
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.Obesity_TEST;
select count(distinct PATIENT_NUM) from S19.dbo.Obesity_TEST;

select top 100 * from S19.dbo.Obesity_CompPheno
order by PATIENT_NUM;
select count(PATIENT_NUM) from S19.dbo.Obesity_CompPheno;
select count(distinct PATIENT_NUM) from S19.dbo.Obesity_CompPheno;

-- Stroke
select distinct earliest_Stroke_code from S19.dbo.Stroke_CompPheno
order by earliest_Stroke_code;


-- T2D
select distinct earliest_T2D_code from S19.dbo.T2D_CompPheno
order by earliest_T2D_code;
