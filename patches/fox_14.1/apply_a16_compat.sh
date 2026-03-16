#!/usr/bin/env bash
set -euo pipefail

source_root="${1:-}"

if [[ -z "${source_root}" ]]; then
  echo "usage: $0 <orangefox-source-root>" >&2
  exit 1
fi

if [[ ! -d "${source_root}" ]]; then
  echo "source root does not exist: ${source_root}" >&2
  exit 1
fi

ensure_git_project() {
  local project_path="$1"
  local revision="$2"
  local label="$3"
  shift 3
  local remote_urls=("$@")

  if [[ -f "${project_path}/Android.bp" ]]; then
    echo "${label} already present: ${project_path}"
    return 0
  fi

  rm -rf "${project_path}"
  mkdir -p "$(dirname "${project_path}")"

  local remote_url
  for remote_url in "${remote_urls[@]}"; do
    if git clone --depth=1 "${remote_url}" -b "${revision}" "${project_path}"; then
      echo "Cloned ${label} from ${remote_url} @ ${revision}"
      return 0
    fi
    rm -rf "${project_path}"
  done

  echo "failed to clone ${label} from all configured remotes" >&2
  exit 1
}

ensure_file_contains() {
  local file_path="$1"
  local needle="$2"
  local label="$3"

  if [[ ! -f "${file_path}" ]]; then
    echo "${label} missing file: ${file_path}" >&2
    exit 1
  fi

  if ! grep -Fq "${needle}" "${file_path}"; then
    echo "${label} missing expected content: ${needle}" >&2
    exit 1
  fi

  echo "Validated ${label}: ${needle}"
}

ensure_value_in_file() {
  local file_path="$1"
  local value="$2"
  local label="$3"

  if [[ ! -f "${file_path}" ]]; then
    echo "::warning::Skipping ${label}; file not found: ${file_path}"
    return 0
  fi

  python3 - "${file_path}" "${value}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
value = sys.argv[2]
lines = path.read_text().splitlines()

if value not in lines:
    lines.append(value)
    path.write_text("\n".join(lines) + "\n")
PY

  local values
  values="$(python3 - "${file_path}" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
print(" ".join(Path(path).read_text().splitlines()))
PY
)"

  echo "Patched ${label}: ${values}"
}

cts_root="${source_root}/cts/tests/tests/os/assets"

ensure_git_project \
  "${source_root}/external/guava" \
  "android14-release" \
  "external/guava" \
  "https://android.googlesource.com/platform/external/guava" \
  "https://gitlab.com/aosp-mirror-1/platform/external/guava.git"

ensure_file_contains \
  "${source_root}/external/guava/Android.bp" \
  'name: "guava"' \
  "external/guava module definition"

if [[ -d "${cts_root}" ]]; then
  echo "Applying Android 16 compatibility patches under: ${cts_root}"
  ensure_value_in_file "${cts_root}/platform_releases.txt" "16" "CTS platform releases"
  ensure_value_in_file "${cts_root}/platform_versions.txt" "16" "CTS platform versions"
else
  echo "::notice::CTS assets directory not present; skipping CTS version patch."
fi

echo "Android 16 compatibility patch completed."
