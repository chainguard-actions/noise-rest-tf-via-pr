<!-- markdownlint-disable -->

# Hardening Report: noise-rest--tf-via-pr/v13.7.11

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **noise-rest--tf-via-pr/v13.7.11** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'setup' step writes workflow-controlled values to $GITHUB_ENV and $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step. Writes to $GITHUB_ENV: `echo "GH_REPO=$GH_REPO"` (from github.repository), `echo "GH_TOKEN=$GH_TOKEN"` (from inputs.token), `echo "TF_CLI_ARGS=${TF_CLI_ARGS:+$TF_CLI_ARGS }-no-color"` (inherited process env) and `echo "TF_WORKSPACE=$INPUTS_ARG_WORKSPACE"` (from env.TF_WORKSPACE / inputs.arg-workspace). Writes to $GITHUB_OUTPUT: `echo "chdir=$(args chdir)"` and `echo "path=${INPUTS_ARG_CHDIR:+$INPUTS_ARG_CHDIR/}tfplan"` (inputs.arg-chdir / inputs.working-directory), `echo "pr=$pr_number"` (can come from inputs.pr-number or github.event.number), and `echo "GH_IDENTIFIER_NAME=$name"` / `echo "name=$name"` (include inputs.tool). The heredoc output() writes also carry inputs. A newline in any of these inputs could inject extra environment variables (e.g. LD_PRELOAD, BASH_ENV) or extra step outputs.

Locations:

- `action.yml:76`
- `action.yml:77`
- `action.yml:78`
- `action.yml:81`
- `action.yml:82`
- `action.yml:109`
- `action.yml:117`
- `action.yml:148`

### github-env-injection (severity: high)

The 'post' step writes workflow-controlled values to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` step. `echo "command=$command"` is built from inputs.tool, the chdir output and ALL_ARGS (steps.setup.outputs.all); it only runs `tr -d '\n'`, which leaves '\r'. `echo "job=$GH_CHECK_RUN_ID"` and `echo "check_id=$GH_CHECK_RUN_ID"` come from job.check_run_id. `echo "run_url=$run_url"` is built from github.server_url and github.repository. The comment_body heredoc embeds the inputs.comment-pos-1..6 values, and `echo "summary=$summary"` writes text taken from tool output.

Locations:

- `action.yml:332`
- `action.yml:377`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

All changes are in action.yml.

Setup step:
- Added a `sanitize()` helper (`printf '%s' | tr -d '\n\r'`).
- Used it on the GH_HOST, GH_REPO, GH_TOKEN, TF_CLI_ARGS and TF_WORKSPACE writes to GITHUB_ENV.
- Used it on the chdir, path, pr and name outputs and on GH_IDENTIFIER_NAME. The chdir value is captured into a variable first and sanitized afterwards.
- The `output()` helper now picks a random /dev/urandom delimiter for each call instead of the fixed EOARGTFVIAPR. The multi-line argument lists are written unchanged.

Post step:
- `sanitize` now runs on command (which previously only had \n removed), summary, job, check_id, run_url and comment_id.
- comment_id is captured with `|| true` first, so a failing jq still doesn't stop the step, the same as upstream's inline echo.
- The result, diff and comment_body heredocs now use random delimiters instead of fixed ones. Their content keeps its line breaks.

