#!/bin/bash
# Experiment Management Script for samhub project
# Keeps sam_api and sam_ui submodules synchronized across experiment branches

set -e

PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAM_API_DIR="$PARENT_DIR/sam_api"
SAM_UI_DIR="$PARENT_DIR/sam_ui"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if we're in a clean state
check_clean_state() {
    local dir=$1
    local name=$2

    cd "$dir"
    if [[ -n $(git status --porcelain) ]]; then
        log_error "$name has uncommitted changes. Please commit or stash them first."
        exit 1
    fi
}

# Create a new experiment
create_experiment() {
    local experiment_name=$1

    if [[ -z "$experiment_name" ]]; then
        log_error "Please provide an experiment name"
        echo "Usage: $0 create <experiment-name>"
        exit 1
    fi

    log_info "Creating experiment: $experiment_name"

    # Check clean state in all repos
    check_clean_state "$PARENT_DIR" "Parent repo"
    check_clean_state "$SAM_API_DIR" "sam_api"
    check_clean_state "$SAM_UI_DIR" "sam_ui"

    # Create branch in sam_api
    log_info "Creating branch in sam_api..."
    cd "$SAM_API_DIR"
    git checkout -b "experiment/$experiment_name"
    git push -u origin "experiment/$experiment_name"
    log_success "sam_api branch created"

    # Create branch in sam_ui
    log_info "Creating branch in sam_ui..."
    cd "$SAM_UI_DIR"
    git checkout -b "experiment/$experiment_name"
    git push -u origin "experiment/$experiment_name"
    log_success "sam_ui branch created"

    # Create branch in parent repo and update submodules
    log_info "Creating branch in parent repo..."
    cd "$PARENT_DIR"
    git checkout -b "experiment/$experiment_name"
    git add sam_api sam_ui
    git commit -m "experiment: Initialize $experiment_name with synchronized submodules"
    git push -u origin "experiment/$experiment_name"
    log_success "Parent branch created"

    log_success "Experiment '$experiment_name' created successfully!"
    log_info "All repos are now on experiment/$experiment_name branch"
}

# Switch to an existing experiment
switch_experiment() {
    local experiment_name=$1

    if [[ -z "$experiment_name" ]]; then
        log_error "Please provide an experiment name"
        echo "Usage: $0 switch <experiment-name>"
        exit 1
    fi

    log_info "Switching to experiment: $experiment_name"

    # Check clean state in all repos
    check_clean_state "$PARENT_DIR" "Parent repo"
    check_clean_state "$SAM_API_DIR" "sam_api"
    check_clean_state "$SAM_UI_DIR" "sam_ui"

    # Switch parent repo
    cd "$PARENT_DIR"
    if ! git rev-parse --verify "experiment/$experiment_name" >/dev/null 2>&1; then
        log_error "Experiment branch 'experiment/$experiment_name' does not exist in parent repo"
        exit 1
    fi
    git checkout "experiment/$experiment_name"

    # Update submodules to match parent repo state
    log_info "Updating submodules..."
    git submodule update --init --recursive

    # Switch sam_api to experiment branch
    cd "$SAM_API_DIR"
    git checkout "experiment/$experiment_name"
    git pull

    # Switch sam_ui to experiment branch
    cd "$SAM_UI_DIR"
    git checkout "experiment/$experiment_name"
    git pull

    log_success "Switched to experiment '$experiment_name'"
}

# Switch back to main
switch_main() {
    log_info "Switching back to main branch..."

    # Check clean state in all repos
    check_clean_state "$PARENT_DIR" "Parent repo"
    check_clean_state "$SAM_API_DIR" "sam_api"
    check_clean_state "$SAM_UI_DIR" "sam_ui"

    # Switch all repos to main
    cd "$SAM_API_DIR"
    git checkout main
    git pull

    cd "$SAM_UI_DIR"
    git checkout main
    git pull

    cd "$PARENT_DIR"
    git checkout main
    git pull
    git submodule update --init --recursive

    log_success "Switched to main branch"
}

