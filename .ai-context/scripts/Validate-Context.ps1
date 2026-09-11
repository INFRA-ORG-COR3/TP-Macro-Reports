$ErrorActionPreference = 'Stop'
$repo = git rev-parse --show-toplevel 2>$null
if (-not $repo) { throw 'Run this from inside the target Git repository.' }
python "$repo\.ai-context\scripts\validate_context.py"
