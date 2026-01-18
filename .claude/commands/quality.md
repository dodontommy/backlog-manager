# Full Quality Check

Run all quality checks before committing or deploying.

## Instructions

Run these checks in sequence:

1. **Tests** - Run the full test suite:
   ```bash
   bin/rails test
   ```

2. **Linting** - Run RuboCop:
   ```bash
   bundle exec rubocop
   ```

3. **Security - Brakeman**:
   ```bash
   bundle exec brakeman -q
   ```

4. **Security - Bundler Audit**:
   ```bash
   bundle exec bundler-audit check --update
   ```

After all checks complete:
1. Provide a summary table showing pass/fail for each check
2. List any issues that need attention before deployment
3. Give a final verdict: "Ready to deploy" or "Issues need attention"

## Argument
$ARGUMENTS
