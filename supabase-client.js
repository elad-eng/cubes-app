// ===== SUPABASE CLIENT =====
// החלף את הערכים האלה עם הפרטים מ-Supabase שלך
const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

const { createClient } = supabase;
const db = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export { db };
