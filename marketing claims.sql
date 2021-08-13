WITH ctebi AS (				
  select				
    cl.invoiceCode,				
    cl.LineNumber,				
    MAX(cl.Units) AS Units,				
    MAX(cl.Sales) AS Sales,				
    gl.PromotionID AS AspirePromotionID -- ,cl.GLTransactionID				
,				
    cast(				
      MAX(				
        CASE WHEN gl.IsNotGoalAttain <> '1' THEN cl.Units ELSE '0' END				
      ) as varchar				
    ) AS GoalUnits				
  from				
    hivegcs.art.marketing_claim cl				
    inner join hivegcs.art.marketing_gltransaction gl on cl.GLTransactionID = gl.GLTransactionID				
  where				
    1 = 1				
    and gl.Status <> 'Denied'				
    AND cl.INVOICEDATE between '2021-01-01 00:00:00'				
    and '2021-04-12 00:00:00' --AND  cl.INVOICECODE='S150017266'				
  GROUP BY				
    cl.InvoiceCode,				
    cl.LineNumber,				
    gl.PromotionID				
),				
cte_DHP as (				
  select				
    *				
  from				
    bigquery.atd_dlk_ebs.reporting_xxatdrp_sales_history_vw DS --PRD_DS_RAW.APPS.XXATDRP_SALES_HISTORY DS				
  where				
    1 = 1				
    and (				
      (				
        date(DS.INVOICE_DATE) between DATE('2021-01-01')				
        and DATE('2021-04-12')				
      )				
    ) --AND '2021-04-12 00:00:00.000') )				
),				
cte_customer as (				
  select				
    *				
  from				
    snowflake_prd_ds_raw_dw.DW.DIM_CUSTOMER C --PRD_DS_RAW.DW_DATA.DIM_CUSTOMER c				
  where				
    1 = 1 --and c.location_cd='640063'				
    and currentflag = '1'				
),				
cte_Program as (				
  select				
    *				
  from				
    msbi_uat.DW.Dim_Program dp				
),				
ctebi_with_Location as (				
  select				
    dd.date_id,				
    hp.Invoice_no as invoiceCode,				
    hp.Invoice_line_no as LineNumber,				
    c.Customer_cd,				
    c.Location_cd,				
    c.DBA_NM as Location_Name,				
    pd.Product_cd,				
    dp.Program_cd,				
    dp.Program_nm,				
    dp.AspirePromotionID,				
    a.Units as AsPire_Unit,				
    a.Sales as AsPire_Sales,				
    a.GoalUnits AS GoalUnits,				
    hp.quantity as hp_Units,				
    hp.GL_TOTAL_SALES as hp_Sales				
  from				
    cte_DHP hp				
    inner join snowflake_prd_ds_raw_dw.DW.DIM_DATE dd on dd.CALENDAR_DT = hp.INVOICE_DATE				
    inner JOIN cte_customer c ON c.Customer_cd = hp.SHIP_TO_CUSTOMER_NO				
    and c.Location_cd = hp.SHIP_TO_LOCATION				
    inner join snowflake_prd_ds_raw_dw.DW.DIM_PRODUCT pd on pd.Product_cd = hp.Product				
    inner join ctebi a ON hp.Invoice_No = a.invoiceCode				
    and cast(hp.Invoice_line_no as varchar) = cast(a.LineNumber as varchar)				
    inner join msbi_uat.DW.Dim_Program dp on cast(dp.AspirePromotionID as varchar) = cast(a.AspirePromotionID as varchar)				
  where				
    a.GoalUnits <> '0'				
),				
ctebi_with_Location_sum as (				
  select				
    Customer_cd,				
    Location_cd,				
    Location_Name,				
    Program_cd,				
    Program_nm,				
    AspirePromotionID,				
    SUM(cast(AsPire_Unit as double)) AS AsPire_Unit,				
    sum(cast(AsPire_Sales as double)) as AsPire_Sales,				
    sum(cast(hp_Units as double)) as hp_Units,				
    sum(cast(hp_Sales as double)) as hp_Sales --,count(*)				
  from				
    ctebi_with_Location				
  where				
    1 = 1 --AND cl.INVOICEDATE between '2021-01-01 00:00:00'and '2021-04-12 00:00:00'   -----3,064,903				
    --and cl.GLTransactionID is not null				
    --GROUP BY cl.ORDERSOURCE;				
  GROUP BY				
    Customer_cd,				
    Location_cd,				
    Location_Name,				
    Program_cd,				
    AspirePromotionID,				
    Program_nm				
)				
, cte_Earnings as (				
select  CAST(YEAR_TO_DATE_PURCHASES as double) AS EarningSummaryUnits,*				
from				
snowflake_dmo_sandbox_mktg.MARKETING.XXATDAR_EARNINGS_SUMMARY_STG_20210512				
 where 1=1				
  and ORG_ID=82				
  and Date(DATA_AS_OF_DATE)= Date('2021-04-12') --00:00:00')--2021-01-01 00:00:00--				
  ),				
      cte_Program_to_Earnings_by_location				
