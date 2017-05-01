
/***********************************************************************
 *  Program Name:	Assessment Compare - Live ALPAS
 *
 *  Purpose:		Compare two instances of assessment vintages 
					report all differences
 *
 *	Description:	User Managed Reports Description*/

/********Pathway to ALPAS**********************/
LIBNAME ALPAS ORACLE user=** password=***                  
 path=MILENET_P.MA.GOV.AB.CA schema=ALPAS;  /* P is Production       */ 
Run; 
/* user specified run time parameters */
%let asmntyear1 = 2015;
%let vintage1 = ALL; 
%let asmntyear2 = 2016;
%let vintage2 = ALL;
%let ptcode = ALL;
%let assessee = All;
%let TJ=MD_Bighorn;
%let TJID=382;
/* derived run time parameters */
%put &asmntyear1 &vintage1 &asmntyear2 &vintage2 &ptcode &assessee;
%global pvseq1max pvseq2max pt;
/*libname GIP "H:\GIP";*/
data _null_;
    call symput('RunDT',compress(put(today(),date9.)||'hms'||put(time(),TOD.),':'));
run;
%put &RunDT;

proc sql noprint;
/* SIMS data linking AEUB BA code, SIMS code, SIMS name */
    create table SIMSJoin as
        select p.COMP_CODE as AEUBcode Label = 'AEUBcode',
               p.STKHLDR_ID as SIMScode Label = 'SIMScode',
               c.STKHLDR_NAME as SIMSname Label = 'SIMSname'
        from ALPAS.ALGV_SIMS_STKHLDR_COMPCODE as p
        left join ALPAS.ALGV_SIMS_STKHLDR as c
		    on  p.STKHLDR_ID = c.STKHLDR_ID;
/* table linking AEUB BA code and SIMS name */
    create table EUBname
    as  select
        AEUBcode as start FORMAT = $CHAR5.,
        SIMSname as label FORMAT = $CHAR50.,
        ' ' as HLO format=$char1.,
        '$EUBname' as fmtname
    from SIMSJoin;
    insert into EUBname
        set start = ' ',
            label = 'Unknown',
            HLO = 'O',
            fmtname = '$EUBname';
/* table linking AEUB BA code and SIMS code */
    create table SIMScode as
        select AEUBcode as start FORMAT = $CHAR5.,
               SIMScode as label FORMAT = 8.,
               ' ' as hlo,
               '$SIMSco' as fmtname
        from SIMSJoin;
    insert into SIMScode
        set start = ' ',
            label = 99999,
            hlo = 'O',
            fmtname = '$SIMSco';
 /* table linking SIMS code and SIMS name */
    create table SIMSname as
        select  STKHLDR_ID as start FORMAT = 8.,
                STKHLDR_NAME as label FORMAT = $CHAR50.,
               ' ' as hlo,
               'SIMSname' as fmtname
        from Alpas.ALGV_SIMS_STKHLDR
        order by STKHLDR_ID;
    insert into SIMSname
        set start = .,
            label = 'Unknown',
            hlo = 'O',
            fmtname = 'SIMSname';
/* SIMS Stakeholder type*/
    create table SIMtype as
    select  STKHLDR_ID as start FORMAT = 8.,
            STKHLDR_TYPE_CODE as label FORMAT = $CHAR4.,
           ' ' as hlo,
           'SIMtype' as fmtname
from ALPAS.ALGV_SIMS_CURRENTSTKHLDR;
    insert into SIMtype
        set start = .,
            label = '9999',
            hlo = 'O',
            fmtname = 'SIMtype';
quit;
	/* Table linking ACC and Acc Description */ 
/* ACC  */
  proc sql noprint;
  create table ACCcode as
    select 
	   ACC_CODE as ACC label='ACC',  
	   ACC_ASMNT_CLASSIFICATION_NAME as ACC_DESC LABEL='ACC_DESC'
       from ALPAS.ALGV_ct_asmnt_classification 
       where ACC_AY_YEAR = &asmntyear2
      order by ACC_CODE ;
	/* table linking AEUB BA code and SIMS name */
    create table ACCDesc
    as  select
        ACC as start FORMAT = $CHAR5.,
        ACC_DESC as label FORMAT = $CHAR100.,
        ' ' as HLO format=$char1.,
        '$ACCDesc' as fmtname
    from ACCcode;
    insert into ACCDesc
        set start = ' ',
            label = 'Unknown',
            HLO = 'O',
            fmtname = '$ACCDesc';
    quit;
proc format cntlin=EUBName;quit;
proc format cntlin=SIMScode;quit;
proc format cntlin=SIMSname;quit;
proc format cntlin=SIMtype;quit;
proc format cntlin=ACCDesc;quit;
PROC FORMAT;
/* Max sequence vs seq Map */
    VALUE MaxSeq   
		0 - <1000 = 0 /*SOURCE*/
		1000 - <1900 = 1899 /*ANNUAL*/
		1900 - <2900 = 2899 /*A1*/
		2900 - <3900 = 3899 /*A2*/
		3900 - <4900 = 4899 /*A3*/
		4900 - <5900 = 5899 /*A4*/
		5900 - <6900 = 6899 /*A5*/
		6900 - <7900 = 7899 /*A6*/
		7900 - <8900 = 8899 /*A7*/
		8900 - <9900 = 9899 /*A8*/
		9900 - <10900 = 10899 /*A9*/
		10900 - <11900 = 11899 /*A10*/
        Other = 1000000; /*max*/
run;
PROC FORMAT; 
VALUE $ACC_GROUP_DESC 
'01PL'   = 'PIPELINES'	
'02WL'   = 'WELLS'
'03GEN'  = 'POWER GENERATION'
'04SST'  = 'SUB-STATION_LPAUIDS' 
'05ESL'  = 'Street Lighting'
'06ET'   = 'Electrical Transmission' 
'07EDS'  = 'Electrical Distribution' 
'08FIBR' = 'FIBER OPTICS'
'09COPR' = 'COPPER WIRE'
'10TWR'  = 'CELL TOWER'
'11CELL' = 'CELL SITE' 
'12COAX' = 'COAX'
OTHER  = 'UNKNOWN'; 

VALUE $ACC_GROUP_UNIT 
'01PL'   = 'KILOMETERS' 
'02WL'   = 'COUNT OF WELLS'
'03GEN'  = 'COUNT OF POWER PLANTS'
'04SST'  = 'COUNT_OF_SUB-STATIONS_LPAUIDS'
'05ESL'  = 'COUNT OF POLES'
'06ET'   = 'KILOMETERS'
'07EDS'  = 'COUNT OF HOOKUPS/DROPS' 
'08FIBR' = 'KILOMETERS' 
'09COPR' = 'KILOMETERS'
'10TWR'  = 'COUNT OF TOWERS'	
'11CELL' = 'COUNT OF CELL SITES'
'12COAX'='KILOMETERS'
  OTHER  = 'UNKNOWN'; 
RUN; 
QUIT; 
/* Well Status Fluid Table */ 
PROC FORMAT; 
VALUE $WS_Fluid_Desc 
'01'   = 'CRUDE OIL'
'02'   = 'GAS'	
'03'   = 'OIL'	
'04'   = 'GAS-WATER'
'05'   = 'UNDESIGNATED'
'06'   = 'GAS-WATER'
'07'   = 'BRINE'
'08'   = 'WASTE'	
'09'   = 'SOLVENT'	
'10'   = 'STEAM'	
'11'   = 'AIR'	
'12'   = 'SYNTHETIC CRUDE'
'13'   = 'CARBON DIOXIDE'	
'14'   = 'POLYMER'	
'15'   = 'NITROGEN'	
'16'   = 'LIQUID PETROLEUM GAS'	
'17'   = 'CRUDE BITUMEN'
'18'   = 'CONDENSATE'	
'19'   = 'OXYGEN'	
'50'   = 'ANYHYDROUS AMMONIA'	
'51'   = 'CRUDE OIL/BITUMEN'	
'52'   = 'NAPTHA'	
OTHER  = 'UNKNOWN'; 

/* Well Status Mode Table */ 
PROC FORMAT; 
VALUE $WS_Mode_Desc 
'01'   = 'SUSPENDED'
'02'   = 'ABANDONED'	
'03'   = 'ABANDONED ZONE'	
'04'   = 'ABANDONED AND RE-ENTERED'
'05'   = 'CAPPED'
'06'   = 'POTENTIAL'
'07'   = 'DRILLED AND CASED'
'08'   = 'JUNKED AND ABANDONED'	
'09'   = 'CLOSED'	
'10'   = 'FLOWING'	
'11'   = 'PUMPING'	
'12'   = 'GAS LIFT'
'13'   = 'TESTING'	
'14'   = 'ABANDONED AND WHIPSTOCKED'	
OTHER  = 'UNKNOWN'; 
RUN; 
QUIT; 

%MACRO Property;
	%if %upcase(&ptcode) = ALL %then %do;
		%let pt = 'WL','PL','GDP','CBL','TEL','ELE','EPG';
		%put Ptcode was ALL: &asmntyear1 &vintage1 &ptcode &pt;
	%end;
	%else %do;
	    %let pt = %sysfunc(dequote("'&ptcode'"));
		%put Ptcode WAS NOT ALL: &asmntyear1 &vintage1 &ptcode &pt;
	%end;
%MEND Property;
%Property;
%put 1: &asmntyear1 &vintage1;
%put 1: &ptcode &pt;
%put 2: &asmntyear2 &vintage2;

%MACRO Vintage;
	%if %upcase(&vintage1) = ALL %then %do;
		proc sql noprint;
		    select max(PV_SEQUENCE_ORDER)
		    into :pvseq1max
		    from ALPAS.ALGV_CT_PUBLICATION_VINTAGE as l
		    where PV_AY_ASMNT_YEAR = &asmntyear1;
		quit;
		%put Vintage1 is ALL: &asmntyear1 &vintage1 &pvseq1max;
	%end;
	%else %do; 
		proc sql noprint;
		    select put(PV_SEQUENCE_ORDER,MaxSeq.)
		    into :pvseq1max
		    from ALPAS.ALGV_CT_PUBLICATION_VINTAGE as l
		    where PV_AY_ASMNT_YEAR = &asmntyear1
		        and PV_VINTAGE_CODE = UPCASE("&vintage1");
		quit;
		%put Vintage1 is NOT ALL: &asmntyear1 &vintage1 &pvseq1max;
	%end;
	%if %upcase(&vintage2) = ALL %then %do;
		proc sql noprint;
		    select max(PV_SEQUENCE_ORDER)
		    into :pvseq2max
		    from ALPAS.ALGV_CT_PUBLICATION_VINTAGE as l
		    where PV_AY_ASMNT_YEAR = &asmntyear2;
		quit;
		%put Vintage2 is ALL: &asmntyear2 &vintage2 &pvseq2max;
	%end;
	%else %do; 
		proc sql noprint;
		    select put(PV_SEQUENCE_ORDER,MaxSeq.)
		    into :pvseq2max
		    from ALPAS.ALGV_CT_PUBLICATION_VINTAGE as l
		    where PV_AY_ASMNT_YEAR = &asmntyear2
		        and PV_VINTAGE_CODE = UPCASE("&vintage2");
		quit;
		%put Vintage2 is NOT ALL: &asmntyear2 &vintage2 &pvseq2max;
	%end;
