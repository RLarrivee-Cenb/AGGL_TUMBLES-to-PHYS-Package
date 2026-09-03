create or replace PACKAGE BODY PKG_AGGL_PHYS_V1 AS

/* ======================= AGGL_TUMBLES Code ======================== */

  g_target_AGGL_table VARCHAR2(30) := 'AGGL_TUMBLES_NEW';
  g_target_phys_table VARCHAR2(30) := 'PHYS';
  g_proc_name VARCHAR2(64);
  g_enable_logging BOOLEAN := TRUE;

  PROCEDURE log_info(p_loc IN VARCHAR2, p_msg IN VARCHAR2) IS
  BEGIN
    IF g_enable_logging THEN
      logger_pkg.log_msg(p_loc, p_msg, 'INFO');
    END IF;
  END log_info;

  PROCEDURE log_warn(p_loc IN VARCHAR2, p_msg IN VARCHAR2) IS
  BEGIN
    IF g_enable_logging THEN
      logger_pkg.log_msg(p_loc, p_msg, 'WARN');
    END IF;
  END log_warn;

  PROCEDURE AGGL_Start_Logger IS
  BEGIN
    logger_pkg.start_run;
    logger_pkg.set_context('PKG_AGGL_PHYS_V1', 'FILL_AGGL_TUMBLES');
    log_info('AGGL_Start_Logger', 'Logger initialized');
  END AGGL_Start_Logger;

  PROCEDURE set_target_table(tablename IN VARCHAR2) IS
  BEGIN
    g_target_AGGL_table := UPPER(tablename);
    logger_pkg.log_msg('set_target_table','Target table set to ' || g_target_AGGL_table,'INFO');
  END set_target_table;

  PROCEDURE set_phys_target_table(p_table_name IN VARCHAR2) IS
  BEGIN
    g_target_phys_table := UPPER(TRIM(p_table_name));
    logger_pkg.log_msg('set_phys_target_table','Target PHYS table set to ' || g_target_phys_table,'INFO');
  END set_phys_target_table;

  PROCEDURE seed_missing_half_shift_rows (p_shift_date IN DATE) IS
    v_proc_name VARCHAR2(32) := 'seed_missing_half_shift_rows';
  BEGIN
    log_info(v_proc_name, 'Start for shift_date=' || TO_CHAR(p_shift_date,'YYYY-MM-DD'));

    EXECUTE IMMEDIATE '
      INSERT INTO ' || g_target_AGGL_table || ' (
        datex, shift, half, line,
        b58, b12, b38, b14, b4m, b28, bm28,
        a58, a12, a38, a14, a4m, a28, am28,
        acomp, acomp200, acomp300,
        b916, a916, comp600, c600m200, b716, a716,
        tons, hours, mtype
      )
      SELECT :1, s.shift, h.half, l.line,
             0,0,0,0,0,0,0,
             0,0,0,0,0,0,0,
             0,0,0,
             0,0,NULL,NULL,0,0,
             0,0,''F''
      FROM (SELECT 1 shift FROM dual UNION ALL SELECT 2 FROM dual UNION ALL SELECT 3 FROM dual) s
      CROSS JOIN (SELECT 1 half FROM dual UNION ALL SELECT 2 FROM dual) h
      CROSS JOIN (SELECT 3 line FROM dual UNION ALL SELECT 4 FROM dual UNION ALL SELECT 5 FROM dual UNION ALL SELECT 6 FROM dual UNION ALL SELECT 7 FROM dual) l
      WHERE NOT EXISTS (
        SELECT 1
          FROM ' || g_target_AGGL_table || ' t
         WHERE TRUNC(t.datex) = TRUNC(:2)
           AND t.shift = s.shift
           AND t.half  = h.half
           AND t.line  = l.line
      )'
    USING TRUNC(p_shift_date), TRUNC(p_shift_date);

    log_info(v_proc_name, 'Completed for shift_date=' || TO_CHAR(p_shift_date,'YYYY-MM-DD'));
  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.log_error(v_proc_name, SQLERRM);
      RAISE;
  END seed_missing_half_shift_rows;

  FUNCTION GET_HOURS (
      p_shift_date IN DATE,
      p_shift      IN NUMBER,
      p_line       IN NUMBER,
      p_half       IN NUMBER DEFAULT NULL
  ) RETURN NUMBER
  IS
      v_sql         VARCHAR2(1000);
      v_hours       NUMBER := 0;
      v_id          NUMBER;
      v_hourly_view VARCHAR2(50);
  BEGIN
      g_proc_name := 'GET_HOURS';
      v_id := CASE p_line
                WHEN 3 THEN 4063
                WHEN 4 THEN 4001
                WHEN 5 THEN 4002
                WHEN 6 THEN 4058
                WHEN 7 THEN 4059
                ELSE NULL
              END;

      v_hourly_view := CASE
                         WHEN p_line IN (3,4,5) THEN 'west_main.west_hourly_agg2'
                         WHEN p_line IN (6,7)   THEN 'west_main.west_hourly_agg3'
                         ELSE NULL
                       END;

      IF v_id IS NULL OR v_hourly_view IS NULL THEN
        logger_pkg.log_msg('GET_HOURS','Shift_Date: ' || p_shift_date || ' Shift: ' || p_shift || ' Shift_Half: ' || p_half  || ' Line: ' || p_line || ' Invalid line','ERROR');
        RETURN 0;
      END IF;

      v_sql := 'SELECT ROUND(SUM(hour_total),4)
                FROM ' || v_hourly_view || '
                WHERE id = :1
                  AND shift = :2
                  AND TRUNC(timestamp) = TRUNC(:3)';

      IF p_half IS NOT NULL THEN
        v_sql := v_sql || ' AND half = :4';
        EXECUTE IMMEDIATE v_sql INTO v_hours USING v_id, p_shift, p_shift_date, p_half;
      ELSE
        EXECUTE IMMEDIATE v_sql INTO v_hours USING v_id, p_shift, p_shift_date;
      END IF;

      log_info('GET_HOURS',
               'shift_date=' || TO_CHAR(p_shift_date,'YYYY-MM-DD') ||
               ', shift=' || p_shift || ', line=' || p_line ||
               ', half=' || NVL(TO_CHAR(p_half),'NULL') ||
               ', hours=' || NVL(TO_CHAR(v_hours),'0'));

      RETURN ROUND(NVL(LEAST(NVL(v_hours,0), 4), 0), 4);

  EXCEPTION
    WHEN OTHERS THEN
      IF g_enable_logging THEN logger_pkg.log_error('GET_HOURS', SQLERRM); END IF;
      general.log_error(in_error_num=>SQLCODE,in_error_desc=>SQLERRM,in_pname=>g_proc_name,in_error_sql=>v_sql);
      RETURN 0;
  END GET_HOURS;

  FUNCTION GET_TONS (
      p_shift_date IN DATE,
      p_shift      IN NUMBER,
      p_line       IN NUMBER,
      p_half       IN NUMBER DEFAULT NULL
  ) RETURN NUMBER
  IS
      v_sql  VARCHAR2(2000);
      v_tons NUMBER := 0;
  BEGIN
      g_proc_name := 'GET_TONS';
      v_sql := 'SELECT ROUND(SUM(production_tons),4)
                FROM lab_phys_analysis
                WHERE lab_phys_type_id = 14
                  AND line_nbr = :1
                  AND shift_nbr8 = :2
                  AND TRUNC(shift_date8) = TRUNC(:3)';

      IF p_half IS NOT NULL THEN
        v_sql := v_sql || ' AND CASE WHEN MOD(shift_half8,2)=1 THEN 1 ELSE 2 END = :4';
        EXECUTE IMMEDIATE v_sql INTO v_tons USING p_line, p_shift, p_shift_date, p_half;
      ELSE
        EXECUTE IMMEDIATE v_sql INTO v_tons USING p_line, p_shift, p_shift_date;
      END IF;

      log_info('GET_TONS',
               'shift_date=' || TO_CHAR(p_shift_date,'YYYY-MM-DD') ||
               ', shift=' || p_shift || ', line=' || p_line ||
               ', half=' || NVL(TO_CHAR(p_half),'NULL') ||
               ', tons=' || NVL(TO_CHAR(v_tons),'0'));

      RETURN ROUND(NVL(v_tons,0), 4);

  EXCEPTION
    WHEN OTHERS THEN
      IF g_enable_logging THEN logger_pkg.log_error('GET_TONS', SQLERRM); END IF;
      general.log_error(in_error_num=>SQLCODE,in_error_desc=>SQLERRM,in_pname=>g_proc_name,in_error_sql=>v_sql);
      RETURN 0;
  END GET_TONS;

  FUNCTION Get_Pellet_Type(
      p_shift_date IN DATE,
      p_line_nbr   IN NUMBER
  ) RETURN VARCHAR2
  IS
      v_pellet_type VARCHAR2(10);
      v_step NUMBER;
  BEGIN
      g_proc_name := 'Get_Pellet_Type';

      v_step := CASE WHEN p_line_nbr IN (3,4,5) THEN 2 ELSE 3 END;
      v_pellet_type := GENERAL.GET_PELLET_TYPE(p_shift_date, v_step);

      IF UPPER(v_pellet_type) LIKE '%FLUX%' THEN
        log_info('GET_PELLET_TYPE', 'line=' || p_line_nbr || ', pellet_type=F');
        RETURN 'F';
      ELSIF UPPER(v_pellet_type) LIKE '%ACID%' THEN
        log_info('GET_PELLET_TYPE', 'line=' || p_line_nbr || ', pellet_type=A');
        RETURN 'A';
      ELSE
        IF g_enable_logging THEN logger_pkg.log_error('Get_Pellet_Type','Invalid pellet type: ' || v_pellet_type); END IF;
        RAISE_APPLICATION_ERROR(-20001,'Invalid pellet type: ' || v_pellet_type);
      END IF;
  END Get_Pellet_Type;

  PROCEDURE Fill_Aggl_Tumbles (p_shift_date IN DATE) IS
    CURSOR cur IS
      SELECT c.shift_date,c.shift,c.shift_half,c.line_nbr,
             NVL(bb.inch_5_8_pct,0) bb_inch_5_8_pct,
             NVL(bb.inch_1_2_pct,0) bb_inch_1_2_pct,NVL(bb.inch_3_8_pct,0) bb_inch_3_8_pct,
             NVL(bb.inch_1_4_pct,0) bb_inch_1_4_pct,NVL(bb.mesh_28_30_pct,0) bb_mesh_28_30_pct,
             NVL(bb.mesh_100_pct,0) bb_mesh_100_pct,NVL(bb.inch_9_16_pct,0) bb_inch_9_16_pct,
             NVL(bb.inch_7_16_pct,0) bb_inch_7_16_pct,
             NVL(ba.inch_5_8_pct,0) ba_inch_5_8_pct,
             NVL(ba.inch_1_2_pct,0) ba_inch_1_2_pct,NVL(ba.inch_3_8_pct,0) ba_inch_3_8_pct,
             NVL(ba.inch_1_4_pct,0) ba_inch_1_4_pct,NVL(ba.mesh_28_30_pct,0) ba_mesh_28_30_pct,
             NVL(ba.mesh_100_pct,0) ba_mesh_100_pct,NVL(ba.inch_9_16_pct,0) ba_inch_9_16_pct,NVL(ba.inch_7_16_pct,0) ba_inch_7_16_pct,
             c.average,c.comp200,c.comp300
      FROM lab_compression c
      JOIN lab_phys_analysis bb
        ON bb.lab_phys_type_id = 14
       AND TRUNC(bb.shift_date8) = TRUNC(c.shift_date)
       AND bb.shift_nbr8 = c.shift
       AND CASE WHEN MOD(bb.shift_half8,2)=1 THEN 1 ELSE 2 END = c.shift_half
       AND bb.line_nbr = c.line_nbr
      JOIN lab_phys_analysis ba
        ON ba.lab_phys_type_id = 15
       AND TRUNC(ba.shift_date8) = TRUNC(c.shift_date)
       AND ba.shift_nbr8 = c.shift
       AND CASE WHEN MOD(ba.shift_half8,2)=1 THEN 1 ELSE 2 END = c.shift_half
       AND ba.line_nbr = c.line_nbr
      WHERE TRUNC(c.shift_date) = TRUNC(p_shift_date)
        AND c.shift_half IN (1,2) AND c.shift IN (1,2,3) AND c.line_nbr IN (3,4,5,6,7)
        AND bb.start_wgt IS NOT NULL AND ba.start_wgt IS NOT NULL;

    v_b58 NUMBER := 0; v_b4m NUMBER := 0; v_a58 NUMBER := 0; v_a4m NUMBER := 0;
    v_comp600 NUMBER; v_c600m200 NUMBER; v_tons NUMBER; v_hours NUMBER; v_mtype VARCHAR2(1);
    v_bm28 NUMBER; v_am28 NUMBER;
    v_b916 NUMBER; v_a916 NUMBER;
  BEGIN
    g_proc_name := 'Fill_Aggl_Tumbles';
    set_target_table('aggl_tumbles_new');
    AGGL_Start_Logger;
    seed_missing_half_shift_rows(TRUNC(p_shift_date));

    log_info(g_proc_name, 'Start p_shift_date=' || TO_CHAR(p_shift_date,'YYYY-MM-DD'));

    FOR r IN cur LOOP
      v_tons := GET_TONS(r.shift_date, r.shift, r.line_nbr, r.shift_half);
      v_hours := GET_HOURS(r.shift_date, r.shift, r.line_nbr, r.shift_half);

      v_b58 := ROUND(r.bb_inch_5_8_pct,4);
      v_a58 := ROUND(r.ba_inch_5_8_pct,4);

      BEGIN
        v_mtype := GET_PELLET_TYPE(r.shift_date, r.line_nbr);
      EXCEPTION
        WHEN OTHERS THEN
          v_mtype := 'F';
          log_warn(g_proc_name, 'Defaulted mtype to F for line=' || r.line_nbr);
      END;

      v_comp600  := NULL;
      v_c600m200 := NULL;

      v_b916 := ROUND(CASE WHEN v_b58 <> 0 AND NVL(r.bb_inch_9_16_pct,0) = 0 THEN v_b58 ELSE NVL(r.bb_inch_9_16_pct,0) END, 4);
      v_a916 := ROUND(CASE WHEN v_a58 <> 0 AND NVL(r.ba_inch_9_16_pct,0) = 0 THEN v_a58 ELSE NVL(r.ba_inch_9_16_pct,0) END, 4);

      v_bm28 := 100 - (ROUND(v_b58,4)+ROUND(r.bb_inch_1_2_pct,4)+ROUND(r.bb_inch_7_16_pct,4)+ROUND(r.bb_inch_3_8_pct,4)+ROUND(r.bb_inch_1_4_pct,4)+ROUND(r.bb_mesh_28_30_pct,4));
      v_am28 := 100 - (ROUND(v_a58,4)+ROUND(r.ba_inch_1_2_pct,4)+ROUND(r.ba_inch_7_16_pct,4)+ROUND(r.ba_inch_3_8_pct,4)+ROUND(r.ba_inch_1_4_pct,4)+ROUND(r.ba_mesh_28_30_pct,4));

      log_info(g_proc_name,
               'Row date=' || TO_CHAR(r.shift_date,'YYYY-MM-DD') ||
               ', shift=' || r.shift || ', half=' || r.shift_half || ', line=' || r.line_nbr ||
               ', tons=' || NVL(TO_CHAR(v_tons),'0') || ', hours=' || NVL(TO_CHAR(v_hours),'0') ||
               ', mtype=' || NVL(v_mtype,'NULL'));

      EXECUTE IMMEDIATE '
        UPDATE ' || g_target_AGGL_table || ' t
           SET b916=:1,b12=:2,b716=:3,b38=:4,b14=:5,b28=:6,bm28=:7,
               a916=:8,a12=:9,a716=:10,a38=:11,a14=:12,a28=:13,am28=:14,
               acomp=:15,acomp200=:16,acomp300=:17,comp600=:18,c600m200=:19,
               tons=:20,hours=:21,b58=:22,b4m=:23,a58=:24,a4m=:25,mtype=:26
         WHERE t.datex=:27 AND t.shift=:28 AND t.half=:29 AND t.line=:30'
      USING v_b916, ROUND(r.bb_inch_1_2_pct,4), ROUND(r.bb_inch_7_16_pct,4),
            ROUND(r.bb_inch_3_8_pct,4), ROUND(r.bb_inch_1_4_pct,4), ROUND(r.bb_mesh_28_30_pct,4), ROUND(v_bm28,4),
            v_a916, ROUND(r.ba_inch_1_2_pct,4), ROUND(r.ba_inch_7_16_pct,4),
            ROUND(r.ba_inch_3_8_pct,4), ROUND(r.ba_inch_1_4_pct,4), ROUND(r.ba_mesh_28_30_pct,4), ROUND(v_am28,4),
            ROUND(r.average,4), ROUND(r.comp200,4), ROUND(r.comp300,4), v_comp600, v_c600m200,
            ROUND(v_tons,4), ROUND(v_hours,4), ROUND(v_b58,4), ROUND(v_b4m,4), ROUND(v_a58,4), ROUND(v_a4m,4),
            v_mtype, r.shift_date, r.shift, r.shift_half, r.line_nbr;

      log_info(g_proc_name, 'Updated row shift='||r.shift||', half='||r.shift_half||', line='||r.line_nbr);
    END LOOP;

    log_info(g_proc_name, 'End p_shift_date=' || TO_CHAR(p_shift_date,'YYYY-MM-DD'));

  EXCEPTION
    WHEN OTHERS THEN
      IF g_enable_logging THEN logger_pkg.log_error('Fill_Aggl_Tumbles', SQLERRM); END IF;
      general.log_error(in_error_num=>SQLCODE,in_error_desc=>SQLERRM,in_pname=>g_proc_name,in_error_sql=>'');
      RAISE;
  END Fill_Aggl_Tumbles;

  PROCEDURE fill_aggl_by_line_shift (
    p_shift_date IN DATE,
    p_line_nbr   IN NUMBER,
    p_shift      IN NUMBER,
    p_shift_half IN NUMBER
  ) IS
    v_shift_date         DATE;
    v_shift              NUMBER;
    v_shift_half         NUMBER;
    v_line_nbr           NUMBER;
    v_bb_inch_5_8_pct    NUMBER;
    v_bb_inch_1_2_pct    NUMBER;
    v_bb_inch_3_8_pct    NUMBER;
    v_bb_inch_1_4_pct    NUMBER;
    v_bb_mesh_28_30_pct  NUMBER;
    v_bb_mesh_100_pct    NUMBER;
    v_bb_inch_9_16_pct   NUMBER;
    v_bb_inch_7_16_pct   NUMBER;
    v_ba_inch_5_8_pct    NUMBER;
    v_ba_inch_1_2_pct    NUMBER;
    v_ba_inch_3_8_pct    NUMBER;
    v_ba_inch_1_4_pct    NUMBER;
    v_ba_mesh_28_30_pct  NUMBER;
    v_ba_mesh_100_pct    NUMBER;
    v_ba_inch_9_16_pct   NUMBER;
    v_ba_inch_7_16_pct   NUMBER;
    v_average            NUMBER;
    v_comp200            NUMBER;
    v_comp300            NUMBER;

    v_comp600   NUMBER;
    v_c600m200  NUMBER;
    v_tons      NUMBER;
    v_hours     NUMBER;
    v_mtype     VARCHAR2(1);

    v_b58 NUMBER := 0;
    v_b4m NUMBER := 0;
    v_a58 NUMBER := 0;
    v_a4m NUMBER := 0;

    v_bm28 NUMBER;
    v_am28 NUMBER;
    v_b916 NUMBER;
    v_a916 NUMBER;
  BEGIN
    g_proc_name := 'fill_aggl_by_line_shift';
    set_target_table('aggl_tumbles_new');
    AGGL_Start_Logger;

    log_info(g_proc_name,
      'Start p_shift_date=' || TO_CHAR(p_shift_date,'YYYY-MM-DD') ||
      ', p_shift=' || p_shift || ', p_half=' || p_shift_half || ', p_line=' || p_line_nbr);

    seed_missing_half_shift_rows(TRUNC(p_shift_date));

    BEGIN
      SELECT
        c.shift_date,c.shift,c.shift_half,c.line_nbr,
        NVL(bb.inch_5_8_pct,0),NVL(bb.inch_1_2_pct,0),NVL(bb.inch_3_8_pct,0),
        NVL(bb.inch_1_4_pct,0),NVL(bb.mesh_28_30_pct,0),NVL(bb.mesh_100_pct,0),
        NVL(bb.inch_9_16_pct,0),NVL(bb.inch_7_16_pct,0),
        NVL(ba.inch_5_8_pct,0),NVL(ba.inch_1_2_pct,0),NVL(ba.inch_3_8_pct,0),
        NVL(ba.inch_1_4_pct,0),NVL(ba.mesh_28_30_pct,0),NVL(ba.mesh_100_pct,0),
        NVL(ba.inch_9_16_pct,0),NVL(ba.inch_7_16_pct,0),
        c.average,c.comp200,c.comp300
      INTO
        v_shift_date,v_shift,v_shift_half,v_line_nbr,
        v_bb_inch_5_8_pct,v_bb_inch_1_2_pct,v_bb_inch_3_8_pct,v_bb_inch_1_4_pct,v_bb_mesh_28_30_pct,v_bb_mesh_100_pct,v_bb_inch_9_16_pct,v_bb_inch_7_16_pct,
        v_ba_inch_5_8_pct,v_ba_inch_1_2_pct,v_ba_inch_3_8_pct,v_ba_inch_1_4_pct,v_ba_mesh_28_30_pct,v_ba_mesh_100_pct,v_ba_inch_9_16_pct,v_ba_inch_7_16_pct,
        v_average,v_comp200,v_comp300
      FROM lab_compression c
      JOIN lab_phys_analysis bb
        ON bb.lab_phys_type_id = 14
       AND TRUNC(bb.shift_date8) = TRUNC(c.shift_date)
       AND bb.shift_nbr8 = c.shift
       AND CASE WHEN MOD(bb.shift_half8,2)=1 THEN 1 ELSE 2 END = c.shift_half
       AND bb.line_nbr = c.line_nbr
      JOIN lab_phys_analysis ba
        ON ba.lab_phys_type_id = 15
       AND TRUNC(ba.shift_date8) = TRUNC(c.shift_date)
       AND ba.shift_nbr8 = c.shift
       AND CASE WHEN MOD(ba.shift_half8,2)=1 THEN 1 ELSE 2 END = c.shift_half
       AND ba.line_nbr = c.line_nbr
      WHERE TRUNC(c.shift_date) = TRUNC(p_shift_date)
        AND c.shift = p_shift
        AND c.shift_half = p_shift_half
        AND c.line_nbr = p_line_nbr
        AND bb.start_wgt IS NOT NULL
        AND ba.start_wgt IS NOT NULL;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        log_warn(g_proc_name,
          'No source data; seeded row retained for date=' || TO_CHAR(p_shift_date,'YYYY-MM-DD') ||
          ', shift=' || p_shift || ', half=' || p_shift_half || ', line=' || p_line_nbr);
        RETURN;
    END;

    v_tons  := GET_TONS(v_shift_date, v_shift, v_line_nbr, v_shift_half);
    v_hours := GET_HOURS(v_shift_date, v_shift, v_line_nbr, v_shift_half);

    v_b58 := ROUND(v_bb_inch_5_8_pct,4);
    v_a58 := ROUND(v_ba_inch_5_8_pct,4);

    BEGIN
      v_mtype := GET_PELLET_TYPE(v_shift_date, v_line_nbr);
    EXCEPTION
      WHEN OTHERS THEN
        v_mtype := 'F';
        log_warn(g_proc_name, 'Defaulted mtype to F for line=' || v_line_nbr);
    END;

    v_comp600  := NULL;
    v_c600m200 := NULL;

    v_b916 := ROUND(CASE WHEN v_b58 <> 0 AND NVL(v_bb_inch_9_16_pct,0) = 0 THEN v_b58 ELSE NVL(v_bb_inch_9_16_pct,0) END, 4);
    v_a916 := ROUND(CASE WHEN v_a58 <> 0 AND NVL(v_ba_inch_9_16_pct,0) = 0 THEN v_a58 ELSE NVL(v_ba_inch_9_16_pct,0) END, 4);

    v_bm28 := 100 - (ROUND(v_b58, 4) + ROUND(v_bb_inch_1_2_pct, 4) + ROUND(v_bb_inch_7_16_pct, 4) + ROUND(v_bb_inch_3_8_pct, 4) + ROUND(v_bb_inch_1_4_pct, 4) + ROUND(v_bb_mesh_28_30_pct, 4));
    v_am28 := 100 - (ROUND(v_a58, 4) + ROUND(v_ba_inch_1_2_pct, 4) + ROUND(v_ba_inch_7_16_pct, 4) + ROUND(v_ba_inch_3_8_pct, 4) + ROUND(v_ba_inch_1_4_pct, 4) + ROUND(v_ba_mesh_28_30_pct, 4));

    log_info(g_proc_name,
      'Computed tons=' || NVL(TO_CHAR(v_tons),'0') || ', hours=' || NVL(TO_CHAR(v_hours),'0') ||
      ', comp600=NULL, c600m200=NULL');

    EXECUTE IMMEDIATE '
      UPDATE ' || g_target_AGGL_table || ' t
         SET b916 = :1,b12=:2,b716=:3,b38=:4,b14=:5,b28=:6,bm28=:7,
             a916=:8,a12=:9,a716=:10,a38=:11,a14=:12,a28=:13,am28=:14,
             acomp=:15,acomp200=:16,acomp300=:17,comp600=:18,c600m200=:19,
             tons=:20,hours=:21,b58=:22,b4m=:23,a58=:24,a4m=:25,mtype=:26
       WHERE TRUNC(t.datex) = TRUNC(:27) AND t.shift = :28 AND t.half = :29 AND t.line = :30'
    USING v_b916, ROUND(v_bb_inch_1_2_pct,4), ROUND(v_bb_inch_7_16_pct,4),
          ROUND(v_bb_inch_3_8_pct,4), ROUND(v_bb_inch_1_4_pct,4), ROUND(v_bb_mesh_28_30_pct,4), ROUND(v_bm28,4),
          v_a916, ROUND(v_ba_inch_1_2_pct,4), ROUND(v_ba_inch_7_16_pct,4),
          ROUND(v_ba_inch_3_8_pct,4), ROUND(v_ba_inch_1_4_pct,4), ROUND(v_ba_mesh_28_30_pct,4), ROUND(v_am28,4),
          ROUND(v_average,4), ROUND(v_comp200,4), ROUND(v_comp300,4), v_comp600, v_c600m200,
          ROUND(v_tons,4), ROUND(v_hours,4), ROUND(v_b58,4), ROUND(v_b4m,4), ROUND(v_a58,4), ROUND(v_a4m,4),
          v_mtype, v_shift_date, v_shift, v_shift_half, v_line_nbr;

    log_info(g_proc_name, 'Updated AGGL row successfully');
    log_info(g_proc_name, 'End');

  EXCEPTION
    WHEN OTHERS THEN
      IF g_enable_logging THEN logger_pkg.log_error('fill_aggl_by_line_shift', SQLERRM); END IF;
      general.log_error(in_error_num=>SQLCODE,in_error_desc=>SQLERRM,in_pname=>g_proc_name,in_error_sql=>'');
      RAISE;
  END fill_aggl_by_line_shift;

  FUNCTION weighted_avg(p_num_sum IN NUMBER,p_ton_sum IN NUMBER) RETURN NUMBER IS
  BEGIN
    IF NVL(p_ton_sum,0)=0 THEN RETURN 0; ELSE RETURN NVL(p_num_sum,0)/p_ton_sum; END IF;
  END weighted_avg;

  PROCEDURE merge_phys_for_shift(p_date IN DATE,p_shift IN NUMBER) IS
    v_sql VARCHAR2(32767);

    s2_tons NUMBER:=0;
    s2_bt12_num NUMBER:=0;
    s2_bt14_cum_num NUMBER:=0;
    s2_at14_cum_num NUMBER:=0;
    s2_a28_num NUMBER:=0;
    s2_acomp_num NUMBER:=0;
    s2_acomp200_num NUMBER:=0;
    s2_acomp300_num NUMBER:=0;
    s2_bt916_num NUMBER:=0;

    s3_tons NUMBER:=0;
    s3_bt12_num NUMBER:=0;
    s3_bt14_cum_num NUMBER:=0;
    s3_at14_cum_num NUMBER:=0;
    s3_a28_num NUMBER:=0;
    s3_acomp_num NUMBER:=0;
    s3_acomp200_num NUMBER:=0;
    s3_acomp300_num NUMBER:=0;
    s3_bt916_num NUMBER:=0;

    v_s2bt12 NUMBER(10,4);
    v_s2bt14 NUMBER(10,4);
    v_s2at14 NUMBER(10,4);
    v_s2at28 NUMBER(10,4);
    v_s2comp NUMBER(10,4);
    v_s2lcomp NUMBER(10,4);
    v_s2bt916 NUMBER(10,4);
    v_s2lcmp3 NUMBER(10,4);

    v_s3bt12 NUMBER(10,4);
    v_s3bt14 NUMBER(10,4);
    v_s3at14 NUMBER(10,4);
    v_s3at28 NUMBER(10,4);
    v_s3comp NUMBER(10,4);
    v_s3lcomp NUMBER(10,4);
    v_s3bt916 NUMBER(10,4);
    v_s3lcmp3 NUMBER(10,4);
  BEGIN
    g_proc_name := 'merge_phys_for_shift';

    log_info(g_proc_name, 'Start p_date=' || TO_CHAR(p_date,'YYYY-MM-DD') || ', p_shift=' || p_shift || ', target=' || g_target_phys_table);

    SELECT
      NVL(SUM(NVL(tons,0)),0),
      NVL(SUM(NVL(b12,0) * NVL(tons,0)),0),
      NVL(SUM((NVL(b58,0)+NVL(b916,0)+NVL(b12,0)+NVL(b716,0)+NVL(b38,0)+NVL(b14,0)) * NVL(tons,0)),0),
      NVL(SUM((NVL(a58,0)+NVL(a916,0)+NVL(a12,0)+NVL(a716,0)+NVL(a38,0)+NVL(a14,0)) * NVL(tons,0)),0),
      NVL(SUM(NVL(a28,0) * NVL(tons,0)),0),
      NVL(SUM(NVL(acomp,0) * NVL(tons,0)),0),
      NVL(SUM(NVL(acomp200,0) * NVL(tons,0)),0),
      NVL(SUM(NVL(acomp300,0) * NVL(tons,0)),0),
      NVL(SUM(NVL(b916,0) * NVL(tons,0)),0)
    INTO
      s2_tons, s2_bt12_num, s2_bt14_cum_num, s2_at14_cum_num, s2_a28_num,
      s2_acomp_num, s2_acomp200_num, s2_acomp300_num, s2_bt916_num
    FROM AGGL_TUMBLES_NEW
    WHERE TRUNC(datex) BETWEEN TRUNC(p_date)-2 AND TRUNC(p_date)
      AND shift = p_shift
      AND line IN (3,4,5);

    SELECT
      NVL(SUM(NVL(tons,0)),0),
      NVL(SUM(NVL(b12,0) * NVL(tons,0)),0),
      NVL(SUM((NVL(b58,0)+NVL(b916,0)+NVL(b12,0)+NVL(b716,0)+NVL(b38,0)+NVL(b14,0)) * NVL(tons,0)),0),
      NVL(SUM((NVL(a58,0)+NVL(a916,0)+NVL(a12,0)+NVL(a716,0)+NVL(a38,0)+NVL(a14,0)) * NVL(tons,0)),0),
      NVL(SUM(NVL(a28,0) * NVL(tons,0)),0),
      NVL(SUM(NVL(acomp,0) * NVL(tons,0)),0),
      NVL(SUM(NVL(acomp200,0) * NVL(tons,0)),0),
      NVL(SUM(NVL(acomp300,0) * NVL(tons,0)),0),
      NVL(SUM(NVL(b916,0) * NVL(tons,0)),0)
    INTO
      s3_tons, s3_bt12_num, s3_bt14_cum_num, s3_at14_cum_num, s3_a28_num,
      s3_acomp_num, s3_acomp200_num, s3_acomp300_num, s3_bt916_num
    FROM AGGL_TUMBLES_NEW
    WHERE TRUNC(datex) BETWEEN TRUNC(p_date)-4 AND TRUNC(p_date)
      AND shift = p_shift
      AND line IN (6,7);

    log_info(g_proc_name, 'S2 tons=' || s2_tons || ', S3 tons=' || s3_tons);

    v_s2bt916 := ROUND(weighted_avg(s2_bt916_num, s2_tons), 1);
    v_s2bt12  := ROUND(weighted_avg(s2_bt12_num, s2_tons), 1);
    v_s2bt14  := ROUND(weighted_avg(s2_bt14_cum_num, s2_tons), 1);
    v_s2at14  := ROUND(weighted_avg(s2_at14_cum_num, s2_tons), 1);
    v_s2at28  := ROUND(weighted_avg(s2_a28_num, s2_tons), 1);
    v_s2comp  := ROUND(weighted_avg(s2_acomp_num, s2_tons), 4);
    v_s2lcomp := ROUND(weighted_avg(s2_acomp200_num, s2_tons), 1);
    v_s2lcmp3 := ROUND(weighted_avg(s2_acomp300_num, s2_tons), 1);

    v_s3bt916 := ROUND(weighted_avg(s3_bt916_num, s3_tons), 1);
    v_s3bt12  := ROUND(weighted_avg(s3_bt12_num, s3_tons), 1);
    v_s3bt14  := ROUND(weighted_avg(s3_bt14_cum_num, s3_tons), 1);
    v_s3at14  := ROUND(weighted_avg(s3_at14_cum_num, s3_tons), 1);
    v_s3at28  := ROUND(weighted_avg(s3_a28_num, s3_tons), 1);
    v_s3comp  := ROUND(weighted_avg(s3_acomp_num, s3_tons), 4);
    v_s3lcomp := ROUND(weighted_avg(s3_acomp200_num, s3_tons), 1);
    v_s3lcmp3 := ROUND(weighted_avg(s3_acomp300_num, s3_tons), 1);

    log_info(g_proc_name,
      'S2BT14=' || v_s2bt14 || ', S2AT14=' || v_s2at14 ||
      ', S3BT14=' || v_s3bt14 || ', S3AT14=' || v_s3at14);

    v_sql :=
      'MERGE INTO ' || g_target_phys_table || ' t USING (SELECT :1 pdate,:2 shift,:3 s2bt12,:4 s2bt14,:5 s2at14,:6 s2at28,:7 s2comp,:8 s2lcomp,' ||
      ' :9 s3bt12,:10 s3bt14,:11 s3at14,:12 s3at28,:13 s3comp,:14 s3lcomp,:15 s2bt916,:16 s3bt916,:17 s2lcmp3,:18 s3lcmp3 FROM dual) s ' ||
      'ON (t.pdate=s.pdate AND t.shift=s.shift) WHEN MATCHED THEN UPDATE SET ' ||
      't.s2bt12=s.s2bt12,t.s2bt14=s.s2bt14,t.s2at14=s.s2at14,t.s2at28=s.s2at28,t.s2comp=s.s2comp,t.s2lcomp=s.s2lcomp,' ||
      't.s3bt12=s.s3bt12,t.s3bt14=s.s3bt14,t.s3at14=s.s3at14,t.s3at28=s.s3at28,t.s3comp=s.s3comp,t.s3lcomp=s.s3lcomp,' ||
      't.s2bt916=s.s2bt916,t.s3bt916=s.s3bt916,t.s2lcmp3=s.s2lcmp3,t.s3lcmp3=s.s3lcmp3 ' ||
      'WHEN NOT MATCHED THEN INSERT (pdate,shift,s2bt12,s2bt14,s2at14,s2at28,s2comp,s2lcomp,s3bt12,s3bt14,s3at14,s3at28,s3comp,s3lcomp,s2bt916,s3bt916,s2lcmp3,s3lcmp3) VALUES ' ||
      '(s.pdate,s.shift,s.s2bt12,s.s2bt14,s.s2at14,s.s2at28,s.s2comp,s.s2lcomp,s.s3bt12,s.s3bt14,s.s3at14,s.s3at28,s.s3comp,s.s3lcomp,s.s2bt916,s.s3bt916,s.s2lcmp3,s.s3lcmp3)';

    EXECUTE IMMEDIATE v_sql
      USING TRUNC(p_date), p_shift,
            v_s2bt12, v_s2bt14, v_s2at14, v_s2at28, v_s2comp, v_s2lcomp,
            v_s3bt12, v_s3bt14, v_s3at14, v_s3at28, v_s3comp, v_s3lcomp,
            v_s2bt916, v_s3bt916, v_s2lcmp3, v_s3lcmp3;

    log_info(g_proc_name, 'Merge complete for p_date=' || TO_CHAR(p_date,'YYYY-MM-DD') || ', shift=' || p_shift);

  EXCEPTION
    WHEN OTHERS THEN
      logger_pkg.log_error(g_proc_name, SQLERRM);
      general.log_error(in_error_num=>SQLCODE,in_error_desc=>SQLERRM,in_pname=>g_proc_name,in_error_sql=>v_sql);
      RAISE;
  END merge_phys_for_shift;

  PROCEDURE populate_phys_by_date_shift(p_date IN DATE,p_shift IN NUMBER) IS
  BEGIN
    g_proc_name := 'populate_phys_by_date_shift';
    set_phys_target_table('phys_new');
    AGGL_Start_Logger;

    log_info(g_proc_name, 'Start p_date=' || TO_CHAR(p_date,'YYYY-MM-DD') || ', p_shift=' || p_shift);
    merge_phys_for_shift(TRUNC(p_date), p_shift);
    log_info(g_proc_name, 'End p_date=' || TO_CHAR(p_date,'YYYY-MM-DD') || ', p_shift=' || p_shift);
  END populate_phys_by_date_shift;

  PROCEDURE populate_phys_by_date(p_date IN DATE) IS
  BEGIN
    g_proc_name := 'populate_phys_by_date';
    set_phys_target_table('phys_new');
    AGGL_Start_Logger;

    log_info(g_proc_name, 'Start p_date=' || TO_CHAR(p_date,'YYYY-MM-DD'));

    FOR r IN (
      SELECT DISTINCT shift
      FROM AGGL_TUMBLES_NEW
      WHERE TRUNC(datex) BETWEEN TRUNC(p_date)-4 AND TRUNC(p_date)
        AND shift IN (1,2,3)
      ORDER BY shift
    ) LOOP
      log_info(g_proc_name, 'Processing shift=' || r.shift);
      merge_phys_for_shift(TRUNC(p_date), r.shift);
    END LOOP;

    log_info(g_proc_name, 'End p_date=' || TO_CHAR(p_date,'YYYY-MM-DD'));
  END populate_phys_by_date;

END PKG_AGGL_PHYS_V1;