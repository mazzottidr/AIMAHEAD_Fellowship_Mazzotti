-- AIM-AHEAD document:
--https://docs.google.com/document/d/1cTt5mY4f9rRTwq3yjDmCV1Xt11knDcqCoDPwLrJo-yE/edit

-- 2/24/2023
-- Exploring data
select top 100 * from FellowsSample.S19.OBSERVATION_FACT; -- main table with all clinical observations

select top 100 * from FellowsSample.common.CONCEPT_DIMENSION; --hierarchy of concepts

select top 100 * from FellowsSample.common.I2B2; --  list of the concept codes: c_basecode is foreing key to concept_cd

select top 100 * from FellowsSample.S19.PATIENT_DIMENSION;

select top 100 * from FellowsSample.S19.VISIT_DIMENSION;


-- I noticed that I did not specify in the Data Worksheet Patient Zip codes. Email was sent to the team on 2/24/2023 to determine whether they could be added to my views.
select top 100 * from FellowsSample.S19.ZCTA_CVS;
select count(*) from FellowsSample.S19.ZCTA_CVS;
select top 100 ZIP_CD from FellowsSample.S19.PATIENT_DIMENSION;

-- Tetsing some basic query performances
-- Query below took 20 seconds
select ENC_TYPE, count(ENC_TYPE) from FellowsSample.S19.VISIT_DIMENSION
group by ENC_TYPE;


-- Exploring concepts (6 seconds). There are 1,148,888 unique concepts
select count(distinct c_basecode) from FellowsSample.common.I2B2;

-- Getting count of all different concepts and categories, storing as a table in S19 database
with temp1 as 
(
	select 
		C_BASECODE,
		REVERSE(PARSENAME(REPLACE(REVERSE(C_BASECODE), ':', '.'), 1)) AS Concept
	from FellowsSample.common.I2B2
),
temp2 as
(
select
	Concept,
	count(Concept) as N_Conpcets
from temp1
group by Concept
)
select * into S19.dbo.ConceptCounts from temp2
order by N_Conpcets DESC;
--where N_Conpcets>1;


-- Exploring specific ones - Demographics (age at visit, State, Race, Gender Identity, FPL, Marital Status, Homeless, Sexual Orientation, Hispanic
select
	C_FULLNAME,
	C_BASECODE,
	C_NAME
from FellowsSample.common.I2B2
where C_BASECODE LIKE 'DEM%';

-- Exploring specific ones - PRO
select
	C_FULLNAME,
	C_BASECODE,
	C_NAME
from FellowsSample.common.I2B2
where C_BASECODE LIKE 'PRO%';

-- Exploring specific ones: ADV - Type of providers / practices / departments?
select
	C_FULLNAME,
	C_BASECODE,
	C_NAME
from FellowsSample.common.I2B2
where C_BASECODE LIKE 'ADV%';

-- Exploring specific ones VANDF - Medication class
select
	C_FULLNAME,
	C_BASECODE,
	C_NAME
from FellowsSample.common.I2B2
where C_BASECODE LIKE 'VANDF%';

-- Exploring specific ones SDH - Social determinants of health. This may be used for HD clusters in those non-missing
select
	C_FULLNAME,
	C_BASECODE,
	C_NAME
from FellowsSample.common.I2B2
where C_BASECODE LIKE 'SDH%';

-- Exploring specific ones CVX - Vaccinces, immunization
select
	C_FULLNAME,
	C_BASECODE,
	C_NAME
from FellowsSample.common.I2B2
where C_BASECODE LIKE 'CVX%';

-- Exploring specific ones PRO - Patient Reported Outcomes (AUDIT, PHQ2, DAST, PHQ9)
select
	C_FULLNAME,
	C_BASECODE,
	C_NAME
from FellowsSample.common.I2B2
where C_BASECODE LIKE 'PRO%';

-- Exploring specific ones VIT - Vitals (Smoking, weight, height, BMI, BP, Tobacco)
select
	C_FULLNAME,
	C_BASECODE,
	C_NAME
from FellowsSample.common.I2B2
where C_BASECODE LIKE 'VIT%';

select * from S19.dbo.ConceptCounts
order by N_Conpcets DESC;
