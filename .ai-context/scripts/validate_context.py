#!/usr/bin/env python3
'''Validate the minimum integrity of the persistent project context.'''

from __future__ import annotations
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
MANDATORY = [
    'AGENTS.md','CONTEXT_INDEX.md','PROJECT_PROFILE.md','PROJECT_STATE.md',
    'tasks/ACTIVE_TASK.md','KNOWN_FAILURES.md','KNOWN_FIXES.md','DECISIONS.md'
]


def main() -> None:
    errors: list[str] = []
    warnings: list[str] = []

    for item in MANDATORY:
        if not (ROOT/item).exists():
            errors.append(f'Missing mandatory file: {item}')

    if errors:
        report(errors, warnings)
        raise SystemExit(1)

    profile = (ROOT/'PROJECT_PROFILE.md').read_text(encoding='utf-8')
    if 'Status: TEMPLATE' in profile or 'Profile: UNINITIALIZED' in profile:
        warnings.append('Project profile is not initialized.')

    active = (ROOT/'tasks'/'ACTIVE_TASK.md').read_text(encoding='utf-8')
    m = re.search(r'^Task:\s*(.+?)\s*$', active, re.MULTILINE)
    task_value = m.group(1) if m else None
    if task_value is None:
        errors.append('ACTIVE_TASK.md has no Task: field.')
    elif task_value != 'NONE':
        task_path = ROOT/task_value.strip('`')
        if not task_path.exists():
            errors.append(f'ACTIVE_TASK points to missing file: {task_value}')
        elif 'tasks/active/' not in task_path.as_posix():
            warnings.append(f'Active task is outside tasks/active/: {task_value}')

    # Duplicate stable IDs create ambiguous retrieval.
    checks = [
        ('DECISIONS.md', r'^##\s+(D-\d+)\b'),
        ('KNOWN_FAILURES.md', r'^##\s+(KF-[A-Z0-9]+-\d+)\b'),
        ('KNOWN_FIXES.md', r'^##\s+(FIX-[A-Z0-9]+-\d+)\b'),
        ('RISKS.md', r'^##\s+(R-\d+)\b'),
    ]
    for file_name, pattern in checks:
        path = ROOT/file_name
        if not path.exists():
            continue
        ids = re.findall(pattern, path.read_text(encoding='utf-8'), flags=re.MULTILINE)
        dups = sorted({x for x in ids if ids.count(x) > 1})
        if dups:
            errors.append(f'Duplicate IDs in {file_name}: {", ".join(dups)}')

    index = (ROOT/'CONTEXT_INDEX.md').read_text(encoding='utf-8')
    for mandatory_ref in ['AGENTS.md','PROJECT_PROFILE.md','PROJECT_STATE.md','tasks/ACTIVE_TASK.md']:
        if mandatory_ref not in index:
            errors.append(f'CONTEXT_INDEX.md missing mandatory reference: {mandatory_ref}')

    secret_patterns = [
        ('OpenAI-style API key', re.compile(r'\bsk-[A-Za-z0-9_-]{8,}')),
        ('private key block', re.compile(r'BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY', re.IGNORECASE)),
        ('inline password assignment', re.compile(r'\bpassword\s*=\s*[^<\s][^\s]{5,}', re.IGNORECASE)),
    ]
    # Lightweight guard; not a comprehensive secret scanner.
    for md in ROOT.glob('*.md'):
        content = md.read_text(encoding='utf-8', errors='ignore')
        for label, pattern in secret_patterns:
            if pattern.search(content):
                warnings.append(f'Potential {label} in {md.name}. Review manually.')

    report(errors, warnings)
    raise SystemExit(1 if errors else 0)


def report(errors: list[str], warnings: list[str]) -> None:
    if errors:
        print('ERRORS')
        for x in errors:
            print(f'- {x}')
    if warnings:
        print('WARNINGS')
        for x in warnings:
            print(f'- {x}')
    if not errors and not warnings:
        print('Context validation PASS.')
    elif not errors:
        print('Context validation PASS with warnings.')


if __name__ == '__main__':
    main()
