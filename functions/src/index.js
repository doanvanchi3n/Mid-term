import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { createUserService, requireAdmin, UserError } from './user_service.js';

initializeApp();
const service = createUserService(getFirestore());
function adminCallable(action) {
  return onCall({ region: 'us-central1', maxInstances: 5, concurrency: 2, memory: '256MiB', timeoutSeconds: 60 }, async (request) => {
    try {
      requireAdmin(request.auth);
      return await action(request.data ?? {});
    } catch (error) {
      if (error instanceof UserError) throw new HttpsError(error.code, error.message);
      // Không ghi request hoặc mật khẩu vào log.
      console.error('User operation failed', { code: error.code ?? 'unknown' });
      throw new HttpsError('internal', 'Không thể hoàn tất thao tác. Vui lòng thử lại.');
    }
  });
}
export const listUsers = adminCallable((data) => service.list(data.cursor ?? null));
export const saveUser = adminCallable((data) => service.save(data.user, data.id ?? null));
export const deleteUser = adminCallable((data) => service.remove(data.id));
export const exportUsers = adminCallable((data) => service.list(data.cursor ?? null, true));
