import { before, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { writeFileSync, mkdirSync } from 'node:fs';
import { initializeApp, deleteApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

const projectId = 'demo-ecomer-users-test';
const root = `http://127.0.0.1:5002/${projectId}/us-central1/`;
const image = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aF1cAAAAASUVORK5CYII=';
let app, db, adminToken, userToken;
const sample = (email = 'an@example.com') => ({ email, matkhau: 'StrongPass123!', hoten: 'Nguyễn Văn An', hinhanh: image });
async function call(name, data = {}, token = adminToken) {
  const response = await fetch(root + name, { method: 'POST', headers: {
    'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}),
  }, body: JSON.stringify({ data }) });
  const body = await response.json();
  if (body.error) throw Object.assign(new Error(body.error.message), { code: body.error.status });
  return body.result;
}
async function signIn(email, password) {
  const response = await fetch('http://127.0.0.1:9299/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=demo-key', {
    method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  const data = await response.json();
  assert.ok(data.idToken);
  return data.idToken;
}
before(async () => {
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8280');
  assert.equal(process.env.FIREBASE_AUTH_EMULATOR_HOST, '127.0.0.1:9299');
  app = initializeApp({ projectId });
  db = getFirestore(app);
  const auth = getAuth(app);
  const admin = await auth.createUser({ email: 'admin@test.local', password: 'EcomerTest123!' });
  await auth.setCustomUserClaims(admin.uid, { admin: true });
  await auth.createUser({ email: 'member@test.local', password: 'EcomerTest123!' });
  adminToken = await signIn('admin@test.local', 'EcomerTest123!');
  userToken = await signIn('member@test.local', 'EcomerTest123!');
});
after(async () => deleteApp(app));

test('chỉ admin được gọi CRUD/export; chặn truy cập Firestore trực tiếp', async () => {
  for (const endpoint of ['listUsers', 'saveUser', 'deleteUser', 'exportUsers']) {
    await assert.rejects(call(endpoint, {}, null), { code: 'UNAUTHENTICATED' });
    await assert.rejects(call(endpoint, {}, userToken), { code: 'PERMISSION_DENIED' });
  }
  const url = `http://127.0.0.1:8280/v1/projects/${projectId}/databases/(default)/documents/users`;
  for (const token of [null, adminToken, userToken]) {
    const response = await fetch(url, { headers: token ? { Authorization: `Bearer ${token}` } : {} });
    assert.equal(response.status, 403);
  }
});

test('CRUD lưu đúng bốn trường; hash có salt; response danh sách che mật khẩu', async () => {
  const first = await call('saveUser', { user: sample() });
  const raw = (await db.doc(`users/${first.id}`).get()).data();
  assert.deepEqual(Object.keys(raw).sort(), ['email', 'hinhanh', 'hoten', 'matkhau']);
  assert.match(raw.matkhau, /^scrypt\$32768\$8\$1\$[a-f0-9]{32}\$[a-f0-9]{128}$/);
  assert.notEqual(raw.matkhau, sample().matkhau);
  const list = await call('listUsers');
  assert.equal(list.records.find((record) => record.id === first.id).matkhau, '••••••••');
  await call('saveUser', { id: first.id, user: { ...sample(), hoten: 'Tên đã sửa', matkhau: '' } });
  assert.equal((await db.doc(`users/${first.id}`).get()).data().matkhau, raw.matkhau);
  const changed = await call('saveUser', { id: first.id, user: { ...sample('new@example.com'), hoten: 'Đổi email' } });
  assert.equal((await db.doc(`users/${first.id}`).get()).exists, false);
  assert.notEqual((await db.doc(`users/${changed.id}`).get()).data().matkhau, raw.matkhau);
  await call('deleteUser', { id: changed.id });
  assert.equal((await db.doc(`users/${changed.id}`).get()).exists, false);
  await assert.rejects(call('saveUser', { id: first.id, user: sample() }), { code: 'NOT_FOUND' });
});

test('email trùng kể cả hoa/thường và ghi đồng thời chỉ tạo một document', async () => {
  const attempts = await Promise.allSettled([
    call('saveUser', { user: sample('Duplicate@example.com') }),
    call('saveUser', { user: sample('duplicate@EXAMPLE.com') }),
  ]);
  assert.equal(attempts.filter((result) => result.status === 'fulfilled').length, 1);
  assert.equal(attempts.filter((result) => result.status === 'rejected')[0].reason.code, 'ALREADY_EXISTS');
  const other = await call('saveUser', { user: sample('other@example.com') });
  await assert.rejects(call('saveUser', { id: other.id, user: sample('duplicate@example.com') }), { code: 'ALREADY_EXISTS' });
  assert.ok((await db.doc(`users/${other.id}`).get()).exists);
});

test('server chặn trường dư, email/tên/mật khẩu/ảnh sai', async () => {
  for (const update of [{ createdAt: 1 }, { role: 'admin' }, { email: 'invalid' }, { hoten: '   ' },
    { matkhau: '' }, { matkhau: 'short' }, { hinhanh: 'https://example.com/image.jpg' },
    { hinhanh: 'data:image/png;base64,YWJj' }]) {
    await assert.rejects(call('saveUser', { user: { ...sample('invalid@example.com'), ...update } }), { code: 'INVALID_ARGUMENT' });
  }
  await assert.rejects(call('deleteUser', { id: '../users' }), { code: 'INVALID_ARGUMENT' });
});

test('xuất JSON từ Firestore thật của Emulator, không thêm trường', async () => {
  const records = []; let cursor = null;
  do {
    const page = await call('exportUsers', { cursor });
    records.push(...page.records); cursor = page.nextCursor;
  } while (cursor);
  assert.ok(records.length >= 2);
  for (const record of records) {
    assert.deepEqual(Object.keys(record).sort(), ['email', 'hinhanh', 'hoten', 'matkhau']);
    assert.match(record.matkhau, /^scrypt\$/);
  }
  mkdirSync('submission', { recursive: true });
  writeFileSync('submission/users.json', JSON.stringify(records, null, 2) + '\n');
});
