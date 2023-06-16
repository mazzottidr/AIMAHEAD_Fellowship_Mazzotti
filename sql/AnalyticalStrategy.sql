-- Analytical Strategy:

-- 1. Create OSA case-control definition
-- DONE  OSA cases: at least 1 year prior to OSA index date
-- DONE OSA controls: 1 year since first encounter; index data will be that year (could consider prescription time matching)

-- DONE For diagnosis, take all ICD codes, map to phecodes (will have to import phecodes to SQL)
-- Will do in R: identify positivity of each phecode at index date

-- For SDH (DONE), labs, medications, PRO and vitals, take the most recent SDH prior to index date, assuming it happened in the prior year. Can be long format for conversion to wide in R.

-- DONE Create patient level dataset for all SDH (including the ones on PATIENT_DIMENTON_Z) for LCA.

-- DONE 3. For both OSA and insomnia, identify cases that had incident event of MACE within 5-years DONE

-- 4. Import into R and Sage Maker for analysis, per HD LCA cluster


-- PROGRESS and tables to likely bring to R

-- Complete cohort with annotated OSA and Insomnia Status
select top 1000 * from S19.dbo.Pat_OSA_INS_Index_Included_Demo_SDOH;
select count(*) from S19.dbo.Pat_OSA_INS_Index_Included_Demo_SDOH; -- N=1,683,999

-- Encounter level SDOH status at OSA index in the long format
select top 1000 * from S19.dbo.EncLevel_SDOH_OSA_long;
select count(*) from S19.dbo.EncLevel_SDOH_OSA_long;

-- Encounter level SDOH status at INSOMNIA index in the long format
select top 1000 * from S19.dbo.EncLevel_SDOH_INSOMNIA_long;
select count(*) from S19.dbo.EncLevel_SDOH_INSOMNIA_long;

-- Diagnosis mapped to phecodes in complete cohort (long format)
select top 1000 * from S19.dbo.ICD_Phecode_Included;
select count(*) from S19.dbo.ICD_Phecode_Included; -- 105475045
select count(distinct PATIENT_NUM) from S19.dbo.ICD_Phecode_Included; -- 1670021

-- Time to event information of outcomes and comorbidities relative to OSA
select top 1000 * from S19.dbo.OSA_OUTCOMES;
select count(*) from S19.dbo.OSA_OUTCOMES;
select  count(distinct PATIENT_NUM) from S19.dbo.OSA_OUTCOMES;

-- Time to event information of outcomes and comorbidities relative to INSOMNIA
select top 1000 * from S19.dbo.INSOMNIA_OUTCOMES;
select count(*) from S19.dbo.INSOMNIA_OUTCOMES;
select  count(distinct PATIENT_NUM) from S19.dbo.INSOMNIA_OUTCOMES;

-- OSA cohort with at least 5 years of enrollment
select top 1000 * from S19.dbo.OSA_COMPLETE_5YR_COHORT;
select count(*) from S19.dbo.OSA_COMPLETE_5YR_COHORT; -- N=5,995

-- INSOMNIA cohort with at least 5 years of enrollment
select top 1000 * from S19.dbo.INSOMNIA_COMPLETE_5YR_COHORT;
select count(*) from S19.dbo.INSOMNIA_COMPLETE_5YR_COHORT; -- N=15,294

-- Encounter level Laboratory value averages (year prior) at OSA index in the long format
-- Only for 5 year cohort
-- TODO

-- Encounter level Laboratory value averages (year prior) at INSOMNIA index in the long format
-- Only for 5 year cohort
-- TODO

-- Encounter level medication status (year prior) at OSA index in the long format
-- Only for 5 year cohort
-- TODO

-- Encounter level medication status (year prior) at INSOMNIA index in the long format
-- Only for 5 year cohort
-- TODO

-- Encounter level PRO status (year prior) at OSA index in the long format
-- Only for 5 year cohort
-- TODO

-- Encounter level PRO status (year prior) at INSOMNIA index in the long format
-- Only for 5 year cohort
-- TODO

-- Encounter level Vitals value averages (year prior) at OSA index in the long format
-- Only for 5 year cohort
-- TODO

-- Encounter level Vitals value averages (year prior) at INSOMNIA index in the long format
-- Only for 5 year cohort
-- TODO
