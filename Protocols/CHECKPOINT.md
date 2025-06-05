# @CHECKPOINT.md

**Trigger**: `@CHECKPOINT [command]`

## Commands

- `status` → Show pending changes in all workspaces
- `framework` → Commit and integrate framework workspace only
- `application` → Commit and integrate application workspace only
- `protocols` → Commit and integrate protocols workspace only
- `all` → Commit and integrate all workspaces

## Core Process

Sync branches → Commit worktrees → Integration branch → Single commit to main → Push to remote

**Philosophy**: Single clean commit to main with protocol file preservation and proper conflict resolution.
**Constraint**: Uses external script to maintain simplicity within protocol.

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
- **Framework workspace**: Only sees `AxiomFramework/` (with symlink to `Protocols/FrameworkProtocols`)
- **Application workspace**: Only sees `AxiomExampleApp/` (with symlink to `Protocols/ApplicationProtocols`)
- **Protocols workspace**: Only sees `Protocols/` directory (all protocol management)
- **Sparse-checkout**: Prevents cross-boundary file access
- **Protocol Protection**: Protocol files preserved during integration

## Technical Details

**Script Location**: `Protocols/checkpoint.sh`

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
# Execute checkpoint script with command
PROTOCOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$PROTOCOL_DIR/checkpoint.sh" "$1"
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
@CHECKPOINT all
# Syncs all three workspaces
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
# Leaves application and protocols untouched
# Single commit approach
```

**Protocols Only**:
```
@CHECKPOINT protocols
# Commits protocol changes only
# Integrates protocols workspace
# Leaves framework and application untouched
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
- Framework workspace: `/AxiomFramework/` (symlink to `../Axiom/Protocols/FrameworkProtocols/`)
- Application workspace: `/AxiomExampleApp/` (symlink to `../Axiom/Protocols/ApplicationProtocols/`)
- Protocols workspace: `/Protocols/` (entire protocols directory)
- Protocol files at root: Protected during integration

**Protocol File Protection**:
1. **Backup Strategy**: Entire Protocols/ directory copied to /tmp before integration
2. **Automatic Restoration**: Protocols directory restored if affected by merge
3. **Conflict Cleanup**: Merge artifacts (Protocols~branch) removed automatically
4. **Root Preservation**: Protocols directory maintained at repository root

**Benefits**:
1. **Single Commit**: Clean remote history with one commit per checkpoint
2. **Protocol Safety**: Protocol files never lost during integration
3. **Proper Dating**: Timestamp variable correctly evaluated in commit messages
4. **Conflict Isolation**: Integration branch prevents main branch corruption
5. **Atomic Operations**: All changes integrated as single unit

Integrates isolated worktree development with protocol file preservation and single commit strategy.