# Security Scanner

Run security scans on the codebase.

## Instructions

Run the following security tools:

1. **Brakeman** - Static analysis for Rails security vulnerabilities:
   ```bash
   bundle exec brakeman -q
   ```

2. **Bundler-Audit** - Check for vulnerable gem versions:
   ```bash
   bundle exec bundler-audit check --update
   ```

After running:
1. Summarize findings from both tools
2. Categorize issues by severity (High, Medium, Low)
3. Provide recommendations for fixing critical issues
4. Note any false positives based on the project context

## Argument
$ARGUMENTS
