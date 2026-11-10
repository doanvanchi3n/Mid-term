import { chromium } from 'playwright';
import { createServer } from 'node:http';
import { readFile, mkdir, writeFile } from 'node:fs/promises';
import { resolve, extname } from 'node:path';
import { execFileSync } from 'node:child_process';

execFileSync(process.execPath, ['scripts/seed_emulator.mjs'], { stdio: 'inherit' });
const root = resolve('build/web');
const types = { '.js': 'application/javascript', '.html': 'text/html', '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.svg': 'image/svg+xml', '.otf': 'font/otf' };
const server = createServer(async (request, response) => {
  try {
    const pathname = new URL(request.url, 'http://127.0.0.1').pathname;
    const file = resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
    if (!file.startsWith(root + '/')) { response.writeHead(403).end(); return; }
    const bytes = await readFile(file);
    response.writeHead(200, { 'Content-Type': types[extname(file)] ?? 'application/octet-stream' }).end(bytes);
  } catch { response.writeHead(404).end(); }
});
await new Promise((done) => server.listen(7357, '127.0.0.1', done));
await mkdir('submission/screenshots', { recursive: true });
const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true, args: ['--disable-dev-shm-usage'] });
const page = await browser.newPage({ viewport: { width: 1366, height: 900 } });
const errors = [];
page.on('pageerror', (error) => errors.push(error.message));
const frames = [];
const cdp = await page.context().newCDPSession(page);
cdp.on('Page.screencastFrame', async ({ data, metadata, sessionId }) => {
  frames.push({ bytes: Buffer.from(data, 'base64'), time: metadata.timestamp });
  await cdp.send('Page.screencastFrameAck', { sessionId }).catch(() => {});
});
async function typeField(index, value, replace = false) {
  await page.getByRole('textbox').nth(index).click();
  await page.waitForTimeout(300);
  if (replace) await page.keyboard.press('Control+A');
  await page.keyboard.type(value, { delay: 65 });
  await page.waitForTimeout(200);
}
try {
  await page.goto('http://127.0.0.1:7357', { waitUntil: 'networkidle' });
  const placeholder = page.locator('flt-semantics-placeholder');
  await placeholder.waitFor({ state: 'attached' });
  await placeholder.evaluate((element) => element.click());
  await page.getByRole('button', { name: 'Đăng nhập', exact: true }).waitFor();
  await page.screenshot({ path: 'submission/screenshots/01-login-web.png' });
  await typeField(0, 'admin@ecomer.local', true);
  await typeField(1, 'EcomerDemo123!', true);
  await page.getByRole('button', { name: 'Đăng nhập', exact: true }).click();
  await page.getByRole('button', { name: 'Thêm người dùng', exact: true }).waitFor();
  await page.screenshot({ path: 'submission/screenshots/02-home-web.png' });
  await cdp.send('Page.startScreencast', { format: 'jpeg', quality: 60, everyNthFrame: 5 });
  // Tệp ảnh kiểm thử là ảnh render từ mascot gốc, không chỉnh sửa asset.
  const assetPage = await browser.newPage({ viewport: { width: 192, height: 192 } });
  await assetPage.setContent('<img src="http://127.0.0.1:7357/assets/assets/mascots/mascot_welcome.svg" width="192" height="192">');
  await assetPage.locator('img').screenshot({ path: 'submission/avatar-fixture.png' });
  await assetPage.close();
  await page.getByRole('button', { name: 'Thêm người dùng', exact: true }).click();
  await page.getByRole('button', { name: 'Chọn ảnh', exact: true }).waitFor();
  const chooserPromise = page.waitForEvent('filechooser');
  await page.getByRole('button', { name: 'Chọn ảnh', exact: true }).click();
  await (await chooserPromise).setFiles('submission/avatar-fixture.png');
  await page.getByRole('button', { name: 'Xóa ảnh', exact: true }).waitFor();
  await typeField(0, 'Nguyễn Văn An');
  await typeField(1, 'web-demo@example.com');
  await typeField(2, 'DemoUser123!');
  await page.screenshot({ path: 'submission/screenshots/03-user-form-web.png' });
  await page.getByRole('button', { name: 'Lưu người dùng', exact: true }).click();
  await page.getByRole('button', { name: 'Đã hiểu', exact: true }).waitFor();
  await page.screenshot({ path: 'submission/screenshots/04-success-web.png' });
  await page.getByRole('button', { name: 'Đã hiểu', exact: true }).click();
  await page.getByRole('button', { name: /^Người dùng Tab/ }).click();
  await page.getByRole('button', { name: 'Sửa Nguyễn Văn An', exact: true }).waitFor();
  await page.screenshot({ path: 'submission/screenshots/05-users-web.png' });
  await page.getByRole('button', { name: 'Sửa Nguyễn Văn An', exact: true }).click();
  await typeField(0, 'Nguyễn Văn An (đã sửa)', true);
  await page.getByRole('button', { name: 'Lưu người dùng', exact: true }).click();
  await page.getByRole('button', { name: 'Đã hiểu', exact: true }).click();
  const downloadPromise = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Xuất JSON', exact: true }).click();
  await (await downloadPromise).saveAs('submission/users-web.json');
  await page.getByRole('button', { name: 'Đã hiểu', exact: true }).click();
  await page.getByRole('button', { name: 'Xem Nguyễn Văn An (đã sửa)', exact: true }).click();
  await page.getByRole('button', { name: 'Chỉnh sửa', exact: true }).waitFor();
  await page.screenshot({ path: 'submission/screenshots/06-detail-web.png' });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({ path: 'submission/screenshots/07-detail-mobile-web.png' });
  await page.setViewportSize({ width: 1366, height: 900 });
  await page.getByRole('button', { name: 'Xóa người dùng', exact: true }).click();
  await page.getByRole('button', { name: 'Xóa', exact: true }).waitFor();
  await page.screenshot({ path: 'submission/screenshots/08-confirm-delete-web.png' });
  await page.getByRole('button', { name: 'Xóa', exact: true }).click();
  await page.getByRole('button', { name: 'Đã hiểu', exact: true }).click();
  await page.getByRole('button', { name: 'Tạo hồ sơ đầu tiên', exact: true }).waitFor();
  console.log('WEB_SMOKE: PASS đăng nhập, chọn ảnh, tạo, hiển thị, sửa, xuất JSON, responsive và xóa');
  if (errors.length) throw new Error(errors.join('\n'));
} catch (error) {
  await writeFile('web-failure.txt', await page.locator('body').ariaSnapshot());
  await page.screenshot({ path: 'submission/screenshots/web-failure.png', timeout: 10000 }).catch(() => {});
  console.error('PAGE_ERRORS', errors);
  throw error;
} finally {
  await cdp.send('Page.stopScreencast').catch(() => {});
  await browser.close();
  await new Promise((done) => server.close(done));
  if (frames.length > 1) {
    const folder = resolve('build/web-recording');
    await mkdir(folder, { recursive: true });
    const lines = [];
    for (let i = 0; i < frames.length; i++) {
      await writeFile(`${folder}/${i}.jpg`, frames[i].bytes);
      lines.push(`file '${folder}/${i}.jpg'`, `duration ${Math.min(3, Math.max(0.08, (frames[i + 1]?.time ?? frames[i].time + 1) - frames[i].time))}`);
    }
    lines.push(`file '${folder}/${frames.length - 1}.jpg'`);
    await writeFile(`${folder}/frames.txt`, lines.join('\n'));
    execFileSync('/usr/bin/ffmpeg', ['-y', '-loglevel', 'error', '-f', 'concat', '-safe', '0', '-i', `${folder}/frames.txt`,
      '-vf', 'scale=1366:900:force_original_aspect_ratio=decrease,pad=1366:900:(ow-iw)/2:(oh-ih)/2,fps=10',
      '-c:v', 'libx264', '-preset', 'fast', '-pix_fmt', 'yuv420p', 'submission/demo-web.mp4']);
  }
}
