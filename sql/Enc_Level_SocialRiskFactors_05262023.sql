-- Create encounter level Social Risk factors

-- Explore concepts
select * from S19.dbo.ConceptCounts
order by N_Conpcets DESC;


-- Exploring specific ones SDH - Social determinants of health.
select
	*
from FellowsSample.common.I2B2
where C_BASECODE LIKE 'SDH:ADV0114';

select * from FellowsSample.common.I2B2
where C_BASECODE LIKE 'SDH%'
order by C_NAME;

select * from FellowsSample.common.I2B2
where C_BASECODE LIKE 'SDH%' and C_NAME = 'Total Score'
order by C_NAME;

select * from FellowsSample.common.CONCEPT_DIMENSION
where CONCEPT_CD LIKE 'SDH%' --and CONCEPT_CD = 'SDH:ADV0114'
order by NAME_CHAR;

select max(QUANTITY_NUM)
	--PATIENT_NUM,
	--ENCOUNTER_NUM,
	--START_DATE,
	--CONCEPT_CD,
	--TVAL_CHAR
from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD LIKE 'SDH:ADV0246';



--- Get counts for SDH:ADV0114
select count (distinct PATIENT_NUM) from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD LIKE 'SDH:ADV0114'; -- there are 34826 patients with any SDH:ADV0114

select count (distinct PATIENT_NUM) from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD = 'SDH:ADV0114' and QUANTITY_NUM = 0; -- there are 29822 patients with any SDH:ADV0114 QUANTITY_NUM = 0

select count (distinct PATIENT_NUM) from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD = 'SDH:ADV0114' and QUANTITY_NUM = 1; -- there are 8235 patients with any SDH:ADV0114 QUANTITY_NUM = 1

select top 100 * from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD LIKE 'SDH:ADV0114';


--- Get counts for SDH:ADV0210
select count (distinct PATIENT_NUM) from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD LIKE 'SDH:ADV0210'; -- there are 12 patients with any SDH:ADV0210

select top 100 * from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD LIKE 'SDH:ADV0210';

--- Get counts for SDH:ADV0214
select count (distinct PATIENT_NUM) from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD LIKE 'SDH:ADV0214'; -- there are 88 patients with any SDH:ADV0214

select top 100 * from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD LIKE 'SDH:ADV0214'
order by PATIENT_NUM;


--- Get counts for SDH:ADV0246
select count (distinct PATIENT_NUM) from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD LIKE 'SDH:ADV0246'; -- there are 3140 patients with any SDH:ADV0246

select top 100 * from FellowsSample.S19.OBSERVATION_FACT
where CONCEPT_CD LIKE 'SDH:ADV0246';


with SDH_concepts as (
select distinct C_BASECODE from FellowsSample.common.I2B2
where C_BASECODE LIKE 'SDH%'
)
select C_BASECODE as SDH
into #ControlTable
from SDH_concepts;

select * from #ControlTable;


declare @SDH as varchar(50)


while exists (select * from #ControlTable)
begin

    select @SDH = (select top 1 SDH
                       from #ControlTable                       )

    -- Do something with your TableID
	select top 10 * from FellowsSample.S19.OBSERVATION_FACT
	where CONCEPT_CD LIKE @SDH;

	delete #ControlTable
    where SDH = @SDH

end

--drop table #ControlTable
