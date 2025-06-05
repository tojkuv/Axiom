#!/bin/bash

# Workspace Management Script
# Used by @WORKSPACE protocol for worktree management

# Determine correct Axiom directory
AXIOM_DIR="/Users/tojkuv/Documents/GitHub/axiom-apple/Axiom"

# Validate Axiom directory exists
if [[ ! -d "$AXIOM_DIR" ]]; then
    echo "ERROR: Axiom directory not found at $AXIOM_DIR"
    echo "Cannot perform workspace operations"
    exit 1
fi

# Change to Axiom directory for all operations
cd "$AXIOM_DIR" || exit 1

# Verify we're in the correct git repository
if [[ ! -d .git ]]; then
    echo "ERROR: Not in a git repository"
    echo "Expected to be in Axiom git root"
    exit 1
fi

# Parse arguments
COMMAND="$1"
WORKSPACE_TYPE="$2"

# Show usage if no command provided
if [[ -z "$COMMAND" ]]; then
    echo "Usage: @WORKSPACE <command> [workspace]"
    echo ""
    echo "Commands:"
    echo "  setup <workspace|all>    Create workspace worktree(s)"
    echo "  reset <workspace|all>    Recreate worktree(s) with clean state"
    echo "  status <workspace|all>   Show worktree details and health"
    echo "  cleanup <workspace|all>  Remove workspace worktree(s)"
    echo ""
    echo "Workspaces:"
    echo "  framework    AxiomFramework development"
    echo "  application  AxiomExampleApp development"
    echo "  protocols    Protocols management"
    echo "  all          All workspaces"
    exit 1
fi

# Validate command
if [[ ! "$COMMAND" =~ ^(setup|reset|status|cleanup)$ ]]; then
    echo "Error: Unknown command '$COMMAND'"
    echo "Valid commands: setup, reset, status, cleanup"
    exit 1
fi

# If workspace not specified, show error
if [[ -z "$WORKSPACE_TYPE" ]]; then
    echo "Error: Workspace type required"
    echo "Usage: @WORKSPACE $COMMAND <workspace|all>"
    exit 1
fi

# Function to setup a single workspace
setup_workspace() {
    local workspace="$1"
    local workspace_dir
    local branch_name
    local sparse_path
    local protocol_source
    local protocol_link
    
    case "$workspace" in
        framework)
            workspace_dir="../framework-workspace"
            branch_name="framework"
            sparse_path="AxiomFramework"
            protocol_source="../Axiom/Protocols/FrameworkProtocols"
            protocol_link="FrameworkProtocols"
            ;;
        application)
            workspace_dir="../application-workspace"
            branch_name="application"
            sparse_path="AxiomExampleApp"
            protocol_source="../Axiom/Protocols/ApplicationProtocols"
            protocol_link="ApplicationProtocols"
            ;;
        protocols)
            workspace_dir="../protocols-workspace"
            branch_name="protocols"
            sparse_path="Protocols"
            protocol_source=""
            protocol_link=""
            ;;
        *)
            echo "Error: Unknown workspace type '$workspace'"
            return 1
            ;;
    esac
    
    echo "Setting up $workspace workspace..."
    
    # Create worktree at parent level
    if ! git worktree list | grep -q "$workspace_dir"; then
        # Ensure branch exists
        if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
            git checkout -b "$branch_name"
            git push -u origin "$branch_name" || true
            git checkout main
        fi
        git worktree add "$workspace_dir" "$branch_name"
    fi
    
    # Configure precise sparse-checkout
    cd "$workspace_dir"
    git sparse-checkout init --cone
    git sparse-checkout set "$sparse_path"
    
    # Clean workspace by reapplying sparse-checkout
    git read-tree -m -u HEAD
    
    # Create protocol symlink (not for protocols workspace)
    if [[ -n "$protocol_link" ]]; then
        ln -sf "$protocol_source" "$protocol_link"
    fi
    
    # Initialize status
    echo "Created: $(date)" > .workspace-status
    echo "Branch: $branch_name" >> .workspace-status
    echo "Type: $workspace" >> .workspace-status
    
    cd "$AXIOM_DIR"
    echo "$workspace workspace ready at $workspace_dir"
}

# Function to get workspace status
get_workspace_status() {
    local workspace="$1"
    local workspace_dir
    
    case "$workspace" in
        framework) workspace_dir="../framework-workspace" ;;
        application) workspace_dir="../application-workspace" ;;
        protocols) workspace_dir="../protocols-workspace" ;;
        *) return 1 ;;
    esac
    
    echo ""
    echo "=== $workspace workspace ==="
    if [[ -d "$workspace_dir" ]]; then
        echo "Status: active"
        echo "Branch: $(cd "$workspace_dir" && git branch --show-current)"
        echo "Contents:"
        (cd "$workspace_dir" && ls -la | grep -E "^d|^l" | grep -v "^\.")
        if [[ -f "$workspace_dir/.workspace-status" ]]; then
            echo "---"
            cat "$workspace_dir/.workspace-status"
        fi
    else
        echo "Status: not found"
    fi
}

# Function to cleanup a workspace
cleanup_workspace() {
    local workspace="$1"
    local workspace_dir
    
    case "$workspace" in
        framework) workspace_dir="../framework-workspace" ;;
        application) workspace_dir="../application-workspace" ;;
        protocols) workspace_dir="../protocols-workspace" ;;
        *) return 1 ;;
    esac
    
    echo "Removing $workspace workspace..."
    git worktree remove "$workspace_dir" --force 2>/dev/null || true
    echo "$workspace workspace removed"
}

# Function to reset a workspace
reset_workspace() {
    local workspace="$1"
    cleanup_workspace "$workspace"
    setup_workspace "$workspace"
}

# Handle "all" workspace operations
if [[ "$WORKSPACE_TYPE" == "all" ]]; then
    case "$COMMAND" in
        setup)
            setup_workspace "framework"
            setup_workspace "application"
            setup_workspace "protocols"
            ;;
        reset)
            reset_workspace "framework"
            reset_workspace "application"
            reset_workspace "protocols"
            ;;
        status)
            get_workspace_status "framework"
            get_workspace_status "application"
            get_workspace_status "protocols"
            ;;
        cleanup)
            cleanup_workspace "framework"
            cleanup_workspace "application"
            cleanup_workspace "protocols"
            ;;
    esac
else
    # Validate workspace type
    if [[ ! "$WORKSPACE_TYPE" =~ ^(framework|application|protocols)$ ]]; then
        echo "Error: Unknown workspace type '$WORKSPACE_TYPE'"
        echo "Valid workspaces: framework, application, protocols, all"
        exit 1
    fi
    
    # Execute command for single workspace
    case "$COMMAND" in
        setup) setup_workspace "$WORKSPACE_TYPE" ;;
        reset) reset_workspace "$WORKSPACE_TYPE" ;;
        status) get_workspace_status "$WORKSPACE_TYPE" ;;
        cleanup) cleanup_workspace "$WORKSPACE_TYPE" ;;
    esac
fi