%MEND Vintage;
%Vintage;
%put 1: &asmntyear1 &vintage1 &pvseq1max;
%put 2: &asmntyear2 &vintage2 &pvseq2max;

/* vintage list */
proc sql noprint;
    select l.PV_ID
    into :pvid1 separated by ','
    from Alpas.ALGV_CT_PUBLICATION_VINTAGE as l
    join Alpas.ALGV_CT_PUB_VINTAGE_TYPE as r
	    on l.PV_PVT_ID = r.PVT_ID
    where l.PV_AY_ASMNT_YEAR = &asmntyear1
		and l.PV_SEQUENCE_ORDER le &pvseq1max
        and UPCASE(r.PVT_VINTAGE_TYPE_CODE)
            in (/*'SOURCE',*/'ANNUAL','AMEND','TRANSFER','ERRATA','DECISION');

    select l.PV_ID
    into :pvid2 separated by ','
    from Alpas.ALGV_CT_PUBLICATION_VINTAGE as l
    join Alpas.ALGV_CT_PUB_VINTAGE_TYPE as r
	    on l.PV_PVT_ID = r.PVT_ID
        and UPCASE(r.PVT_VINTAGE_TYPE_CODE)
            in ('SOURCE','ANNUAL','AMEND','TRANSFER','ERRATA','DECISION')
    where l.PV_AY_ASMNT_YEAR = &asmntyear2
		and l.PV_SEQUENCE_ORDER le &pvseq2max;
quit;
%put 1: &asmntyear1 &pvid1;
%put 2: &asmntyear2 &pvid2;

proc sql noprint;
    select PT_ID
    into :ptid1 separated by ','
    from ALPAS.ALGV_CT_PROP_TYPES
    where PT_AY_YEAR = &asmntyear1 and PT_CODE in (&pt);

    select PT_ID
    into :ptid2 separated by ','
    from ALPAS.ALGV_CT_PROP_TYPES
    where PT_AY_YEAR = &asmntyear2 and PT_CODE in (&pt);
quit;
%put 1: &asmntyear1 &ptcode &ptid1;
%put 2: &asmntyear2 &ptcode &ptid2;

/*   Assessment runs   */
proc sql noprint;
    create table AmId1 as select
    l.AM_PT_ID, r.PV_SEQUENCE_ORDER, l.AM_ASMNT_RUN_STATUS, l.AM_ID, l.AM_PV_ID
    from ALPAS.ALGV_ASMNT_METADATA as l
    join ALPAS.ALGV_CT_PUBLICATION_VINTAGE as r on r.PV_ID  = l.AM_PV_ID
    where l.AM_AY_ASMNT_YEAR = &asmntyear1
        and UPCASE(l.AM_ASMNT_RUN_STATUS) in ('DECLARED','TRIAL')
        and l.AM_PT_ID in (&ptid1) /* OK */
        and l.AM_PV_ID in (&pvid1) /* OK */
    order by l.AM_PT_ID, r.PV_SEQUENCE_ORDER desc, 
		l.AM_ASMNT_RUN_STATUS, l.AM_ID desc;

    create table AmId2 as select
    l.AM_PT_ID, r.PV_SEQUENCE_ORDER, l.AM_ASMNT_RUN_STATUS, l.AM_ID, l.AM_PV_ID
    from ALPAS.ALGV_ASMNT_METADATA as l
    join ALPAS.ALGV_CT_PUBLICATION_VINTAGE as r on r.PV_ID  = l.AM_PV_ID
    where l.AM_AY_ASMNT_YEAR = &asmntyear2
        and UPCASE(l.AM_ASMNT_RUN_STATUS) in ('DECLARED','TRIAL')
        and l.AM_PT_ID in (&ptid2) /* OK */
        and l.AM_PV_ID in (&pvid2) /* OK */
    order by l.AM_PT_ID, r.PV_SEQUENCE_ORDER desc, 
		l.AM_ASMNT_RUN_STATUS, l.AM_ID desc;
quit;

/* Select the runs of interest based on sort sequence*/
data VintageAm1;
set AmId1;
by AM_PT_ID descending PV_SEQUENCE_ORDER;
if first.PV_SEQUENCE_ORDER = 1;
run;
data VintageAm2;
set AmId2;
by AM_PT_ID descending PV_SEQUENCE_ORDER /*AM_ASMNT_RUN_STATUS descending AM_ID*/;
if first.PV_SEQUENCE_ORDER = 1;
run;

/* Asmnt runs for old & new */
proc sql noprint;
    select AM_ID
    into :amlist1 separated by ','
    from work.VintageAm1;

    select AM_ID
    into :amlist2 separated by ','
    from work.VintageAm2;
quit;
%put 1: &amlist1;
%put 2: &amlist2;

