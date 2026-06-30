-- =================================================================
-- Migration 08: Add Chess as a Valid Sport Option
-- =================================================================

-- 1. Drop existing sport check constraints
ALTER TABLE public.batches DROP CONSTRAINT IF EXISTS batches_sport_check;
ALTER TABLE public.students DROP CONSTRAINT IF EXISTS students_sport_check;

-- 2. Add updated check constraints supporting 'cricket', 'football', and 'chess'
ALTER TABLE public.batches ADD CONSTRAINT batches_sport_check CHECK (sport IN ('cricket', 'football', 'chess'));
ALTER TABLE public.students ADD CONSTRAINT students_sport_check CHECK (sport IN ('cricket', 'football', 'chess'));
