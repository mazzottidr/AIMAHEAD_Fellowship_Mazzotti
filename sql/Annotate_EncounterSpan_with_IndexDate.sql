-- Add OSA index date and Insomnia index date to encounter Span table and create subset meeting eligibility (at least one year prior to OSA, or at least one year ever).

select top 100 * from S19.dbo.EncounterSpan;


-- ED only for creating a cohort of newly diagnosed
select top 100 * from S19.dbo.OSA_only_ED;
select top 100 * from S19.dbo.Insomnia_ED_only_CompPheno;


drop table S19.dbo.Pat_OSA_INS_Index_ALL;

select
	es.*,
	case
		when es.time_span_days >= 365 and N_encounters > 3 then 1 -- indicate whether they have at least 356 days and 3 encounters
		else  0
	end as has_at_least_1yr_and_3enc,
	
	-- OSA
	case 
		when osa.earliest_OSA_date IS NOT NULL then osa.earliest_OSA_date -- Define OSA index date as date of first OSA (for cases) or 1 year since first encounter (for controls)
		else dateadd(year, 1, es.earliest_encounter_date)
	end as OSA_CONTROL_INDEX_DATE, -- also consider matching on days_firstenc_to_OSA
	case 
		when osa.N_OSA_codes_anydate IS NOT NULL then osa.N_OSA_codes_anydate -- Get number of codes
		else 0
	end as N_OSA_codes,
	case
		when osa.OSA_ComputablePhenotype IS NOT NULL then osa.OSA_ComputablePhenotype -- Determine Computable Phenotype for OSA
		when osa.OSA_ComputablePhenotype IS NULL then 0
	end as OSA_ED_only_ComputablePhenotype,
	datediff(day, es.earliest_encounter_date, osa.earliest_OSA_date) as days_firstenc_to_osa,
	case
		when datediff(day, es.earliest_encounter_date, osa.earliest_OSA_date)>=365 then 1
		else 0
	end as has_1yr_before_osa,
		
	-- Insomnia
	case 
		when ins.earliest_Insomnia_date IS NOT NULL then ins.earliest_Insomnia_date
		else dateadd(year, 1, es.earliest_encounter_date)
	end as INSOMNIA_CONTROL_INDEX_DATE,
	case 
		when ins.N_Insomnia_codes_diffdates IS NOT NULL then ins.N_Insomnia_codes_diffdates
		else 0
	end as N_Insomnia_codes,
	case
		when ins.Insomnia_ED_only_ComputablePhenotype IS NOT NULL then ins.Insomnia_ED_only_ComputablePhenotype
		when ins.Insomnia_ED_only_ComputablePhenotype IS NULL then 0
	end as Insomnia_ED_only_ComputablePhenotype,
	datediff(day, es.earliest_encounter_date, ins.earliest_Insomnia_date) as days_firstenc_to_insomnia,
	case
		when datediff(day, es.earliest_encounter_date, ins.earliest_Insomnia_date)>=365 then 1
		else 0
	end as has_1yr_before_insomnia
	
into S19.dbo.Pat_OSA_INS_Index_ALL
from S19.dbo.EncounterSpan es
left join S19.dbo.OSA_only_ED osa on es.PATIENT_NUM = osa.PATIENT_NUM
left join S19.dbo.Insomnia_ED_only_CompPheno ins on es.PATIENT_NUM = ins.PATIENT_NUM;


select top 100 * from S19.dbo.Pat_OSA_INS_Index_ALL;

drop table S19.dbo.Pat_OSA_INS_Index_Included;

select 
	*,
	case
		when datediff(day, OSA_CONTROL_INDEX_DATE, latest_encounter_date) >= 1825  then 1
		else 0
	end as has_5yr_from_osa_index,
	case
		when datediff(day, INSOMNIA_CONTROL_INDEX_DATE, latest_encounter_date) >= 1825  then 1
		else 0
	end as has_5yr_from_insomnia_index

into S19.dbo.Pat_OSA_INS_Index_Included
from S19.dbo.Pat_OSA_INS_Index_ALL
where has_at_least_1yr_and_3enc = 1;

select top 100 * from Pat_OSA_INS_Index_Included;

select
	PATIENT_NUM,
	earliest_encounter_date,
	latest_encounter_date,
	N_encounters,
	time_span_days,
	OSA_CONTROL_INDEX_DATE,
	N_OSA_codes,
	days_firstenc_to_osa,
	datediff(day, OSA_CONTROL_INDEX_DATE, latest_encounter_date) as days_osa_index_to_lastenc
into S19.dbo.OSA_COMPLETE_5YR_COHORT
from S19.dbo.Pat_OSA_INS_Index_Included
where has_1yr_before_osa = 1 and has_5yr_from_osa_index = 1;

select
	PATIENT_NUM,
	earliest_encounter_date,
	latest_encounter_date,
	N_encounters,
	time_span_days,
	INSOMNIA_CONTROL_INDEX_DATE,
	N_Insomnia_codes,
	days_firstenc_to_insomnia,
	datediff(day, INSOMNIA_CONTROL_INDEX_DATE, latest_encounter_date) as days_insomnia_index_to_lastenc
into S19.dbo.INSOMNIA_COMPLETE_5YR_COHORT
from S19.dbo.Pat_OSA_INS_Index_Included
where has_1yr_before_insomnia = 1 and has_5yr_from_insomnia_index = 1;