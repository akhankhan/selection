/**
 * Copy all Firestore data from selection-admin -> menu2go-fb7de.
 * Requires: Firestore database created on menu2go-fb7de (Console once).
 * Run: node scripts/migrate_firestore.mjs
 */
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const SOURCE = 'selection-admin';
const DEST = 'menu2go-fb7de';

const sourceApp = initializeApp(
  { credential: applicationDefault(), projectId: SOURCE },
  'source',
);
const destApp = initializeApp(
  { credential: applicationDefault(), projectId: DEST },
  'dest',
);

const sourceDb = getFirestore(sourceApp);
const destDb = getFirestore(destApp);

async function copyCollection(sourcePath, destPath) {
  const snap = await sourceDb.collection(sourcePath).get();
  if (snap.empty) {
    console.log(`  (empty) ${sourcePath}`);
    return 0;
  }

  let count = 0;
  const batchSize = 400;
  let batch = destDb.batch();
  let ops = 0;

  for (const doc of snap.docs) {
    batch.set(destDb.doc(`${destPath}/${doc.id}`), doc.data());
    ops++;
    count++;

    if (ops >= batchSize) {
      await batch.commit();
      batch = destDb.batch();
      ops = 0;
    }
  }
  if (ops > 0) await batch.commit();

  for (const doc of snap.docs) {
    const subcols = await doc.ref.listCollections();
    for (const sub of subcols) {
      await copyCollection(
        `${sourcePath}/${doc.id}/${sub.id}`,
        `${destPath}/${doc.id}/${sub.id}`,
      );
    }
  }

  console.log(`  copied ${count} docs from ${sourcePath}`);
  return count;
}

async function listRootCollections(db) {
  return db.listCollections();
}

async function main() {
  console.log(`Migrating Firestore: ${SOURCE} -> ${DEST}`);

  // Verify destination DB exists.
  try {
    await destDb.collection('_migration_probe').doc('ping').set({
      at: new Date().toISOString(),
    });
    await destDb.collection('_migration_probe').doc('ping').delete();
  } catch (e) {
    console.error(
      '\nDestination Firestore is not ready. Create it first:\n' +
        '  Firebase Console -> menu2go-fb7de -> Firestore -> Create database\n' +
        '  Location: nam5 (United States multi-region)\n',
    );
    process.exit(1);
  }

  const roots = await listRootCollections(sourceDb);
  let total = 0;

  for (const col of roots) {
    console.log(`Copying /${col.id} ...`);
    total += await copyCollection(col.id, col.id);
  }

  console.log(`\nDone. ${total} top-level documents copied (plus subcollections).`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
