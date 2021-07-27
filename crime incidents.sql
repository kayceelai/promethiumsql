WITH crime_and_region AS
  (SELECT "mysql"."promethium"."US_REGIONS"."US_STATE" AS "State Code",
          "mysql"."promethium"."COMBINED_CRIME_INCIDENTS"."COMBINED_CRIME_INCIDENTS" AS "COMBINED_CRIME_INCIDENTS"
   FROM "mysql"."promethium"."COMBINED_CRIME_INCIDENTS"
   LEFT OUTER JOIN "mysql"."promethium"."US_REGIONS" ON ("mysql"."promethium"."COMBINED_CRIME_INCIDENTS"."REGION_CODE" = "mysql"."promethium"."US_REGIONS"."REGION_CODE"))
SELECT "State Code",
       SUM(COMBINED_CRIME_INCIDENTS) as "Total Crimes"
FROM crime_and_region
GROUP BY "State Code"