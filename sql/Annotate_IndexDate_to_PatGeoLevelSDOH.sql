-- Annotate S19.dbo.Pat_OSA_INS_Index_Included with Geo-level SDOH

select top 100 * from S19.dbo.Pat_OSA_INS_Index_Included;

select top 100 * from S19.dbo.PATIENT_DIMENSION_Z;

select 
	pin.*,
	pdim.VITAL_STATUS_CD,
	pdim.BIRTH_DATE,
	pdim.DEATH_DATE,
	pdim.SEX_CD,
	pdim.LANGUAGE_CD,
	pdim.RACE_CD,
	pdim.MARITAL_STATUS_CD,
	pdim.ZIP_CD,
	pdim.CURRENT_FPL_CD,
	pdim.HISPANIC_CD,
	pdim.GENDER_CD,
	pdim.HOMELESS_CD,
	pdim.SEXORIENTATION_CD,
	pdim.MIGRANTSEASONAL_CD,
	pdim.RURAL_CD,
	pdim.STATE_CD,
	pdim.ACS_Unemployment,
	pdim.ACS_MedHHIncome,
	pdim.ACS_pctCollGrad,
	pdim.ACS_GINI,
	pdim.ACS_pctPoverty100
into S19.dbo.Pat_OSA_INS_Index_Included_Demo_SDOH
from S19.dbo.Pat_OSA_INS_Index_Included pin
left join S19.dbo.PATIENT_DIMENSION_Z pdim on pin.PATIENT_NUM = pdim.PATIENT_NUM;
