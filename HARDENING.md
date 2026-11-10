<!-- markdownlint-disable -->

# Hardening Report: noise-rest--tf-via-pr/v13.7.8

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **noise-rest--tf-via-pr/v13.7.8** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'setup' step writes workflow-controlled values to $GITHUB_ENV and $GITHUB_OUTPUT without first running them through printf '%s' ... | tr -d '\n\r'. Writes to $GITHUB_ENV: echo "GH_REPO=$GH_REPO", echo "GH_TOKEN=$GH_TOKEN" (from inputs.token), echo "TF_CLI_ARGS=${TF_CLI_ARGS:+$TF_CLI_ARGS }-no-color" (env inherited from the calling workflow), echo "TF_WORKSPACE=$INPUTS_ARG_WORKSPACE" (from env.TF_WORKSPACE / inputs.arg-workspace), and echo "GH_IDENTIFIER_NAME=$name" (built from inputs.tool). Writes to $GITHUB_OUTPUT: echo "chdir=$(args chdir)", echo "path=${INPUTS_ARG_CHDIR:+$INPUTS_ARG_CHDIR/}tfplan", echo "pr=$pr_number" (from inputs.pr-number) and echo "name=$name". The output() helper also writes input-derived argument lists between heredoc delimiters without sanitizing them. A value containing a newline could inject extra environment variables or outputs.

Locations:

- `action.yml:66`

### github-env-injection (severity: high)

The 'post' step writes values derived from inputs, the workflow environment and tool console output to $GITHUB_OUTPUT without the required printf '%s' ... | tr -d '\n\r' step. These include echo "command=$command" (hide-args/show-args and the input-derived command; it strips '\n' but not '\r' and doesn't use the required pipeline), echo "summary=$summary", echo "run_url=$run_url" (built from GH_SERVER_URL and GH_REPO, which the step inherits through $GITHUB_ENV from the setup step's unsanitized write), and the result/diff/comment_body heredoc blocks that include inputs.comment-pos-* and console content.

Locations:

- `action.yml:306`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Setup step: added a sanitize() helper (printf '%s' | tr -d '\n\r'). Values are now sanitized before they are written to GITHUB_ENV: GH_HOST, GH_REPO, GH_TOKEN, TF_CLI_ARGS, TF_WORKSPACE and GH_IDENTIFIER_NAME. Same for the chdir, path, pr and name outputs. chdir is captured first ('raw=$(args chdir)') and then sanitized, so errexit still applies. The output() helper keeps its multi-line argument lists but now uses a random delimiter per call (od /dev/urandom) instead of the fixed EOARGTFVIAPR. Post step: command now uses the printf|tr -d '\n\r' pipeline. summary, run_url, job/check_id and comment_id are sanitized too. comment_id is captured with '|| true' because upstream ran that command inside echo, where a failure didn't stop the step. The result, diff and comment_body heredocs keep their multi-line content and now use random per-run delimiters.

