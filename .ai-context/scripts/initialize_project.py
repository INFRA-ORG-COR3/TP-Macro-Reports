#!/usr/bin/env python3
'''Initialize a cloned Universal AI Project Context Template.'''

from __future__ import annotations
import argparse
import datetime as dt
import json
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[2]
ALL_MODULES = [
    'ARCHITECTURE.md','REQUIREMENTS.md','DECISIONS.md','KNOWN_FAILURES.md','KNOWN_FIXES.md',
    'SECURITY.md','ENVIRONMENT.md','TESTING.md','DEPLOYMENT.md','RUNBOOK.md','INTEGRATIONS.md',
    'DATA_MODEL.md','DATA_PROFILE.md','SOURCE_INDEX.md','RISKS.md','BACKLOG.md','GLOSSARY.md'
]


def fail(message: str) -> None:
    print(f'ERROR: {message}', file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument('--name', required=True, help='Project display name')
    parser.add_argument('--profile', default='universal', choices=['software','network','server','saas','data','policy','universal'])
    parser.add_argument('--force', action='store_true', help='Reinitialize an already initialized template')
    args = parser.parse_args()

    required = [ROOT/'AGENTS.md', ROOT/'PROJECT_PROFILE.md', ROOT/'PROJECT_STATE.md', ROOT/'CONTEXT_INDEX.md']
    missing = [str(p.name) for p in required if not p.exists()]
    if missing:
        fail('Not at a valid template root. Missing: ' + ', '.join(missing))

    current_profile = (ROOT/'PROJECT_PROFILE.md').read_text(encoding='utf-8')
    if 'Status: TEMPLATE' not in current_profile and not args.force:
        fail('Project appears initialized. Re-run with --force only if reinitialization is intentional.')

    profile_path = ROOT/'.ai-context'/'profiles'/f'{args.profile}.json'
    profile = json.loads(profile_path.read_text(encoding='utf-8'))
    enabled = profile['enabled_modules']
    disabled = [m for m in ALL_MODULES if m not in enabled]
    today = dt.date.today().isoformat()
    stamp = dt.datetime.now().strftime('%Y%m%d-%H%M%S')

    backup = ROOT/'.context-backup'/stamp
    backup.mkdir(parents=True, exist_ok=True)
    for name in ['PROJECT_PROFILE.md','PROJECT_STATE.md','CONTEXT_INDEX.md','tasks/ACTIVE_TASK.md']:
        src = ROOT/name
        dest = backup/name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)

    profile_md = f'''# PROJECT_PROFILE\n\nProject: {args.name}\nProfile: {args.profile}\nProfile Name: {profile['display_name']}\nStatus: ACTIVE\nStandard: 1.1.2\nInitialized: {today}\n\n## Enabled Modules\n\n''' + ''.join(f'- `{m}`\n' for m in enabled)
    profile_md += '\n## Disabled / On-Demand Modules\n\n' + (''.join(f'- `{m}`\n' for m in disabled) if disabled else '- None.\n')
    profile_md += '\n## Rule\n\nEnabled modules are available project context but are still loaded only when relevant. Disabled modules may be consulted when an active task explicitly requires them.\n'
    (ROOT/'PROJECT_PROFILE.md').write_text(profile_md, encoding='utf-8')

    state_md = f'''# PROJECT_STATE\n\nProject: {args.name}\nUpdated: {today}\nStatus: INITIALIZING\n\n## Current Objective\n\nUNDEFINED — replace with one confirmed current objective.\n\n## Current Baseline\n\n- Environment: UNKNOWN\n- Version/release: UNKNOWN\n- Validation state: NOT RUN\n- Production state: UNCHANGED / UNKNOWN\n\n## Active Task\n\nNone.\n\n## Completed\n\n- Persistent project context initialized using profile `{args.profile}`.\n\n## Pending\n\n- Confirm project objective.\n- Capture baseline.\n- Create first task.\n\n## Blockers\n\nNone confirmed.\n\n## Critical Constraints\n\n- Do not invent requirements.\n- Do not modify production without explicit authorization.\n- Do not store secrets in project context.\n\n## Next\n\nConfirm objective and create the first scoped task.\n'''
    (ROOT/'PROJECT_STATE.md').write_text(state_md, encoding='utf-8')

    index_md = f'''# CONTEXT_INDEX\n\nProject: {args.name}\nUpdated: {today}\n\n## Mandatory Startup\n\n- `AGENTS.md`\n- `PROJECT_PROFILE.md`\n- `PROJECT_STATE.md`\n- `tasks/ACTIVE_TASK.md`\n\n## Active Task\n\nNone.\n\n## Task-Relevant Context\n\nNone yet. Add only files/sections necessary for the active task.\n\n## Enabled Profile Modules\n\n'''
    index_md += ''.join(f'- `{m}`\n' for m in enabled)
    index_md += '\n## Explicitly Not Required For Current Task\n\nNone.\n'
    (ROOT/'CONTEXT_INDEX.md').write_text(index_md, encoding='utf-8')

    active_md = f'''# ACTIVE_TASK\n\nTask: NONE\nStatus: IDLE\nObjective: No active task.\nUpdated: {today}\n\n## Rule\n\nWhen a task becomes active, point `Task:` to exactly one primary file under `tasks/active/` unless parallel workstreams are explicitly defined.\n'''
    (ROOT/'tasks'/'ACTIVE_TASK.md').write_text(active_md, encoding='utf-8')

    # Replace generic tokens in decision file only if still present.
    decision = ROOT/'DECISIONS.md'
    text = decision.read_text(encoding='utf-8')
    text = text.replace('{{DATE}}', today).replace('{{PROJECT_NAME}}', args.name)
    decision.write_text(text, encoding='utf-8')

    print('Initialized successfully.')
    print(f'Project: {args.name}')
    print(f'Profile: {args.profile} ({profile["display_name"]})')
    print(f'Enabled modules: {len(enabled)}')
    print(f'Backup: {backup.relative_to(ROOT)}')
    print('Next: define PROJECT_STATE.md objective/baseline, then create the first task.')


if __name__ == '__main__':
    main()
