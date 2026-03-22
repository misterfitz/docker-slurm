# Contributing

Thank you for your interest in contributing to this project!

## Pre-commit Hooks

This repository uses [pre-commit](https://pre-commit.com/) to enforce code
quality checks before changes reach CI. The following hooks are configured:

| Hook | Tool | Purpose |
|:-----|:-----|:--------|
| `hadolint` | [hadolint](https://github.com/hadolint/hadolint) | Lint Dockerfiles for best practices |
| `shellcheck` | [ShellCheck](https://www.shellcheck.net/) | Lint shell scripts (`startup.sh`) |
| `yamllint` | [yamllint](https://yamllint.readthedocs.io/) | Lint YAML files (workflows, docker-compose) |
| `trailing-whitespace` | [pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks) | Remove trailing whitespace |
| `end-of-file-fixer` | [pre-commit-hooks](https://github.com/pre-commit/pre-commit-hooks) | Ensure files end with a newline |

### Setup

1. Install pre-commit (requires Python 3):

   ```shell
   pip install pre-commit
   ```

2. Install the hooks into the local repository:

   ```shell
   pre-commit install
   ```

After installation the hooks run automatically on every `git commit`. To run
them manually against all files at any time:

```shell
pre-commit run --all-files
```

### CI

The hooks are also enforced in CI via the
[Pre-commit Checks](.github/workflows/pre-commit.yml) workflow, which runs on
every push to `main` and on every pull request.

### Linter Configuration

| File | Description |
|:-----|:------------|
| `.hadolint.yaml` | hadolint rules — intentionally unpinned packages (`DL3041`), shell-based `CMD` (`DL3025`), and multi-stage build selectors (`DL3006`) are suppressed project-wide; info-level findings do not fail the build |
| `.yamllint.yml` | yamllint rules — `document-start` is disabled; line length is relaxed to 120 characters; `truthy` key checking is disabled to allow GitHub Actions `on:` syntax |
