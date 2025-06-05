#!/bin/bash
# Determine correct Axiom directory
AXIOM_DIR="/Users/tojkuv/Documents/GitHub/axiom-apple/Axiom"

# Validate Axiom directory exists
if [[ ! -d "$AXIOM_DIR" ]]; then
    echo "ERROR: Axiom directory not found at $AXIOM_DIR"
    echo "Cannot perform checkpoint operations"
    exit 1
fi

# Change to Axiom directory for all operations
cd "$AXIOM_DIR" || exit 1

# Verify we are in the correct git repository
if [[ ! -d .git ]]; then
    echo "ERROR: Not in a git repository"
    echo "Expected to be in Axiom git root"
    exit 1
fi

# Safety check: Verify expected directory structure
if [[ ! -d "AxiomFramework" ]] || [[ ! -d "AxiomExampleApp" ]] || [[ ! -d "Protocols" ]]; then
    echo "ERROR: Expected Axiom directory structure not found"
    echo "Missing AxiomFramework, AxiomExampleApp, or Protocols directories"
    exit 1
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
BRANCH_TIMESTAMP=$(date '+%Y-%m-%d_%H-%M')

# Process all workspaces
INTEGRATE_FRAMEWORK="true"
INTEGRATE_APPLICATION="true"
INTEGRATE_PROTOCOLS="true"

echo "=== Starting CHECKPOINT for all workspaces ==="
echo "Timestamp: $TIMESTAMP"

# 1. Sync and commit framework workspace
if [[ "$INTEGRATE_FRAMEWORK" == "true" ]] && [ -d "../framework-workspace" ]; then
    echo -e "\n--- Processing framework workspace ---"
    cd ../framework-workspace
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
    else
        echo "No changes to commit in framework workspace"
    fi
    cd ../Axiom
fi

# 2. Sync and commit application workspace
if [[ "$INTEGRATE_APPLICATION" == "true" ]] && [ -d "../application-workspace" ]; then
    echo -e "\n--- Processing application workspace ---"
    cd ../application-workspace
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
    else
        echo "No changes to commit in application workspace"
    fi
    cd ../Axiom
fi

# 3. Sync and commit protocols workspace
if [[ "$INTEGRATE_PROTOCOLS" == "true" ]] && [ -d "../protocols-workspace" ]; then
    echo -e "\n--- Processing protocols workspace ---"
    cd ../protocols-workspace
    git fetch origin main
    git merge origin/main -m "Sync with main: $TIMESTAMP" || {
        echo "Auto-resolving conflicts in favor of protocols"
        git checkout --theirs .
        git add --sparse .
        git commit -m "Sync with main: $TIMESTAMP - protocols preserved"
    }
    
    if [ -n "$(git status --porcelain)" ]; then
        git add --sparse .
        git commit -m "Protocols development checkpoint: $TIMESTAMP

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    else
        echo "No changes to commit in protocols workspace"
    fi
    cd ../Axiom
fi

echo -e "\n--- Creating integration branch ---"
# 4. Create integration branch and merge workspaces
git checkout main
git pull origin main || true

# Preserve protocol files before integration
cp -r Protocols /tmp/protocols-backup 2>/dev/null || true

# Create integration branch
git checkout -b "integration-$BRANCH_TIMESTAMP" main

# Merge workspaces into integration branch
if [[ "$INTEGRATE_FRAMEWORK" == "true" ]] && [ -d "../framework-workspace" ]; then
    echo "Merging framework workspace..."
    git merge framework --no-ff --strategy=recursive -X ours \
        -m "Integrate framework workspace: $TIMESTAMP" || {
        echo "Resolving framework conflicts"
        git add .
        git commit -m "Integrate framework workspace: $TIMESTAMP"
    }
fi

if [[ "$INTEGRATE_APPLICATION" == "true" ]] && [ -d "../application-workspace" ]; then
    echo "Merging application workspace..."
    git merge application --no-ff --strategy=recursive -X ours \
        -m "Integrate application workspace: $TIMESTAMP" || {
        echo "Resolving application conflicts"
        git add .
        git commit -m "Integrate application workspace: $TIMESTAMP"
    }
fi

if [[ "$INTEGRATE_PROTOCOLS" == "true" ]] && [ -d "../protocols-workspace" ]; then
    echo "Merging protocols workspace..."
    git merge protocols --no-ff --strategy=recursive -X ours \
        -m "Integrate protocols workspace: $TIMESTAMP" || {
        echo "Resolving protocols conflicts"
        git add .
        git commit -m "Integrate protocols workspace: $TIMESTAMP"
    }
fi

# Restore protocol files if they were affected
if [ -d "/tmp/protocols-backup" ]; then
    rm -rf Protocols
    cp -r /tmp/protocols-backup Protocols
    rm -rf /tmp/protocols-backup
fi

# Clean up any merge artifacts
rm -rf Protocols~* 2>/dev/null || true

# Commit protocol restoration if needed
if [ -n "$(git status --porcelain)" ]; then
    git add .
    git commit -m "Preserve protocol files during integration"
fi

echo -e "\n--- Squash merging to main ---"
# 4. Squash merge to main and push
git checkout main
git merge --squash "integration-$BRANCH_TIMESTAMP"

# Determine commit message based on what was integrated
INTEGRATED_PARTS=()
[[ "$INTEGRATE_FRAMEWORK" == "true" ]] && INTEGRATED_PARTS+=("framework")
[[ "$INTEGRATE_APPLICATION" == "true" ]] && INTEGRATED_PARTS+=("application")
[[ "$INTEGRATE_PROTOCOLS" == "true" ]] && INTEGRATED_PARTS+=("protocols")

if [[ ${#INTEGRATED_PARTS[@]} -eq 3 ]]; then
    INTEGRATION_MSG="Integrated framework, application, and protocols workspace changes"
elif [[ ${#INTEGRATED_PARTS[@]} -eq 2 ]]; then
    INTEGRATION_MSG="Integrated ${INTEGRATED_PARTS[0]} and ${INTEGRATED_PARTS[1]} workspace changes"
elif [[ ${#INTEGRATED_PARTS[@]} -eq 1 ]]; then
    INTEGRATION_MSG="Integrated ${INTEGRATED_PARTS[0]} workspace changes"
fi

# Check if there are changes to commit
if [ -n "$(git status --porcelain)" ]; then
    git commit -m "Development checkpoint: $TIMESTAMP

$INTEGRATION_MSG

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
    
    # Clean up integration branch
    git branch -D "integration-$BRANCH_TIMESTAMP"
    
    # Push single commit to remote
    echo -e "\n--- Pushing to remote ---"
    git push origin main || echo "Local integration complete - remote push failed"
else
    echo "No changes to integrate"
    # Clean up integration branch
    git branch -D "integration-$BRANCH_TIMESTAMP"
fi

echo -e "\n=== CHECKPOINT complete ==="