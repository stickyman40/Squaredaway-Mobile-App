-- Forward-only promotions v2 migration for databases that already have the
-- legacy promotions_data table from earlier migrations.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'promotions_data'
          AND column_name = 'army_acft_points'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'promotions_data'
          AND column_name = 'army_aft_points'
    ) THEN
        ALTER TABLE public.promotions_data
            RENAME COLUMN army_acft_points TO army_aft_points;
    END IF;
END $$;

ALTER TABLE public.promotions_data
    ALTER COLUMN current_rank SET DEFAULT '',
    ALTER COLUMN target_rank SET DEFAULT '';

ALTER TABLE public.promotions_data
    ADD COLUMN IF NOT EXISTS current_pay_grade TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS target_pay_grade TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS months_in_service INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS months_in_grade INT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS army_mil_ed_pts INT,
    ADD COLUMN IF NOT EXISTS army_civ_ed_pts INT,
    ADD COLUMN IF NOT EXISTS army_awards_pts INT,
    ADD COLUMN IF NOT EXISTS army_mil_trg_pts INT,
    ADD COLUMN IF NOT EXISTS army_aft_pts INT,
    ADD COLUMN IF NOT EXISTS army_weapons_pts INT,
    ADD COLUMN IF NOT EXISTS army_mos_cutoff INT,
    ADD COLUMN IF NOT EXISTS waps_skt_raw INT,
    ADD COLUMN IF NOT EXISTS waps_pfe_raw INT,
    ADD COLUMN IF NOT EXISTS waps_epr_rating INT,
    ADD COLUMN IF NOT EXISTS waps_decorations_pts INT,
    ADD COLUMN IF NOT EXISTS waps_afadcons_pts INT,
    ADD COLUMN IF NOT EXISTS waps_tis_years INT,
    ADD COLUMN IF NOT EXISTS waps_tig_months INT,
    ADD COLUMN IF NOT EXISTS waps_cutoff_published INT,
    ADD COLUMN IF NOT EXISTS navy_pma NUMERIC(4,2),
    ADD COLUMN IF NOT EXISTS navy_exam_raw INT,
    ADD COLUMN IF NOT EXISTS navy_awards_pts INT,
    ADD COLUMN IF NOT EXISTS navy_sipg_years NUMERIC(4,2),
    ADD COLUMN IF NOT EXISTS navy_pna_attempts INT,
    ADD COLUMN IF NOT EXISTS marine_pft_raw INT,
    ADD COLUMN IF NOT EXISTS marine_cft_raw INT,
    ADD COLUMN IF NOT EXISTS marine_rifle_qual INT,
    ADD COLUMN IF NOT EXISTS marine_mci_credits INT,
    ADD COLUMN IF NOT EXISTS marine_cut_score INT,
    ADD COLUMN IF NOT EXISTS cg_swe_raw INT,
    ADD COLUMN IF NOT EXISTS cg_cut_score INT,
    ADD COLUMN IF NOT EXISTS board_notes TEXT,
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.promotions_data
    ALTER COLUMN branch SET DEFAULT 'Army';

UPDATE public.promotions_data AS pd
SET branch = COALESCE(NULLIF(pd.branch, ''), up.branch, 'Army')
FROM public.users_profile AS up
WHERE up.id = pd.user_id
  AND (pd.branch IS NULL OR pd.branch = '');

UPDATE public.promotions_data
SET branch = 'Army'
WHERE branch IS NULL OR branch = '';

ALTER TABLE public.promotions_data
    ALTER COLUMN branch SET NOT NULL;

UPDATE public.promotions_data
SET current_pay_grade = COALESCE(NULLIF(current_pay_grade, ''), current_rank, '')
WHERE current_pay_grade = '';

UPDATE public.promotions_data
SET target_pay_grade = COALESCE(NULLIF(target_pay_grade, ''), target_rank, '')
WHERE target_pay_grade = '';

UPDATE public.promotions_data
SET board_notes = COALESCE(board_notes, notes)
WHERE board_notes IS NULL
  AND notes IS NOT NULL;

