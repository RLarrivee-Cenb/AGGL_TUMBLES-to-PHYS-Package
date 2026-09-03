create or replace PACKAGE PKG_AGGL_PHYS_V1 AS

PROCEDURE seed_missing_half_shift_rows (p_shift_date IN DATE);
PROCEDURE set_target_table(tablename IN VARCHAR2);

  PROCEDURE Fill_Aggl_Tumbles (p_shift_date IN DATE);

  PROCEDURE fill_aggl_by_line_shift (
    p_shift_date IN DATE,
    p_line_nbr   IN NUMBER,
    p_shift      IN NUMBER,
    p_shift_half IN NUMBER
  );

  -- PHYS population controls
  PROCEDURE set_phys_target_table(p_table_name IN VARCHAR2);

  -- Populate PHYS for all shifts found on a date
  PROCEDURE populate_phys_by_date(p_date IN DATE);

  -- Populate PHYS for one date+shift
  PROCEDURE populate_phys_by_date_shift(
    p_date  IN DATE,
    p_shift IN NUMBER
  );

END PKG_AGGL_PHYS_V1;