-- Extends auth.users with role info
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text,
  role text not null check (role in ('admin','coach')),
  is_active boolean not null default true,
  must_change_password boolean not null default true,
  created_at timestamptz not null default now()
);

create table batches (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  sport text not null check (sport in ('cricket','football')),
  coach_id uuid references profiles(id),
  created_at timestamptz not null default now()
);

create table students (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  parent_name text,
  phone text,
  age int,
  sport text not null check (sport in ('cricket','football')),
  batch_id uuid references batches(id),
  monthly_fee numeric(10,2) not null default 0,
  join_date date not null default current_date,
  status text not null default 'active' check (status in ('active','inactive')),
  photo_url text,
  created_at timestamptz not null default now()
);

create table attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  date date not null,
  status text not null check (status in ('present','absent')),
  marked_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  unique (student_id, date)  -- enforces "one entry per student per day" at the DB level
);

create table payments (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  amount numeric(10,2) not null,
  payment_date date not null default current_date,
  month int not null,
  year int not null,
  mode text not null check (mode in ('cash','upi')),
  recorded_by uuid not null references profiles(id),
  created_at timestamptz not null default now(),
  constraint month_range check (month between 1 and 12)
);

create table expenses (
  id uuid primary key default gen_random_uuid(),
  category text not null check (category in
    ('cricket_pitch','football_ground','equipment','shed_construction','maintenance','salary','misc')),
  amount numeric(10,2) not null,
  date date not null default current_date,
  description text,
  receipt_url text,
  recorded_by uuid not null references profiles(id),
  created_at timestamptz not null default now()
);

-- Optimization Indexes
create index on attendance(date);
create index on payments(student_id, month, year);
create index on students(batch_id);
create index on batches(coach_id);

-- Row Level Security Helper
create or replace function is_admin() returns boolean as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin' and is_active);
$$ language sql security definer stable;

alter table profiles   enable row level security;
alter table batches    enable row level security;
alter table students   enable row level security;
alter table attendance enable row level security;
alter table payments   enable row level security;
alter table expenses   enable row level security;

-- profiles: everyone can read their own row; admins read/manage all
create policy "self_read_profile" on profiles for select using (auth.uid() = id or is_admin());
create policy "admin_manage_profiles" on profiles for all using (is_admin()) with check (is_admin());

-- batches: admin full access, coach reads own batch
create policy "admin_full_batches" on batches for all using (is_admin()) with check (is_admin());
create policy "coach_read_own_batch" on batches for select using (coach_id = auth.uid());

-- students: admin full access, coach reads own batch's students only
create policy "admin_full_students" on students for all using (is_admin()) with check (is_admin());
create policy "coach_read_own_students" on students for select using (
  exists (select 1 from batches b where b.id = students.batch_id and b.coach_id = auth.uid())
);

-- attendance: admin full access, coach can insert/read only for own students
create policy "admin_full_attendance" on attendance for all using (is_admin()) with check (is_admin());
create policy "coach_mark_attendance" on attendance for insert with check (
  marked_by = auth.uid() and exists (
    select 1 from students s join batches b on b.id = s.batch_id
    where s.id = attendance.student_id and b.coach_id = auth.uid()
  )
);
create policy "coach_read_attendance" on attendance for select using (
  exists (
    select 1 from students s join batches b on b.id = s.batch_id
    where s.id = attendance.student_id and b.coach_id = auth.uid()
  )
);

-- payments & expenses: admin only, no coach access at all
create policy "admin_full_payments" on payments for all using (is_admin()) with check (is_admin());
create policy "admin_full_expenses" on expenses for all using (is_admin()) with check (is_admin());

-- Storage policies for storage.objects table
-- student_photos: authenticated staff only, not the public internet
create policy "read_student_photos" on storage.objects for select
  using (bucket_id = 'student_photos' and auth.role() = 'authenticated');
create policy "admin_write_student_photos" on storage.objects for insert
  with check (bucket_id = 'student_photos' and is_admin());

-- expense_receipts: admin only, no public access at all
create policy "admin_only_receipts" on storage.objects for all
  using (bucket_id = 'expense_receipts' and is_admin())
  with check (bucket_id = 'expense_receipts' and is_admin());

-- Student dues calculation view (calculates monthly fee * months since join - total payments made)
create or replace view student_dues with (security_invoker = on) as
select
  s.id as student_id,
  s.name,
  s.monthly_fee,
  s.join_date,
  s.status,
  s.batch_id,
  greatest(1, (extract(year from age(current_date, s.join_date)) * 12 + extract(month from age(current_date, s.join_date)) + 1)::int) as months_since_join,
  (s.monthly_fee * greatest(1, (extract(year from age(current_date, s.join_date)) * 12 + extract(month from age(current_date, s.join_date)) + 1)::int)) as expected_fees,
  coalesce((select sum(amount) from payments where student_id = s.id), 0) as total_paid,
  ((s.monthly_fee * greatest(1, (extract(year from age(current_date, s.join_date)) * 12 + extract(month from age(current_date, s.join_date)) + 1)::int)) - coalesce((select sum(amount) from payments where student_id = s.id), 0)) as pending_dues
from students s
where s.status = 'active';
