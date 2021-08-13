SELECT 
       ps.party_id as "Party Id",
       ca.cust_account_id as "Account Id",
       ca.account_number as "Account Number",
       ca.status as "Account Status",
       cp.contact_point_id as "Id",
       cp.contact_point_type as "Type",
       cp.owner_table_name as "Owner Table Name",
       cp.status as "Status",
       su.site_use_code as "Site Use Code",
       su.status as "Site Use Status",
       su.location as "Site Use Location"
FROM "bigquery"."atd_dlk_ebs_data"."ar_hz_contact_points_gg" cp
LEFT JOIN "bigquery"."atd_dlk_ebs_data"."ar_hz_party_sites_gg" ps ON cp.owner_table_id = ps.party_site_id
LEFT JOIN "bigquery"."atd_dlk_ebs_data"."ar_hz_cust_acct_sites_all_gg" sa ON owner_table_id = sa.party_site_id
LEFT JOIN "bigquery"."atd_dlk_ebs_data"."ar_hz_cust_accounts_gg" ca ON sa.cust_account_id = ca.cust_account_id
LEFT JOIN "bigquery"."atd_dlk_ebs_data"."ar_hz_cust_site_uses_all_gg" su ON sa.cust_acct_site_id = su.cust_acct_site_id
WHERE OWNER_TABLE_NAME = 'HZ_PARTY_SITES'
AND location IS NOT NULL
LIMIT 100