cd D:\PROJECTS\MCPcloud\terraform-aws-deploy

C:\Users\abish\Terraform\terraform.exe destroy `
-auto-approve `
-var "repo_url=dummy" `
-var "dockerfile_content=dummy"

Write-Host ""
Write-Host "Press Escape to close..."
while ($true) {
    $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    if ($key.VirtualKeyCode -eq 27) { break }
}
