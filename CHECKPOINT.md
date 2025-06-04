# @CHECKPOINT.md

**Trigger**: `@CHECKPOINT [workspace]`

## Commands

- `status` → Show pending changes in all workspaces
- `framework` → Commit and integrate framework workspace only
- `application` → Commit and integrate application workspace only
- `(no args)` → Commit and integrate all workspaces

## Core Process

Sync branches → Commit worktrees → Integration branch → Single commit to main → Push to remote

**Philosophy**: Single clean commit to main with protocol file preservation and proper conflict resolution.
**Constraint**: Located at repository root to prevent workspace duplication.

## Workflow

### Standard Integration
1. Sync worktree branches with main (auto-resolve conflicts)
2. Commit changes in worktrees with timestamp
3. Create temporary integration branch from main
4. Merge workspace branches into integration branch
5. Preserve protocol files explicitly
6. Squash merge integration branch to main as single commit
7. Push single commit to remote

### Workspace Isolation
- **Framework workspace**: Only sees `AxiomFramework/` (with symlink to `../FrameworkProtocols/`)
- **Application workspace**: Only sees `AxiomExampleApp/` (with symlink to `../ApplicationProtocols/`)
- **Sparse-checkout**: Prevents cross-boundary file access
- **Protocol Protection**: Root protocol files preserved during integration

## Technical Details

**Commit Message Format**:
```
Development checkpoint: YYYY-MM-DD HH:MM

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Integration Strategy**:
- Single commit to main remote (no intermediate commits)
- Protocol files preserved at repository root
- Workspace changes integrated through temporary branch
- Proper date evaluation in commit messages
- Clean history with descriptive commit message

**Safety Features**:
- Pre-merge sync prevents most conflicts
- Protocol file protection prevents deletion
- Integration branch isolates merge conflicts
- Only commits when changes exist
- Single push reduces remote history noise

## Execution Process

```bash
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

# 1. Sync and commit framework workspace
if [ -d "framework-workspace" ]; then
    cd framework-workspace
    git fetch origin main
    git merge origin/main -m "Sync with main: $TIMESTAMP" || {
        echo "Auto-resolving conflicts in favor of framework"
        git checkout --theirs .
        git add --sparse .
        git commit -m "Sync with main: $TIMESTAMP - framework preserved"
    }
    
    if [ -n "$(git status --porcelain)" ]; then
        git add --sparse .
        git commit -m "Framework development checkpoint: $TIMESTAMP

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    fi
    cd ..
fi

# 2. Sync and commit application workspace
if [ -d "application-workspace" ]; then
    cd application-workspace
    git fetch origin main
    git merge origin/main -m "Sync with main: $TIMESTAMP" || {
        echo "Auto-resolving conflicts in favor of application"
        git checkout --theirs .
        git add --sparse .
        git commit -m "Sync with main: $TIMESTAMP - application preserved"
    }
    
    if [ -n "$(git status --porcelain)" ]; then
        git add --sparse .
        git commit -m "Application development checkpoint: $TIMESTAMP

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    fi
    cd ..
fi

# 3. Create integration branch and merge workspaces
git checkout main
git pull origin main || true

# Preserve protocol files before integration
cp -r FrameworkProtocols /tmp/framework-protocols-backup 2>/dev/null || true
cp -r ApplicationProtocols /tmp/application-protocols-backup 2>/dev/null || true

# Create integration branch
git checkout -b "integration-$TIMESTAMP" main

# Merge workspaces into integration branch
if [ -d "framework-workspace" ]; then
    git merge framework --no-ff --strategy=recursive -X ours \
        -m "Integrate framework workspace: $TIMESTAMP" || {
        echo "Resolving framework conflicts"
        git add .
        git commit -m "Integrate framework workspace: $TIMESTAMP"
    }
fi

if [ -d "application-workspace" ]; then
    git merge application --no-ff --strategy=recursive -X ours \
        -m "Integrate application workspace: $TIMESTAMP" || {
        echo "Resolving application conflicts"
        git add .
        git commit -m "Integrate application workspace: $TIMESTAMP"
    }
fi

# Restore protocol files if they were affected
if [ -d "/tmp/framework-protocols-backup" ]; then
    rm -rf FrameworkProtocols
    cp -r /tmp/framework-protocols-backup FrameworkProtocols
    rm -rf /tmp/framework-protocols-backup
fi

if [ -d "/tmp/application-protocols-backup" ]; then
    rm -rf ApplicationProtocols  
    cp -r /tmp/application-protocols-backup ApplicationProtocols
    rm -rf /tmp/application-protocols-backup
fi

# Clean up any merge artifacts
rm -rf FrameworkProtocols~* ApplicationProtocols~* 2>/dev/null || true

# Commit protocol restoration if needed
if [ -n "$(git status --porcelain)" ]; then
    git add .
    git commit -m "Preserve protocol files during integration"
fi

# 4. Squash merge to main and push
git checkout main
git merge --squash "integration-$TIMESTAMP"
git commit -m "Development checkpoint: $TIMESTAMP

Integrated framework and application workspace changes

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"

# Clean up integration branch
git branch -D "integration-$TIMESTAMP"

# Push single commit to remote
git push origin main || echo "Local integration complete - remote push failed"
```

## Error Handling

**Common Issues**:
- "Conflict during sync" → Auto-resolved using workspace-specific strategy
- "Protocol files deleted" → Automatically restored from backup
- "Remote push failed" → Check credentials/connection
- "Integration branch exists" → Cleaned up automatically
- "No changes to commit" → Normal, nothing to do

**Recovery Steps**:
1. Sync conflicts: Automatically resolved using appropriate strategy per workspace
2. Failed push: Fix connection, then `git push origin main`
3. Broken state: `git checkout main && git reset --hard origin/main`
4. Manual override: Clean up integration branch manually if needed
5. Protocol file loss: Restored from /tmp backup automatically

**Safety Mechanisms**:
- Protocol files backed up before integration
- Merge artifacts cleaned automatically  
- Integration branch isolated from main
- Single atomic commit to remote
- Workspace-specific conflict resolution

## Examples

**Full Integration**:
```
@CHECKPOINT
# Syncs both workspaces
# Creates integration branch
# Preserves protocol files
# Single commit to main
# Pushes to remote
```

**Framework Only**:
```
@CHECKPOINT framework
# Commits framework changes only
# Integrates framework workspace
# Leaves application untouched
# Single commit approach
```

**Check Status First**:
```
@CHECKPOINT status
# Shows pending changes in all workspaces
# No commits made
# Helps plan integration timing
```

## Workspace Configuration

**Sparse-Checkout Setup**:
- Framework workspace: `/AxiomFramework/`, `/.gitignore` (symlink to `../FrameworkProtocols/`)
- Application workspace: `/AxiomExampleApp/`, `/.gitignore` (symlink to `../ApplicationProtocols/`)
- Protocol files at root only: Protected during integration

**Protocol File Protection**:
1. **Backup Strategy**: Files copied to /tmp before integration
2. **Automatic Restoration**: Protocol files restored if affected by merge
3. **Conflict Cleanup**: Merge artifacts (Protocol~branch) removed automatically
4. **Root Preservation**: Protocol files maintained at repository root

**Benefits**:
1. **Single Commit**: Clean remote history with one commit per checkpoint
2. **Protocol Safety**: Protocol files never lost during integration
3. **Proper Dating**: Timestamp variable correctly evaluated in commit messages
4. **Conflict Isolation**: Integration branch prevents main branch corruption
5. **Atomic Operations**: All changes integrated as single unit

Integrates isolated worktree development with protocol file preservation and single commit strategy.