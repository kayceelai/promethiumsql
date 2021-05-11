WITH d_tbl AS
  (SELECT "mysql"."promethium"."COMBINED_CRIME_INCIDENTS"."SERIES_ID" AS "SERIES_ID",
          "mysql"."promethium"."COMBINED_CRIME_INCIDENTS"."REGION_CODE" AS "REGION_CODE",
          "mysql"."promethium"."COMBINED_CRIME_INCIDENTS"."COMBINED_CRIME_INCIDENTS" AS "COMBINED_CRIME_INCIDENTS",
          "mysql"."promethium"."COMBINED_CRIME_INCIDENTS"."YEAR" AS "YEAR",
          "mysql"."promethium"."US_REGIONS"."REGION_CODE" AS "REGION_CODE2",
          "mysql"."promethium"."US_REGIONS"."REGION_NAME" AS "REGION_NAME",
          "mysql"."promethium"."US_REGIONS"."US_STATE" AS "US_STATE"
   FROM "mysql"."promethium"."COMBINED_CRIME_INCIDENTS"
   LEFT OUTER JOIN "mysql"."promethium"."US_REGIONS" ON ("mysql"."promethium"."COMBINED_CRIME_INCIDENTS"."REGION_CODE" = "mysql"."promethium"."US_REGIONS"."REGION_CODE")
   LIMIT 100)
SELECT REGION_CODE,
       COMBINED_CRIME_INCIDENTS
FROM d_tbl
ORDER BY COMBINED_CRIME_INCIDENTS DESC