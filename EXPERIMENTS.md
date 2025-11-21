# Samhub Experiment Workflow

This document explains how to manage synchronized experiments across sam_api and sam_ui submodules.

## Repository Structure

```
samhub/                    # Parent repository
├── sam_api/              # Git submodule (API component)
├── sam_ui/               # Git submodule (UI component)
├── experiment.sh         # Experiment management script
└── EXPERIMENTS.md        # This file
```

## Quick Start

### 1. Create a New Experiment

```bash
./experiment.sh create my-new-feature
```

This will:
- Create `experiment/my-new-feature` branch in sam_api
- Create `experiment/my-new-feature` branch in sam_ui
- Create `experiment/my-new-feature` branch in parent repo
- Push all branches to remote
- Switch all repos to the new experiment branches

### 2. Work on Your Experiment

Make changes in sam_api and/or sam_ui as needed. Both components will stay synchronized on the same experiment branch.

```bash
# Check status across all repos
./experiment.sh status

# Make changes in sam_api
cd sam_api
# ... make your changes ...

# Make changes in sam_ui
cd sam_ui
# ... make your changes ...
```

### 3. Sync Your Changes

Commit and push changes across all repos with a single command:

```bash
./experiment.sh sync "Add authentication feature"
```

This will:
- Commit and push changes in sam_api (if any)
- Commit and push changes in sam_ui (if any)
- Update parent repo with new submodule commits
- Keep everything synchronized

### 4. Switch Between Experiments

```bash
# List all experiments
./experiment.sh list

# Switch to a different experiment
./experiment.sh switch other-experiment

# Switch back to main
./experiment.sh main
```

### 5. Delete an Experiment

When you're done with an experiment (merged or abandoned):

```bash
./experiment.sh delete my-old-experiment
```

This will delete the experiment branch from:
- sam_api
- sam_ui
- parent repo
- All remote repositories

## Command Reference

### `create <name>`
Create a new experiment with synchronized branches across all repos.

**Example:**
```bash
./experiment.sh create authentication-refactor
```

### `switch <name>`
Switch to an existing experiment.

**Example:**
```bash
./experiment.sh switch authentication-refactor
```

### `main`
Switch all repos back to the main branch.

**Example:**
```bash
./experiment.sh main
```

### `sync "message"`
Commit and push changes across all repos with the same commit message.

**Example:**
```bash
./experiment.sh sync "Fix login validation bug"
```

### `list`
List all available experiments.

**Example:**
```bash
./experiment.sh list
```

### `status`
Show git status of all three repos (parent, sam_api, sam_ui).

**Example:**
```bash
./experiment.sh status
```

### `delete <name>`
Delete an experiment from all repos (local and remote).

**Example:**
```bash
./experiment.sh delete old-experiment
```

## Workflow Examples

### Scenario 1: Simple Feature Development

```bash
# Create experiment
./experiment.sh create new-dashboard-widget

# Make changes in sam_api
cd sam_api
# ... implement API endpoint ...
cd ..

# Make changes in sam_ui
cd sam_ui
# ... implement UI component ...
cd ..

# Sync everything
./experiment.sh sync "Add dashboard widget feature"

# Continue working...
./experiment.sh sync "Fix widget styling"
./experiment.sh sync "Add tests"

# When done, merge via PR and delete
./experiment.sh delete new-dashboard-widget
```

### Scenario 2: Multiple Parallel Experiments

```bash
# Create first experiment
./experiment.sh create experiment-a
# ... work on experiment A ...
./experiment.sh sync "WIP: experiment A changes"

# Switch to second experiment
./experiment.sh create experiment-b
# ... work on experiment B ...
./experiment.sh sync "WIP: experiment B changes"

# Switch back to first experiment
./experiment.sh switch experiment-a
# ... continue work ...
./experiment.sh sync "Complete experiment A"

# Switch back to main
./experiment.sh main
```

### Scenario 3: Bug Fix in Experiment

