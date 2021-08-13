WITH ctebi AS
(
SELECT     cl.invoicecode,
cl.linenumber,
Max(cl.units)  AS units,
Max(cl.sales)  AS sales,
gl.promotionid AS aspirepromotionid
/* -- ,cl.GLTransactionID , */
CAST( MAX(
CASE
WHEN gl.isnotgoalattain <> '1' THEN cl.units
ELSE '0'
END ) AS VARCHAR ) AS goalunits
FROM       hivegcs.art.marketing_claim cl
INNER JOIN hivegcs.art.marketing_gltransaction gl
ON         cl.gltransactionid = gl.gltransactionid
WHERE      1 = 1
AND        gl.status <> 'Denied'
AND        cl.invoicedate BETWEEN '2021-01-01 00:00:00' AND        '2021-04-12 00:00:00'
/* --AND  cl.INVOICECODE='S150017266'   */
GROUP BY   cl.invoicecode,
cl.linenumber,
gl.promotionid ), cte_dhp AS
(
SELECT *
FROM   bigquery.atd_dlk_ebs.reporting_xxatdrp_sales_history_vw ds
/* --PRD_DS_RAW.APPS.XXATDRP_SALES_HISTORY DS   */
WHERE  1 = 1
AND    ( (
DATE(ds.invoice_date) BETWEEN DATE('2021-01-01') AND    DATE('2021-04-12') ) )
/* --AND '2021-04-12 00:00:00.000') ) ), cte_customer AS (   */SELECT *
FROM   snowflake_prd_ds_raw_dw.dw.dim_customer c
/* --PRD_DS_RAW.DW_DATA.DIM_CUSTOMER c   */
WHERE  1 = 1
/* --and c.location_cd='640063'     */
AND    currentflag = '1' ), cte_program AS
(
SELECT *
FROM   msbi_uat.dw.dim_program dp ), ctebi_with_location AS
(
SELECT     dd.date_id,
hp.invoice_no      AS invoicecode,
hp.invoice_line_no AS linenumber,
c.customer_cd,
c.location_cd,
c.dba_nm AS location_name,
pd.product_cd,
dp.program_cd,
dp.program_nm,
dp.aspirepromotionid,
a.units           AS aspire_unit,
a.sales           AS aspire_sales,
a.goalunits       AS goalunits,
hp.quantity       AS hp_units,
hp.gl_total_sales AS hp_sales
FROM       cte_dhp hp
INNER JOIN snowflake_prd_ds_raw_dw.dw.dim_date dd
ON         dd.calendar_dt = hp.invoice_date
INNER JOIN cte_customer c
ON         c.customer_cd = hp.ship_to_customer_no
AND        c.location_cd = hp.ship_to_location
INNER JOIN snowflake_prd_ds_raw_dw.dw.dim_product pd
ON         pd.product_cd = hp.product
INNER JOIN ctebi a
ON         hp.invoice_no = a.invoicecode
AND        CAST(hp.invoice_line_no AS VARCHAR) = CAST(a.linenumber AS VARCHAR)
INNER JOIN msbi_uat.dw.dim_program dp
ON         CAST(dp.aspirepromotionid AS VARCHAR) = CAST(a.aspirepromotionid AS VARCHAR)
WHERE      a.goalunits <> '0' ), ctebi_with_location_sum AS
(
SELECT   customer_cd,
location_cd,
location_name,
program_cd,
program_nm,
aspirepromotionid,
SUM(CAST(aspire_unit AS DOUBLE))  AS aspire_unit,
SUM(CAST(aspire_sales AS DOUBLE)) AS aspire_sales,
SUM(CAST(hp_units AS DOUBLE))     AS hp_units,
SUM(CAST(hp_sales AS DOUBLE))     AS hp_sales
/* --,count(*)   */
FROM     ctebi_with_location
WHERE    1 = 1
/* --AND cl.INVOICEDATE between '2021-01-01 00:00:00'and '2021-04-12 00:00:00'   -----3,064,903     --and cl.GLTransactionID is not null     --GROUP BY cl.ORDERSOURCE;   */
GROUP BY customer_cd,
location_cd,
location_name,
program_cd,
aspirepromotionid,
program_nm ) , cte_earnings AS
(
SELECT CAST(year_to_date_purchases AS DOUBLE) AS earningsummaryunits,
*
FROM   snowflake_dmo_sandbox_mktg.marketing.xxatdar_earnings_summary_stg_20210512
WHERE  1=1
AND    org_id=82
AND    DATE(data_as_of_date)= DATE('2021-04-12')
/* --00:00:00')--2021-01-01 00:00:00--   ),       cte_Program_to_Earnings_by_location AS */
(
SELECT i.customer_cd,
i.location_cd,
i.location_name,
i.program_cd,
i.program_nm,
i.aspirepromotionid,
MAX(i.aspire_unit)         AS aspire_unit,
MAX(i.hp_units)            AS hp_units,
MAX(i.hp_sales)            AS hp_sales,
MAX(u.earningsummaryunits) AS earningsummary_units,
/* --(CASE       --          WHEN i.Program_cd = '21WHEELGROWTH' THEN 1       --      ELSE 0 END) AS ProgramType,  ( */
CASE
WHEN (
MAX(u.account_number) IS NULL
AND    MAX(u.location_number) IS NULL) THEN 1
/* --MAX(u.YearPurchases)  IS NULL THEN 1             */
ELSE 0
END) AS claimonly,
/* --(CASE      --           WHEN MAX(u.YEAR_TO_DATE_PURCHASES)  IS NULL THEN 1      --       ELSE 0  END) AS ClaimOnly, ( */
CASE
WHEN i.program_cd = '21WHEELGROWTH' THEN ROUND(MAX(i.hp_sales), 0)
ELSE 0
END) AS totalsales, (
CASE
WHEN i.program_cd <> '21WHEELGROWTH'THEN
MAX(u.earningsummaryunits)
ELSE
0
END) AS totalearningsummarysales, (
CASE
WHEN i.program_cd = '21WHEELGROWTH' THEN
0
ELSE
MAX((i.aspire_unit))
END) AS totalunits, (
CASE
WHEN MAX((i.aspire_unit)) = 0 THEN
'N'
ELSE
'Y'
END) AS isvalue, (
CASE
WHEN i.program_cd = '21WHEELGROWTH' THEN
(ROUND(MAX((i.hp_sales)), 0) - ROUND(MAX(u.earningsummaryunits), 0))
ELSE
MAX((i.aspire_unit)) - MAX(u.earningsummaryunits)
END ) AS difference2 ,
CASE
WHEN (
CASE
WHEN i.program_cd = '21WHEELGROWTH' THEN
(ROUND(MAX(i.hp_sales), 0) - ROUND(MAX(u.earningsummaryunits), 0))
ELSE
MAX(i.aspire_unit) - MAX(u.earningsummaryunits)
END )=0 THEN
'Y'
ELSE
'N'
END AS ismatch FROM ctebi_with_location_sum i LEFT OUTER JOIN cte_earnings u ON i.customer_cd = CAST(u.account_number AS VARCHAR(40))
AND
i.location_cd = CAST(u.location_number AS VARCHAR(40))
AND
i.program_cd = u.program_code GROUP BY i.customer_cd, i.location_cd, i.location_name, i.program_cd, i.program_nm, i.aspirepromotionid)SELECT customer_cd,
location_cd,
location_name,
program_cd,
program_nm,
aspirepromotionid,
aspire_unit,
hp_units,
hp_sales,
earningsummary_units,
claimonly,
totalsales,
totalearningsummarysales,
totalunits,
totalearningsummarysales,
totalunits,
isvalue,
difference2,
ismatch
FROM  cte_program_to_earnings_by_location limit 10