-- Trigger to automatically create a public.profiles row when a new user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, phone, role, is_active, must_change_password)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', ''),
    new.raw_user_meta_data->>'phone',
    coalesce(new.raw_user_meta_data->>'role', 'coach'), -- default to coach
    true,
    false -- Since they sign up themselves, they already chose their password
  );
  return new;
end;
$$ language plpgsql security definer;

-- Recreate trigger
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Backfill existing users who don't have a profile yet
insert into public.profiles (id, full_name, phone, role, is_active, must_change_password)
select
  u.id,
  coalesce(u.raw_user_meta_data->>'full_name', ''),
  u.raw_user_meta_data->>'phone',
  coalesce(u.raw_user_meta_data->>'role', 'coach'),
  true,
  false
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;

-- Function to allow self-creation of profile on login if missing
create or replace function public.create_profile_if_missing()
returns void as $$
begin
  if not exists (select 1 from public.profiles where id = auth.uid()) then
    insert into public.profiles (id, full_name, phone, role, is_active, must_change_password)
    values (
      auth.uid(),
      coalesce((select raw_user_meta_data->>'full_name' from auth.users where id = auth.uid()), ''),
      (select raw_user_meta_data->>'phone' from auth.users where id = auth.uid()),
      coalesce((select raw_user_meta_data->>'role' from auth.users where id = auth.uid()), 'coach'),
      true,
      false
    );
  end if;
end;
$$ language plpgsql security definer;
