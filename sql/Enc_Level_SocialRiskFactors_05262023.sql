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


select top 100 * from FellowsSample.common.I2B2
where C_BASECODE LIKE 'SDH:ADV0246';

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











select top 100
	o.PATIENT_NUM
	,o.QUANTITY_NUM as SDOH_QUANTITY_NUM
	,o.START_DATE as SDOH_Date
	,'Any_SDOH' as SDOH
	,o.CONCEPT_CD as SDOH_CONCEPT_CD
	,c.C_FULLNAME as SDOH_FULLNAME
	,c.C_NAME as SDOH_NAME
	,c.C_COLUMNNAME as SDOH_COLUMNNAME
	,c.C_DIMCODE as SDOH_DIMCODE
from FellowsSample.S19.OBSERVATION_FACT o
left join FellowsSample.common.I2B2 c on o.CONCEPT_CD = c.C_BASECODE
where CONCEPT_CD IN ('SDH:ADV0045',
	'SDH:ADV0051',
	'SDH:ADV0052',
	'SDH:ADV0055',
	'SDH:ADV0057',
	'SDH:ADV0058',
	'SDH:ADV0070',
	'SDH:ADV0073',
	'SDH:ADV0074',
	'SDH:ADV0075',
	'SDH:ADV0076',
	'SDH:ADV0088',
	'SDH:ADV0089',
	'SDH:ADV0096',
	'SDH:ADV0097',
	'SDH:ADV0099',
	'SDH:ADV0121',
	'SDH:ADV0123',
	'SDH:ADV0124',
	'SDH:ADV0125',
	'SDH:ADV0208',
	'SDH:ADV0209',
	'SDH:ADV0210',
	'SDH:ADV0219',
	'SDH:ADV0222',
	'SDH:ADV0223',
	'SDH:ADV0224',
	'SDH:ADV0230',
	'SDH:ADV0245',
	'SDH:ADV0247',
	'SDH:ADV0248',
	'SDH:ADV0042',
	'SDH:ADV0043',
	'SDH:ADV0044',
	'SDH:ADV0063',
	'SDH:ADV0065',
	'SDH:ADV0066',
	'SDH:ADV0068',
	'SDH:ADV0081',
	'SDH:ADV0082',
	'SDH:ADV0083',
	'SDH:ADV0084',
	'SDH:ADV0090',
	'SDH:ADV0091',
	'SDH:ADV0102',
	'SDH:ADV0103',
	'SDH:ADV0104',
	'SDH:ADV0106',
	'SDH:ADV0114',
	'SDH:ADV0115',
	'SDH:ADV0116',
	'SDH:ADV0117',
	'SDH:ADV0118',
	'SDH:ADV0200',
	'SDH:ADV0201',
	'SDH:ADV0203',
	'SDH:ADV0213',
	'SDH:ADV0227',
	'SDH:ADV0228',
	'SDH:ADV0229',
	'SDH:ADV0231',
	'SDH:ADV0232',
	'SDH:ADV0235',
	'SDH:ADV0236',
	'SDH:ADV0237',
	'SDH:ADV0240',
	'SDH:ADV0243',
	'SDH:ADV0250',
	'SDH:ADV0251',
	'SDH:ADV0262',
	'SDH:ADV0263',
	'SDH:ADV0264',
	'SDH:ADV0265',
	'SDH:ADV0268',
	'SDH:ADV0269',
	'SDH:ADV0040',
	'SDH:ADV0041',
	'SDH:ADV0047',
	'SDH:ADV0050',
	'SDH:ADV0054',
	'SDH:ADV0059',
	'SDH:ADV0060',
	'SDH:ADV0062',
	'SDH:ADV0064',
	'SDH:ADV0067',
	'SDH:ADV0069',
	'SDH:ADV0072',
	'SDH:ADV0077',
	'SDH:ADV0079',
	'SDH:ADV0080',
	'SDH:ADV0085',
	'SDH:ADV0087',
	'SDH:ADV0092',
	'SDH:ADV0094',
	'SDH:ADV0100',
	'SDH:ADV0107',
	'SDH:ADV0109',
	'SDH:ADV0111',
	'SDH:ADV0113',
	'SDH:ADV0202',
	'SDH:ADV0204',
	'SDH:ADV0206',
	'SDH:ADV0212',
	'SDH:ADV0214',
	'SDH:ADV0215',
	'SDH:ADV0217',
	'SDH:ADV0220',
	'SDH:ADV0225',
	'SDH:ADV0234',
	'SDH:ADV0238',
	'SDH:ADV0239',
	'SDH:ADV0242',
	'SDH:ADV0244',
	'SDH:ADV0249',
	'SDH:ADV0253',
	'SDH:ADV0255',
	'SDH:ADV0256',
	'SDH:ADV0258',
	'SDH:ADV0261',
	'SDH:ADV0266',
	'SDH:ADV0046',
	'SDH:ADV0048',
	'SDH:ADV0049',
	'SDH:ADV0053',
	'SDH:ADV0056',
	'SDH:ADV0061',
	'SDH:ADV0071',
	'SDH:ADV0078',
	'SDH:ADV0086',
	'SDH:ADV0093',
	'SDH:ADV0095',
	'SDH:ADV0098',
	'SDH:ADV0101',
	'SDH:ADV0108',
	'SDH:ADV0110',
	'SDH:ADV0112',
	'SDH:ADV0120',
	'SDH:ADV0122',
	'SDH:ADV0205',
	'SDH:ADV0207',
	'SDH:ADV0211',
	'SDH:ADV0216',
	'SDH:ADV0218',
	'SDH:ADV0221',
	'SDH:ADV0226',
	'SDH:ADV0233',
	'SDH:ADV0241',
	'SDH:ADV0246',
	'SDH:ADV0252',
	'SDH:ADV0254',
	'SDH:ADV0257',
	'SDH:ADV0259',
	'SDH:ADV0260',
	'SDH:ADV0267')
