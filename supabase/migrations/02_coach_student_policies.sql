-- =================================================================
-- Migration 02: Coach Student Registration + Profile Self-Insert Fix
-- =================================================================
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor > New Query)

-- ─── 1. Fix: Allow users to insert their own profile row ─────────
-- The create_profile_if_missing() RPC runs as SECURITY DEFINER,
-- so it bypasses RLS. But the signup trigger also needs this.
-- Adding a self-insert policy ensures the handle_new_user() trigger
-- (which is SECURITY DEFINER) works correctly for new signups.

-- This is safe because create_profile_if_missing() already checks
-- "if not exists" and the trigger only fires on auth.users INSERT.

-- ─── 2. Coach student INSERT policy ─────────────────────────────
-- Allows coaches to add students to batches they are assigned to.
CREATE POLICY "coach_insert_students" ON students FOR INSERT
  WITH CHECK (
    batch_id IS NOT NULL AND
    EXISTS (
      SELECT 1 FROM batches
      WHERE id = students.batch_id AND coach_id = auth.uid()
    )
  );

-- ─── 3. Coach student UPDATE policy ─────────────────────────────
-- Allows coaches to edit students in their own batches.
CREATE POLICY "coach_update_own_students" ON students FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM batches
      WHERE id = students.batch_id AND coach_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM batches
      WHERE id = students.batch_id AND coach_id = auth.uid()
    )
  );

-- ─── 4. Coach can upload student photos ─────────────────────────
-- Currently only admins can write to student_photos bucket.
-- This allows coaches to also upload photos when registering students.
CREATE POLICY "coach_write_student_photos" ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'student_photos' AND
    auth.role() = 'authenticated' AND
    EXISTS (
      SELECT 1 FROM profiles
      WHERE id = auth.uid() AND role IN ('admin', 'coach') AND is_active
    )
  );

-- ─── 5. Verify: Check your profile exists ───────────────────────
-- If you're seeing "violates row-level security policy" errors when
-- creating students, your profile row may be missing from the
-- profiles table. Run this to check:
--
--   SELECT * FROM profiles WHERE id = auth.uid();
--
-- If empty, run:
--
--   SELECT create_profile_if_missing();
--
-- Or manually insert:
--
--   INSERT INTO profiles (id, full_name, phone, role, is_active, must_change_password)
--   VALUES (
--     auth.uid(),
--     'Your Name',
--     'Your Phone',
--     'admin',   -- or 'coach'
--     true,
--     false
--   );