%MACRO Model;
%if &ptcode = CBL or &ptcode = TEL or &ptcode = ELE 
	or &ptcode = EPG or &ptcode = GDP or %upcase(&ptcode) = ALL 
	%then %do;
	proc sql noprint;
	    create table Work.SrOtPropAsmnt1 as select
	        p.SOP_PT_CODE as PtCode label='PtCode',
	        p.SOP_AY_ASMNT_YEAR as AsmntYr label='AsmntYr',
	        VINT.PV_VINTAGE_CODE as AsmntVint label='AsmntVint',
			p.SOP_LPAU_PROPERTY_ID as LpauID label='LpauID',
	        VINT.PV_SEQUENCE_ORDER,
	        p.SOP_SIMS_ASSESSEE_ID as AsseId label='AsseId',
			p.SOP_SIMS_TJ_STKHLDR_ID as TaxJurid   label = 'TaxJurId',
			c.SOC_SIMS_AJ_STKHLDR_ID as AsmntJurID label='AsmntJurID',
			a.SOPA_SCHED_A_ACC as Acc label='Acc',
	        put(p.SOP_SIMS_ASSESSEE_ID, SIMSname.) as AsseName,
	        p.SOP_SIMS_TJ_STKHLDR_ID as TJcode label = 'TJcode',
	        put(p.SOP_SIMS_TJ_STKHLDR_ID, SIMSname.) as TJName label = 'TJName',
	        put(p.SOP_SIMS_TJ_STKHLDR_ID, SIMtype.) as TJtype label = 'TJtype',
			p.SOP_PROPERTY_QUANTITY  as PROP_QTY   LABEL='PROP_QTY',
			p.SOP_EATL_ALLOC_PERCENT_T as PctT label='PctT',
			p.SOP_EATL_ALLOC_PERCENT_E as PctE label='PctE',
			p.SOP_EATL_ALLOC_PERCENT_G as PctG label='PctG',
			a.SOPA_AM_ID as AmId label='AmId',			
			a.SOPA_SCHED_A_BASE_COST as SchaBaseCost label='SchaBaseCost',
			a.SOPA_SCHED_B_FACTOR as SchbFctr label='SchbFctr',
			a.SOPA_SCHED_C_FACTOR as SchcFctr label='SchcFctr',
			a.SOPA_SCHED_D_FACTOR as SchdFctr label='SchdFctr',
			a.SOPA_SCHED_D_CODE as SOPA_SCHED_D_CODE label="SOPA_SCHED_D_CODE",
			a.SOPA_EATL_PROP_DESC_CODE as SOPA_EATL_PROP_DESC_CODE label="SOPA_EATL_PROP_DESC_CODE",
			a.SOPA_SCHED_A_QTY as SOPA_SCHED_A_QTY label="SOPA_SCHED_A_QTY",
	        a.SOPA_ASSESSMENT_VALUE as Asmnt label='Asmnt',
			a.SOPA_EATL_ALLOCATED_VALUE_T as AsmntT label='AsmntT',
			a.SOPA_EATL_ALLOCATED_VALUE_E as AsmntE label='AsmntE',
			a.SOPA_EATL_ALLOCATED_VALUE_G as AsmntG label='AsmntG',
			p.SOP_LINEAR_PROP_FLAG    as InvNalFlag        label='InvNalFlag',
	        p.SOP_COMPANY_REF_ID      as company_ref_id label='company_ref_id',
	        p.SOP_REPORTED_PROPERTY_NAME as REPORTED_PROPERTY_NAME label='REPORTED_PROPERTY_NAME',
			p.SOP_UTILIZATION_PERCENT as SOP_UTILIZATION_PERCENT label="SOP_UTILIZATION_PERCENT",
			p.SOP_REPORTED_PROPERTY_NAME as REPORTED_PROPERTY_NAME label='REPORTED_PROPERTY_NAME',
			p.SOP_REPORTED_PROPERTY_DESC as SOP_REPORTED_PROPERTY_DESC label='SOP_REPORTED_PROPERTY_DESC',
			p.SOP_ATS_LSD_FROM as SOP_ATS_LSD_FROM label="SOP_ATS_LSD_FROM",
			p.SOP_ATS_QTR_SECTION_FROM as SOP_ATS_QTR_SECTION_FROM label="SOP_ATS_QTR_SECTION_FROM",
			p.SOP_ATS_SECTION_FROM as SOP_ATS_SECTION_FROM label="SOP_ATS_SECTION_FROM",
			p.SOP_ATS_TOWNSHIP_FROM as SOP_ATS_TOWNSHIP_FROM label="SOP_ATS_TOWNSHIP_FROM",
			p.SOP_ATS_RANGE_FROM as SOP_ATS_RANGE_FROM label="SOP_ATS_RANGE_FROM",
			p.SOP_ATS_MERIDIAN_FROM as SOP_ATS_MERIDIAN_FROM label="SOP_ATS_MERIDIAN_FROM",
			p.SOP_ATS_LSD_TO as SOP_ATS_LSD_TO label="SOP_ATS_LSD_TO",
			p.SOP_ATS_QTR_SECTION_TO as SOP_ATS_QTR_SECTION_TO label="SOP_ATS_QTR_SECTION_TO",
			p.SOP_ATS_SECTION_TO as SOP_ATS_SECTION_TO label="SOP_ATS_SECTION_TO",
			p.SOP_ATS_TOWNSHIP_TO as SOP_ATS_TOWNSHIP_TO label="SOP_ATS_TOWNSHIP_TO",
			p.SOP_ATS_RANGE_TO as SOP_ATS_RANGE_TO label="SOP_ATS_RANGE_TO",
			p.SOP_ATS_MERIDIAN_TO as SOP_ATS_MERIDIAN_TO label="SOP_ATS_MERIDIAN_TO",
			p.SOP_PLAN_FROM as SOP_PLAN_FROM label="SOP_PLAN_FROM",
			p.SOP_BLOCK_FROM as SOP_BLOCK_FROM label="SOP_BLOCK_FROM",
			p.SOP_LOT_FROM as SOP_LOT_FROM label="SOP_LOT_FROM",
			p.SOP_PLAN_TO as SOP_PLAN_TO label="SOP_PLAN_TO",
			p.SOP_BLOCK_TO as SOP_BLOCK_TO label="SOP_BLOCK_TO",
			p.SOP_LOT_TO as SOP_LOT_TO label="SOP_LOT_TO",
            p.SOP_YEAR_BUILT      as YEAR_BUILT label='YEAR_BUILT'        	

                from ALPAS.ALGV_SR_OTHER_PROPERTY as p
				left outer join alpas.Algv_sr_other_component c
                           on p.sop_id = c.soc_sop_id 
	            left outer join ALPAS.ALGV_SR_OTHER_PROP_ASMNT as a
	                      on a.SOP_ID = p.SOP_ID and a.SOPA_AM_ID in (0, &amlist1)
	            left outer join Alpas.ALGV_CT_PUBLICATION_VINTAGE as VINT
	                      on p.SOP_PV_ID = VINT.pv_id
	            where p.SOP_PV_ID in (&pvid1) and SOP_PT_CODE in (&pt)
	            order by p.SOP_LPAU_PROPERTY_ID, VINT.PV_SEQUENCE_ORDER desc/*,
			META.AM_ASMNT_RUN_STATUS, a.SOPA_AM_ID desc*/;

		  create table Work.SrOtPropAsmnt2 as select
	        p.SOP_PT_CODE as PtCode label='PtCode',
	        p.SOP_AY_ASMNT_YEAR as AsmntYr label='AsmntYr',
	        VINT.PV_VINTAGE_CODE as AsmntVint label='AsmntVint',			
	        p.SOP_LPAU_PROPERTY_ID as LpauID label='LpauID',
	        VINT.PV_SEQUENCE_ORDER,
	        p.SOP_SIMS_ASSESSEE_ID as AsseId label='AsseId',
			p.SOP_SIMS_TJ_STKHLDR_ID as TaxJurid   label = 'TaxJurId',
			c.SOC_SIMS_AJ_STKHLDR_ID as AsmntJurID label='AsmntJurID',                
	        a.SOPA_SCHED_A_ACC       as Acc        label='Acc',          
	        put(p.SOP_SIMS_ASSESSEE_ID, SIMSname.) as AsseName,
	        p.SOP_SIMS_TJ_STKHLDR_ID as TJcode label = 'TJcode',
	        put(p.SOP_SIMS_TJ_STKHLDR_ID, SIMSname.) as TJName label = 'TJName',
	        put(p.SOP_SIMS_TJ_STKHLDR_ID, SIMtype.) as TJtype label = 'TJtype',
			p.SOP_PROPERTY_QUANTITY  as PROP_QTY   LABEL='PROP_QTY',
			p.SOP_EATL_ALLOC_PERCENT_T as PctT label='PctT',
			p.SOP_EATL_ALLOC_PERCENT_E as PctE label='PctE',
			p.SOP_EATL_ALLOC_PERCENT_G as PctG label='PctG',				
			a.SOPA_AM_ID as AmId label='AmId',		
			a.SOPA_SCHED_A_BASE_COST as SchaBaseCost label='SchaBaseCost',
			a.SOPA_SCHED_B_FACTOR as SchbFctr label='SchbFctr',
			a.SOPA_SCHED_C_FACTOR as SchcFctr label='SchcFctr',
			a.SOPA_SCHED_D_FACTOR as SchdFctr label='SchdFctr',
			a.SOPA_SCHED_D_CODE as SOPA_SCHED_D_CODE label="SOPA_SCHED_D_CODE",
			a.SOPA_EATL_PROP_DESC_CODE as SOPA_EATL_PROP_DESC_CODE label="SOPA_EATL_PROP_DESC_CODE",
	        a.SOPA_ASSESSMENT_VALUE as Asmnt label='Asmnt',
			a.SOPA_EATL_ALLOCATED_VALUE_T as AsmntT label='AsmntT',
			a.SOPA_EATL_ALLOCATED_VALUE_E as AsmntE label='AsmntE',
			a.SOPA_EATL_ALLOCATED_VALUE_G as AsmntG label='AsmntG',
			p.SOP_LINEAR_PROP_FLAG as InvNalFlag label='InvNalFlag',
			p.SOP_COMPANY_REF_ID      as company_ref_id label='company_ref_id',
			p.SOP_REPORTED_PROPERTY_NAME as REPORTED_PROPERTY_NAME label='REPORTED_PROPERTY_NAME',
			p.SOP_UTILIZATION_PERCENT as SOP_UTILIZATION_PERCENT label="SOP_UTILIZATION_PERCENT",
	        p.SOP_REPORTED_PROPERTY_NAME as REPORTED_PROPERTY_NAME label='REPORTED_PROPERTY_NAME',
			p.SOP_REPORTED_PROPERTY_DESC as SOP_REPORTED_PROPERTY_DESC label='SOP_REPORTED_PROPERTY_DESC',
			p.SOP_ATS_LSD_FROM as SOP_ATS_LSD_FROM label="SOP_ATS_LSD_FROM",
			p.SOP_ATS_QTR_SECTION_FROM as SOP_ATS_QTR_SECTION_FROM label="SOP_ATS_QTR_SECTION_FROM",
			p.SOP_ATS_SECTION_FROM as SOP_ATS_SECTION_FROM label="SOP_ATS_SECTION_FROM",
			p.SOP_ATS_TOWNSHIP_FROM as SOP_ATS_TOWNSHIP_FROM label="SOP_ATS_TOWNSHIP_FROM",
			p.SOP_ATS_RANGE_FROM as SOP_ATS_RANGE_FROM label="SOP_ATS_RANGE_FROM",
			p.SOP_ATS_MERIDIAN_FROM as SOP_ATS_MERIDIAN_FROM label="SOP_ATS_MERIDIAN_FROM",
			p.SOP_ATS_LSD_TO as SOP_ATS_LSD_TO label="SOP_ATS_LSD_TO",
			p.SOP_ATS_QTR_SECTION_TO as SOP_ATS_QTR_SECTION_TO label="SOP_ATS_QTR_SECTION_TO",
			p.SOP_ATS_SECTION_TO as SOP_ATS_SECTION_TO label="SOP_ATS_SECTION_TO",
			p.SOP_ATS_TOWNSHIP_TO as SOP_ATS_TOWNSHIP_TO label="SOP_ATS_TOWNSHIP_TO",
			p.SOP_ATS_RANGE_TO as SOP_ATS_RANGE_TO label="SOP_ATS_RANGE_TO",
			p.SOP_ATS_MERIDIAN_TO as SOP_ATS_MERIDIAN_TO label="SOP_ATS_MERIDIAN_TO",
            p.SOP_PLAN_FROM as SOP_PLAN_FROM label="SOP_PLAN_FROM",
			p.SOP_BLOCK_FROM as SOP_BLOCK_FROM label="SOP_BLOCK_FROM",
			p.SOP_LOT_FROM as SOP_LOT_FROM label="SOP_LOT_FROM",
			p.SOP_PLAN_TO as SOP_PLAN_TO label="SOP_PLAN_TO",
			p.SOP_BLOCK_TO as SOP_BLOCK_TO label="SOP_BLOCK_TO",
			p.SOP_LOT_TO as SOP_LOT_TO label="SOP_LOT_TO",
            p.SOP_YEAR_BUILT         as YEAR_BUILT label='YEAR_BUILT'			

                from ALPAS.ALGV_SR_OTHER_PROPERTY as p
				left outer join alpas.Algv_sr_other_component as c
                         on p.sop_id = c.soc_sop_id 
	            left outer join ALPAS.ALGV_SR_OTHER_PROP_ASMNT as a
	                    on a.SOP_ID = p.SOP_ID and a.SOPA_AM_ID in (0, &amlist2)
	            left outer join Alpas.ALGV_CT_PUBLICATION_VINTAGE as VINT
	                    on p.SOP_PV_ID = VINT.pv_id
	            where p.SOP_PV_ID in (&pvid2) and SOP_PT_CODE in (&pt)
	            order by p.SOP_LPAU_PROPERTY_ID, VINT.PV_SEQUENCE_ORDER desc/*,
			META.AM_ASMNT_RUN_STATUS, a.SOPA_AM_ID desc*/;
	            quit;
	data SrOtClosingBal1;
	set SrOtPropAsmnt1;
	by  LpauID;
	if first.LpauID = 1 ;/*and InvNalFlag = 'A'*/
	run;
	data SrOtClosingBal2;
	set SrOtPropAsmnt2;
	by  LpauID;
	if first.LpauID = 1; /*and InvNalFlag = 'A'*/
	run;
