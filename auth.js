import { db } from './supabase-client.js';

export async function signIn(email, password) {
  const { data, error } = await db.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data;
}

export async function signOut() {
  await db.auth.signOut();
  window.location.href = '/index.html';
}

export async function getSession() {
  const { data: { session } } = await db.auth.getSession();
  return session;
}

export async function requireAuth() {
  const session = await getSession();
  if (!session) {
    window.location.href = '/index.html';
    return null;
  }
  return session;
}

export function isAdmin(session) {
  return session?.user?.email === 'elad@cubes-projects.co.il';
}
