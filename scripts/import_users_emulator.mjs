import { readFileSync } from 'node:fs';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { validateUser, documentId } from '../functions/src/user_service.js';

// Chỉ nhập vào Emulator. Không ghi đè document đã có.
const filename = process.argv[2];
if (!filename) throw new Error('Dùng: node scripts/import_users_emulator.mjs submission/users.json');
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8180';
initializeApp({ projectId: 'demo-ecomer' });
const rows = JSON.parse(readFileSync(filename, 'utf8'));
if (!Array.isArray(rows) || rows.length > 200) throw new Error('Mỗi lần nhập tối đa 200 bản ghi.');
const ids = new Set();
for (const row of rows) {
  if (Object.keys(row).sort().join(',') !== 'email,hinhanh,hoten,matkhau') throw new Error('File phải có đúng bốn trường.');
  validateUser({ ...row, matkhau: 'ImportCheck123!' });
  if (!/^scrypt\$32768\$8\$1\$[a-f0-9]{32}\$[a-f0-9]{128}$/.test(row.matkhau)) throw new Error('Mật khẩu trong file phải là hash scrypt.');
  row.email = row.email.trim().toLowerCase(); row.hoten = row.hoten.trim();
  const id = documentId(row.email);
  if (ids.has(id)) throw new Error('File có email trùng.');
  ids.add(id);
}
const db = getFirestore();
if (rows.length) await db.runTransaction(async (transaction) => {
  const refs = rows.map((row) => db.doc(`users/${documentId(row.email)}`));
  const existing = await transaction.getAll(...refs);
  if (existing.some((doc) => doc.exists)) throw new Error('Có email đã tồn tại. Không ghi đè dữ liệu.');
  refs.forEach((ref, index) => transaction.create(ref, rows[index]));
});
console.log(`Đã nhập ${rows.length} hồ sơ vào Firestore Emulator demo-ecomer.`);
process.exit(0);