%put ptcode is SROT or ALL: &asmntyear1 &ptcode;
%end;
%if &ptcode = WL or %upcase(&ptcode) = ALL %then %do;
	proc sql noprint;
	    create table Work.WlPropAsmnt1 as select
	        p.EWP_PT_CODE as PtCode label='PtCode',
	        p.EWP_AY_ASMNT_YEAR as AsmntYr label='AsmntYr',
	        VINT.PV_VINTAGE_CODE as AsmntVint label='AsmntVint',
            p.EWP_LINEAR_PROP_FLAG as InvNalFlag label="InvNalFlag",	
	        p.EWP_LPAU_PROPERTY_ID as LpauID label='LpauID',
	        VINT.PV_SEQUENCE_ORDER,
	        input(put(p.EWP_SIMS_EUB_ASSESSEE_COMP_CD, $SIMSco.),8.)as AsseId label = 'AsseID',
			p.EWP_SIMS_TJ_STKHLDR_ID  as TaxJurid   label ='TaxJurId',
            p.EWP_SIMS_AJ_STKHLDR_ID  as AsmntJurID label='AsmntJurID',
	        a.EWPA_SCHED_A_ACC as Acc label='Acc', 
	        put(p.EWP_SIMS_EUB_ASSESSEE_COMP_CD, $EUBname.) as AsseName label = 'AsseName',
	        p.EWP_SIMS_TJ_STKHLDR_ID as TJcode label = 'TJcode',
	        put(p.EWP_SIMS_TJ_STKHLDR_ID, SIMSname.) as TJName label = 'TJName',
	        put(p.EWP_SIMS_TJ_STKHLDR_ID, SIMtype.) as TJtype label = 'TJtype',
			a.EWPA_SCHED_A_QTY        as PROP_QTY   LABEL='PROP_QTY',
			p.EWP_EATL_ALLOC_PERCENT_T as PctT label='PctT',
			p.EWP_EATL_ALLOC_PERCENT_E as PctE label='PctE',
			p.EWP_EATL_ALLOC_PERCENT_G as PctG label='PctG',             
            a.EWPA_AM_ID as AmId label='AmId',		
			a.EWPA_SCHED_A_BASE_COST as SchaBaseCost label='SchaBaseCost',
			a.EWPA_SCHED_B_FACTOR as SchbFctr label='SchbFctr',
			a.EWPA_SCHED_C_FACTOR as SchcFctr label='SchcFctr',
			a.EWPA_SCHED_D_FACTOR as SchdFctr label='SchdFctr',
	        a.EWPA_ASSESSMENT_VALUE as Asmnt label='Asmnt',
			a.EWPA_EATL_ALLOCATED_VALUE_T as AsmntT label='AsmntT',
			a.EWPA_EATL_ALLOCATED_VALUE_E as AsmntE label='AsmntE',
			a.EWPA_EATL_ALLOCATED_VALUE_G as AsmntG label='AsmntG',			
			p.EWP_SIMS_EUB_ASSESSEE_COMP_CD as SIMS_EUB_ID LABEL='SIMS_EUB_ID' , 
	        p.EWP_EUB_LICENSE_NO  as EUB_LICENSE_NO label = 'EUB_LICENSE_NO' , 
	        c.EWC_COMMON_WELL_ID  as COMMON_WELL_ID label='COMMON_WELL_ID',
            c.EWC_FIN_DRILLING_DATE as FIN_DRILLING_DATE label='FIN_DRILLING_DATE',  
	        C.EWC_PERF_TREAT_CODE AS PERF_TREAT_CODE LABEL='PERF_TREAT_CODE',
	        C.EWC_PERF_TREAT_INTVL_BOT_DEPTH AS PERF_TREAT_INTVL_BOT_DEPTH LABEL='PERF_TREAT_INTVL_BOT_DEPTH',
	        C.EWC_PERF_TREAT_INTVL_TOP_DEPTH AS PERF_TREAT_INTVL_TOP_DEPTH  LABEL='PERF_TREAT_INTVL_TOP_DEPTH',
	        C.EWC_POOL_CODE            AS POOL_CODE LABEL='POOL_CODE',
	        C.EWC_PROD_INTVL_BOT_DEPTH AS PROD_INTVL_BOT_DEPTH LABEL='PROD_INTVL_BOT_DEPTH', 
	        C.EWC_PROD_INTVL_TOP_DEPTH AS PROD_INTVL_TOP_DEPTH LABEL='PROD_INTVL_TOP_DEPTH', 
	        C.EWC_SHOE_SET_DEPTH       AS SHOE_SET_DEPTH LABEL='SHOE_SET_DEPTH',
	        C.EWC_SURF_HOLE_ID         AS SURF_HOLE_ID LABEL='SURF_HOLE_ID',
	        C.EWC_WELL_NAME            AS WELL_NAME LABEL='WELL_NAME', 
	        C.EWC_PLUG_BACK_DEPTH      AS PLUG_BACK_DEPTH LABEL='PLUG_BACK_DEPTH',
	        C.EWC_WELL_STATUS_FLUID    AS WELL_STATUS_FLUID LABEL='WELL_STATUS_FLUID',
	        C.EWC_WELL_STATUS_MODE     AS WELL_STATUS_MODE  LABEL='WELL_STATUS_MODE',  
	        C.EWC_WELL_STATUS_TYPE     AS WELL_STATUS_TYPE  LABEL='WELL_STATUS_TYPE',  
	        C.EWC_WELL_STATUS_STRUCTURE AS WELL_STATUS_STRUCT LABEL='WELL_STATUS_STRUCT', 
	        C.EWC_TOTAL_DEPTH          AS TOTAL_DEPTH LABEL='TOTAL_DEPTH', 
	        C.EWC_TRUE_VERTICAL_DEPTH AS TRUE_VERTICAL_DEPTH LABEL='TRUE_VERTICAL_DEPTH', 
	        C.EWC_PROD_HOURS_12_MONTH_TOT AS PROD_HOURS_12_MONTH_TOT LABEL='PROD_HOURS_12_MONTH_TOT',
	        C.EWC_INJ_HOURS_12_MONTH_TOT  AS INJ_HOURS_12_MONTH_TOT  LABEL='INJ_HOURS_12_MONTH_TOT',
	        C.EWC_GAS_VOLUME_12_MONTH_TOT AS GAS_VOLUME_12_MONTH_TOT LABEL='GAS_VOLUME_12_MONTH_TOT',
	        C.EWC_GAS_VOLUME_CUM_TOT      AS GAS_VOLUME_CUM_TOT LABEL='GAS_VOLUME_CUM_TOT',                                 
	        C.EWC_OIL_VOLUME_12_MONTH_TOT AS OIL_VOLUME_12_MONTH_TOT LABEL='OIL_VOLUME_12_MONTH_TOT', 
	        C.EWC_OIL_VOLUME_CUM_TOT      AS OIL_VOLUME_CUM_TOT LABEL='OIL_VOLUME_CUM_TOT',
	        C.EWC_COND_VOLUME_12_MONTH_TOT AS COND_VOLUME_12_MONTH_TOT LABEL='COND_VOLUME_12_MONTH_TOT',
	        C.EWC_COND_VOLUME_CUM_TOT AS COND_VOLUME_CUM_TOT LABEL='COND_VOLUME_CUM_TOT', 
	        C.EWC_LINEAR_PROP_COMP_FLAG AS LINEAR_PROP_COMP_FLAG LABEL='LINEAR_PROP_COMP_FLAG'
	          from ALPAS.ALGV_EUB_WELL_PROPERTY as p
              left outer join ALPAS.ALGV_EUB_WELL_COMPONENT as C
		                ON C.EWC_EWP_ID = p.EWP_ID 
	          left outer join ALPAS.ALGV_EUB_WELL_PROP_ASMNT as a
	                    on a.EWP_ID = p.EWP_ID and a.EWPA_AM_ID in (0, &amlist1)   
	          left outer join Alpas.ALGV_CT_PUBLICATION_VINTAGE as VINT
	                    on p.EWP_PV_ID = VINT.pv_id
	          where p.EWP_PV_ID in (&pvid1)
	          order by p.EWP_LPAU_PROPERTY_ID, VINT.PV_SEQUENCE_ORDER desc/*,
			META.AM_ASMNT_RUN_STATUS, a.EWPA_AM_ID desc*/;

		create table Work.WlPropAsmnt2 as select
	        p.EWP_PT_CODE as PtCode label='PtCode',
	        p.EWP_AY_ASMNT_YEAR as AsmntYr label='AsmntYr',
	        VINT.PV_VINTAGE_CODE as AsmntVint label='AsmntVint',
            p.EWP_LINEAR_PROP_FLAG as InvNalFlag label="InvNalFlag",	
	        p.EWP_LPAU_PROPERTY_ID as LpauID label='LpauID',
	        VINT.PV_SEQUENCE_ORDER,
	        input(put(p.EWP_SIMS_EUB_ASSESSEE_COMP_CD, $SIMSco.),8.) as AsseId label = 'AsseID',
			p.EWP_SIMS_TJ_STKHLDR_ID  as TaxJurid   label ='TaxJurId',
            p.EWP_SIMS_AJ_STKHLDR_ID  as AsmntJurID label='AsmntJurID',
			a.EWPA_SCHED_A_ACC as Acc label='Acc',
	        put(p.EWP_SIMS_EUB_ASSESSEE_COMP_CD, $EUBname.) as AsseName label = 'AsseName',
	        p.EWP_SIMS_TJ_STKHLDR_ID as TJcode label = 'TJcode',
	        put(p.EWP_SIMS_TJ_STKHLDR_ID, SIMSname.) as TJName label = 'TJName',
	        put(p.EWP_SIMS_TJ_STKHLDR_ID, SIMtype.) as TJtype label = 'TJtype',
			a.EWPA_SCHED_A_QTY        as PROP_QTY   LABEL='PROP_QTY',
			p.EWP_EATL_ALLOC_PERCENT_T as PctT label='PctT',
			p.EWP_EATL_ALLOC_PERCENT_E as PctE label='PctE',
			p.EWP_EATL_ALLOC_PERCENT_G as PctG label='PctG',             	
			a.EWPA_AM_ID as AmId label='AmId',		
			a.EWPA_SCHED_A_BASE_COST as SchaBaseCost label='SchaBaseCost',
			a.EWPA_SCHED_B_FACTOR as SchbFctr label='SchbFctr',
			a.EWPA_SCHED_C_FACTOR as SchcFctr label='SchcFctr',
			a.EWPA_SCHED_D_FACTOR as SchdFctr label='SchdFctr',
	        a.EWPA_ASSESSMENT_VALUE as Asmnt label='Asmnt',
			a.EWPA_EATL_ALLOCATED_VALUE_T as AsmntT label='AsmntT',
			a.EWPA_EATL_ALLOCATED_VALUE_E as AsmntE label='AsmntE',
			a.EWPA_EATL_ALLOCATED_VALUE_G as AsmntG label='AsmntG',		
			p.EWP_SIMS_EUB_ASSESSEE_COMP_CD as SIMS_EUB_ID LABEL='SIMS_EUB_ID' , 
	        p.EWP_EUB_LICENSE_NO  as EUB_LICENSE_NO label = 'EUB_LICENSE_NO' , 
	        c.EWC_COMMON_WELL_ID  as COMMON_WELL_ID label='COMMON_WELL_ID',
            c.EWC_FIN_DRILLING_DATE as FIN_DRILLING_DATE label='FIN_DRILLING_DATE',  
	        C.EWC_PERF_TREAT_CODE AS PERF_TREAT_CODE LABEL='PERF_TREAT_CODE',
	        C.EWC_PERF_TREAT_INTVL_BOT_DEPTH AS PERF_TREAT_INTVL_BOT_DEPTH  LABEL='PERF_TREAT_INTVL_BOT_DEPTH',
	        C.EWC_PERF_TREAT_INTVL_TOP_DEPTH AS PERF_TREAT_INTVL_TOP_DEPTH LABEL='PERF_TREAT_INTVL_TOP_DEPTH',
	        C.EWC_POOL_CODE            AS POOL_CODE LABEL='POOL_CODE',
	        C.EWC_PROD_INTVL_BOT_DEPTH AS PROD_INTVL_BOT_DEPTH LABEL='PROD_INTVL_BOT_DEPTH', 
	        C.EWC_PROD_INTVL_TOP_DEPTH AS PROD_INTVL_TOP_DEPTH LABEL='PROD_INTVL_TOP_DEPTH', 
	        C.EWC_SHOE_SET_DEPTH       AS SHOE_SET_DEPTH LABEL='SHOE_SET_DEPTH',
	        C.EWC_SURF_HOLE_ID         AS SURF_HOLE_ID LABEL='SURF_HOLE_ID',
	        C.EWC_WELL_NAME            AS WELL_NAME LABEL='WELL_NAME', 
	        C.EWC_PLUG_BACK_DEPTH      AS PLUG_BACK_DEPTH LABEL='PLUG_BACK_DEPTH',
	        C.EWC_WELL_STATUS_FLUID    AS WELL_STATUS_FLUID LABEL='WELL_STATUS_FLUID',
	        C.EWC_WELL_STATUS_MODE     AS WELL_STATUS_MODE  LABEL='WELL_STATUS_MODE',  
	        C.EWC_WELL_STATUS_TYPE     AS WELL_STATUS_TYPE  LABEL='WELL_STATUS_TYPE',  
	        C.EWC_WELL_STATUS_STRUCTURE AS WELL_STATUS_STRUCT LABEL='WELL_STATUS_STRUCT', 
	        C.EWC_TOTAL_DEPTH          AS TOTAL_DEPTH LABEL='TOTAL_DEPTH', 
	        C.EWC_TRUE_VERTICAL_DEPTH AS TRUE_VERTICAL_DEPTH LABEL='TRUE_VERTICAL_DEPTH', 
	        C.EWC_PROD_HOURS_12_MONTH_TOT AS PROD_HOURS_12_MONTH_TOT LABEL='PROD_HOURS_12_MONTH_TOT',
	        C.EWC_INJ_HOURS_12_MONTH_TOT  AS INJ_HOURS_12_MONTH_TOT  LABEL='INJ_HOURS_12_MONTH_TOT',
	        C.EWC_GAS_VOLUME_12_MONTH_TOT AS GAS_VOLUME_12_MONTH_TOT LABEL='GAS_VOLUME_12_MONTH_TOT',
	        C.EWC_GAS_VOLUME_CUM_TOT      AS GAS_VOLUME_CUM_TOT LABEL='GAS_VOLUME_CUM_TOT',                                 
	        C.EWC_OIL_VOLUME_12_MONTH_TOT AS OIL_VOLUME_12_MONTH_TOT LABEL='OIL_VOLUME_12_MONTH_TOT', 
	        C.EWC_OIL_VOLUME_CUM_TOT      AS OIL_VOLUME_CUM_TOT LABEL='OIL_VOLUME_CUM_TOT',
	        C.EWC_COND_VOLUME_12_MONTH_TOT AS COND_VOLUME_12_MONTH_TOT LABEL='COND_VOLUME_12_MONTH_TOT',
	        C.EWC_COND_VOLUME_CUM_TOT AS COND_VOLUME_CUM_TOT LABEL='COND_VOLUME_CUM_TOT', 
	        C.EWC_LINEAR_PROP_COMP_FLAG AS LINEAR_PROP_COMP_FLAG LABEL='LINEAR_PROP_COMP_FLAG'		
	       from ALPAS.ALGV_EUB_WELL_PROPERTY as p
		   left outer join ALPAS.ALGV_EUB_WELL_COMPONENT as C
		            ON C.EWC_EWP_ID = p.EWP_ID 
	       left outer join ALPAS.ALGV_EUB_WELL_PROP_ASMNT as a
	                on a.EWP_ID = p.EWP_ID 	and a.EWPA_AM_ID in (0, &amlist2)
		   left outer join ALPAS.ALGV_EUB_WELL_COMPONENT as comp
	                on comp.EWC_EWP_ID = p.EWP_ID
	       left outer join Alpas.ALGV_CT_PUBLICATION_VINTAGE as VINT
	                on p.EWP_PV_ID = VINT.pv_id
	       where p.EWP_PV_ID in (&pvid2)

           order by p.EWP_LPAU_PROPERTY_ID, VINT.PV_SEQUENCE_ORDER desc/*,
			META.AM_ASMNT_RUN_STATUS, a.EWPA_AM_ID desc*/;
	       quit;
	data WlClosingBal1;
	set WlPropAsmnt1;
	by  LpauID;
	if first.LpauID = 1 /*and InvNalFlag = 'A'*/;
	run;
	data WlClosingBal2;
	set WlPropAsmnt2;
	by  LpauID;
	if first.LpauID = 1 /*and InvNalFlag = 'A'*/;
	run;
	%put ptcode is WL or ALL: &asmntyear1 &ptcode;
