# @CHECKPOINT.md

**Trigger**: `@CHECKPOINT [workspace]`

## Commands

- `status` → Show pending changes in all workspaces
- `framework` → Commit and integrate framework workspace only
- `application` → Commit and integrate application workspace only
- `(no args)` → Commit and integrate all workspaces

## Core Process

Commit worktrees → Merge to main → Push to remote

**Philosophy**: Automated integration with clear commit history.
**Constraint**: Merge conflicts require manual resolution.

## Workflow

### Standard Integration
1. Check for changes in each worktree
2. Commit changes with timestamp
3. Switch to main branch
4. Merge framework branch (no-ff)
5. Merge application branch (no-ff)  
6. Push integrated changes to remote

### Selective Integration
- **Framework only**: Steps 1-3, merge framework, push
- **Application only**: Steps 1-3, merge application, push
- **Fallback**: If no worktrees, commit directly on current branch

## Technical Details

**Commit Message Format**:
```
Framework development checkpoint: YYYY-MM-DD HH:MM

Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Merge Strategy**:
- Always use `--no-ff` to preserve branch history
- Stop on conflicts for manual resolution
- Each branch merged separately for clarity

**Safety Features**:
- Only commits when changes exist
- Validates worktree presence
- Handles remote push failures gracefully
- Preserves branch context in commits

## Execution Process

```bash
# Check and commit framework changes
if [ -d "framework-workspace" ] && [ -n "$(cd framework-workspace && git status --porcelain)" ]; then
    cd framework-workspace
    git add .
    git commit -m "Framework development checkpoint: $(date '+%Y-%m-%d %H:%M')

Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    cd ..
fi

# Merge to main
git checkout main
git pull origin main || true

# Merge branches with history
git merge framework --no-ff -m "Integrate framework development: $(date '+%Y-%m-%d %H:%M')

Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>" || {
    echo "Merge conflict - manual resolution required"
    exit 1
}

# Push to remote
git push origin main || echo "Local integration complete - remote push failed"
```

## Error Handling

**Common Issues**:
- "Merge conflict" → Resolve manually, then continue
- "Remote push failed" → Check credentials/connection
- "No changes to commit" → Normal, nothing to do

**Recovery Steps**:
1. Conflicts: `git status` to see conflicts, resolve, then `git commit`
2. Failed push: Fix connection, then `git push origin main`
3. Broken state: `git checkout main && git reset --hard origin/main`

## Examples

**Full Integration**:
```
@CHECKPOINT
# Commits both worktrees
# Merges to main
# Pushes to remote
```

**Framework Only**:
```
@CHECKPOINT framework
# Commits framework changes
# Merges framework branch only
# Leaves application untouched
```

**Check Status First**:
```
@CHECKPOINT status
# Shows pending changes
# No commits made
# Helps plan integration
```

Integrates worktree development into main branch with automated commits and merges.