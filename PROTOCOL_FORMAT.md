# PROTOCOL_FORMAT.md

Protocol files define automated workflows with consistent structure and clear documentation.

## Required Structure

```markdown
# @PROTOCOL_NAME.md

**Trigger**: `@PROTOCOL [command] [args]`

## Commands

- `command1 [args]` → Brief outcome
- `command2 [args]` → Brief outcome  
- `command3` → Brief outcome

## Core Process

Brief description or visual flow.
Key constraints or philosophy.

## [Protocol-Specific Sections]

Technical implementation details.
Workflows and procedures.
Edge cases and error handling.

## Examples

```
Usage examples with expected outputs
```

One-line protocol summary.
```

## Format Guidelines

**Length**:
- Maximum 350 lines (allows for technical detail)
- Minimum content for clarity
- Balance between completeness and conciseness

**Consistency**:
- Always start with `# @PROTOCOL_NAME.md`
- Always include trigger format after title
- Use `## Commands` (not Command List, etc.)
- End with one-line summary

**Required Sections**:
1. **Commands** - All available commands with outcomes
2. **Core Process** - Philosophy, constraints, overview

**Common Sections**:
- **Workflow** - Step-by-step procedures
- **Technical Details** - Implementation specifics
- **Examples** - Usage demonstrations
- **Error Handling** - Known issues and solutions
- **Dependencies** - Required tools or states

**Visual Elements**:
- `→` for outcomes and flows
- Numbered lists for sequential steps
- Bullet lists for options/features
- Code blocks for scripts/examples
- Tables for complex comparisons

**Code Blocks**:
```bash
# Essential bash scripts allowed
# Include key comments for clarity
# Focus on execution, not theory
```

## Section Templates

### Commands Section
```markdown
## Commands

- `status` → Show current state
- `create [name]` → Initialize new item
- `update [id] [changes]` → Modify existing item
- `delete [id]` → Remove item permanently
```

### Workflow Section
```markdown
## Workflow

1. Initialize with `create`
2. Check status with `status`
3. Make changes with `update`
4. Clean up with `delete`

**Error Recovery**:
- If step 2 fails → Check prerequisites
- If step 3 fails → Verify permissions
```

### Technical Details Section
```markdown
## Technical Details

**File Locations**:
- Input: `data/input/`
- Output: `data/output/`
- Logs: `logs/protocol.log`

**Constraints**:
- Maximum 100 items per batch
- 5-minute timeout per operation
- Requires write permissions
```

### Examples Section
```markdown
## Examples

**Basic Usage**:
```
@PROTOCOL create my-item
@PROTOCOL update my-item --priority=high
@PROTOCOL status
```

**Advanced Workflow**:
```
@PROTOCOL create batch-job --parallel=4
@PROTOCOL status --watch
@PROTOCOL delete batch-job --force
```
```

## Complete Example

```markdown
# @DEPLOY.md

**Trigger**: `@DEPLOY [command] [args]`

## Commands

- `prepare [env]` → Validate deployment readiness
- `execute [env]` → Deploy to environment
- `verify [env]` → Check deployment health
- `rollback [env]` → Revert to previous version
- `status` → Show all deployments

## Core Process

Prepare → Execute → Verify (→ Rollback if needed)

**Philosophy**: Safe, validated deployments with automatic rollback capability.
**Constraint**: Production requires two-phase approval.

## Workflow

### Standard Deployment
1. `@DEPLOY prepare staging` → Runs tests, builds artifacts
2. `@DEPLOY execute staging` → Deploys to staging
3. `@DEPLOY verify staging` → Health checks pass
4. `@DEPLOY prepare production` → Production validation
5. `@DEPLOY execute production` → Production deployment

### Emergency Rollback
1. `@DEPLOY status` → Identify problematic deployment
2. `@DEPLOY rollback production` → Immediate reversion
3. `@DEPLOY verify production` → Confirm restoration

## Technical Details

**Environments**:
- `local` → Developer machine
- `staging` → Pre-production testing
- `production` → Live environment

**Health Checks**:
- HTTP endpoints return 200
- Database connections active
- Required services responding
- Memory usage under 80%

**Rollback Window**:
- Automatic: 5 minutes after deployment
- Manual: Up to 24 hours
- Beyond 24h: Requires new deployment

## Error Handling

**Common Issues**:
- "Build failed" → Check test results in `logs/build.log`
- "Health check timeout" → Service may need longer startup
- "Rollback unavailable" → Previous version may be expired

**Recovery Procedures**:
1. Failed prepare → Fix tests, retry
2. Failed execute → Auto-rollback triggers
3. Failed verify → Manual rollback required

## Examples

**First Deployment**:
```
@DEPLOY prepare staging
@DEPLOY execute staging
@DEPLOY verify staging
```

**Production with Approval**:
```
@DEPLOY prepare production --dry-run
# Review changes
@DEPLOY execute production --approve=2FA
@DEPLOY verify production --detailed
```

**Emergency Response**:
```
@DEPLOY rollback production --immediate
@DEPLOY verify production
@DEPLOY status --last=10
```

Manages application deployment lifecycle with safety checks and rollback capability.
```

## Best Practices

**Clarity**:
- Lead with most common commands
- Show workflow before edge cases
- Examples demonstrate real usage

**Organization**:
- Group related information
- Progress from simple to complex
- Keep technical details separate

**Maintenance**:
- Update examples when behavior changes
- Document new commands immediately
- Remove deprecated features

**Cross-Protocol Consistency**:
- Similar commands use similar syntax
- Shared concepts use same terminology
- Error patterns remain predictable

Target: Complete enough for automation, clear enough for humans.