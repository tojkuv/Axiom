# @CHECKPOINT.md

**Trigger**: `@CHECKPOINT [workspace]`

## Commands

- `status` → Show pending changes in all workspaces
- `framework` → Commit and integrate framework workspace only
- `application` → Commit and integrate application workspace only
- `(no args)` → Commit and integrate all workspaces

## Core Process

Sync branches → Commit worktrees → Merge to main → Push to remote

**Philosophy**: Automated integration with conflict prevention.
**Strategy**: Sync feature branches with main before merging.

## Workflow

### Standard Integration
1. Sync each worktree branch with main
2. Check for changes in each worktree
3. Commit changes with timestamp
4. Switch to main branch
5. Merge framework branch (no-ff, strategy=ours)
6. Merge application branch (no-ff, strategy=ours)  
7. Push integrated changes to remote

### Selective Integration
- **Framework only**: Steps 1-4, merge framework, push
- **Application only**: Steps 1-4, merge application, push
- **Fallback**: If no worktrees, commit directly on current branch

## Technical Details

**Commit Message Format**:
```
Framework development checkpoint: YYYY-MM-DD HH:MM

Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Merge Strategy**:
- Sync feature branches with main before committing (prevents conflicts)
- Use `--no-ff` to preserve branch history
- Apply `--strategy=recursive -X theirs` to auto-resolve in favor of feature branch
- Each branch merged separately for clarity

**Safety Features**:
- Pre-merge sync prevents most conflicts
- Auto-resolution favors feature branch changes
- Only commits when changes exist
- Validates worktree presence
- Preserves branch context in commits

## Execution Process

```bash
# Sync framework branch with main first (prevents conflicts)
if [ -d "framework-workspace" ]; then
    cd framework-workspace
    git fetch origin main
    git merge origin/main -m "Sync with main: $(date '+%Y-%m-%d %H:%M')" || {
        echo "Conflict during sync - resolving in favor of framework changes"
        git checkout --theirs .
        git add .
        git commit -m "Sync with main: $(date '+%Y-%m-%d %H:%M') - framework changes preserved"
    }
    cd ..
fi

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

# Merge branches with history (using recursive strategy with theirs option)
git merge framework --no-ff --strategy=recursive -X theirs -m "Integrate framework development: $(date '+%Y-%m-%d %H:%M')

Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Push to remote
git push origin main || echo "Local integration complete - remote push failed"
```

## Error Handling

**Common Issues**:
- "Conflict during sync" → Auto-resolved in favor of framework changes
- "Remote push failed" → Check credentials/connection
- "No changes to commit" → Normal, nothing to do

**Recovery Steps**:
1. Sync conflicts: Automatically resolved using `--theirs` strategy
2. Failed push: Fix connection, then `git push origin main`
3. Broken state: `git checkout main && git reset --hard origin/main`
4. Manual override: Use `git merge --abort` then resolve manually if needed

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

## Conflict Prevention

The checkpoint process prevents merge conflicts through:

1. **Pre-sync**: Framework branch pulls latest main changes before committing
2. **Auto-resolution**: When conflicts occur during sync, framework changes are preserved
3. **Merge strategy**: Final merge uses `-X theirs` to favor framework branch changes
4. **Clean history**: Each integration maintains clear commit history

This ensures framework development can proceed independently without manual conflict resolution.