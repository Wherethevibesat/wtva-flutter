#!/usr/bin/env node
/**
 * Apply supabase/migrations/000_full_database.sql to remote Postgres.
 *
 * Usage:
 *   node scripts/apply-db.mjs
 *   node scripts/apply-db.mjs --password YOUR_DB_PASSWORD
 *
 * Or create .env with:
 *   SUPABASE_DB_PASSWORD=your_password
 */
import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');
const PROJECT_REF = 'wabtknktqnrxnffkgpzh';
const sqlPath = join(root, 'supabase', 'migrations', '000_full_database.sql');

function loadEnv() {
  const envPath = join(root, '.env');
  if (!existsSync(envPath)) return;
  for (const line of readFileSync(envPath, 'utf8').split('\n')) {
    const t = line.trim();
    if (!t || t.startsWith('#')) continue;
    const i = t.indexOf('=');
    if (i < 0) continue;
    const key = t.slice(0, i).trim();
    let val = t.slice(i + 1).trim();
    if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    if (!process.env[key]) process.env[key] = val;
  }
}

function getPassword() {
  const argIdx = process.argv.indexOf('--password');
  if (argIdx >= 0 && process.argv[argIdx + 1]) {
    return process.argv[argIdx + 1];
  }
  return process.env.SUPABASE_DB_PASSWORD;
}

async function main() {
  loadEnv();
  const password = getPassword();
  if (!password) {
    console.error('Missing database password.');
    console.error('  node scripts/apply-db.mjs --password YOUR_PASSWORD');
    console.error('  or add SUPABASE_DB_PASSWORD=... to .env');
    console.error(`  Dashboard: https://supabase.com/dashboard/project/${PROJECT_REF}/settings/database`);
    process.exit(1);
  }

  if (!existsSync(sqlPath)) {
    console.error('SQL file not found:', sqlPath);
    process.exit(1);
  }

  const sql = readFileSync(sqlPath, 'utf8');
  const { default: postgres } = await import('postgres');

  const encoded = encodeURIComponent(password);
  const sqlClient = postgres({
    host: `db.${PROJECT_REF}.supabase.co`,
    port: 5432,
    database: 'postgres',
    username: 'postgres',
    password,
    ssl: 'require',
    max: 1,
  });

  console.log(`Applying ${sqlPath} to project ${PROJECT_REF}...`);
  try {
    await sqlClient.unsafe(sql);
    console.log('Success — full database schema applied.');
    console.log('Restart the app: flutter run');
  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  } finally {
    await sqlClient.end({ timeout: 5 });
  }
}

main();
