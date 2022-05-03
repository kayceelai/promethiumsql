SELECT 
       site_uses.status AS "Site Use Status",
       site_uses.location AS "Site Use Location",
       contact_points.status AS "Contact Point Status",
       site_uses.site_use_code AS "Site Use Code",
       party_sites.party_id AS "Party Id",
       cust_accounts.cust_account_id AS "Account Id",
       cust_accounts.account_number AS "Account Number",
       cust_accounts.status AS "Account Status",
       contact_points.contact_point_id AS "Id",
       contact_points.contact_point_type AS "Type",
       contact_points.owner_table_name AS "Owner Table Name"
FROM "bigquery"."atd_dlk_ebs_data"."ar_hz_contact_points_gg" contact_points
LEFT JOIN "bigquery"."atd_dlk_ebs_data"."ar_hz_party_sites_gg" party_sites ON contact_points.owner_table_id = party_sites.party_site_id
LEFT JOIN "bigquery"."atd_dlk_ebs_data"."ar_hz_cust_acct_sites_all_gg" sites_all ON owner_table_id = sites_all.party_site_id
LEFT JOIN "bigquery"."atd_dlk_ebs_data"."ar_hz_cust_accounts_gg" cust_accounts ON sites_all.cust_account_id = cust_accounts.cust_account_id
LEFT JOIN "bigquery"."atd_dlk_ebs_data"."ar_hz_cust_site_uses_all_gg" site_uses ON sites_all.cust_acct_site_id = site_uses.cust_acct_site_id
WHERE OWNER_TABLE_NAME = 'HZ_PARTY_SITES'
  AND LOCATION IS NOT NULL
LIMIT 1000