%end;
%if &ptcode = PL or %upcase(&ptcode) = ALL %then %do;
	proc sql noprint;
	    create table Work.PlPropAsmnt1 as select
	        p.EPP_PT_CODE as PtCode label='PtCode',
	        p.EPP_AY_ASMNT_YEAR as AsmntYr label='AsmntYr',
	        VINT.PV_VINTAGE_CODE as AsmntVint label='AsmntVint',
			p.EPP_LINEAR_PROP_FLAG as InvNalFlag label='InvNalFlag',
	        p.EPP_LPAU_PROPERTY_ID as LpauID label='LpauID',
	        VINT.PV_SEQUENCE_ORDER,
	        input(put(p.EPP_SIMS_EUB_ASSESSEE_COMP_CD, $SIMSco.),8.) as AsseId label = 'AsseID',
			p.EPP_SIMS_TJ_STKHLDR_ID  as TaxJurid   label ='TaxJurId',
            c.EPC_SIMS_AJ_STKHLDR_ID  as AsmntJurID label='AsmntJurID', 
			a.EPPA_SCHED_A_ACC        as Acc        label='Acc',
	        put(p.EPP_SIMS_EUB_ASSESSEE_COMP_CD, $EUBname.) as AsseName label = 'AsseName',
	        p.EPP_SIMS_TJ_STKHLDR_ID as TJcode label = 'TJcode',
	        put(p.EPP_SIMS_TJ_STKHLDR_ID, SIMSname.) as TJName label = 'TJName',
	        put(p.EPP_SIMS_TJ_STKHLDR_ID, SIMtype.) as TJtype label = 'TJtype',
			p.EPP_ASR_PROP_QTY       as PROP_QTY   LABEL='PROP_QTY',
			p.EPP_EATL_ALLOC_PERCENT_T as PctT label='PctT',
			p.EPP_EATL_ALLOC_PERCENT_E as PctE label='PctE',
			p.EPP_EATL_ALLOC_PERCENT_G as PctG label='PctG', 	              		
			a.EPPA_AM_ID as AmId label='AmId',		
			a.EPPA_SCHED_A_BASE_COST as SchaBaseCost label='SchaBaseCost',
			a.EPPA_SCHED_B_FACTOR as SchbFctr label='SchbFctr',
			a.EPPA_SCHED_C_FACTOR as SchcFctr label='SchcFctr',
			a.EPPA_SCHED_D_FACTOR as SchdFctr label='SchdFctr',
	        a.EPPA_ASSESSMENT_VALUE as Asmnt label='Asmnt',
			a.EPPA_EATL_ALLOCATED_VALUE_T as AsmntT label='AsmntT',
			a.EPPA_EATL_ALLOCATED_VALUE_E as AsmntE label='AsmntE',
			a.EPPA_EATL_ALLOCATED_VALUE_G as AsmntG label='AsmntG',			   
            p.EPP_SIMS_EUB_ASSESSEE_COMP_CD as SIMS_EUB_ID LABEL="SIMS_EUB_ID" , 
            put(p.EPP_EUB_LICENSE_NO,9. -L)      as EUB_LICENSE_NO label = "EUB_LICENSE_NO" , 
            p.EPP_EUB_LINE_NO         as EUB_LINE_NO    label="EUB_LINE_NO",
	        p.EPP_LICENSED_LENGTH     AS LICENSED_LENGTH LABEL="LICENSED_LENGTH" ,
            p.EPP_PROPERTY_LENGTH     AS PROPERTY_LENGTH  LABEL="PROPERTY_LENGTH" , 
            p.EPP_PIPELINE_STATUS_CODE AS PIPELINE_STATUS_CODE LABEL="PIPELINE_STATUS_CODE" ,
            p.EPP_MAX_OPERATING_PRESSURE  AS MAX_OPER_PRESSURE LABEL="MAX_OPER_PRESSURE" , 
            p.EPP_OUTSIDE_DIAMETER     AS OUTSIDE_DIAMETER LABEL="OUTSIDE_DIAMETER" ,
            p.EPP_FACILITY_FROM_CODE   as FACILITY_FROM_CODE label = "FACILITY_FROM_CODE",
	        p.EPP_FACILITY_TO_CODE     as FACILITY_TO_CODE  label="FACILITY_TO_CODE" 			
	        from ALPAS.ALGV_EUB_PIPELINE_PROPERTY as p
	        left outer join alpas.Algv_eub_pipeline_component as c
		                 on p.EPP_ID = c.epc_epp_id  
 
	        left outer join ALPAS.ALGV_EUB_PIPE_PROP_ASMNT as a

	                    on a.EPP_ID = p.EPP_ID and a.EPPA_AM_ID in (0, &amlist1)
	        left outer join Alpas.ALGV_CT_PUBLICATION_VINTAGE as VINT

	                    on p.EPP_PV_ID = VINT.pv_id
	                    where p.EPP_PV_ID in (&pvid1)
	                   order by p.EPP_LPAU_PROPERTY_ID, VINT.PV_SEQUENCE_ORDER desc/*,
			META.AM_ASMNT_RUN_STATUS, a.EPPA_AM_ID desc*/;

		create table Work.PlPropAsmnt2 as select
	        p.EPP_PT_CODE as PtCode label='PtCode',
	        p.EPP_AY_ASMNT_YEAR as AsmntYr label='AsmntYr',
	        VINT.PV_VINTAGE_CODE as AsmntVint label='AsmntVint',
			p.EPP_LINEAR_PROP_FLAG as InvNalFlag label='InvNalFlag',
	        p.EPP_LPAU_PROPERTY_ID as LpauID label='LpauID',
	        VINT.PV_SEQUENCE_ORDER,
	        input(put(p.EPP_SIMS_EUB_ASSESSEE_COMP_CD, $SIMSco.),8.)as AsseId label = 'AsseID',
			p.EPP_SIMS_TJ_STKHLDR_ID  as TaxJurid   label ='TaxJurId',
            c.EPC_SIMS_AJ_STKHLDR_ID  as AsmntJurID label='AsmntJurID', 
			a.EPPA_SCHED_A_ACC        as Acc        label='Acc',
	        put(p.EPP_SIMS_EUB_ASSESSEE_COMP_CD, $EUBname.) as AsseName label = 'AsseName',
	        p.EPP_SIMS_TJ_STKHLDR_ID as TJcode label = 'TJcode',
	        put(p.EPP_SIMS_TJ_STKHLDR_ID, SIMSname.) as TJName label = 'TJName',
	        put(p.EPP_SIMS_TJ_STKHLDR_ID, SIMtype.) as TJtype label = 'TJtype',
			p.EPP_ASR_PROP_QTY       as PROP_QTY   LABEL='PROP_QTY',
	        p.EPP_EATL_ALLOC_PERCENT_T as PctT label='PctT',
			p.EPP_EATL_ALLOC_PERCENT_E as PctE label='PctE',
			p.EPP_EATL_ALLOC_PERCENT_G as PctG label='PctG',      
	      
	       
			a.EPPA_AM_ID as AmId label='AmId',	
			a.EPPA_SCHED_A_BASE_COST as SchaBaseCost label='SchaBaseCost',
			a.EPPA_SCHED_B_FACTOR as SchbFctr label='SchbFctr',
			a.EPPA_SCHED_C_FACTOR as SchcFctr label='SchcFctr',
			a.EPPA_SCHED_D_FACTOR as SchdFctr label='SchdFctr',
	        a.EPPA_ASSESSMENT_VALUE as Asmnt label='Asmnt',
			a.EPPA_EATL_ALLOCATED_VALUE_T as AsmntT label='AsmntT',
			a.EPPA_EATL_ALLOCATED_VALUE_E as AsmntE label='AsmntE',
			a.EPPA_EATL_ALLOCATED_VALUE_G as AsmntG label='AsmntG',		
            p.EPP_SIMS_EUB_ASSESSEE_COMP_CD as SIMS_EUB_ID LABEL="SIMS_EUB_ID" , 
            put(p.EPP_EUB_LICENSE_NO,9. -L)      as EUB_LICENSE_NO label = "EUB_LICENSE_NO" , 
            p.EPP_EUB_LINE_NO         as EUB_LINE_NO    label="EUB_LINE_NO",
	        p.EPP_LICENSED_LENGTH     AS LICENSED_LENGTH LABEL="LICENSED_LENGTH" ,
            p.EPP_PROPERTY_LENGTH     AS PROPERTY_LENGTH  LABEL="PROPERTY_LENGTH" , 
            p.EPP_PIPELINE_STATUS_CODE AS PIPELINE_STATUS_CODE LABEL="PIPELINE_STATUS_CODE" ,
            p.EPP_MAX_OPERATING_PRESSURE  AS MAX_OPER_PRESSURE LABEL="MAX_OPER_PRESSURE" , 
            p.EPP_OUTSIDE_DIAMETER     AS OUTSIDE_DIAMETER LABEL="OUTSIDE_DIAMETER" ,
            p.EPP_FACILITY_FROM_CODE   as FACILITY_FROM_CODE label = "FACILITY_FROM_CODE",
	        p.EPP_FACILITY_TO_CODE     as FACILITY_TO_CODE  label="FACILITY_TO_CODE" 
	      from ALPAS.ALGV_EUB_PIPELINE_PROPERTY as p
		  left outer join alpas.Algv_eub_pipeline_component as c
		                 on p.EPP_ID = c.epc_epp_id         
	      left outer join ALPAS.ALGV_EUB_PIPE_PROP_ASMNT as a
	                    on a.EPP_ID = p.EPP_ID and a.EPPA_AM_ID in (0, &amlist2)
	      left outer join Alpas.ALGV_CT_PUBLICATION_VINTAGE as VINT
	                    on p.EPP_PV_ID = VINT.pv_id
	                    where p.EPP_PV_ID in (&pvid2)
	                    order by p.EPP_LPAU_PROPERTY_ID, VINT.PV_SEQUENCE_ORDER desc/*,
			META.AM_ASMNT_RUN_STATUS, a.EPPA_AM_ID desc*/;

		create table Work.PlSrPropAsmnt1 as select
	        p.SPP_PT_CODE as PtCode label='PtCode',
	        p.SPP_AY_ASMNT_YEAR as AsmntYr label='AsmntYr',
	        VINT.PV_VINTAGE_CODE as AsmntVint label='AsmntVint',
			p.SPP_LINEAR_PROP_FLAG as InvNalFlag label='InvNalFlag',
	        p.SPP_LPAU_PROPERTY_ID as LpauID label='LpauID',
	        VINT.PV_SEQUENCE_ORDER,
	        p.SPP_SIMS_ASSESSEE_ID as AsseId label='AsseId',
			p.SPP_SIMS_TJ_STKHLDR_ID  as TaxJurid   label ='TaxJurId',
            c.SPC_SIMS_AJ_STKHLDR_ID  as AsmntJurID label='AsmntJurID',
			a.SPPA_SCHED_A_ACC as Acc label='Acc', 
	        put(p.SPP_SIMS_ASSESSEE_ID, SIMSname.) as AsseName,
	        p.SPP_SIMS_TJ_STKHLDR_ID as TJcode label = 'TJcode',
	        put(p.SPP_SIMS_TJ_STKHLDR_ID, SIMSname.) as TJName label = 'TJName',
	        put(p.SPP_SIMS_TJ_STKHLDR_ID, SIMtype.) as TJtype label = 'TJtype',
			p.SPP_ASR_PROP_QTY       as PROP_QTY   LABEL='PROP_QTY',
			p.SPP_EATL_ALLOC_PERCENT_T as PctT label='PctT',
			p.SPP_EATL_ALLOC_PERCENT_E as PctE label='PctE',
			p.SPP_EATL_ALLOC_PERCENT_G as PctG label='PctG',          
           
			a.SPPA_AM_ID as AmId label='AmId',			
			a.SPPA_SCHED_A_BASE_COST as SchaBaseCost label='SchaBaseCost',
			a.SPPA_SCHED_B_FACTOR as SchbFctr label='SchbFctr',
			a.SPPA_SCHED_C_FACTOR as SchcFctr label='SchcFctr',
			a.SPPA_SCHED_D_FACTOR as SchdFctr label='SchdFctr',
	        a.SPPA_ASSESSMENT_VALUE as Asmnt label='Asmnt',
			a.SPPA_EATL_ALLOCATED_VALUE_T as AsmntT label='AsmntT',
			a.SPPA_EATL_ALLOCATED_VALUE_E as AsmntE label='AsmntE',
			a.SPPA_EATL_ALLOCATED_VALUE_G as AsmntG label='AsmntG',		 
	        put(p.SPP_AEUB_LICENSE_NO,9. -L)     as EUB_LICENSE_NO label = 'EUB_LICENSE_NO' , 
            p.SPP_AEUB_LINE_NO        as EUB_LINE_NO    label='EUB_LINE_NO',
	        p.SPP_LICENSED_LENGTH  AS LICENSED_LENGTH LABEL='LICENSED_LENGTH' ,
            p.SPP_PROPERTY_LENGTH  AS PROPERTY_LENGTH  LABEL='PROPERTY_LENGTH' , 
            p.SPP_PIPELINE_STATUS_CODE  AS PIPELINE_STATUS_CODE LABEL='PIPELINE_STATUS_CODE' ,
            p.SPP_MAX_OPERATING_PRESSURE AS MAX_OPER_PRESSURE LABEL='MAX_OPER_PRESSURE' , 
            p.SPP_OUTSIDE_DIAMETER AS OUTSIDE_DIAMETER LABEL='OUTSIDE_DIAMETER',
            p.SPP_FACILITY_FROM_CODE as FACILITY_FROM_CODE label = 'FACILITY_FROM_CODE',
	        p.SPP_FACILITY_TO_CODE   as FACILITY_TO_CODE  label='FACILITY_TO_CODE'    
 
	      from ALPAS.ALGV_SR_PIPELINE_PROPERTY as p
		  left outer join alpas.Algv_SR_pipe_prop_comp c        /* component */ 
                   on p.SPP_ID = c.SPC_SPP_ID 
	      left outer join ALPAS.ALGV_SR_PIPE_PROP_ASMNT as a
	                on a.SPP_ID = p.SPP_ID and a.SPPA_AM_ID in (0, &amlist1)
	      left outer join Alpas.ALGV_CT_PUBLICATION_VINTAGE as VINT
	                on p.SPP_PV_ID = VINT.pv_id
	      where p.SPP_PV_ID in (&pvid1)
	      order by p.SPP_LPAU_PROPERTY_ID, VINT.PV_SEQUENCE_ORDER desc/*,
			META.AM_ASMNT_RUN_STATUS, a.SPPA_AM_ID desc*/;

		create table Work.PlSrPropAsmnt2 as select
	        p.SPP_PT_CODE as PtCode label='PtCode',
	        p.SPP_AY_ASMNT_YEAR as AsmntYr label='AsmntYr',
	        VINT.PV_VINTAGE_CODE as AsmntVint label='AsmntVint',
			p.SPP_LINEAR_PROP_FLAG as InvNalFlag label='InvNalFlag',
	        p.SPP_LPAU_PROPERTY_ID as LpauID label='LpauID',
	        VINT.PV_SEQUENCE_ORDER,
	        p.SPP_SIMS_ASSESSEE_ID as AsseId label='AsseId',
			p.SPP_SIMS_TJ_STKHLDR_ID  as TaxJurid   label ='TaxJurId',
            c.SPC_SIMS_AJ_STKHLDR_ID  as AsmntJurID label='AsmntJurID',
			a.SPPA_SCHED_A_ACC as Acc label='Acc',
	        put(p.SPP_SIMS_ASSESSEE_ID, SIMSname.) as AsseName,
	        p.SPP_SIMS_TJ_STKHLDR_ID as TJcode label = 'TJcode',
	        put(p.SPP_SIMS_TJ_STKHLDR_ID, SIMSname.) as TJName label = 'TJName',
	        put(p.SPP_SIMS_TJ_STKHLDR_ID, SIMtype.) as TJtype label = 'TJtype',
			p.SPP_ASR_PROP_QTY       as PROP_QTY   LABEL='PROP_QTY',
			p.SPP_EATL_ALLOC_PERCENT_T as PctT label='PctT',
			p.SPP_EATL_ALLOC_PERCENT_E as PctE label='PctE',
			p.SPP_EATL_ALLOC_PERCENT_G as PctG label='PctG',  
          
			a.SPPA_AM_ID as AmId label='AmId',			
			a.SPPA_SCHED_A_BASE_COST as SchaBaseCost label='SchaBaseCost',
			a.SPPA_SCHED_B_FACTOR as SchbFctr label='SchbFctr',
			a.SPPA_SCHED_C_FACTOR as SchcFctr label='SchcFctr',
			a.SPPA_SCHED_D_FACTOR as SchdFctr label='SchdFctr',
	        a.SPPA_ASSESSMENT_VALUE as Asmnt label='Asmnt',
			a.SPPA_EATL_ALLOCATED_VALUE_T as AsmntT label='AsmntT',
			a.SPPA_EATL_ALLOCATED_VALUE_E as AsmntE label='AsmntE',
			a.SPPA_EATL_ALLOCATED_VALUE_G as AsmntG label='AsmntG',
			"0" as SIMS_EUB_ID as SIMS_EUB_ID LABEL='SIMS_EUB_ID' , 
	        put(p.SPP_AEUB_LICENSE_NO,9. -L)     as EUB_LICENSE_NO label = 'EUB_LICENSE_NO' , 
            p.SPP_AEUB_LINE_NO        as EUB_LINE_NO    label='EUB_LINE_NO',
	        p.SPP_LICENSED_LENGTH  AS LICENSED_LENGTH LABEL='LICENSED_LENGTH' ,
            p.SPP_PROPERTY_LENGTH  AS PROPERTY_LENGTH  LABEL='PROPERTY_LENGTH' , 
            p.SPP_PIPELINE_STATUS_CODE AS PIPELINE_STATUS_CODE LABEL='PIPELINE_STATUS_CODE' ,
            p.SPP_MAX_OPERATING_PRESSURE AS MAX_OPER_PRESSURE LABEL='MAX_OPER_PRESSURE' , 
            p.SPP_OUTSIDE_DIAMETER AS OUTSIDE_DIAMETER LABEL='OUTSIDE_DIAMETER',
            p.SPP_FACILITY_FROM_CODE as FACILITY_FROM_CODE label = 'FACILITY_FROM_CODE',
	        p.SPP_FACILITY_TO_CODE   as FACILITY_TO_CODE  label='FACILITY_TO_CODE'    
  
	       from ALPAS.ALGV_SR_PIPELINE_PROPERTY as p
		    left outer join alpas.Algv_SR_pipe_prop_comp c        /* component */ 
                    on p.SPP_ID = c.SPC_SPP_ID 
	        left outer join ALPAS.ALGV_SR_PIPE_PROP_ASMNT as a
	                on a.SPP_ID = p.SPP_ID and a.SPPA_AM_ID in (0, &amlist2)
	        left outer join Alpas.ALGV_CT_PUBLICATION_VINTAGE as VINT
	              on p.SPP_PV_ID = VINT.pv_id
	        where p.SPP_PV_ID in (&pvid2)
	        order by p.SPP_LPAU_PROPERTY_ID, VINT.PV_SEQUENCE_ORDER desc/*,
			META.AM_ASMNT_RUN_STATUS, a.SPPA_AM_ID desc*/;
	quit;
	data PlClosingBal1;
	set PlPropAsmnt1;
	by  LpauID;
	if first.LpauID = 1 /*and InvNalFlag = 'A'*/;
	run;
	data PlClosingBal2;
	set PlPropAsmnt2;
	by  LpauID;
	if first.LpauID = 1 /*and InvNalFlag = 'A'*/;
	run;
	data PlSrClosingBal1;
	set PlSrPropAsmnt1;
	by  LpauID;
	if first.LpauID = 1 /*and InvNalFlag = 'A'*/;
	run;
	data PlSrClosingBal2;
	set PlSrPropAsmnt2;
	by  LpauID;
	if first.LpauID = 1 /*and InvNalFlag = 'A'*/;
	run;
	%put ptcode is PL or ALL: &asmntyear1 &ptcode;