UPDATE public.promotions_data
SET next_board_date = COALESCE(next_board_date, board_date)
WHERE next_board_date IS NULL
  AND board_date IS NOT NULL;

UPDATE public.promotions_data
SET created_at = updated_at
WHERE created_at IS NULL;

UPDATE public.promotions_data
SET army_mil_ed_pts = COALESCE(army_mil_ed_pts, army_mil_ed_points),
    army_civ_ed_pts = COALESCE(army_civ_ed_pts, army_civ_ed_points),
    army_awards_pts = COALESCE(army_awards_pts, army_awards_points),
    army_mil_trg_pts = COALESCE(army_mil_trg_pts, army_mil_trg_points),
    army_aft_pts = COALESCE(army_aft_pts, army_aft_points),
    army_weapons_pts = COALESCE(army_weapons_pts, army_weapons_points),
    army_mos_cutoff = COALESCE(army_mos_cutoff, army_current_cutoff),
    waps_skt_raw = COALESCE(waps_skt_raw, waps_skt_score),
    waps_pfe_raw = COALESCE(waps_pfe_raw, waps_pfe_score),
    waps_decorations_pts = COALESCE(waps_decorations_pts, waps_decorations_points),
    waps_afadcons_pts = COALESCE(waps_afadcons_pts, waps_afadcons_points),
    waps_cutoff_published = COALESCE(waps_cutoff_published, waps_cutoff_score),
    navy_pma = COALESCE(navy_pma, navy_pma_score),
    navy_exam_raw = COALESCE(navy_exam_raw, navy_exam_score),
    navy_awards_pts = COALESCE(navy_awards_pts, navy_awards_points),
    navy_sipg_years = COALESCE(navy_sipg_years, LEAST(11.0, COALESCE(navy_sipg_points, 0) * 2)),
    navy_pna_attempts = COALESCE(navy_pna_attempts, LEAST(3, GREATEST(0, ROUND(COALESCE(navy_pna_points, 0) * 2))::INT)),
    marine_pft_raw = COALESCE(marine_pft_raw, marine_pft_score),
    marine_cft_raw = COALESCE(marine_cft_raw, marine_cft_score),
    marine_rifle_qual = COALESCE(
        marine_rifle_qual,
        CASE marine_rifle_score
        WHEN 5 THEN 50
        WHEN 4 THEN 40
        WHEN 3 THEN 30
        ELSE 0
        END
    ),
    marine_mci_credits = COALESCE(marine_mci_credits, marine_mci_points),
    marine_cut_score = COALESCE(marine_cut_score, marine_cutting_score),
    cg_swe_raw = COALESCE(cg_swe_raw, cg_swe_score),
    cg_cut_score = COALESCE(cg_cut_score, cg_advancement_cut)
WHERE TRUE;

UPDATE public.promotions_data
SET waps_epr_rating = COALESCE(
    waps_epr_rating,
    CASE waps_epr_score
    WHEN 27 THEN 1
    WHEN 42 THEN 1
    WHEN 54 THEN 2
    WHEN 63 THEN 2
    WHEN 81 THEN 3
    WHEN 84 THEN 3
    WHEN 105 THEN 4
    WHEN 108 THEN 4
    WHEN 126 THEN 5
    WHEN 135 THEN 5
    ELSE NULL
    END
)
WHERE waps_epr_rating IS NULL
  AND waps_epr_score IS NOT NULL;

ALTER TABLE public.promotions_data
    ADD CONSTRAINT promotions_data_waps_epr_rating_check
        CHECK (waps_epr_rating IS NULL OR waps_epr_rating BETWEEN 1 AND 5);

ALTER TABLE public.promotions_data
    ADD CONSTRAINT promotions_data_waps_decorations_pts_check
        CHECK (waps_decorations_pts IS NULL OR waps_decorations_pts BETWEEN 0 AND 25);

ALTER TABLE public.promotions_data
    ADD CONSTRAINT promotions_data_waps_afadcons_pts_check
        CHECK (waps_afadcons_pts IS NULL OR waps_afadcons_pts BETWEEN 0 AND 25);

