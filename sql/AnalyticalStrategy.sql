-- Analytical Strategy:

-- 1. Create OSA case-control definition
-- OSA cases: at least 1 year prior to OSA index date
-- OSA controls: 1 year since first encounter; index data will be that year (could consider prescription time matching)

-- Create a subset of obs_fact table that captures all observations prior to and at index date

-- For diagnosis, take all ICD codes, map to phecodes (will have to import phecodes to SQL) and identify positivity of each phecode at index date

-- For SDH, labs, medications, PRO and vitals, take the most recent SDH prior to index date, assuming it happened in the prior year. Can be long format for conversion to wide in R.

-- Create patient level dataset for all SDH (including the ones on PATIENT_DIMENTON_Z) for LCA.

-- 2. Repeat for Insomnia

-- 3. For both OSA and insomnia, identify cases that had incident event of MACE within 5-years

-- 4. Import into R and Sage Maker for analysis, per HD LCA cluster