%end;
%MEND Model;
%Model;
/* Create old & new closing Balance */
%MACRO CB;
%if %upcase(&ptcode) = ALL %then %do;
	data ClosingBal1;
	set SrOtClosingBal1 WlClosingBal1 PlClosingBal1  PlSrClosingBal1; run;
	data ClosingBal2;
	set SrOtClosingBal2 WlClosingBal2 PlClosingBal2  PlSrClosingBal2; run;
%end;
%if &ptcode = CBL or &ptcode = TEL or &ptcode = ELE 
	or &ptcode = EPG or &ptcode = GDP %then %do;
	data ClosingBal1; set SrOtClosingBal1; run;
	data ClosingBal2; set SrOtClosingBal2; run;
%end;
%if &ptcode = PL %then %do;
	data ClosingBal1; set PlClosingBal1  PlSrClosingBal1; run;
	data ClosingBal2; set PlClosingBal2  PlSrClosingBal2; run;
%end;
%if &ptcode = WL %then %do;
	data ClosingBal1; set WlClosingBal1; run;
	data ClosingBal2; set WlClosingBal2; run;
%end;
%MEND CB;
%CB;
data closingbal1;
set closingbal1;
if AsmntJurID in (.,0) then AsmntJurID=TaxJurid;
else AsmntJurID=AsmntJurID;
run;
data closingbal2;
set closingbal2;
if AsmntJurID in (.,0) then AsmntJurID=TaxJurid;
else AsmntJurID=AsmntJurID;
run;
data PL_&TJ;
set ClosingBal2;
if ptcode="PL" and TaxJurid=&TJID  ;
run; 
data &TJ.PL;
set PL_&TJ;
if InvNalFlag="A";
run;
data &TJ.PL1(keep=PtCode AsmntYr AsmntVint  LpauID AsseId TaxJurid TJName AsmntJurID Acc AsseName TJtype PROP_QTY PctT PctE PctG SchaBaseCost SchbFctr SchcFctr SchdFctr Asmnt AsmntT InvNalFlag SIMS_EUB_ID EUB_LICENSE_NO EUB_LINE_NO LICENSED_LENGTH PROPERTY_LENGTH PIPELINE_STATUS_CODE MAX_OPER_PRESSURE OUTSIDE_DIAMETER Lic_Line );
set &TJ.PL;
Lic_Line=catx("x",input(EUB_LICENSE_NO,best12.), EUB_LINE_NO,TaxJurid,AsmntJurID);/***Put SchD also if this one is exists in data-only for PL***/
run;
/***export for joining in arcmap***/
proc export outfile="C:\_LOCALdata\ALL_Chetan\GIS_Job\MD-Bighorn-2017\Alpasfile\pl\&TJ.Pipeline.csv"
data=&TJ.PL1
dbms=csv replace;
run;

