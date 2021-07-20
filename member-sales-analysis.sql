SELECT A.COMPARE_YN AS "대조군여부",
       CASE
           WHEN D.MAX_SELL_DY IS NULL THEN '1.1년초과'
           WHEN date_diff('day',date_parse(C.MIN_SELL_DY,'%Y%m%d'), date_parse(D.MAX_SELL_DY,'%Y%m%d')) BETWEEN 0 AND 180 THEN '3.6개월미만'
           WHEN date_diff('day',date_parse(C.MIN_SELL_DY,'%Y%m%d'), date_parse(D.MAX_SELL_DY,'%Y%m%d')) BETWEEN 181 AND 365 THEN '2.6개월~1년이하'
           WHEN date_diff('day',date_parse(C.MIN_SELL_DY,'%Y%m%d'), date_parse(D.MAX_SELL_DY,'%Y%m%d')) > 365 THEN '1.1년초과'
       END AS "브랜드구매기간구분",
       A.DMT_YM AS "타깃휴면개월수구분",
       COUNT(DISTINCT A.MBR_NO) AS "대상고객수",
       COUNT(DISTINCT (CASE
                           WHEN B.MBR_NO IS NOT NULL THEN c.MBR_NO
                           ELSE NULL
                       END)) AS "구매고객수",
       SUM(CASE
               WHEN B.MBR_NO IS NOT NULL THEN C.PURC_CNT
               ELSE 0
           END) AS "구매건수",
       SUM(CASE
               WHEN B.MBR_NO IS NOT NULL THEN C.AMT
               ELSE 0
           END) AS "구매금액",
       COUNT(DISTINCT E.MBR_NO) AS "응모고객수"
FROM "hive"."promethium"."temp_cross_mbr" A
INNER JOIN "hive"."promethium"."membership" AA ON A.MBR_NO = AA.MBR_NO
LEFT OUTER JOIN "hive"."promethium"."temp_cross_mbr" B ON (A.MBR_NO = B.MBR_NO)
LEFT OUTER JOIN
  (SELECT A.MBR_NO,
          A.BRND,
          MIN(MIN_SELL_DY) AS MIN_SELL_DY,
          SUM(A.PURC_CNT) AS PURC_CNT,
          SUM(A.AMT) AS AMT
   FROM
     (SELECT MBR_NO,
             COMPANY||BRAND AS BRND,
             MIN(SELL_DY) AS MIN_SELL_DY,
             SUM(PURC_CNT) AS PURC_CNT,
             SUM(CASE
                     WHEN SAV_TGT_AMT = 0 THEN (PURC_AMT-TOT_DSC_AMT)
                     ELSE SAV_TGT_AMT + USE_PNT
                 END) AS AMT
      FROM "hive"."promethium"."sales"
      WHERE APRV_DY BETWEEN '20200224' AND '20200229'
      GROUP BY MBR_NO,
               COMPANY||BRAND
      HAVING SUM(CASE
                     WHEN SAV_TGT_AMT = 0 THEN (PURC_AMT-TOT_DSC_AMT)
                     ELSE SAV_TGT_AMT + USE_PNT
                 END) >= 1
      UNION ALL SELECT MBR_NO,
                       COMPANY||BRAND AS BRND,
                       MIN(SELL_DY) AS MIN_SELL_DY,
                       SUM(PURC_CNT) AS PURC_CNT,
                       SUM(CASE
                               WHEN APRV_DY = '29991231' THEN (PURC_AMT-TOT_DSC_AMT)
                               WHEN APRV_DY <> '29991231'
                                    AND SAV_TGT_AMT > 0 THEN (SAV_TGT_AMT)
                               WHEN APRV_DY <> '29991231'
                                    AND SAV_TGT_AMT = 0
                                    AND use_pnt = 0 THEN (PURC_AMT-TOT_DSC_AMT)
                               WHEN APRV_DY <> '29991231'
                                    AND SAV_TGT_AMT = 0
                                    AND use_pnt > 0 THEN (use_pnt)
                               ELSE 0
                           END) AS AMT
      FROM "hive"."promethium"."sales"
      WHERE SELL_DY BETWEEN '20200224' AND '20200229'
        AND COMPANY||BRAND IN ('DAEWOO')
      GROUP BY MBR_NO,
               COMPANY||BRAND
      HAVING SUM(CASE
                     WHEN APRV_DY = '29991231' THEN (PURC_AMT-TOT_DSC_AMT)
                     WHEN APRV_DY <> '29991231'
                          AND SAV_TGT_AMT > 0 THEN (SAV_TGT_AMT)
                     WHEN APRV_DY <> '29991231'
                          AND SAV_TGT_AMT = 0
                          AND use_pnt = 0 THEN (PURC_AMT-TOT_DSC_AMT)
                     WHEN APRV_DY <> '29991231'
                          AND SAV_TGT_AMT = 0
                          AND use_pnt > 0 THEN (use_pnt)
                     ELSE 0
                 END) >= 1) A
   GROUP BY A.MBR_NO,
            A.BRND) C ON A.MBR_NO = C.MBR_NO
LEFT OUTER JOIN
  (SELECT MBR_NO,
          COMPANY||BRAND AS BRND,
          MAX(SELL_DY) AS MAX_SELL_DY
   FROM "hive"."promethium"."sales"
   WHERE APRV_DY <= '20200223'
   GROUP BY MBR_NO,
            COMPANY||BRAND
   UNION
 SELECT MBR_NO,
        COMPANY||BRAND AS BRND,
        MAX(SELL_DY) AS MAX_SELL_DY
   FROM "hive"."promethium"."sales"
   WHERE SELL_DY <= '20200223'
     AND COMPANY||BRAND IN ('DAEWOO')
   GROUP BY MBR_NO,
            COMPANY||BRAND) D ON A.MBR_NO = D.MBR_NO
AND C.BRND = D.BRND

LEFT OUTER JOIN
  (SELECT MBR_NO
   FROM "hive"."promethium"."membership"
   WHERE EVT_SEQ = 1848
   GROUP BY MBR_NO) E ON A.MBR_NO = E.MBR_NO
GROUP BY A.COMPARE_YN,
         CASE
             WHEN D.MAX_SELL_DY IS NULL THEN '1.1년초과'
             WHEN date_diff('day',date_parse(C.MIN_SELL_DY,'%Y%m%d'), date_parse(D.MAX_SELL_DY,'%Y%m%d')) BETWEEN 0 AND 180 THEN '3.6개월미만'
             WHEN date_diff('day',date_parse(C.MIN_SELL_DY,'%Y%m%d'), date_parse(D.MAX_SELL_DY,'%Y%m%d')) BETWEEN 181 AND 365 THEN '2.6개월~1년이하'
             WHEN date_diff('day',date_parse(C.MIN_SELL_DY,'%Y%m%d'), date_parse(D.MAX_SELL_DY,'%Y%m%d')) > 365 THEN '1.1년초과'
         END,
         A.DMT_YM
ORDER BY A.COMPARE_YN,
         "브랜드구매기간구분",
         "타깃휴면개월수구분"