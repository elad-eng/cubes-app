-- ===== CUBES APP - SUPABASE SCHEMA =====
-- הרץ את זה ב-Supabase SQL Editor

-- מתקינים
CREATE TABLE IF NOT EXISTS workers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  last_name TEXT,
  first_name TEXT NOT NULL,
  phone TEXT,
  employment_type TEXT CHECK (employment_type IN ('חברה','עצמאי','קבלן')),
  team_leader TEXT,
  role TEXT,
  has_license BOOLEAN DEFAULT false,
  has_car BOOLEAN DEFAULT false,
  has_tools BOOLEAN DEFAULT false,
  current_project TEXT,
  area TEXT,
  notes TEXT,
  visa_expiry DATE,
  height_cert_expiry DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- פרויקטים
CREATE TABLE IF NOT EXISTS projects (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  manager TEXT,
  qa_lead TEXT,
  team TEXT,
  status TEXT CHECK (status IN ('בביצוע','לקראת סיום','בעצירה','לקראת ביצוע','בתכנון','הסתיים')),
  end_date DATE,
  planner TEXT,
  area_sqm TEXT,
  notes TEXT,
  stop_date DATE,
  return_date DATE,
  reinforce_needed TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- עדכוני שטח
CREATE TABLE IF NOT EXISTS field_updates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  project_id UUID REFERENCES projects(id),
  project_name TEXT,
  manager TEXT,
  update_date DATE DEFAULT CURRENT_DATE,
  content TEXT NOT NULL,
  workers_present INTEGER,
  issues TEXT,
  needs_reinforcement BOOLEAN DEFAULT false,
  reinforcement_details TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- הרשאות Row Level Security
ALTER TABLE workers ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE field_updates ENABLE ROW LEVEL SECURITY;

-- מדיניות: כל משתמש מחובר יכול לקרוא
CREATE POLICY "authenticated_read_workers" ON workers FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_read_projects" ON projects FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_read_updates" ON field_updates FOR SELECT TO authenticated USING (true);
CREATE POLICY "authenticated_insert_updates" ON field_updates FOR INSERT TO authenticated WITH CHECK (true);

-- עדכון אדמין (רק elad)
CREATE POLICY "admin_all_workers" ON workers FOR ALL TO authenticated USING (auth.email() = 'elad@cubes-projects.co.il');
CREATE POLICY "admin_all_projects" ON projects FOR ALL TO authenticated USING (auth.email() = 'elad@cubes-projects.co.il');

-- פונקציה לעדכון updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_workers_updated BEFORE UPDATE ON workers FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER trg_projects_updated BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- VIEW: התראות
CREATE OR REPLACE VIEW alerts_view AS
SELECT 
  'ויזה' AS alert_type,
  first_name || ' ' || COALESCE(last_name,'') AS worker_name,
  phone,
  visa_expiry AS expiry_date,
  (visa_expiry - CURRENT_DATE) AS days_left,
  CASE WHEN (visa_expiry - CURRENT_DATE) <= 7 THEN 'דחוף'
       WHEN (visa_expiry - CURRENT_DATE) <= 30 THEN 'שים לב'
       ELSE 'תקין' END AS severity
FROM workers 
WHERE visa_expiry IS NOT NULL AND is_active = true AND visa_expiry <= CURRENT_DATE + 30
UNION ALL
SELECT 
  'תעודת גובה',
  first_name || ' ' || COALESCE(last_name,''),
  phone,
  height_cert_expiry,
  (height_cert_expiry - CURRENT_DATE),
  CASE WHEN (height_cert_expiry - CURRENT_DATE) <= 7 THEN 'דחוף'
       WHEN (height_cert_expiry - CURRENT_DATE) <= 30 THEN 'שים לב'
       ELSE 'תקין' END
FROM workers 
WHERE height_cert_expiry IS NOT NULL AND is_active = true AND height_cert_expiry <= CURRENT_DATE + 30;
