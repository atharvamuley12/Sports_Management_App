-- =================================================================
-- Migration 03: Permissive RLS Policies for Authenticated Users
-- =================================================================
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- This ensures that both Admins and Coaches can register students,
-- record payments, log expenses, and update profiles without RLS errors.

-- ─── 1. Drop existing restrictive & permissive policies ─────────
DROP POLICY IF EXISTS "self_read_profile" ON profiles;
DROP POLICY IF EXISTS "admin_manage_profiles" ON profiles;
DROP POLICY IF EXISTS "allow_auth_read_profiles" ON profiles;
DROP POLICY IF EXISTS "allow_auth_insert_self_profile" ON profiles;
DROP POLICY IF EXISTS "allow_auth_update_self_profile" ON profiles;
DROP POLICY IF EXISTS "allow_admin_manage_profiles" ON profiles;

DROP POLICY IF EXISTS "admin_full_batches" ON batches;
DROP POLICY IF EXISTS "coach_read_own_batch" ON batches;
DROP POLICY IF EXISTS "allow_auth_all_batches" ON batches;

DROP POLICY IF EXISTS "admin_full_students" ON students;
DROP POLICY IF EXISTS "coach_read_own_students" ON students;
DROP POLICY IF EXISTS "coach_insert_students" ON students;
DROP POLICY IF EXISTS "coach_update_own_students" ON students;
DROP POLICY IF EXISTS "allow_auth_all_students" ON students;

DROP POLICY IF EXISTS "admin_full_attendance" ON attendance;
DROP POLICY IF EXISTS "coach_mark_attendance" ON attendance;
DROP POLICY IF EXISTS "coach_read_attendance" ON attendance;
DROP POLICY IF EXISTS "allow_auth_all_attendance" ON attendance;

DROP POLICY IF EXISTS "admin_full_payments" ON payments;
DROP POLICY IF EXISTS "allow_auth_all_payments" ON payments;

DROP POLICY IF EXISTS "admin_full_expenses" ON expenses;
DROP POLICY IF EXISTS "allow_auth_all_expenses" ON expenses;

DROP POLICY IF EXISTS "read_student_photos" ON storage.objects;
DROP POLICY IF EXISTS "admin_write_student_photos" ON storage.objects;
DROP POLICY IF EXISTS "coach_write_student_photos" ON storage.objects;
DROP POLICY IF EXISTS "admin_only_receipts" ON storage.objects;
DROP POLICY IF EXISTS "allow_auth_all_storage" ON storage.objects;

-- ─── 2. Create permissive policies for profiles ─────────────────
CREATE POLICY "allow_auth_read_profiles" ON profiles FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "allow_auth_insert_self_profile" ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "allow_auth_update_self_profile" ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "allow_admin_manage_profiles" ON profiles FOR ALL
  USING (is_admin());


-- ─── 3. Create permissive policies for batches ──────────────────
CREATE POLICY "allow_auth_all_batches" ON batches FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- ─── 4. Create permissive policies for students ─────────────────
CREATE POLICY "allow_auth_all_students" ON students FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- ─── 5. Create permissive policies for attendance ───────────────
CREATE POLICY "allow_auth_all_attendance" ON attendance FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- ─── 6. Create permissive policies for payments ─────────────────
CREATE POLICY "allow_auth_all_payments" ON payments FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- ─── 7. Create permissive policies for expenses ─────────────────
CREATE POLICY "allow_auth_all_expenses" ON expenses FOR ALL
  USING (auth.role() = 'authenticated')
  WITH CHECK (auth.role() = 'authenticated');

-- ─── 8. Create permissive policies for storage buckets ──────────
-- Allows any authenticated coach or admin to read and write student photos and expense receipts.
CREATE POLICY "allow_auth_all_storage" ON storage.objects FOR ALL
  USING (
    auth.role() = 'authenticated' AND
    bucket_id IN ('student_photos', 'expense_receipts')
  )
  WITH CHECK (
    auth.role() = 'authenticated' AND
    bucket_id IN ('student_photos', 'expense_receipts')
  );
