import { spawn } from 'node:child_process';
import { writeFileSync } from 'node:fs';
const exe = 'C:\\Users\\c2590\\AppData\\Local\\Programs\\nodejs-portable\\npm-global\\node_modules\\supabase\\node_modules\\@supabase\\cli-windows-x64\\bin\\supabase.exe';
const out = [];
const err = [];
const p = spawn(exe, ['--version'], { stdio: ['ignore', 'pipe', 'pipe'] });
p.stdout.on('data', (chunk) => out.push(chunk.toString()));
p.stderr.on('data', (chunk) => err.push(chunk.toString()));
p.on('close', (code) => {
  writeFileSync('supabase-pipe.log', out.join(''));
  writeFileSync('supabase-pipe.err', err.join(''));
  writeFileSync('supabase-pipe.exit', String(code));
});
