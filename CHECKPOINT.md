# @CHECKPOINT.md

**Trigger**: `@CHECKPOINT [workspace]`

## Commands

- `status` → Show pending changes in all workspaces
- `framework` → Commit and integrate framework workspace only
- `application` → Commit and integrate application workspace only
- `(no args)` → Commit and integrate all workspaces

## Core Process

Sync branches → Commit worktrees → Merge to main → Push to remote

**Philosophy**: Automated integration with conflict prevention through sync-first approach.
**Constraint**: Located at repository root to prevent workspace duplication.

## Workflow

### Standard Integration
1. Sync worktree branch with main (auto-resolve conflicts)
2. Commit changes in worktree with timestamp
3. Switch to main branch
4. Merge framework branch with `--no-ff --strategy=recursive -X theirs`
5. Merge application branch with same strategy
6. Push integrated changes to remote

### Workspace Isolation
- **Framework workspace**: Only sees `FrameworkProtocols/` and `AxiomFramework/`
- **Application workspace**: Only sees `ApplicationProtocols/` and `AxiomExampleApp/`
- **Sparse-checkout**: Prevents cross-boundary file access

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
# 1. Sync and commit framework workspace
if [ -d "framework-workspace" ]; then
    cd framework-workspace
    git fetch origin main
    git merge origin/main -m "Sync with main: $(date '+%Y-%m-%d %H:%M')" || {
        echo "Auto-resolving conflicts in favor of framework"
        git checkout --theirs .
        git add .
        git commit -m "Sync with main: $(date '+%Y-%m-%d %H:%M') - framework preserved"
    }
    
    if [ -n "$(git status --porcelain)" ]; then
        git add .
        git commit -m "Framework development checkpoint: $(date '+%Y-%m-%d %H:%M')

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    fi
    cd ..
fi

# 2. Sync and commit application workspace
if [ -d "application-workspace" ]; then
    cd application-workspace
    git fetch origin main
    git merge origin/main -m "Sync with main: $(date '+%Y-%m-%d %H:%M')" || {
        echo "Auto-resolving conflicts in favor of application"
        git checkout --theirs .
        git add .
        git commit -m "Sync with main: $(date '+%Y-%m-%d %H:%M') - application preserved"
    }
    
    if [ -n "$(git status --porcelain)" ]; then
        git add .
        git commit -m "Application development checkpoint: $(date '+%Y-%m-%d %H:%M')

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    fi
    cd ..
fi

# 3. Integrate to main
git checkout main
git pull origin main || true

# Merge with auto-conflict resolution
git merge framework --no-ff --strategy=recursive -X theirs \
    -m "Integrate framework development: $(date '+%Y-%m-%d %H:%M')

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

git merge application --no-ff --strategy=recursive -X theirs \
    -m "Integrate application development: $(date '+%Y-%m-%d %H:%M')

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com)"

# 4. Push to remote
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

## Workspace Configuration

**Sparse-Checkout Setup**:
- Framework workspace: `/FrameworkProtocols/`, `/AxiomFramework/`, `/.gitignore`
- Application workspace: `/ApplicationProtocols/`, `/AxiomExampleApp/`, `/.gitignore`
- Protocol files at root: Prevents duplication and conflicts

**Benefits**:
1. **Isolation**: Each workspace only sees relevant files
2. **No Conflicts**: Protocol files exist only at repository root
3. **Clean Boundaries**: Cannot accidentally edit cross-workspace files
4. **Focused Development**: Reduced complexity and faster operations

Integrates isolated worktree development with automatic conflict resolution and clean history.