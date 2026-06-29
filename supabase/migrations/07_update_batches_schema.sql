-- =================================================================
-- Migration 07: Update Batches Schema & Create Coach Admin Functions
-- =================================================================

-- 1. Alter batches table to include capacity, days, start_time, and end_time
ALTER TABLE public.batches ADD COLUMN IF NOT EXISTS capacity INT NOT NULL DEFAULT 20;
ALTER TABLE public.batches ADD COLUMN IF NOT EXISTS days TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE public.batches ADD COLUMN IF NOT EXISTS start_time TEXT;
ALTER TABLE public.batches ADD COLUMN IF NOT EXISTS end_time TEXT;

-- Alter profiles table to include email
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;

-- 2. Update/Re-create the create_coach_user RPC function to set must_change_password to false
CREATE OR REPLACE FUNCTION public.create_coach_user(
  coach_email TEXT,
  coach_password TEXT,
  coach_name TEXT,
  coach_phone TEXT
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
    crypt(coach_password, gen_salt('bf', 10)),
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

  -- Insert profile
  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = new_user_id) THEN
    INSERT INTO public.profiles (
      id,
      full_name,
      phone,
      email,
      role,
      is_active,
      must_change_password
    ) VALUES (
      new_user_id,
      coach_name,
      coach_phone,
      coach_email,
      'coach',
      true,
      false -- Set to false as per user request (no first-time change requirement)
    );
  ELSE
    UPDATE public.profiles
    SET email = coach_email,
        must_change_password = false
    WHERE id = new_user_id;
  END IF;

  RETURN new_user_id;
END;
$$;

-- 3. Create public.reset_coach_password RPC function
CREATE OR REPLACE FUNCTION public.reset_coach_password(
  coach_id UUID,
  new_password TEXT
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
    RAISE EXCEPTION 'Unauthorized: Only active admins can reset passwords.';
  END IF;

  -- Update auth.users password
  UPDATE auth.users
  SET encrypted_password = crypt(new_password, gen_salt('bf', 10)),
      updated_at = now()
  WHERE id = coach_id;

  -- Ensure must_change_password is set to false (no forced reset flow)
  UPDATE public.profiles
  SET must_change_password = false
  WHERE id = coach_id;
END;
$$;

-- 4. Create public.update_coach_profile RPC function to allow admins to edit coach details (including email)
CREATE OR REPLACE FUNCTION public.update_coach_profile(
  coach_id UUID,
  new_name TEXT,
  new_phone TEXT,
  new_email TEXT
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

  -- Check if email is already in use by another user
  IF EXISTS (
    SELECT 1 FROM auth.users WHERE email = new_email AND id != coach_id
  ) THEN
    RAISE EXCEPTION 'Email already registered by another user.';
  END IF;

  -- Update profiles table
  UPDATE public.profiles
  SET full_name = new_name,
      phone = new_phone
  WHERE id = coach_id;

  -- Update email and raw_user_meta_data in auth.users
  UPDATE auth.users
  SET email = new_email,
      raw_user_meta_data = raw_user_meta_data || jsonb_build_object('full_name', new_name, 'phone', new_phone)
  WHERE id = coach_id;
END;
$$;
