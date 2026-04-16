#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin" "$tmpdir/home/.cache"

cat >"$tmpdir/bin/gh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >>"$FAKE_GH_LOG"
EOF
chmod +x "$tmpdir/bin/gh"

run_gh() {
  HOME="$tmpdir/home" \
  PATH="$tmpdir/bin:$PATH" \
  FAKE_GH_LOG="$tmpdir/gh.log" \
  zsh -fc 'compdef() { :; }; source /Users/samwang/dotfiles/zsh/tools.zsh; gh "$@"' zsh "$@"
}

assert_output_equals() {
  local actual="$1"
  local expected="$2"
  local label="$3"

  if [[ "$actual" != "$expected" ]]; then
    printf 'FAIL: %s\nEXPECTED:\n%s\nACTUAL:\n%s\n' "$label" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_log_equals() {
  local expected="$1"
  local label="$2"
  local actual=""

  if [[ -f "$tmpdir/gh.log" ]]; then
    actual="$(cat "$tmpdir/gh.log")"
  fi

  assert_output_equals "$actual" "$expected" "$label"
}

home_root="$tmpdir/home/code/github.com"

rm -f "$tmpdir/gh.log"
run_gh repo clone softleader/kapok
assert_log_equals "repo
clone
softleader/kapok
$home_root/softleader/kapok" "default clone path"

rm -f "$tmpdir/gh.log"
run_gh repo clone softleader/kapok softleader/kapok-worktree2
assert_log_equals "repo
clone
softleader/kapok
$home_root/softleader/kapok-worktree2" "root-relative explicit directory"

rm -f "$tmpdir/gh.log"
run_gh repo clone softleader/kapok /tmp/kapok
assert_log_equals "repo
clone
softleader/kapok
/tmp/kapok" "absolute path passthrough"

rm -f "$tmpdir/gh.log"
run_gh repo clone --no-upstream softleader/kapok -- --depth=1
assert_log_equals "repo
clone
--no-upstream
softleader/kapok
$home_root/softleader/kapok
--
--depth=1" "clone flags and git flags"

mkdir -p "$home_root/softleader/agent-skills"
rm -f "$tmpdir/gh.log"
existing_stdout="$tmpdir/existing.stdout"
existing_stderr="$tmpdir/existing.stderr"

set +e
run_gh repo clone softleader/agent-skills >"$existing_stdout" 2>"$existing_stderr"
status=$?
set -e

if [[ $status -eq 0 ]]; then
  printf 'FAIL: existing target should return non-zero\n' >&2
  exit 1
fi

assert_output_equals "$(cat "$existing_stdout")" "" "existing target stdout"
assert_log_equals "" "existing target should not call gh"

stderr_output="$(cat "$existing_stderr")"
case "$stderr_output" in
  *"目標目錄已存在: $home_root/softleader/agent-skills"* ) ;;
  *)
    printf 'FAIL: existing target message missing target path\n%s\n' "$stderr_output" >&2
    exit 1
    ;;
esac

case "$stderr_output" in
  *"gh repo clone softleader/agent-skills softleader/agent-skills-worktree2"* ) ;;
  *)
    printf 'FAIL: existing target message missing suggested command\n%s\n' "$stderr_output" >&2
    exit 1
    ;;
esac

printf 'ALL CHECKS PASSED\n'