/***Start Well****/
data WL_&TJ;
set ClosingBal2;
if TJcode in (&TJID) and ptcode="WL" ;
run;
data &TJ.wL;
set WL_&TJ;
if InvNalFlag="A";
run;
data WL_&TJ.1(keep=PtCode AsmntYr AsmntVint LpauID AsseId TaxJurid TJName AsmntJurID Acc AsseName TJtype PROP_QTY PctT PctE PctG SchaBaseCost SchbFctr SchcFctr SchdFctr Asmnt AsmntT InvNalFlag SIMS_EUB_ID EUB_LICENSE_NO COMMON_WELL_ID WELL_NAME SHOE_SET_DEPTH PLUG_BACK_DEPTH WELL_STATUS_MODE);
set &TJ.wL;
run;
/***export for joining in arcmap***/
proc export outfile="C:\_LOCALdata\ALL_Chetan\GIS_Job\MD-Bighorn-2017\Alpasfile\wl\&TJ.WL.xlsx"
data=WL_&TJ.1
dbms=xlsx replace;
run; 

/*TELECOMMUNICATION*/
proc sql;
create table rfitel as
select *
from Alpas.Algv_Rfi_tel_tfac
where RFI_AY_ASMNT_YEAR=2016 and RFI_IMPORT_EXPORT="I";
run;
proc sql;
create table &TJ._Tel as
select *
from rfitel 
where RFI_TAXJUR in (&TJID) and RFI_RECTYPE="FIBR";
run;
data SROT_TEL_&TJ;
set ClosingBal2;
if TJcode in (&TJID) and ptcode="TEL" ;
run; 
data SROT_TEL_&TJ._Final(keep=PtCode AsmntYr AsmntVint LpauID AsseId TaxJurid TJName AsmntJurID Acc AsseName TJtype PROP_QTY PctT PctE PctG SchaBaseCost SchbFctr SchcFctr SchdFctr SOPA_SCHED_D_CODE Asmnt AsmntT AsmntE AsmntG InvNalFlag SOP_UTILIZATION_PERCENT SOP_ATS_LSD_FROM SOP_ATS_QTR_SECTION_FROM SOP_ATS_SECTION_FROM SOP_ATS_TOWNSHIP_FROM SOP_ATS_RANGE_FROM  SOP_ATS_MERIDIAN_FROM SOP_ATS_LSD_TO SOP_ATS_QTR_SECTION_TO SOP_ATS_SECTION_TO SOP_ATS_TOWNSHIP_TO SOP_ATS_RANGE_TO SOP_ATS_MERIDIAN_TO SOP_PLAN_FROM SOP_BLOCK_FROM SOP_LOT_FROM SOP_PLAN_TO SOP_BLOCK_TO SOP_LOT_TO YEAR_BUILT);
set SROT_TEL_&TJ;
run;
/*Allstream***/ /***Look up values are taken from allstream shape file*/
data &TJ._Allstream;
set &TJ._Tel;
if RFI_ASSEINVENTID in ('80B78/12EXSWABACxxxxABJXLDCRCP5800','80B78/12xxxxABJXLDCRCP4795xxxxABJXLDCRCP5370','80B78/12xxxxABJXLDCRCP5800xxxxABJXLDCRCP6360','80B78/12CNMRABJXLDCRCP6790xxxxABJXLDCRCP6360','80B78/12xxxxABJXLDCRCP4040xxxxABJXLDCRCP4578','80B78/12CNMRABJXLDCRCP6790xxxxABJXLDCRCP7298','80B78/12xxxxABJXLDCRCP3370xxxxABJXLDCRCP3540','80B78/12EXSWABACxxxxABJXLDCRCP5370','80B78/12xxxxABJXLDCRCP3160xxxxABJXLDCRCP3370','80B78/12xxxxABJXLDCRCP4578xxxxABJXLDCRCP4795','80B78/12xxxxABJXLDCRCP3540xxxxABJXLDCRCP4040');
run;
data SROT_TEL&TJ._Allstream;
set SROT_TEL_&TJ._Final;
if Lpauid=7831112; /***see the Lpauid from just previous output-Allstream***/
run;
proc sql;
create table Allstream as
select
a.AsmntYr,
a.AsmntVint,
b.RFI_ASSEINVENTID as ASSEINVENTID label="ASSEINVENTID",
a.LpauID,
a.AsseId,
a.TaxJurid,
a.AsmntJurID,
a.Acc,
a.AsseName,
a.PROP_QTY,
a.PctT,
a.PctE,
a.PctG,
a.SchaBaseCost,
a.SchbFctr,
a.SchcFctr,
a.SchdFctr,
a.SOPA_SCHED_D_CODE as SCHED_D_CODE label= "SCHED_D_CODE",
a.Asmnt,
a.AsmntT,
a.AsmntE,
a.AsmntG,
a.InvNalFlag,
a.SOP_UTILIZATION_PERCENT,
b.RFI_LENGTH as RFI_LENGTH label="RFI_LENGTH",
b.RFI_SHEATHSTRANDS as SHEATHSTRANDS label="SHEATHSTRANDS",
b.RFI_STRANDSOWNED as STRANDSOWNED label="STRANDSOWNED",
b.RFI_STRANDSLIT as RFI_STRANDSLIT label="STRANDSLIT",
a.YEAR_BUILT
from SROT_TEL&TJ._Allstream as a
left join &TJ._Allstream as b on a.LPAUID=b.RFI_LPAUID;
quit;
 /***export for joining in arcmap***/
