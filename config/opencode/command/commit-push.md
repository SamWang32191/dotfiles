---
description: Git commit and push
agent: build
model: openai/gpt-5.4-mini
subtask: true
---

commit and push

make sure it uses the conventional commit format

prefer to explain WHY something was done from an end user perspective instead of
WHAT was done.

do not do generic messages like "improved agent experience" be very specific
about what user facing changes were made

if there are conflicts DO NOT FIX THEM. notify me and I will fix them

if the `git-commit-co-author` skill is available, you MUST use it to determine
and append the appropriate Co-authored-by trailer(s) to the commit message.

## GIT DIFF

!`git diff`

## GIT DIFF --cached

!`git diff --cached`

## GIT STATUS --short

!`git status --short`

<user-request>
$ARGUMENTS
</user-request>