AS (SELECT i.Customer_cd,				
           i.Location_cd,				
           i.Location_NAME,				
           i.Program_cd,				
           i.Program_nm,				
           i.AspirePromotionID,				
           MAX(i.AsPire_Unit) AS AsPire_Unit,				
           MAX(i.hp_Units) AS hp_Units,				
           MAX(i.hp_Sales) AS hp_Sales,				
           MAX(u.EarningSummaryUnits) AS EarningSummary_Units,				
		    --(CASE		
      --          WHEN i.Program_cd = '21WHEELGROWTH' THEN 1				
      --      ELSE 0 END) AS ProgramType,				
				
				  (CASE
                WHEN  (MAX(u.ACCOUNT_NUMBER)  IS NULL  AND MAX(u.LOCATION_NUMBER) IS NULL)  THEN 1   --MAX(u.YearPurchases)  IS NULL THEN 1				
            ELSE 0  END) AS ClaimOnly,				
				
			  --(CASE	
     --           WHEN MAX(u.YEAR_TO_DATE_PURCHASES)  IS NULL THEN 1				
     --       ELSE 0  END) AS ClaimOnly,				
			(CASE	
                WHEN i.Program_cd = '21WHEELGROWTH' THEN				
           ROUND(MAX(i.hp_Sales), 0)  ELSE 0  END) AS TotalSales,				
		   (CASE		
                WHEN i.Program_cd <> '21WHEELGROWTH'THEN				
           MAX(u.EarningSummaryUnits)  ELSE 0  END) AS TotalEarningSummarySales,				
		   (CASE		
                WHEN i.Program_cd = '21WHEELGROWTH'  THEN				
           0  ELSE MAX((i.AsPire_Unit))  END) AS TotalUnits,				
		      (CASE		
                WHEN MAX((i.AsPire_Unit)) = 0 THEN				
           'N'  ELSE 'Y'  END) AS IsValue,				
				
           (CASE				
                WHEN i.Program_cd = '21WHEELGROWTH'  THEN				
           (ROUND(MAX((i.hp_Sales)), 0) - ROUND(MAX(u.EarningSummaryUnits), 0))				
                ELSE				
                    MAX((i.AsPire_Unit)) - MAX(u.EarningSummaryUnits)				
            END				
           ) AS Difference2				
		   , CASE WHEN    (CASE		
                WHEN i.Program_cd = '21WHEELGROWTH'  THEN				
           (ROUND(MAX(i.hp_Sales), 0) - ROUND(MAX(u.EarningSummaryUnits), 0))				
                ELSE				
                    MAX(i.AsPire_Unit) - MAX(u.EarningSummaryUnits)				
            END				
           )=0 THEN 'Y' ELSE 'N' END  AS IsMatch				
    FROM ctebi_with_Location_sum i				
        LEFT OUTER JOIN cte_Earnings u				
            ON i.Customer_cd = CAST(u.ACCOUNT_NUMBER AS VARCHAR(40))				
               AND i.Location_cd = CAST(u.LOCATION_NUMBER AS VARCHAR(40))				
               AND i.Program_cd = u.PROGRAM_CODE				
    GROUP BY i.Customer_cd,				
             i.Location_cd,				
             i.Location_NAME,				
             i.Program_cd,				
             i.Program_nm,				
             i.AspirePromotionID)				
select *				
from				
cte_Program_to_Earnings_by_location				
  --cte_Program				
  --  cte_customer				
limit 10