# Protocol Quick Reference Index

This document provides quick answers to common "I'm about to do X, what protocol should I follow?" questions.

## File Operations

### "I'm about to create a file" → Where does it go?

| File Type | Location | Examples |
|-----------|----------|----------|
| **Documentation** | `doc/` | User guides, architecture docs, protocols |
| **Project Config** | Root | `CLAUDE.md`, `README.md`, `package.json` |
| **Temporary/Analysis** | `temp/` or `tmp/` | Debug reports, investigation notes, test artifacts |
| **Source Code** | Follow project structure | `src/`, `app/`, `lib/` |
| **Tests** | Alongside source | `src/__tests__/`, `tests/`, `spec/` |
| **Experiment Docs** | `doc/EXPERIMENTS.md` | Already created |

**Quick Check:**
```bash
# Ask yourself:
# - Will other developers need this to build/run the app? → Commit to repo
# - Is this analysis, debugging, or temporary testing? → temp/ directory
# - Is this needed in production or CI? → Commit to repo
# - Will this be deleted after the task? → temp/ directory
```

### "I'm about to commit a file" → What should I check?

**Run through this checklist:**
- [ ] No documentation files in root (except CLAUDE.md, README.md)
- [ ] No temporary files (check patterns: `*_REPORT.md`, `*_INVESTIGATION.md`, `debug-*`, etc.)
- [ ] No placeholder code (TODO, FIXME, mock, "you would implement")
- [ ] Documentation updated to match code changes
- [ ] Tests written and passing
- [ ] Commit message follows `type(scope): description` format

**Pre-commit hook will catch:**
- Documentation files in wrong location
- Temporary file patterns
- Placeholder code in diffs
- Invalid commit message format

## Git Operations

### "I'm about to commit" → What format?

**Format:** `type(scope): description`

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation only
- `refactor` - Code restructuring
- `test` - Adding tests
- `chore` - Maintenance
- `perf` - Performance improvement
- `ci` - CI/CD changes
- `build` - Build system changes
- `revert` - Revert previous commit

**Examples:**
```bash
git commit -m "feat(auth): add JWT authentication"
git commit -m "fix(api): handle null workspace gracefully"
git commit -m "docs(experiments): clarify branching behavior"
git commit -m "refactor(dashboard): extract chart components"
```

### "I'm about to push/deploy" → What should I verify?

**Before pushing:**
- [ ] All tests passing locally
- [ ] No temporary files in commit history
- [ ] Branch name follows conventions
- [ ] PR description explains changes

**Before deploying:**
- [ ] Screenshots taken and user approved
- [ ] All tests passing in CI
- [ ] User explicitly said "deploy" or "push to production"
- [ ] Rollback plan documented
- [ ] No "pause" or "wait" requests pending

## Code Operations

### "I'm about to write code" → What should I check first?

**Before writing:**
1. [ ] **Read existing code patterns** - Understand current architecture
2. [ ] **Check for similar code** - Don't duplicate, refactor instead
3. [ ] **Verify requirements** - Understand what's actually needed
4. [ ] **Plan refactoring** - Identify duplication to eliminate

**While writing:**
- [ ] Follow existing patterns and conventions
- [ ] Single responsibility per function/class
- [ ] DRY principle - eliminate duplication
- [ ] No over-engineering - simplest solution that works

**After writing:**
- [ ] Refactor - clean up duplication
- [ ] Test - verify it works
- [ ] Format - apply linting/formatting
- [ ] Document - update relevant docs

### "I found duplicate code" → What should I do?

**If duplication exists in 2+ places:**
1. Extract to shared function/utility
2. Update all usage sites
3. Test that behavior remains identical
4. Remove the duplicates

**Never:**
- Copy-paste code without extracting commonality
- Leave "TODO: refactor this" comments
- Create similar functions with slightly different names

## Deployment Operations

### "I'm about to deploy UI changes" → What's the protocol?

**Visual Verification Protocol:**

1. **Development Testing**
   - [ ] Start dev server
   - [ ] Take screenshot of working UI
   - [ ] Test all user flows
   - [ ] Save screenshots to `temp/test-artifacts/`

2. **User Approval Required**
   - [ ] Share screenshot with user BEFORE deployment
   - [ ] Get explicit "looks good, deploy it" approval
   - [ ] NEVER deploy without visual confirmation
   - [ ] If user says "pause" or "let me check", STOP immediately

3. **Production Deployment**
   - [ ] Deploy to production
   - [ ] Immediately verify with screenshots
   - [ ] Compare production vs development screenshots
   - [ ] Report any differences before proceeding

### "I'm about to merge a branch" → What should I check?

**Before merging ANY branch:**

