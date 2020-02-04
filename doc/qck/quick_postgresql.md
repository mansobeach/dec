psql s2boa_orc root

s2boa_orc=> \list

s2boa_orc=> \connect s2boa_orc

s2boa_orc=> \dt

s2boa_orc=> \d trigger_products

select id,filename,detection_date from trigger_products where filename like 'S2A_OPER_REP_PASS_5_MTI__20200123T194543_V20200123T193244_20200123T194228%' ;
   id   |                                   filename                                    |       detection_date      
--------+-------------------------------------------------------------------------------+----------------------------
 153775 | S2A_OPER_REP_PASS_5_MTI__20200123T194543_V20200123T193244_20200123T194228.EOF | 2020-01-23 19:50:51.753993
 160858 | S2A_OPER_REP_PASS_5_MTI__20200123T194543_V20200123T193244_20200123T194228     | 2020-01-27 09:12:45.885475
(2 rows)
