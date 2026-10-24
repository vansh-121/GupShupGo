import fs from 'fs';
import path from 'path';

function scan(dir, out = []) {
  for (const f of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, f.name);
    if (f.isDirectory()) {
      if (f.name !== 'l10n') scan(full, out);
    } else if (f.isFile() && f.name.endsWith('.dart') && !f.name.endsWith('.g.dart')) {
      const content = fs.readFileSync(full, 'utf8');
      const matches = [...content.matchAll(/Text\(\s*['"]([^'"$\n]{4,})['"]/g)];
      if (matches.length > 0) {
        out.push({
          file: full.replace(/\\/g, '/'),
          count: matches.length,
          samples: matches.slice(0, 5).map(m => m[1])
        });
      }
    }
  }
  return out;
}

const screens = scan('lib/screens');
console.log('--- SCREENS WITH LITERAL Text(...) ---');
screens.sort((a, b) => b.count - a.count);
for (const s of screens) {
  console.log(`${s.file} (${s.count} occurrences):`);
  console.log('   Samples:', s.samples.join(' | '));
}

const widgets = scan('lib/widgets');
console.log('\n--- WIDGETS WITH LITERAL Text(...) ---');
widgets.sort((a, b) => b.count - a.count);
for (const w of widgets) {
  console.log(`${w.file} (${w.count} occurrences):`);
  console.log('   Samples:', w.samples.join(' | '));
}
