SELECT "Menu Item",
       "City",
       "State",
       "Franchisee Group",
       "Franchisee Parent",
       sum("seat_cnt") AS "Total Seats",
       sum("AMOUNT") AS "Revenue"
FROM
  ( SELECT "Menu Items"."NAME" AS "Menu Item",
           "Menu Items"."AMOUNT" AS "AMOUNT",
           "mysql"."promethium"."restaurant_orders"."created_dt" AS "created_dt",
           "mysql"."promethium"."restaurant_orders"."rest_nm" AS "rest_nm",
           "mysql"."promethium"."restaurant_orders"."city_nm" AS "City",
           "mysql"."promethium"."restaurant_orders"."state_nm" AS "State",
           "mysql"."promethium"."restaurant_orders"."country_nm" AS "country_nm",
           "mysql"."promethium"."restaurant_orders"."postal_cd" AS "postal_cd",
           "mysql"."promethium"."restaurant_orders"."franchisee_grp_no" AS "franchisee_grp_no",
           "mysql"."promethium"."restaurant_orders"."franchisee_grp_nm" AS "Franchisee Group",
           "mysql"."promethium"."restaurant_orders"."seat_cnt" AS "seat_cnt",
           "mysql"."promethium"."restaurant_orders"."royalty_pct" AS "royalty_pct",
           "mysql"."promethium"."restaurant_orders"."fran_rollup_nm" AS "Franchisee Parent",
           "mysql"."promethium"."restaurant_orders"."home_dlvry" AS "home_dlvry"
   FROM "oracle"."RDSORACLEFORPRESTO"."TLOG_PRODUCT_PLUNAMES" as "Menu Items"
   LEFT OUTER JOIN "mysql"."promethium"."restaurant_orders" ON ( "Menu Items"."REST_KEY" = "mysql"."promethium"."restaurant_orders"."rest_key" ) )
GROUP BY "Menu Item",
         "city",
         "State",
         "Franchisee Group",
         "Franchisee Parent"
LIMIT 100