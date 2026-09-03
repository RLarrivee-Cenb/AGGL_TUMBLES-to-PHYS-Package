--------------------------------------------------------
--  File created - Thursday-April-02-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Table AGGL_TUMBLES_NEW
--------------------------------------------------------

  CREATE TABLE "TOLIVE"."AGGL_TUMBLES_NEW" 
   (	"DATEX" DATE, 
	"SHIFT" NUMBER, 
	"HALF" NUMBER, 
	"LINE" NUMBER, 
	"B58" NUMBER, 
	"B12" NUMBER, 
	"B38" NUMBER, 
	"B14" NUMBER, 
	"B4M" NUMBER, 
	"B28" NUMBER, 
	"BM28" NUMBER, 
	"A58" NUMBER, 
	"A12" NUMBER, 
	"A38" NUMBER, 
	"A14" NUMBER, 
	"A4M" NUMBER, 
	"A28" NUMBER, 
	"AM28" NUMBER, 
	"ACOMP" NUMBER, 
	"ACOMP200" NUMBER, 
	"B916" NUMBER, 
	"A916" NUMBER, 
	"COMP600" NUMBER, 
	"C600M200" NUMBER, 
	"B716" NUMBER, 
	"A716" NUMBER, 
	"TONS" NUMBER, 
	"HOURS" NUMBER, 
	"MTYPE" VARCHAR2(1 BYTE), 
	"ACOMP300" NUMBER, 
	"SAMPLE_DATE" DATE GENERATED ALWAYS AS ("DATEX"-.0625+(("SHIFT"-1)*8+("HALF"-1)*4)/24) VIRTUAL VISIBLE 
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 35651584 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "LIVE" ;

   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."DATEX" IS 'Shift Date';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."SHIFT" IS 'Shift Number';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."HALF" IS 'Shift Half';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."LINE" IS 'Pellet line number';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."B58" IS 'Before Tumbles +5/8 inch Percent, no longer used';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."B12" IS 'Before Tumbles +1/2 inch screen percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."B38" IS 'Before Tumbles +3/8 inch screen percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."B14" IS 'Before Tumbles +1/4 inch screen percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."B4M" IS 'Not used';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."B28" IS 'Before tumbles +28 mesh percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."BM28" IS 'Before tumbles -28 mesh percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."A58" IS 'After Tumbles +5/8 inch Percent, no longer used';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."A12" IS 'After Tumbles +1/2 inch screen percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."A38" IS 'After Tumbles +3/8 inch screen percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."A14" IS 'After Tumbles +1/4 inch screen percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."A4M" IS 'Not used';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."A28" IS 'After tumbles +28 mesh percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."AM28" IS 'After tumbles -28 mesh percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."ACOMP" IS 'Average compression lbs';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."ACOMP200" IS 'Standard Deviation Calc of the compression average minus 200';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."B916" IS 'Before tumbles +9/16 inch percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."A916" IS 'After tumbles +9/16 inch percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."B716" IS 'Before tumbles +7/16 inch percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."A716" IS 'After tumbles +7/16 inch percent';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."TONS" IS 'Line pellet tons for specified Shift Date/Shift/Half';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."HOURS" IS 'Grate hours for specified Shift Date/Shift/Half';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."MTYPE" IS 'Pellet Type (A=Acid, F=Flux)';
   COMMENT ON COLUMN "TOLIVE"."AGGL_TUMBLES_NEW"."ACOMP300" IS 'Standard Deviation Calc of the compression average minus 300';
   COMMENT ON TABLE "TOLIVE"."AGGL_TUMBLES_NEW"  IS 'Data sent from VMS on Minntac Tummbles data.';
  GRANT UPDATE ON "TOLIVE"."AGGL_TUMBLES_NEW" TO "R_TOLIVE_APP";
  GRANT SELECT ON "TOLIVE"."AGGL_TUMBLES_NEW" TO "R_TOLIVE_APP";
  GRANT INSERT ON "TOLIVE"."AGGL_TUMBLES_NEW" TO "R_TOLIVE_APP";
  GRANT DELETE ON "TOLIVE"."AGGL_TUMBLES_NEW" TO "R_TOLIVE_APP";
  GRANT SELECT ON "TOLIVE"."AGGL_TUMBLES_NEW" TO "R_TOLIVE_SELECT";
  GRANT SELECT ON "TOLIVE"."AGGL_TUMBLES_NEW" TO "VIEW_ONLY";
--------------------------------------------------------
--  DDL for Index AGGL_TUMBLES_NEW_PK
--------------------------------------------------------

  CREATE UNIQUE INDEX "TOLIVE"."AGGL_TUMBLES_NEW_PK" ON "TOLIVE"."AGGL_TUMBLES_NEW" ("DATEX", "SHIFT", "HALF", "LINE", "MTYPE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 6291456 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "LIVE" ;
--------------------------------------------------------
--  DDL for Index IX_AGGL_TUMBLES_NEW_SDATE
--------------------------------------------------------

  CREATE INDEX "TOLIVE"."IX_AGGL_TUMBLES_NEW_SDATE" ON "TOLIVE"."AGGL_TUMBLES_NEW" ("SAMPLE_DATE") 
  PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "LIVEINDEX" ;
--------------------------------------------------------
--  DDL for Trigger AGGL_TUMBLES_NEW_AR
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TOLIVE"."AGGL_TUMBLES_NEW_AR" AFTER INSERT OR UPDATE ON AGGL_TUMBLES_NEW
     REFERENCING NEW AS new OLD AS old
     FOR EACH ROW
DECLARE
    -- BEGIN Error variables
    c_Debug     error.error_sql%TYPE    := ''; -- Additional debug info for errors
    c_ErrorDesc error.error_desc%TYPE   := ''; -- Standard error variable
    c_ErrorSql  error.error_sql%TYPE    := ''; -- Standard error variable
    c_ProcName  error.pname%TYPE        := 'AGGL_TUMBLES_NEW_ar';-- Standard error variable
    n_Error     error.error_num%TYPE    := 0; -- Standard error variable
    n_ErrorDescLen      NUMBER  := 200; -- Max length of c_ErrorDesc variable
    -- END Error variables
BEGIN
    -- 20080320 Insert records into debug table to track any changes coming in
    -- We need to see if any "default" value records are coming in without the tumble data
    INSERT INTO AGGL_TUMBLES_NEW_debug (inserted_date, datex, shift, half, line, b916, b58, b12,
            b716, b38, b14, b4m, b28, bm28, a916, a58, a12,
            a716, a38, a14, a4m, a28, am28, acomp, acomp200,
            comp600, c600m200, tons, hours, mtype)
        VALUES (SYSDATE, :new.datex, :new.shift, :new.half, :new.line, :new.b916, :new.b58, :new.b12,
            :new.b716, :new.b38, :new.b14, :new.b4m, :new.b28, :new.bm28, :new.a916, :new.a58, :new.a12,
            :new.a716, :new.a38, :new.a14, :new.a4m, :new.a28, :new.am28, :new.acomp, :new.acomp200,
            :new.comp600, :new.c600m200, :new.tons, :new.hours, :new.mtype);
EXCEPTION
    WHEN OTHERS THEN
        -- Log error
        n_Error := SQLCODE;
        c_ErrorDesc := SUBSTR(SQLERRM, 1, n_ErrorDescLen);
        c_ErrorSql := c_ErrorSql || ' (' || c_Debug || ')';
        general.log_error(in_error_date=>SYSDATE, in_error_num=>n_Error, in_error_desc=>c_ErrorDesc, in_pname=>c_ProcName, in_error_sql=>c_ErrorSql);
END;
/
ALTER TRIGGER "TOLIVE"."AGGL_TUMBLES_NEW_AR" ENABLE;
--------------------------------------------------------
--  DDL for Trigger AGGL_TUMBLES_NEW_AS
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "TOLIVE"."AGGL_TUMBLES_NEW_AS" AFTER INSERT OR UPDATE ON TOLIVE.AGGL_TUMBLES_NEW  
BEGIN
 icp_to_met.tumbles_to_met; 
END;

/
ALTER TRIGGER "TOLIVE"."AGGL_TUMBLES_NEW_AS" ENABLE;
--------------------------------------------------------
--  Constraints for Table AGGL_TUMBLES_NEW
--------------------------------------------------------

  ALTER TABLE "TOLIVE"."AGGL_TUMBLES_NEW" ADD CONSTRAINT "AGGL_TUMBLES_NEW_PK" PRIMARY KEY ("DATEX", "SHIFT", "HALF", "LINE", "MTYPE")
  USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255 COMPUTE STATISTICS 
  STORAGE(INITIAL 6291456 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "LIVE"  ENABLE;
