import { randomBytes, scrypt as scryptCallback, createHash } from 'node:crypto';
import { promisify } from 'node:util';

const scrypt = promisify(scryptCallback);
export const fields = ['email', 'matkhau', 'hoten', 'hinhanh'];
export class UserError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
export function requireAdmin(auth) {
  if (!auth) throw new UserError('unauthenticated', 'Vui lòng đăng nhập.');
  if (auth.token?.admin !== true) throw new UserError('permission-denied', 'Tài khoản chưa có quyền quản trị.');
}
export function documentId(email) { return createHash('sha256').update(email).digest('hex'); }

export function validateUser(input, { creating = true } = {}) {
  if (!input || typeof input !== 'object' || Array.isArray(input) ||
    Object.keys(input).some((key) => !fields.includes(key)) || fields.some((key) => typeof input[key] !== 'string')) {
    throw new UserError('invalid-argument', 'Dữ liệu phải có đúng email, matkhau, hoten, hinhanh.');
  }
  const email = input.email.trim().toLowerCase();
  const hoten = input.hoten.trim();
  if (email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new UserError('invalid-argument', 'Email không hợp lệ.');
  if (!hoten || hoten.length > 120) throw new UserError('invalid-argument', 'Họ tên phải từ 1 đến 120 ký tự.');
  if ((creating || input.matkhau !== '') && (input.matkhau.length < 8 || input.matkhau.length > 128)) {
    throw new UserError('invalid-argument', 'Mật khẩu phải từ 8 đến 128 ký tự.');
  }
  validateImage(input.hinhanh);
  return { email, matkhau: input.matkhau, hoten, hinhanh: input.hinhanh };
}
export function validateImage(value) {
  if (value === '') return;
  const match = /^data:image\/(jpeg|png|webp);base64,([A-Za-z0-9+/]+={0,2})$/.exec(value);
  if (!match || value.length > 210000) throw new UserError('invalid-argument', 'Ảnh phải là JPEG, PNG hoặc WebP, tối đa 150 KB.');
  const data = Buffer.from(match[2], 'base64');
  if (data.length > 150 * 1024 || data.toString('base64') !== match[2]) throw new UserError('invalid-argument', 'Ảnh không hợp lệ hoặc quá 150 KB.');
  const valid = (match[1] === 'jpeg' && data[0] === 0xff && data[1] === 0xd8 && data[2] === 0xff)
    || (match[1] === 'png' && data.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])))
    || (match[1] === 'webp' && data.subarray(0, 4).toString() === 'RIFF' && data.subarray(8, 12).toString() === 'WEBP');
  if (!valid) throw new UserError('invalid-argument', 'Nội dung tệp không khớp định dạng ảnh.');
}
export async function hashPassword(password) {
  const salt = randomBytes(16).toString('hex');
  const hash = await scrypt(password, salt, 64, { N: 32768, r: 8, p: 1, maxmem: 64 * 1024 * 1024 });
  return `scrypt$32768$8$1$${salt}$${hash.toString('hex')}`;
}
export function createUserService(db) {
  const users = db.collection('users');
  return {
    async save(input, previousId = null) {
      const value = validateUser(input, { creating: !previousId });
      if (previousId !== null && !/^[a-f0-9]{64}$/.test(previousId)) throw new UserError('invalid-argument', 'ID không hợp lệ.');
      const id = documentId(value.email);
      const passwordHash = value.matkhau ? await hashPassword(value.matkhau) : null;
      await db.runTransaction(async (transaction) => {
        const targetRef = users.doc(id);
        const target = await transaction.get(targetRef);
        let previous = null;
        if (previousId) previous = previousId === id ? target : await transaction.get(users.doc(previousId));
        if (previousId && !previous.exists) throw new UserError('not-found', 'Hồ sơ đã bị xóa hoặc email đã được đổi. Hãy tải lại.');
        if (target.exists && previousId !== id) throw new UserError('already-exists', 'Email này đã có trong danh sách.');
        const record = { email: value.email, matkhau: passwordHash ?? previous.data().matkhau, hoten: value.hoten, hinhanh: value.hinhanh };
        transaction.set(targetRef, record);
        if (previousId && previousId !== id) transaction.delete(users.doc(previousId));
      });
      return { id };
    },
    async remove(id) {
      if (typeof id !== 'string' || !/^[a-f0-9]{64}$/.test(id)) throw new UserError('invalid-argument', 'ID không hợp lệ.');
      await db.runTransaction(async (transaction) => {
        const ref = users.doc(id);
        if (!(await transaction.get(ref)).exists) throw new UserError('not-found', 'Hồ sơ đã bị xóa.');
        transaction.delete(ref);
      });
      return { deleted: true };
    },
    async list(cursor = null, exporting = false) {
      if (cursor !== null && (typeof cursor !== 'string' || !/^[a-f0-9]{64}$/.test(cursor))) throw new UserError('invalid-argument', 'Con trỏ không hợp lệ.');
      let query = users.orderBy('__name__').limit(20);
      if (cursor) query = query.startAfter(cursor);
      const snapshot = await query.get();
      return {
        records: snapshot.docs.map((doc) => exporting ? doc.data() : { id: doc.id, ...doc.data(), matkhau: '••••••••' }),
        nextCursor: snapshot.size === 20 ? snapshot.docs.at(-1).id : null,
      };
    },
  };
}
