<!-- markdownlint-disable -->

# Hardening Report: noise-rest--tf-via-pr/v13.7.10

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **noise-rest--tf-via-pr/v13.7.10** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'setup' composite step writes values the caller controls to $GITHUB_ENV and $GITHUB_OUTPUT without the printf '%s' | tr -d '\n\r' sanitization step. Writes to $GITHUB_ENV: `echo "GH_REPO=$GH_REPO"`, `echo "GH_TOKEN=$GH_TOKEN"` (from inputs.token), `echo "TF_CLI_ARGS=${TF_CLI_ARGS:+$TF_CLI_ARGS }-no-color"` (inherited from the calling workflow), `echo "TF_WORKSPACE=$INPUTS_ARG_WORKSPACE"` (from env.TF_WORKSPACE or inputs.arg-workspace), and `echo "GH_IDENTIFIER_NAME=$name"` (built from inputs.tool). Writes to $GITHUB_OUTPUT: `echo "chdir=$(args chdir)"`, `echo "path=${INPUTS_ARG_CHDIR:+$INPUTS_ARG_CHDIR/}tfplan"`, `echo "pr=$pr_number"` (from inputs.pr-number), `echo "name=$name"`, and the heredoc `output()` helper, which writes inputs.arg-* values directly. A newline in any of these values lets an attacker inject extra environment variables or outputs, for example a malicious TF_CLI_ARGS, PATH or LD_PRELOAD.

Locations:

- `action.yml:81`
- `action.yml:100`
- `action.yml:109`
- `action.yml:117`
- `action.yml:146`

### github-env-injection (severity: high)

The 'post' composite step writes to $GITHUB_OUTPUT using heredoc delimiters, and the content includes workflow-controlled input with no tr -d '\n\r' sanitization: `echo "comment_body<<EOCOMMENTTFVIAPR"$'\n'"$body"$'\n'EOCOMMENTTFVIAPR >> "$GITHUB_OUTPUT"`. Here $body embeds inputs.comment-pos-1 through comment-pos-6. The step also writes `echo "command=$command"`, which strips '\n' but not '\r' and includes inputs.show-args/arg-* values, and `echo "run_url=$run_url"`. If an input contains a newline plus the delimiter, an attacker can inject arbitrary step outputs.

Locations:

- `action.yml:288`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Setup step: added a sanitize() helper (printf '%s' | tr -d '\n\r') and applied it to the GH_HOST, GH_REPO, GH_TOKEN, TF_CLI_ARGS and TF_WORKSPACE writes to $GITHUB_ENV, and to the chdir, path, pr and name outputs (name also goes to GH_IDENTIFIER_NAME). The chdir value is captured into a variable first and then sanitized, instead of nesting one command substitution inside another. The output() heredoc helper now uses a delimiter generated once per run from /dev/urandom instead of the fixed EOARGTFVIAPR, and its multi-line argument lists are left as they are. Post step: command now strips '\r' as well as '\n'. summary, run_url and comment_id are sanitized. comment_id is captured with '|| true' so a failing jq still doesn't stop the step, as upstream. The result, diff and comment_body heredocs now use a random /dev/urandom delimiter instead of the fixed ones, written with printf '%s\n' so their lines stay intact.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In the 'post' step of action.yml, GH_CHECK_RUN_ID is now cleaned with printf '%s' | tr -d '\n\r' and stored in check_run_id. That value is then written to the job= and check_id= entries in $GITHUB_OUTPUT. The step's other uses of the variable are unchanged.

