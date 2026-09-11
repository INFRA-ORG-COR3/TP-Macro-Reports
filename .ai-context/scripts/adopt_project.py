#!/usr/bin/env python3
"""Conservatively adopt/update the Universal AI Project Context Standard in an existing repository."""

from __future__ import annotations
import argparse
import datetime as dt
import json
from pathlib import Path
import shutil
import sys

BEGIN = "<!-- AI-CONTEXT-STANDARD:BEGIN -->"
END = "<!-- AI-CONTEXT-STANDARD:END -->"

def copy_with_backup(src: Path, dst: Path, backup_root: Path, overwrite: bool) -> str:
    if not dst.exists():
        dst.parent.mkdir(parents=True, exist_ok=True)
        if src.is_dir():
            shutil.copytree(src, dst)
        else:
            shutil.copy2(src, dst)
        return "created"
    if not overwrite:
        return "preserved"
    if src.is_file() and dst.is_file() and src.read_bytes() == dst.read_bytes():
        return "unchanged"
    rel = dst.relative_to(dst.parents[len(dst.parts)-1]) if False else None
    # caller provides backup destination separately by recreating relative path
    return "needs-overwrite"

def extract_block(text: str) -> str:
    start = text.find(BEGIN)
    end = text.find(END)
    if start == -1 or end == -1 or end < start:
        raise ValueError("Master AGENTS.md is missing the managed context block.")
    return text[start:end + len(END)]