ALTER TABLE public.promotions_data
    ADD CONSTRAINT promotions_data_navy_pma_check
        CHECK (navy_pma IS NULL OR navy_pma BETWEEN 1.0 AND 5.0);

ALTER TABLE public.promotions_data
    ADD CONSTRAINT promotions_data_navy_exam_raw_check
        CHECK (navy_exam_raw IS NULL OR navy_exam_raw BETWEEN 0 AND 80);

ALTER TABLE public.promotions_data
    ADD CONSTRAINT promotions_data_navy_pna_attempts_check
        CHECK (navy_pna_attempts IS NULL OR navy_pna_attempts BETWEEN 0 AND 3);

ALTER TABLE public.promotions_data
    ADD CONSTRAINT promotions_data_marine_pft_raw_check
        CHECK (marine_pft_raw IS NULL OR marine_pft_raw BETWEEN 0 AND 300);

ALTER TABLE public.promotions_data
    ADD CONSTRAINT promotions_data_marine_cft_raw_check
        CHECK (marine_cft_raw IS NULL OR marine_cft_raw BETWEEN 0 AND 300);

ALTER TABLE public.promotions_data
    ADD CONSTRAINT promotions_data_marine_rifle_qual_check
        CHECK (marine_rifle_qual IS NULL OR marine_rifle_qual IN (0, 30, 40, 50));

ALTER TABLE public.promotions_data
    ADD CONSTRAINT promotions_data_cg_swe_raw_check
        CHECK (cg_swe_raw IS NULL OR cg_swe_raw BETWEEN 0 AND 100);

CREATE INDEX IF NOT EXISTS idx_promotions_branch ON public.promotions_data(branch);

CREATE OR REPLACE FUNCTION public.handle_promotion_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_user_id uuid;
  title text;
  body text;
  target_label text;
BEGIN
  IF tg_op = 'DELETE' THEN
    target_user_id := old.user_id;
    title := 'Promotion tracker deleted';
    body := 'Your saved promotion readiness data was removed.';
  ELSE
    target_user_id := new.user_id;
    target_label := COALESCE(NULLIF(new.target_pay_grade, ''), NULLIF(new.target_rank, ''), 'your next rank');

    IF tg_op = 'INSERT' THEN
      title := 'Promotion tracker created';
      body := format('Promotion tracking started for %s.', target_label);
    ELSE
      title := 'Promotion tracker updated';
      body := format('Promotion tracking details were updated for %s.', target_label);
    END IF;
  END IF;

  PERFORM public.create_system_notification(target_user_id, 'readiness', title, body);

  RETURN COALESCE(new, old);
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_legacy_promotion_columns()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.current_pay_grade IS NOT NULL AND NEW.current_pay_grade <> '' THEN
    NEW.current_rank := NEW.current_pay_grade;
  END IF;

  IF NEW.target_pay_grade IS NOT NULL AND NEW.target_pay_grade <> '' THEN
    NEW.target_rank := NEW.target_pay_grade;
  END IF;

  IF NEW.next_board_date IS NOT NULL THEN
    NEW.board_date := NEW.next_board_date;
  END IF;

  IF NEW.board_notes IS NOT NULL AND NEW.board_notes <> '' THEN
    NEW.notes := NEW.board_notes;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_legacy_promotion_columns ON public.promotions_data;
CREATE TRIGGER trg_sync_legacy_promotion_columns
    BEFORE INSERT OR UPDATE ON public.promotions_data
    FOR EACH ROW EXECUTE FUNCTION public.sync_legacy_promotion_columns();

CREATE OR REPLACE FUNCTION public.enforce_promotions_branch_lock()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF OLD.branch IS DISTINCT FROM NEW.branch THEN
        RAISE EXCEPTION 'Branch cannot be changed after initial record creation.';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_promotions_branch_lock ON public.promotions_data;
CREATE TRIGGER trg_promotions_branch_lock
    BEFORE UPDATE ON public.promotions_data
    FOR EACH ROW EXECUTE FUNCTION public.enforce_promotions_branch_lock();
