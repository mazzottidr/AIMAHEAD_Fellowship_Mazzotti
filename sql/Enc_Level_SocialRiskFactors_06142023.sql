-- Create encounter level Laboratory values

-- Only in 5 year cohort

-- OSA
with lab_event as (
select distinct
	o.PATIENT_NUM
	,o.NVAL_NUM as LAB_VALUE
	,o.START_DATE as LAB_Date
	,c.C_NAME as LAB_NAME
	,o.CONCEPT_CD as LOINC_CODE
from FellowsSample.S19.OBSERVATION_FACT o
join FellowsSample.common.I2B2 c on o.CONCEPT_CD = c.C_BASECODE
where CONCEPT_CD LIKE 'LOINC%' and o.PATIENT_NUM in (select PATIENT_NUM from S19.dbo.OSA_OUTCOMES) and o.NVAL_NUM IS NOT NULL
),
--select top 1000 * from lab_event;
lab_occur as (
select p.PATIENT_NUM
      ,datediff(day,p.OSA_CONTROL_INDEX_DATE,le.LAB_Date) as DAYS_OSA_LAB
	  ,LOINC_CODE
	  ,LAB_NAME
	  ,LAB_VALUE as LAB_VALUE_1YR_PRIOR_OSA
from S19.dbo.OSA_OUTCOMES p
join lab_event le on p.PATIENT_NUM = le.PATIENT_NUM 
where datediff(day,p.OSA_CONTROL_INDEX_DATE,le.LAB_Date)<0 and datediff(day,p.OSA_CONTROL_INDEX_DATE,le.LAB_Date)>=-365
)
select *
into S19.dbo.OSA_ONLY_LABS_1YR_PRIOR
from lab_occur;

--drop table S19.dbo.OSA_ONLY_LABS_1YR_PRIOR;
select top 100 * from S19.dbo.OSA_ONLY_LABS_1YR_PRIOR;
select count(*) from S19.dbo.OSA_ONLY_LABS_1YR_PRIOR; -- 48,284,011 lab measurements
select count(distinct PATIENT_NUM) from S19.dbo.OSA_ONLY_LABS_1YR_PRIOR;  -- 101,567 patients

select count(*) from S19.dbo.OSA_OUTCOMES;

-- INSOMNIA
with lab_event as (
select 
	o.PATIENT_NUM
	,o.NVAL_NUM as LAB_VALUE
	,o.START_DATE as LAB_Date
	,c.C_NAME as LAB_NAME
	,o.CONCEPT_CD as LOINC_CODE
from FellowsSample.S19.OBSERVATION_FACT o
left join FellowsSample.common.I2B2 c on o.CONCEPT_CD = c.C_BASECODE
where CONCEPT_CD LIKE 'LOINC%' and o.PATIENT_NUM in (select PATIENT_NUM from S19.dbo.INSOMNIA_OUTCOMES)
),
--select top 1000 * from lab_event;
lab_occur as (
select p.PATIENT_NUM
      ,datediff(day,p.INSOMNIA_CONTROL_INDEX_DATE,le.LAB_Date) as DAYS_INSOMNIA_LAB
	  ,LOINC_CODE
	  ,LAB_NAME
	  ,LAB_VALUE as LAB_VALUE_1YR_PRIOR_INSOMNIA
from S19.dbo.INSOMNIA_OUTCOMES p
left join lab_event le on p.PATIENT_NUM = le.PATIENT_NUM 
where datediff(day,p.INSOMNIA_CONTROL_INDEX_DATE,le.LAB_Date)<0 and datediff(day,p.INSOMNIA_CONTROL_INDEX_DATE,le.LAB_Date)>=-365 and LAB_VALUE IS NOT NULL
)
select distinct *
into S19.dbo.INSOMNIA_ONLY_LABS_1YR_PRIOR
from lab_occur;


--drop table S19.dbo.INSOMNIA_ONLY_LABS_1YR_PRIOR;
select top 100 * from S19.dbo.INSOMNIA_ONLY_LABS_1YR_PRIOR;
select count(*) from S19.dbo.INSOMNIA_ONLY_LABS_1YR_PRIOR;  -- 1,106,653 SDH measurements
select count(distinct PATIENT_NUM) from S19.dbo.INSOMNIA_ONLY_LABS_1YR_PRIOR;  -- 104,448 patients






-- Explore concepts
select * from S19.dbo.ConceptCounts
order by N_Conpcets DESC;

-- Exploring specific LOINC
select --top 100
	*
from FellowsSample.common.I2B2
where C_BASECODE LIKE 'LOINC%';


with Lab_concepts as (
select distinct
	C_BASECODE as LOINC,
	C_NAME as Lab_Name
from FellowsSample.common.I2B2
where C_BASECODE LIKE 'LOINC%'
)
select *
from Lab_concepts; -- 79,346 concepts


select  CONCEPT_CD, count(CONCEPT_CD) as N  from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD LIKE 'LOINC%' 
group by CONCEPT_CD
order by N DESC