```bash
# You're working on an experiment
./experiment.sh create performance-optimization

# Oh no, found a bug that needs fixing on main!
./experiment.sh sync "WIP: performance optimization"
./experiment.sh main

# Fix the bug on main
cd sam_api
# ... fix bug ...
cd ../sam_ui
# ... fix bug ...
cd ..
./experiment.sh sync "Fix critical bug"

# Switch back to your experiment
./experiment.sh switch performance-optimization
# Continue where you left off
```

## Best Practices

### 1. Always Use Clean State
The script requires all repos to be in a clean state (no uncommitted changes) before switching experiments. This prevents accidental loss of work.

If you have uncommitted changes:
```bash
# Option 1: Commit them
./experiment.sh sync "WIP: current progress"

# Option 2: Stash them
cd sam_api && git stash
cd ../sam_ui && git stash
```

### 2. Descriptive Experiment Names
Use clear, descriptive names for experiments:
- ✅ Good: `authentication-refactor`, `new-reporting-api`, `fix-performance-issue`
- ❌ Bad: `test`, `experiment1`, `temp`

### 3. Regular Syncing
Sync your changes regularly to avoid losing work:
```bash
./experiment.sh sync "Implement user profile API"
./experiment.sh sync "Add profile component"
./experiment.sh sync "Fix validation bugs"
```

### 4. Keep Experiments Focused
Each experiment should focus on one feature or fix. If you find yourself working on multiple unrelated things, create separate experiments.

### 5. Delete Completed Experiments
After merging an experiment to main, delete the experiment branches to keep your repo clean:
```bash
./experiment.sh delete completed-feature
```

## Troubleshooting

### "Parent repo has uncommitted changes"
You have changes in the parent repo that need to be committed or stashed.

**Solution:**
```bash
cd ~/Documents/code/claude/samhub
git status
# Commit or stash changes
```

### "sam_api has uncommitted changes"
You have changes in sam_api that need to be committed or stashed.

**Solution:**
```bash
./experiment.sh sync "Save current progress"
# OR
cd sam_api && git stash
```

### "Experiment branch does not exist"
The experiment you're trying to switch to doesn't exist.

**Solution:**
```bash
# List available experiments
./experiment.sh list

# Or create a new one
./experiment.sh create new-experiment
```

### Submodules Not Updating
If submodules seem out of sync:

**Solution:**
```bash
cd ~/Documents/code/claude/samhub
git submodule update --init --recursive
```

### Lost Track of Current Experiment
Check which experiment you're currently on:

**Solution:**
```bash
./experiment.sh status
```

## Advanced Usage

### Manual Submodule Management
If you need to manually manage submodules:

```bash
# Update submodules to latest commits
git submodule update --remote

# Check submodule status
git submodule status

# Reset submodules to parent repo state
git submodule update --init --recursive
```

### Merging Experiments Back to Main
The experiment script doesn't handle merging. Use your normal git workflow:

```bash
# 1. Make sure experiment is fully synced
./experiment.sh sync "Final changes before merge"

# 2. Create pull requests in both repos:
#    - sam_api: experiment/my-feature -> main
#    - sam_ui: experiment/my-feature -> main

# 3. After PRs are merged, update main and delete experiment
./experiment.sh main
git pull
git submodule update --init --recursive
./experiment.sh delete my-feature
```

### Working with Docker
If sam_api runs in Docker, remember to restart containers when switching experiments:

```bash
./experiment.sh switch new-experiment
cd sam_api
docker-compose restart
```

## Port Management
Always check `~/.port-registry.txt` before configuring ports for your experiments to avoid conflicts across projects.

## Tips

1. **Use `./experiment.sh status` frequently** to check the state of all repos
2. **Create experiments from main** - always start from a clean main branch
3. **Sync before switching** - commit your work before switching to a different experiment
4. **Descriptive commit messages** - use meaningful messages when syncing
5. **Delete old experiments** - keep your branch list clean

## Questions?

If you run into issues or have questions about the experiment workflow, refer to this documentation or check the script itself:

```bash
./experiment.sh
```
