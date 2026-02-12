# OpenBMC Delivery Workflow - DriveNets

## Branch Structure

```
upstream/master ──→ master (reference only)
                     
upstream/scarthgap ──→ scarthgap (stable mirror)
                         ↓
                    dev-scarthgap (active development)
                         ↓
                    release/X.Y (delivery branches)
                         ↓
                    vX.Y.Z (tags)
```

## Branches

| Branch | Purpose | Push Commits? | Tracks |
|--------|---------|---------------|--------|
| `master` | Upstream reference | ❌ Never | `upstream/master` |
| `scarthgap` | Stable LTS mirror | ❌ Never | `upstream/scarthgap` |
| `dev-scarthgap` | Active development | ✅ Always | `origin/dev-scarthgap` |
| `release/X.Y` | Delivery versions | ✅ Hotfixes only | `origin/release/X.Y` |

---

## Daily Workflow

### 1. Development Work

```bash
# Start your work session
cd ~/ws_wsl/openbmc_fork
git checkout dev-scarthgap

# Sync with upstream stable (weekly)
git checkout scarthgap
git pull upstream scarthgap
git push origin scarthgap

# Merge stable updates into your dev branch
git checkout dev-scarthgap
git merge scarthgap

# Work on meta-drivenets features
# ... make changes ...
git add meta-drivenets/
git commit -m "meta-drivenets: add XYZ feature"
git push origin dev-scarthgap
```

### 2. Check Master for Reference

```bash
# Update master to see what's happening upstream
git checkout master
git pull upstream master
git push origin master

# Look at new features/fixes
git log master --oneline -20

# Cherry-pick specific fix to dev-scarthgap if needed
git log master --oneline --grep="feature-name"
git checkout dev-scarthgap
git cherry-pick <commit-hash>
```

---

## Release Management

### Creating a New Release

```bash
# 1. Make sure dev-scarthgap is stable and tested
git checkout dev-scarthgap
git status  # Ensure everything is committed

# 2. Create release branch
git checkout -b release/1.0 dev-scarthgap
git push -u origin release/1.0

# 3. Final testing and bug fixes on release branch
# ... test thoroughly ...
# ... fix any issues ...
git commit -m "Fix: delivery issue XYZ"
git push origin release/1.0

# 4. Tag the release
git tag -a v1.0.0 -m "Release 1.0.0 - Production delivery for hardware batch A"
git push origin v1.0.0

# 5. Merge fixes back to dev
git checkout dev-scarthgap
git merge release/1.0
git push origin dev-scarthgap
```

### Release Branch Naming Convention

```
release/1.0   - First major delivery
release/1.1   - Minor update with new features
release/2.0   - Major version change
release/2.0-hw2  - Hardware-specific variant (optional)
```

### Tag Naming Convention

```
v1.0.0   - Major.Minor.Patch
v1.0.1   - Hotfix release
v1.1.0   - Minor feature update
v2.0.0   - Major version
```

---

## Hotfix Workflow

When a critical bug is found in a delivered release:

```bash
# 1. Create fix on release branch
git checkout release/1.0
git pull origin release/1.0

# 2. Make the fix
# ... fix the bug ...
git commit -m "Hotfix: critical issue XYZ"
git push origin release/1.0

# 3. Tag the hotfix
git tag -a v1.0.1 -m "Hotfix 1.0.1 - Critical bug fix"
git push origin v1.0.1

# 4. Merge hotfix back to dev-scarthgap
git checkout dev-scarthgap
git merge release/1.0
git push origin dev-scarthgap

# 5. If multiple release branches exist, cherry-pick to others
git checkout release/1.1
git cherry-pick <hotfix-commit>
git push origin release/1.1
```

---

## Syncing with Upstream

### Weekly: Sync Stable Branch

```bash
# Update scarthgap
git checkout scarthgap
git pull upstream scarthgap
git push origin scarthgap

# Merge into dev
git checkout dev-scarthgap
git merge scarthgap
git push origin dev-scarthgap
```

### Monthly: Check Master for Features

```bash
# Update master reference
git checkout master
git pull upstream master
git push origin master

# Review changes
git log scarthgap..master --oneline

# Cherry-pick specific features if needed
git checkout dev-scarthgap
git cherry-pick <commit-hash>
git push origin dev-scarthgap
```

---

## Delivery Checklist

### Before Creating Release Branch

- [ ] All meta-drivenets features tested on dev-scarthgap
- [ ] Hardware tested with latest dev-scarthgap
- [ ] No open critical bugs
- [ ] Documentation updated
- [ ] Changelog prepared

### Creating Release

- [ ] Create release/X.Y branch from dev-scarthgap
- [ ] Final testing on release branch
- [ ] Fix any last-minute issues
- [ ] Create annotated tag vX.Y.0
- [ ] Push branch and tag to origin
- [ ] Merge fixes back to dev-scarthgap

### After Release

- [ ] Document known issues
- [ ] Create release notes
- [ ] Update team on delivery
- [ ] Continue development on dev-scarthgap

---

## Common Commands

```bash
# Show all branches
git branch -vv

# Show all tags
git tag -l

# Show commits on your branch not in upstream
git log upstream/scarthgap..dev-scarthgap --oneline

# Show upstream commits not in your branch
git log dev-scarthgap..upstream/scarthgap --oneline

# Show difference between dev and a release
git log release/1.0..dev-scarthgap --oneline

# Delete remote branch
git push origin --delete branch-name

# Delete remote tag
git push origin --delete v1.0.0

# Fetch all updates without merging
git fetch --all --prune

# See what's changed in meta-drivenets
git log --oneline -- meta-drivenets/
```

---

## Troubleshooting

### Merge Conflicts

```bash
git checkout dev-scarthgap
git merge scarthgap
# CONFLICT!

# Resolve conflicts
# ... edit files ...
git add <resolved-files>
git commit -m "Merge scarthgap into dev-scarthgap"
```

### Accidentally Committed to Wrong Branch

```bash
# If you committed to scarthgap instead of dev-scarthgap
git checkout scarthgap
git reset --hard upstream/scarthgap

git checkout dev-scarthgap
# Re-do your changes here
```

### Need to Revert a Release Tag

```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin --delete v1.0.0

# Create new corrected tag
git tag -a v1.0.0 -m "Corrected release tag"
git push origin v1.0.0
```

---

## Best Practices

1. **Never commit directly to `master` or `scarthgap`** - These are mirrors
2. **Always test on dev-scarthgap first** - Before creating release branches
3. **Use descriptive commit messages** - Include "meta-drivenets:" prefix
4. **Tag every delivery** - Makes it easy to track what was shipped
5. **Merge hotfixes back** - Always merge release fixes to dev-scarthgap
6. **Document in tags** - Use detailed tag messages
7. **Keep release branches** - Don't delete old release branches
8. **Regular upstream sync** - Weekly scarthgap updates

---

## Questions?

Contact: [Your team lead / Git administrator]
Last Updated: 2026-02-12
