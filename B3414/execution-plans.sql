EXPLAIN PLAN  
  SET STATEMENT_ID = 'sel1'
  FOR;
    SELECT * FROM CLIENTS;

SELECT * FROM PLAN_TABLE;

DELETE FROM PLAN_TABLE;


SELECT PLAN_TABLE_OUTPUT FROM TABLE(DBMS_XPLAN.DISPLAY());