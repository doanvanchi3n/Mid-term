import { test } from 'node:test';
import assert from 'node:assert/strict';
import { validateUser, hashPassword, documentId, requireAdmin } from '../src/user_service.js';

test('validation và chuẩn hóa chỉ trả về bốn trường', () => {
  const record = validateUser({ email: ' AN@example.com ', hoten: ' Nguyễn An ', matkhau: 'abc123456', hinhanh: '' });
  assert.deepEqual(Object.keys(record), ['email', 'matkhau', 'hoten', 'hinhanh']);
  assert.equal(record.email, 'an@example.com');
  assert.equal(record.hoten, 'Nguyễn An');
  assert.equal(documentId(record.email).length, 64);
});
test('hash mỗi lần dùng salt khác nhau, không chứa mật khẩu rõ', async () => {
  const [a, b] = await Promise.all([hashPassword('Secret123!'), hashPassword('Secret123!')]);
  assert.notEqual(a, b);
  assert.ok(!a.includes('Secret123!'));
  assert.throws(() => requireAdmin(null), { code: 'unauthenticated' });
  assert.throws(() => requireAdmin({ token: {} }), { code: 'permission-denied' });
  requireAdmin({ token: { admin: true } });
});
