-- =================================================================
-- Migration 09: Add Features Schema (Parent Profession, Coach Details & RPCs)
-- =================================================================

-- 1. Alter students table to add parent_profession
ALTER TABLE public.students 
ADD COLUMN IF NOT EXISTS parent_profession TEXT;

-- 2. Alter profiles table to add coach details
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS degree TEXT,
ADD COLUMN IF NOT EXISTS experience TEXT,
ADD COLUMN IF NOT EXISTS speciality TEXT,
ADD COLUMN IF NOT EXISTS achievements TEXT,
ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- 3. Drop existing RPC functions to avoid signature conflicts
DROP FUNCTION IF EXISTS public.create_coach_user(TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.update_coach_profile(UUID, TEXT, TEXT, TEXT);

-- 4. Recreate create_coach_user function with new details
CREATE OR REPLACE FUNCTION public.create_coach_user(
  coach_email TEXT,
  coach_password TEXT,
  coach_name TEXT,
  coach_phone TEXT,
  coach_degree TEXT DEFAULT NULL,
  coach_experience TEXT DEFAULT NULL,
  coach_speciality TEXT DEFAULT NULL,
  coach_achievements TEXT DEFAULT NULL,
  coach_photo_url TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_user_id UUID := gen_random_uuid();
BEGIN
  -- Check if caller is active admin
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin' AND is_active
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Only active admins can create coach accounts.';
  END IF;

  -- Check if email exists
  IF EXISTS (
    SELECT 1 FROM auth.users WHERE email = coach_email
  ) THEN
    RAISE EXCEPTION 'Email already registered.';
  END IF;

  -- Insert into auth.users
  INSERT INTO auth.users (
    id,
    instance_id,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    role,
    aud,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token,
    phone_change_token,
    email_change_token_current
  ) VALUES (
    new_user_id,
    '00000000-0000-0000-0000-000000000000',
    coach_email,
    crypt(coach_password, gen_salt('bf')),
    now(),
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object('full_name', coach_name, 'phone', coach_phone, 'role', 'coach'),
    now(),
    now(),
    'authenticated',
    'authenticated',
    '',
    '',
    '',
    '',
    '',
    ''
  );

  -- Insert/update public.profiles
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = new_user_id) THEN
    INSERT INTO public.profiles (
      id,
      full_name,
      phone,
      role,
      is_active,
      must_change_password,
      degree,
      experience,
      speciality,
      achievements,
      photo_url
    ) VALUES (
      new_user_id,
      coach_name,
      coach_phone,
      'coach',
      true,
      true,
      coach_degree,
      coach_experience,
      coach_speciality,
      coach_achievements,
      coach_photo_url
    );
  ELSE
    UPDATE public.profiles
    SET 
      must_change_password = true,
      degree = coach_degree,
      experience = coach_experience,
      speciality = coach_speciality,
      achievements = coach_achievements,
      photo_url = coach_photo_url
    WHERE id = new_user_id;
  END IF;

  RETURN new_user_id;
END;
$$;

-- 5. Recreate update_coach_profile function with new details
CREATE OR REPLACE FUNCTION public.update_coach_profile(
  coach_id UUID,
  new_name TEXT,
  new_phone TEXT,
  new_email TEXT,
  new_degree TEXT DEFAULT NULL,
  new_experience TEXT DEFAULT NULL,
  new_speciality TEXT DEFAULT NULL,
  new_achievements TEXT DEFAULT NULL,
  new_photo_url TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if caller is active admin
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND role = 'admin' AND is_active
  ) THEN
    RAISE EXCEPTION 'Unauthorized: Only active admins can update coach profiles.';
  END IF;

  -- Update auth.users email & raw metadata
  UPDATE auth.users
  SET 
    email = new_email,
    raw_user_meta_data = jsonb_build_object('full_name', new_name, 'phone', new_phone, 'role', 'coach')
  WHERE id = coach_id;

  -- Update public.profiles
  UPDATE public.profiles
  SET 
    full_name = new_name,
    phone = new_phone,
    degree = new_degree,
    experience = new_experience,
    speciality = new_speciality,
    achievements = new_achievements,
    photo_url = new_photo_url
  WHERE id = coach_id;
END;
$$;

-- 6. Add policies for coach_photos bucket (assumes coach_photos bucket exists)
-- (The admin can create this bucket named 'coach_photos' in Supabase dashboard)
-- Note: We write permissive policy checks to ensure access control.
CREATE POLICY "read_coach_photos" ON storage.objects FOR SELECT
  USING (bucket_id = 'coach_photos' AND auth.role() = 'authenticated');

CREATE POLICY "admin_write_coach_photos" ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'coach_photos' AND EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin' AND is_active
  ));

CREATE POLICY "admin_update_coach_photos" ON storage.objects FOR UPDATE
  USING (bucket_id = 'coach_photos' AND EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin' AND is_active
  ));

CREATE POLICY "admin_delete_coach_photos" ON storage.objects FOR DELETE
  USING (bucket_id = 'coach_photos' AND EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin' AND is_active
  ));

-- 7. Redefine student_dues view to include phone, sport, and batch_name columns
DROP VIEW IF EXISTS public.student_dues CASCADE;
CREATE OR REPLACE VIEW public.student_dues WITH (security_invoker = on) AS
SELECT
  s.id as student_id,
  s.name,
  s.monthly_fee,
  s.join_date,
  s.status,
  s.batch_id,
  s.phone,
  s.sport,
  (SELECT name FROM public.batches WHERE id = s.batch_id) as batch_name,
  greatest(1, (extract(year from age(current_date, s.join_date)) * 12 + extract(month from age(current_date, s.join_date)) + 1)::int) as months_since_join,
  (s.monthly_fee * greatest(1, (extract(year from age(current_date, s.join_date)) * 12 + extract(month from age(current_date, s.join_date)) + 1)::int)) as expected_fees,
  coalesce((select sum(amount) from public.payments where student_id = s.id), 0) as total_paid,
  ((s.monthly_fee * greatest(1, (extract(year from age(current_date, s.join_date)) * 12 + extract(month from age(current_date, s.join_date)) + 1)::int)) - coalesce((select sum(amount) from public.payments where student_id = s.id), 0)) as pending_dues
FROM public.students s
WHERE s.status = 'active';
