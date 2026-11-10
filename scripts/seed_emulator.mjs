import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9199';
initializeApp({ projectId: 'demo-ecomer' });
const email = 'admin@ecomer.local';
const password = 'EcomerDemo123!';
const auth = getAuth();
let user;
try { user = await auth.getUserByEmail(email); }
catch (error) {
  if (error.code !== 'auth/user-not-found') throw error;
  user = await auth.createUser({ email, password, displayName: 'ECOMER Admin' });
}
await auth.setCustomUserClaims(user.uid, { ...user.customClaims, admin: true });
console.log(`Admin Emulator: ${email} / ${password}`);
console.log('Quyền admin nằm trong Auth custom claims. Không thêm trường/collection quản trị vào Firestore.');
process.exit(0);
