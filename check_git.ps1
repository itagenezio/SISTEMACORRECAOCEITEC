$git = "C:\Program Files\Git\bin\git.exe"
Write-Host "Checking git version..."
try {
    & $git version *>&1
}
catch {
    Write-Host "Error running git version: $_"
}

Write-Host "`nChecking git status..."
try {
    & $git status *>&1
}
catch {
    Write-Host "Error running git status: $_"
}

Write-Host "`nChecking git remote..."
try {
    & $git remote -v *>&1
}
catch {
    Write-Host "Error running git remote: $_"
}
