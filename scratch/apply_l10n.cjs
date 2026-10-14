const fs = require('fs');
const path = require('path');

const d1 = require('./data_auth_vault.cjs');
const d2 = require('./data_features_screens.cjs');
const b1 = require('./translations_batch1.cjs');
const b2 = require('./translations_batch2.cjs');
const b3 = require('./translations_batch3.cjs');

const meta = { ...d1.meta, ...d2.meta };
const en = { ...d1.en, ...d2.en };
const allLangs = { ...b1, ...b2, ...b3 };

const l10nDir = path.resolve(__dirname, '../lib/l10n');

// 1. Update app_en.arb
const enPath = path.join(l10nDir, 'app_en.arb');
const enArb = JSON.parse(fs.readFileSync(enPath, 'utf8'));

let enAdded = 0;
for (const key of Object.keys(en)) {
  enArb[key] = en[key];
  const m = meta[key] || {};
  const metaObj = {
    description: m.desc || m.description || `Key for ${key}`,
  };
  if (m.placeholders) {
    metaObj.placeholders = m.placeholders;
  }
  enArb[`@${key}`] = metaObj;
  enAdded++;
}
fs.writeFileSync(enPath, JSON.stringify(enArb, null, 2) + '\n', 'utf8');
console.log(`Updated app_en.arb: added ${enAdded} keys (plus @meta). Total keys now: ${Object.keys(enArb).length}`);

// 2. Update each of the 15 languages
const expectedLangs = ['ar', 'bn', 'de', 'es', 'fr', 'hi', 'id', 'ja', 'pt', 'ru', 'ta', 'te', 'tr', 'ur', 'zh'];

for (const lang of expectedLangs) {
  const filePath = path.join(l10nDir, `app_${lang}.arb`);
  if (!fs.existsSync(filePath)) {
    console.error(`File does not exist: ${filePath}`);
    continue;
  }
  const langArb = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const translations = allLangs[lang];
  if (!translations) {
    console.error(`No translations found for ${lang}`);
    continue;
  }

  let count = 0;
  for (const key of Object.keys(en)) {
    if (translations[key] !== undefined) {
      langArb[key] = translations[key];
      count++;
    } else {
      console.warn(`Missing key ${key} for ${lang}`);
    }
  }
  fs.writeFileSync(filePath, JSON.stringify(langArb, null, 2) + '\n', 'utf8');
  console.log(`Updated app_${lang}.arb: added/updated ${count} keys. Total keys now: ${Object.keys(langArb).length}`);
}

console.log('All .arb files updated successfully!');
