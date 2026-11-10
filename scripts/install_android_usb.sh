#!/usr/bin/env bash
set -euo pipefail

connect_only=false
if [[ $# -eq 1 && "$1" == '--connect-only' ]]; then
  connect_only=true
elif [[ $# -ne 0 ]]; then
  printf 'Cách chạy: bash scripts/install_android_usb.sh [--connect-only]\n' >&2
  exit 1
fi

project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
apk_path="$project_dir/submission/apk/ecomer-usb-debug.apk"
adb_bin="$(command -v adb || true)"
if [[ -z "$adb_bin" ]]; then
  adb_bin="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}/platform-tools/adb"
fi
if [[ ! -x "$adb_bin" ]]; then
  printf 'Không tìm thấy adb. Cài Android SDK Platform Tools hoặc thêm adb vào PATH.\n' >&2
  exit 1
fi
if [[ "$connect_only" == false && ! -f "$apk_path" ]]; then
  printf 'Chưa có APK: %s\nXem docs/CAI_APK_DIEN_THOAI.md để build.\n' "$apk_path" >&2
  exit 1
fi

devices_output="$("$adb_bin" devices)"
mapfile -t device_ids < <(printf '%s\n' "$devices_output" | awk 'NR > 1 && $2 == "device" { print $1 }')
if [[ -n "${ECOMER_DEVICE_ID:-}" ]]; then
  device_id="$ECOMER_DEVICE_ID"
  if [[ "$("$adb_bin" -s "$device_id" get-state 2>/dev/null || true)" != 'device' ]]; then
    printf 'Thiết bị %s chưa sẵn sàng. Kiểm tra cáp và xác nhận gỡ lỗi USB.\n' "$device_id" >&2
    exit 1
  fi
elif [[ ${#device_ids[@]} -eq 1 ]]; then
  device_id="${device_ids[0]}"
else
  printf '%s\n' "$devices_output" >&2
  if [[ "$devices_output" == *'no permissions'* ]]; then
    printf 'Linux chưa cấp quyền USB. Chạy: sudo apt-get install android-sdk-platform-tools-common\n' >&2
    printf 'Sau đó rút/cắm lại cáp, mở khóa điện thoại và cho phép gỡ lỗi USB.\n' >&2
    exit 1
  fi
  if [[ "$devices_output" == *'unauthorized'* ]]; then
    printf 'Mở khóa điện thoại và chấp nhận thông báo Cho phép gỡ lỗi USB.\n' >&2
    exit 1
  fi
  printf 'Cần một điện thoại đã bật gỡ lỗi USB và cho phép máy tính kết nối.\n' >&2
  printf 'Nếu có nhiều thiết bị, chạy: ECOMER_DEVICE_ID=SERIAL bash scripts/install_android_usb.sh\n' >&2
  exit 1
fi

"$adb_bin" -s "$device_id" reverse tcp:9199 tcp:9199
"$adb_bin" -s "$device_id" reverse tcp:5001 tcp:5001
if [[ "$connect_only" == false ]]; then
  "$adb_bin" -s "$device_id" install -r "$apk_path"
fi
"$adb_bin" -s "$device_id" shell am start -n vn.ecomer.ecomer/.MainActivity
printf 'Đã nối cổng USB và mở ECOMER. Giữ cáp USB và Firebase Emulator chạy trong lúc demo.\n'
