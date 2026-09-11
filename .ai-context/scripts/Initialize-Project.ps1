param(
    [Parameter(Mandatory=$true)][string]$ProjectName,
    [ValidateSet('software','network','server','saas','data','policy','universal')]
    [string]$Profile = 'universal',
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
$repo = git rev-parse --show-toplevel 2>$null
if (-not $repo) { throw 'Run this from inside the target Git repository.' }
$args = @("$repo\.ai-context\scripts\initialize_project.py",'--name',$ProjectName,'--profile',$Profile)
if ($Force) { $args += '--force' }
python @args
