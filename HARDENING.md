<!-- markdownlint-disable -->

# Hardening Report: noise-rest--tf-via-pr/v13.7.9

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **noise-rest--tf-via-pr/v13.7.9** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The composite step 'setup' writes untrusted values to $GITHUB_ENV without running them through printf '%s' ... | tr -d '\n\r' first. The block `{ echo "GH_REPO=$GH_REPO"; echo "GH_TOKEN=$GH_TOKEN"; echo "TF_CLI_ARGS=${TF_CLI_ARGS:+$TF_CLI_ARGS }-no-color"; echo "TF_WORKSPACE=$INPUTS_ARG_WORKSPACE"; } >> "$GITHUB_ENV"` takes its values from inputs.token, env.TF_WORKSPACE / inputs.arg-workspace, github.repository and the inherited TF_CLI_ARGS variable. If a value contains a newline, extra environment variables can be injected. The same step also writes input-derived values to $GITHUB_OUTPUT without sanitizing them: `echo "chdir=$(args chdir)"`, `echo "path=${INPUTS_ARG_CHDIR:+$INPUTS_ARG_CHDIR/}tfplan"`, and `echo "GH_IDENTIFIER_NAME=$name" >> "$GITHUB_ENV"`, where name comes from INPUTS_TOOL. The `pr=$pr_number` write is also unsanitized when pr_number comes from inputs.pr-number. Finally, the heredoc output() writes multi-line argument lists built from inputs.

Locations:

- `action.yml:75`
- `action.yml:79`

### github-env-injection (severity: high)

The composite step 'post' writes workflow-controlled values to $GITHUB_OUTPUT without the printf '%s' ... | tr -d '\n\r' step. `echo "run_url=$run_url" >> "$GITHUB_OUTPUT"` builds its value from the unsanitized GH_SERVER_URL, the inherited GH_REPO and GH_CHECK_RUN_ID (job.check_run_id). `echo "job=$GH_CHECK_RUN_ID"` and `echo "check_id=$GH_CHECK_RUN_ID"` write the raw value. `echo "command=$command"` only strips '\n', not '\r', and its value comes from inputs.hide-args / inputs.show-args and argument lists built from inputs. `echo "comment_body<<EOCOMMENTTFVIAPR"...` writes a body that includes inputs.comment-pos-1 through inputs.comment-pos-6, so an input containing the delimiter line can inject extra outputs.

Locations:

- `action.yml:322`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

action.yml, 'setup' step: added a sanitize() helper (printf '%s' | tr -d '\n\r'). It now cleans every value written to GITHUB_ENV that comes from outside the step: GH_HOST, GH_REPO, GH_TOKEN, TF_CLI_ARGS, TF_WORKSPACE and GH_IDENTIFIER_NAME. It also cleans the chdir, path, pr and name outputs. The chdir value is captured into a variable first, then sanitized. The output() helper still writes the multi-line argument lists unchanged, but each call now gets a random delimiter from /dev/urandom instead of the fixed EOARGTFVIAPR.

'post' step: command is now sanitized for both \n and \r. Sanitizing also covers summary, job, check_id, run_url and comment_id. The result, diff and comment_body heredocs now use random /dev/urandom delimiters, and their content is written unchanged, so multi-line values keep their lines. The comment_id lookup keeps upstream's tolerance of failure: upstream ran jq inside echo, so a jq error never stopped the step, and the new standalone capture has '|| true' to match.

