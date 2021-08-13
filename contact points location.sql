SELECT ps.party_id AS "Party Id",
       ca.cust_account_id AS "Account Id",
       ca.account_number AS "Account Number",
       ca.status AS "Account Status",
       cp.contact_point_id AS "Id",
       cp.contact_point_type AS "Type",
       cp.owner_table_name AS "Owner Table Name",
       cp.status AS "Status",
       su.site_use_code AS "Site Use Code",
       su.status AS "Site Use Status",
       su.location AS "Site Use Location"
FROM "bigquery"."atd_dlk_ebs_data"."ar_hz_contact_points_gg" cp
LEFT JOIN "bigquery"."atd_dlk_ebs_data"."ar_hz_party_sites_gg" ps ON cp.owner_table_id = ps.party_site_id
LEFT JOIN "bigquery"."atd_dlk_ebs_data"."ar_hz_cust_acct_sites_all_gg" sa ON owner_table_id = sa.party_site_id
LEFT JOIN "bigquery"."atd_dlk_ebs_data"."ar_hz_cust_accounts_gg" ca ON sa.cust_account_id = ca.cust_account_id
LEFT JOIN "bigquery"."atd_dlk_ebs_data"."ar_hz_cust_site_uses_all_gg" su ON sa.cust_acct_site_id = su.cust_acct_site_id
WHERE OWNER_TABLE_NAME = 'HZ_PARTY_SITES'
  AND LOCATION IS NOT NULL
LIMIT 100