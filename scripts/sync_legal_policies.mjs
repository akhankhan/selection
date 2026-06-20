import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, '..');

initializeApp({
  credential: applicationDefault(),
  projectId: 'selection-admin',
});

const db = getFirestore();

function inlineStyles(html) {
  const css = fs.readFileSync(
    path.join(root, 'assets/legal/styles.css'),
    'utf8',
  );
  return html.replace(
    /<link rel="stylesheet" href="[^"]+"\s*\/?>/,
    `<style>${css}</style>`,
  );
}

const policies = [
  {
    id: 'terms_of_service',
    title: 'Terms of Service',
    file: 'assets/legal/terms-of-service.html',
  },
  {
    id: 'privacy_policy',
    title: 'Privacy Policy',
    file: 'assets/legal/privacy-policy.html',
  },
  {
    id: 'enhanced_notice',
    title: 'Enhanced Notice',
    file: 'assets/legal/enhanced-notice.html',
  },
];

for (const policy of policies) {
  const raw = fs.readFileSync(path.join(root, policy.file), 'utf8');
  const htmlContent = inlineStyles(raw);

  await db.collection('legal_policies').doc(policy.id).set(
    {
      title: policy.title,
      slug: policy.id,
      htmlContent,
      isPublished: true,
      updatedBy: 'sync_legal_policies.mjs',
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log(`Synced legal_policies/${policy.id}`);
}

console.log('Done.');