1. **Show commit summary:**
   ```bash
   git log --oneline <branch> ^main
   ```

2. **List ALL changed files:**
   ```bash
   git diff --name-only main...<branch>
   git diff --stat main...<branch>
   ```

3. **Identify all dependencies:**
   - New migrations? (List them)
   - New models/controllers? (List them)
   - Environment variable changes? (Show them)
   - Route changes? (Show the diff)
   - Schema changes? (Show the diff)
   - Configuration changes? (List them)

4. **Get user approval with FULL context**
   - Present all the above information
   - Ask: "This branch changes X files including Y migrations and Z models. Should I proceed?"
   - Wait for explicit "yes, merge it"

**If user says "there might be other changes":**
- **STOP immediately**
- Do NOT proceed with merge
- Ask: "What specifically would you like me to verify?"

## Documentation Operations

### "I'm about to create documentation" → Where and how?

**Location:**
- All documentation files go in `doc/` directory
- Exceptions: `CLAUDE.md`, `README.md` (root only)

**Format:**
- Use Markdown (.md)
- Include table of contents for long docs
- Use code blocks with language hints
- Include examples and use cases

**Synchronization:**
- Update documentation in SAME commit as code changes
- Never commit code without updating related docs
- Check: Does README still reflect current behavior?
- Check: Are code examples still accurate?

**See Also:**
- Global CLAUDE.md: "DOCUMENTATION SYNCHRONIZATION PROTOCOL"

## Experiment Workflow (Samhub Project)

### "I'm about to create an experiment" → What's the workflow?

**See:** `doc/EXPERIMENTS.md` for complete guide

**Quick Start:**
```bash
# Verify starting branch
./experiment.sh status

# Create experiment (branches from current branch in all repos)
./experiment.sh create my-experiment-name

# Make changes, then sync
./experiment.sh sync "commit message"

# Switch between experiments
./experiment.sh switch other-experiment

# Return to main
./experiment.sh main

# Delete completed experiment
./experiment.sh delete old-experiment
```

## Emergency Protocols

### "User said 'pause' or 'wait'" → What do I do?

**STOP IMMEDIATELY:**
1. Stop all work - don't complete in-progress operations
2. Do NOT proceed with planned tasks
3. Ask clarifying questions:
   - "What would you like me to verify?"
   - "What concerns do you have?"
   - "Should I revert the last change?"
4. Wait for explicit approval before continuing

### "Something broke in production" → What's the protocol?

**Immediate Actions:**
1. **Tell user immediately** with screenshot/error
2. **Offer rollback options:**
   - "I can rollback to previous release"
   - "I can revert the git commits and redeploy"
3. **Do NOT attempt fixes without approval**
4. **Wait for user decision**

**Never:**
- Assume you know how to fix it
- Deploy a "quick fix" without testing
- Hide errors or downplay severity

## Common Mistakes to Avoid

### ❌ Don't Do These:

1. **Create documentation in root** → Use `doc/` directory
2. **Commit temporary files** → Use `temp/` directory
3. **Deploy without screenshots** → Get user approval first
4. **Merge without showing changes** → List all files and dependencies
5. **Continue after "pause"** → Stop and wait for clarification
6. **Skip tests** → Tests are mandatory
7. **Leave TODO comments** → Complete implementation
8. **Copy-paste code** → Extract and refactor
9. **Ignore user's stop signals** → "pause" means STOP
10. **Deploy on assumptions** → User must explicitly approve

## Protocol Sources

**Global Protocols:**
- `~/.claude/CLAUDE.md` - User's global development guidelines
- `~/.claude/PROTOCOL_INDEX.md` - Global protocol index

**Project-Specific Protocols:**
- `CLAUDE.md` - Project configuration and setup
- `doc/PROTOCOL_INDEX.md` - This file
- `doc/EXPERIMENTS.md` - Experiment workflow guide

**Git Enforcement:**
- `.git/hooks/pre-commit` - Automated protocol checks

## Quick Decision Tree

```
┌─ Creating a file?
│  ├─ Documentation? → doc/
│  ├─ Temporary? → temp/
│  └─ Code? → Follow structure
│
├─ Committing?
│  ├─ Check: No temp files?
│  ├─ Check: Docs updated?
│  ├─ Check: No placeholders?
│  └─ Check: Message format?
│
├─ Deploying?
│  ├─ Screenshots taken?
│  ├─ User approved?
│  └─ Tests passing?
│
└─ User said "pause"?
   └─ STOP EVERYTHING
```

## Questions?

If unsure about a protocol:
1. Check this index
2. Check relevant documentation
3. Ask the user before proceeding

**Remember:** It's better to ask than to violate a protocol and have to fix it later.