# Sync current experiment (commit and push changes in all repos)
sync_experiment() {
    local message=$1

    if [[ -z "$message" ]]; then
        log_error "Please provide a commit message"
        echo "Usage: $0 sync \"commit message\""
        exit 1
    fi

    log_info "Syncing experiment changes..."

    # Get current branch name
    cd "$PARENT_DIR"
    local current_branch=$(git rev-parse --abbrev-ref HEAD)

    if [[ ! $current_branch =~ ^experiment/ ]]; then
        log_error "Not on an experiment branch. Current branch: $current_branch"
        exit 1
    fi

    # Commit and push sam_api if there are changes
    cd "$SAM_API_DIR"
    if [[ -n $(git status --porcelain) ]]; then
        log_info "Committing changes in sam_api..."
        git add -A
        git commit -m "$message"
        git push
        log_success "sam_api changes committed and pushed"
    else
        log_info "No changes in sam_api"
    fi

    # Commit and push sam_ui if there are changes
    cd "$SAM_UI_DIR"
    if [[ -n $(git status --porcelain) ]]; then
        log_info "Committing changes in sam_ui..."
        git add -A
        git commit -m "$message"
        git push
        log_success "sam_ui changes committed and pushed"
    else
        log_info "No changes in sam_ui"
    fi

    # Update parent repo with new submodule commits
    cd "$PARENT_DIR"
    if [[ -n $(git status --porcelain) ]]; then
        log_info "Updating parent repo with submodule changes..."
        git add sam_api sam_ui
        git commit -m "$message"
        git push
        log_success "Parent repo updated"
    else
        log_info "No submodule changes to commit"
    fi

    log_success "Experiment synced successfully!"
}

# List all experiments
list_experiments() {
    log_info "Available experiments:"
    cd "$PARENT_DIR"
    git branch -a | grep "experiment/" | sed 's/remotes\/origin\///' | sort -u | while read branch; do
        if [[ $(git rev-parse --abbrev-ref HEAD) == "$branch" ]]; then
            echo -e "  ${GREEN}* $branch${NC} (current)"
        else
            echo -e "    $branch"
        fi
    done
}

# Show status of all repos
status() {
    echo -e "\n${BLUE}=== Parent Repo ===${NC}"
    cd "$PARENT_DIR"
    git status -sb

    echo -e "\n${BLUE}=== sam_api ===${NC}"
    cd "$SAM_API_DIR"
    git status -sb

    echo -e "\n${BLUE}=== sam_ui ===${NC}"
    cd "$SAM_UI_DIR"
    git status -sb
}

# Delete an experiment
delete_experiment() {
    local experiment_name=$1

    if [[ -z "$experiment_name" ]]; then
        log_error "Please provide an experiment name"
        echo "Usage: $0 delete <experiment-name>"
        exit 1
    fi

    log_warning "This will delete experiment/$experiment_name from all repos"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Aborted"
        exit 0
    fi

    # Make sure we're not on the branch we're deleting
    cd "$PARENT_DIR"
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    if [[ $current_branch == "experiment/$experiment_name" ]]; then
        log_info "Switching to main before deleting..."
        switch_main
    fi

    # Delete from sam_api
    log_info "Deleting from sam_api..."
    cd "$SAM_API_DIR"
    git branch -D "experiment/$experiment_name" 2>/dev/null || true
    git push origin --delete "experiment/$experiment_name" 2>/dev/null || true

    # Delete from sam_ui
    log_info "Deleting from sam_ui..."
    cd "$SAM_UI_DIR"
    git branch -D "experiment/$experiment_name" 2>/dev/null || true
    git push origin --delete "experiment/$experiment_name" 2>/dev/null || true

    # Delete from parent
    log_info "Deleting from parent repo..."
    cd "$PARENT_DIR"
    git branch -D "experiment/$experiment_name" 2>/dev/null || true
    git push origin --delete "experiment/$experiment_name" 2>/dev/null || true

    log_success "Experiment '$experiment_name' deleted"
}

# Main command dispatcher
case "${1:-}" in
    create)
        create_experiment "$2"
        ;;
    switch)
        switch_experiment "$2"
        ;;
    main)
        switch_main
        ;;
    sync)
        sync_experiment "$2"
        ;;
    list)
        list_experiments
        ;;
    status)
        status
        ;;
    delete)
        delete_experiment "$2"
        ;;
    *)
        echo "Samhub Experiment Management"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  create <name>      Create a new experiment with synchronized branches"
        echo "  switch <name>      Switch to an existing experiment"
        echo "  main               Switch back to main branch"
        echo "  sync \"message\"     Commit and push changes across all repos"
        echo "  list               List all available experiments"
        echo "  status             Show git status of all repos"
        echo "  delete <name>      Delete an experiment from all repos"
        echo ""
        echo "Examples:"
        echo "  $0 create new-feature"
        echo "  $0 switch new-feature"
        echo "  $0 sync \"Add user authentication\""
        echo "  $0 main"
        echo "  $0 delete old-experiment"
        ;;
esac