proc export outfile="C:\_LOCALdata\ALL_Chetan\GIS_Job\MD-Bighorn-2017\Alpasfile\SR\&TJ.ALLSTREAM.xlsx"
data=Allstream
dbms=xlsx replace;
run;
 
/*Bell*/
data &TJ._Bell;
set &TJ._tel;
if RFI_ASSEINVENTID in ('LKLSABAF-EXSWABAC-014','INT0144-LAC005721','LKLSABAF-EXSWABAC-012','EXSWABAC-CLGRABJS-005','EXSWABAC-CLGRABJS-004','LKLSABAF-EXSWABAC-015','LKLSABAF-EXSWABAC-013','EXSWABAC-CLGRABJS-001','EXSWABAC-CLGRABJS-002','EXSWABAC-CLGRABJS-003','EXSWABAC-CLGRABJS-006');
run;
data  SROT_TEL&TJ._Bell;
set SROT_TEL_&TJ._Final;
if Lpauid=7842306 ; /***see the Lpauid from just previous output***/
run; 
proc sql;
create table Bell as
select
a.AsmntYr,
a.AsmntVint,
b.RFI_ASSEINVENTID as ASSEINVENTID label="ASSEINVENTID",
a.LpauID,
a.AsseId,
a.TaxJurid,
a.AsmntJurID,
a.Acc,
a.AsseName,
a.PROP_QTY,
a.PctT,
a.PctE,
a.PctG,
a.SchaBaseCost,
a.SchbFctr,
a.SchcFctr,
a.SchdFctr,
a.SOPA_SCHED_D_CODE as SCHED_D_CODE label= "SCHED_D_CODE",
a.Asmnt,
a.AsmntT,
a.AsmntE,
a.AsmntG,
a.InvNalFlag,
a.SOP_UTILIZATION_PERCENT,
b.RFI_LENGTH as RFI_LENGTH label="RFI_LENGTH",
b.RFI_SHEATHSTRANDS as SHEATHSTRANDS label="SHEATHSTRANDS",
b.RFI_STRANDSOWNED as STRANDSOWNED label="STRANDSOWNED",
b.RFI_STRANDSLIT as RFI_STRANDSLIT label="STRANDSLIT",
a.YEAR_BUILT
from SROT_TEL&TJ._Bell as a
left join &TJ._Bell as b on a.LPAUID=b.RFI_LPAUID;
quit;
  /***export for joining in arcmap***/
proc export outfile="C:\_LOCALdata\ALL_Chetan\GIS_Job\MD-Bighorn-2017\Alpasfile\SR\&TJ.BELL.xlsx"
data=BELL
dbms=xlsx replace;
run;

 
/***CABLE DISTRIBUTION***/
proc sql;
create table rficbl as
select *
from Alpas.Algv_Rfi_cbl_tfac
where RFI_AY_ASMNT_YEAR=2016 and RFI_IMPORT_EXPORT="I";
run;
proc sql;
create table &TJ._cbl as
select *
from rficbl 
where RFI_TAXJUR in (&TJID) and RFI_RECTYPE="FIBR";
run;
/**************************SHAW**********************/
data &TJ._Shaw;
set &TJ._cbl;
if  RFI_ASSEINVENTID in('CN-SH13-30f','CN-SH40-30f');
run;
data SROT_CBL_&TJ;
set ClosingBal2;
if TJcode in (&TJID) and ptcode="CBL" ;
run; 
data SROT_CBL_&TJ._Final(keep=PtCode AsmntYr AsmntVint LpauID AsseId TaxJurid TJName AsmntJurID Acc AsseName TJtype PROP_QTY PctT PctE PctG SchaBaseCost SchbFctr SchcFctr SchdFctr SOPA_SCHED_D_CODE Asmnt AsmntT AsmntE AsmntG InvNalFlag SOP_UTILIZATION_PERCENT SOP_ATS_LSD_FROM SOP_ATS_QTR_SECTION_FROM SOP_ATS_SECTION_FROM SOP_ATS_TOWNSHIP_FROM SOP_ATS_RANGE_FROM  SOP_ATS_MERIDIAN_FROM SOP_ATS_LSD_TO SOP_ATS_QTR_SECTION_TO SOP_ATS_SECTION_TO SOP_ATS_TOWNSHIP_TO SOP_ATS_RANGE_TO SOP_ATS_MERIDIAN_TO SOP_PLAN_FROM SOP_BLOCK_FROM SOP_LOT_FROM SOP_PLAN_TO SOP_BLOCK_TO SOP_LOT_TO YEAR_BUILT);
set SROT_CBL_&TJ;
run; 
/*****Shaw*/
data SROT_CBL&TJ._SHAW;
set SROT_CBL_&TJ._Final;
if Lpauid IN (7829998) ;
run; 
proc sql;
create table Shaw as
select
a.AsmntYr,
a.AsmntVint,
b.RFI_ASSEINVENTID as ASSEINVENTID label="ASSEINVENTID",
a.LpauID,
a.AsseId,
a.TaxJurid,
a.AsmntJurID,
a.Acc,
a.AsseName,
a.PROP_QTY,
a.PctT,
a.PctE,
a.PctG,
a.SchaBaseCost,
a.SchbFctr,
a.SchcFctr,
a.SchdFctr,
a.SOPA_SCHED_D_CODE as SCHED_D_CODE label= "SCHED_D_CODE",
a.Asmnt,
a.AsmntT,
a.AsmntE,
a.AsmntG,
a.InvNalFlag,
a.SOP_UTILIZATION_PERCENT,
b.RFI_LENGTH as RFI_LENGTH label="RFI_LENGTH",
b.RFI_SHEATHSTRANDS as SHEATHSTRANDS label="SHEATHSTRANDS",
b.RFI_STRANDSOWNED as STRANDSOWNED label="STRANDSOWNED",
b.RFI_STRANDSLIT as RFI_STRANDSLIT label="STRANDSLIT",
a.YEAR_BUILT
from SROT_CBL&TJ._SHAW as a
left join &TJ._Shaw as b on a.LPAUID=b.RFI_LPAUID;
quit;
   /***export for joining in arcmap***/
proc export outfile="C:\_LOCALdata\ALL_Chetan\GIS_Job\MD-Bighorn-2017\Alpasfile\SR\&TJ.SHAW.xlsx"
data=SHAW
dbms=xlsx replace;
run;

/****Self Reported Others*****/
data SROT_&TJ;
set ClosingBal2;
if TJcode in (&TJID ) and ptcode not in ("WL",'PL') ;
run; 
data SROT_&TJ._PreFinal1(keep=PtCode AsmntYr AsmntVint LpauID AsseId TaxJurid TJName AsmntJurID Acc AsseName TJtype PROP_QTY PctT PctE PctG SchaBaseCost SchbFctr SchcFctr SchdFctr SOPA_SCHED_D_CODE Asmnt AsmntT AsmntE AsmntG InvNalFlag SOP_UTILIZATION_PERCENT SOP_ATS_LSD_FROM SOP_ATS_QTR_SECTION_FROM SOP_ATS_SECTION_FROM SOP_ATS_TOWNSHIP_FROM SOP_ATS_RANGE_FROM  SOP_ATS_MERIDIAN_FROM SOP_ATS_LSD_TO SOP_ATS_QTR_SECTION_TO SOP_ATS_SECTION_TO SOP_ATS_TOWNSHIP_TO SOP_ATS_RANGE_TO SOP_ATS_MERIDIAN_TO SOP_PLAN_FROM SOP_BLOCK_FROM SOP_LOT_FROM SOP_PLAN_TO SOP_BLOCK_TO SOP_LOT_TO YEAR_BUILT LABEL4);
set SROT_&TJ;
LABEL4=catx('-', SOP_ATS_SECTION_FROM,SOP_ATS_TOWNSHIP_FROM,SOP_ATS_RANGE_FROM,SOP_ATS_MERIDIAN_FROM);
run;
data SROT_&TJ._PreFinal2(keep=PtCode AsmntYr AsmntVint LpauID AsseId TaxJurid TJName AsmntJurID Acc AsseName TJtype PROP_QTY PctT PctE PctG SchaBaseCost SchbFctr SchcFctr SchdFctr SOPA_SCHED_D_CODE Asmnt AsmntT AsmntE AsmntG InvNalFlag SOP_UTILIZATION_PERCENT SOP_ATS_LSD_FROM SOP_ATS_QTR_SECTION_FROM SOP_ATS_SECTION_FROM SOP_ATS_TOWNSHIP_FROM SOP_ATS_RANGE_FROM  SOP_ATS_MERIDIAN_FROM SOP_ATS_LSD_TO SOP_ATS_QTR_SECTION_TO SOP_ATS_SECTION_TO SOP_ATS_TOWNSHIP_TO SOP_ATS_RANGE_TO SOP_ATS_MERIDIAN_TO SOP_PLAN_FROM SOP_BLOCK_FROM SOP_LOT_FROM SOP_PLAN_TO SOP_BLOCK_TO SOP_LOT_TO YEAR_BUILT LABEL4);
set SROT_&TJ;
LABEL4=catx('-', SOP_ATS_SECTION_TO,SOP_ATS_TOWNSHIP_TO,SOP_ATS_RANGE_TO,SOP_ATS_MERIDIAN_TO);
run;
DATA SROT_&TJ._PreFinal;
SET SROT_&TJ._PreFinal1
 SROT_&TJ._PreFinal2;
RUN;
DATA SROT_&TJ._Final;
SET SROT_&TJ._PreFinal;
IF LABEL4 NOT EQ "";
RUN;
PROC SORT DATA=SROT_&TJ._Final NODUPKEYS OUT=SROT_&TJ._Final DUPOUT=REPEAT;
BY LPAUID;
RUN;
/*****Export the SR Others***/
proc export outfile="C:\_LOCALdata\ALL_Chetan\GIS_Job\MD-Bighorn-2017\Alpasfile\SR\SROther.xlsx"
data=SROT_&TJ._Final
dbms=dbf replace;
run;
/********end of the program***/