def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", required=True, help="Master template repository path")
    ap.add_argument("--target", required=True, help="Existing repository path")
    ap.add_argument("--name", required=True)
    ap.add_argument("--profile", default="universal",
                    choices=["software","network","server","saas","data","policy","universal"])
    args = ap.parse_args()

    source = Path(args.source).resolve()
    target = Path(args.target).resolve()
    if not (target / ".git").exists():
        raise SystemExit("ERROR: target is not a Git repository root.")
    if not (source / ".ai-context" / "managed-manifest.json").exists():
        raise SystemExit("ERROR: source is not a valid v1.1+ master template.")

    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = target / ".context-backup" / stamp
    report = {"created": [], "preserved": [], "updated_managed": [], "warnings": []}

    # Managed machinery: safe to synchronize because it is owned by the standard.
    managed_items = [".ai-context", ".github/workflows/ai-context-validate.yml"]
    for rel in managed_items:
        s = source / rel
        d = target / rel
        if d.exists():
            same = False
            if s.is_file() and d.is_file():
                same = s.read_bytes() == d.read_bytes()
            if not same:
                b = backup / rel
                b.parent.mkdir(parents=True, exist_ok=True)
                if d.is_dir():
                    shutil.copytree(d, b, dirs_exist_ok=True)
                    shutil.rmtree(d)
                    shutil.copytree(s, d)
                else:
                    shutil.copy2(d, b)
                    shutil.copy2(s, d)
                report["updated_managed"].append(rel)
        else:
            d.parent.mkdir(parents=True, exist_ok=True)
            if s.is_dir():
                shutil.copytree(s, d)
            else:
                shutil.copy2(s, d)
            report["created"].append(rel)

    # Project-owned root context files: create missing, preserve existing.
    manifest = json.loads((source / ".ai-context" / "managed-manifest.json").read_text(encoding="utf-8"))
    for rel in manifest["root_context_files"]:
        s = source / rel
        d = target / rel
        if rel == "AGENTS.md":
            master_text = s.read_text(encoding="utf-8")
            block = extract_block(master_text)
            if not d.exists():
                shutil.copy2(s, d)
                report["created"].append(rel)
            else:
                current = d.read_text(encoding="utf-8")
                if BEGIN in current and END in current:
                    a, rest = current.split(BEGIN, 1)
                    _, b = rest.split(END, 1)
                    new = a.rstrip() + "\n\n" + block + b
                    if new != current:
                        bd = backup / rel
                        bd.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(d, bd)
                        d.write_text(new, encoding="utf-8")
                        report["updated_managed"].append("AGENTS.md managed block")
                else:
                    bd = backup / rel
                    bd.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(d, bd)
                    d.write_text(current.rstrip() + "\n\n" + block + "\n", encoding="utf-8")
                    report["updated_managed"].append("AGENTS.md appended managed block")
            continue

        if not d.exists():
            shutil.copy2(s, d)
            report["created"].append(rel)
        else:
            report["preserved"].append(rel)

    # Project structure and optional PR template.
    for rel in ["tasks/active", "tasks/completed", "docs/requirements", "docs/references",
                "docs/procedures", "docs/diagrams", "docs/evidence"]:
        (target / rel).mkdir(parents=True, exist_ok=True)

    for rel in ["tasks/ACTIVE_TASK.md", ".github/PULL_REQUEST_TEMPLATE.md"]:
        s = source / rel
        d = target / rel
        if not d.exists():
            d.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(s, d)
            report["created"].append(rel)
        else:
            report["preserved"].append(rel)

    # Initialize placeholder files only when they are still untouched template copies.
    today = dt.date.today().isoformat()
    profile_file = target / "PROJECT_PROFILE.md"
    profile_text = profile_file.read_text(encoding="utf-8")
    if "Status: TEMPLATE" in profile_text or "Profile: UNINITIALIZED" in profile_text:
        profile = json.loads((source / ".ai-context" / "profiles" / f"{args.profile}.json").read_text(encoding="utf-8"))
        all_modules = [
            'ARCHITECTURE.md','REQUIREMENTS.md','DECISIONS.md','KNOWN_FAILURES.md','KNOWN_FIXES.md',
            'SECURITY.md','ENVIRONMENT.md','TESTING.md','DEPLOYMENT.md','RUNBOOK.md','INTEGRATIONS.md',
            'DATA_MODEL.md','DATA_PROFILE.md','SOURCE_INDEX.md','RISKS.md','BACKLOG.md','GLOSSARY.md'
        ]
        enabled = profile["enabled_modules"]
        disabled = [m for m in all_modules if m not in enabled]
        profile_md = f"# PROJECT_PROFILE\n\nProject: {args.name}\nProfile: {args.profile}\nProfile Name: {profile['display_name']}\nStatus: ACTIVE\nStandard: 1.1.2\nInitialized: {today}\n\n## Enabled Modules\n\n"
        profile_md += "".join(f"- `{m}`\n" for m in enabled)
        profile_md += "\n## Disabled / On-Demand Modules\n\n"
        profile_md += "".join(f"- `{m}`\n" for m in disabled) if disabled else "- None.\n"
        profile_md += "\n## Rule\n\nLoad enabled modules only when task-relevant. Disabled modules remain available on demand.\n"
        profile_file.write_text(profile_md, encoding="utf-8")

    state_file = target / "PROJECT_STATE.md"
    state_text = state_file.read_text(encoding="utf-8")
    if "Status: TEMPLATE" in state_text or "{{PROJECT_NAME}}" in state_text:
        state_file.write_text(
            f"# PROJECT_STATE\n\nProject: {args.name}\nUpdated: {today}\nStatus: ADOPTING_STANDARD\n\n"
            "## Current Objective\n\nUNDEFINED — capture the confirmed objective from existing project evidence.\n\n"
            "## Current Baseline\n\n- Baseline must be captured before modifications.\n\n"
            "## Active Task\n\nNone.\n\n"
            "## Completed\n\n- Universal AI Project Context Standard adopted conservatively.\n\n"
            "## Pending\n\n- Reconstruct current state from repository evidence.\n- Create first scoped task.\n\n"
            "## Blockers\n\nNone confirmed.\n\n"
            "## Critical Constraints\n\n- Preserve existing behavior and uncommitted work.\n"
            "- Do not invent project state.\n- Do not deploy without explicit authorization.\n"
            "- Do not store secrets in context files.\n",
            encoding="utf-8"
        )

    # Preserve existing .gitignore and append only standard housekeeping rules.
    gitignore_path = target / ".gitignore"
    existing_ignore = gitignore_path.read_text(encoding="utf-8") if gitignore_path.exists() else ""
    required_ignores = [".context-backup/", "__pycache__/", "*.pyc"]
    ignore_lines = {line.strip() for line in existing_ignore.splitlines()}
    additions = [x for x in required_ignores if x not in ignore_lines]
    if additions:
        if gitignore_path.exists():
            bd = backup / ".gitignore"
            bd.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(gitignore_path, bd)
        new_ignore = existing_ignore.rstrip()
        if new_ignore:
            new_ignore += "\n\n"
        new_ignore += "# Universal AI Project Context Standard\n" + "\n".join(additions) + "\n"
        gitignore_path.write_text(new_ignore, encoding="utf-8")
        report["updated_managed"].append(".gitignore housekeeping")

    # Always set standard version marker.
    (target / ".context-standard-version").write_text("1.1.2\n", encoding="utf-8")

    print("Adoption complete.")
    print(json.dumps(report, indent=2))
    if report["preserved"]:
        print("\nNOTE: Existing project-owned context was preserved and may need manual reconciliation.")

if __name__ == "__main__":
    main()
