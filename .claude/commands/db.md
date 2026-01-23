# Database Operations

Run database commands for Backlog Manager.

## Instructions

Execute the database command based on the argument:

- `migrate` or no argument: Run `bin/rails db:migrate`
- `rollback`: Run `bin/rails db:rollback`
- `seed`: Run `bin/rails db:seed`
- `reset`: Run `bin/rails db:reset` (WARNING: destroys data!)
- `status`: Run `bin/rails db:migrate:status`
- `create`: Run `bin/rails db:create`
- `console`: Run `bin/rails dbconsole`

After running:
1. Confirm the operation completed successfully
2. If migrate/rollback, show which migrations were applied/reverted
3. If there are errors, explain what went wrong and suggest fixes

**CRITICAL**: For destructive operations (reset, drop), ask for confirmation first!

## Argument
$ARGUMENTS
