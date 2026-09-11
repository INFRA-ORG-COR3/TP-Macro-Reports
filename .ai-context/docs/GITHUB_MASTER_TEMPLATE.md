# GitHub Master Template Setup

Version: 1.1.2

## Objective

Use one GitHub Template Repository as the canonical source for persistent AI context.

Recommended repository name:

`ai-project-context-template`

## One-Time Publication

From this repository on a workstation with GitHub CLI authenticated:

```powershell
.\bootstrap\Publish-MasterTemplate.ps1 `
  -RepositoryName 'ai-project-context-template' `
  -Visibility private
```

The script creates/pushes the repository when needed and enables GitHub's Template Repository flag.

## New Projects

```powershell
.\bootstrap\New-AIProject.ps1 `
  -Name 'COR3-New-Project' `
  -Profile software
```

This creates a GitHub repository from the master template, clones it, initializes the selected profile, validates context, commits the initialization, and pushes it.

## Existing Projects

Run from a local clone of the master template:

```powershell
.\bootstrap\Adopt-AIContext.ps1 `
  -TargetPath 'C:\Repos\ExistingProject' `
  -Profile universal
```

Adoption policy:

- Existing uncommitted work is never discarded.
- Existing project-owned Markdown is preserved.
- Missing standard files are created.
- The managed bootstrap block is appended/updated in `AGENTS.md`.
- `.ai-context/` validation machinery is synchronized with backups.
- No deployment or application runtime change occurs.

## All Existing GitHub Repositories

Profiles are selected from `bootstrap/repository-profiles.json`. A repository with no initialized profile and no mapping is blocked until classified.

Dry run:

```powershell
.\bootstrap\Sync-All-Repositories.ps1
```

Pilot one repository:

```powershell
.\bootstrap\Sync-All-Repositories.ps1 `
  -Repositories 'cor3-sms-mms-notifications' `
  -CreatePullRequests
```

Roll out an explicit batch:

```powershell
.\bootstrap\Sync-All-Repositories.ps1 `
  -Repositories @('Repo-A','Repo-B') `
  -CreatePullRequests
```

The script creates a branch and pull request per targeted non-archived, non-fork repository that needs adoption. It intentionally does not push directly to default branches and never auto-merges.

## Standard Startup

Every new AI/Codex session:

`AGENTS.md -> CONTEXT_INDEX.md -> PROJECT_PROFILE.md -> PROJECT_STATE.md -> tasks/ACTIVE_TASK.md -> active task`

Load additional Markdown only when relevant.
