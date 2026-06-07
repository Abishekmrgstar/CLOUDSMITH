param(
[string]$repo,
[string]$dockerfile,
[string]$port = "3000"
)

cd D:\PROJECTS\MCPcloud\terraform-aws-deploy

docker rm -f $(docker ps -aq) 2>$null
docker rmi -f app 2>$null

C:\Users\abish\Terraform\terraform.exe init

C:\Users\abish\Terraform\terraform.exe apply `
-auto-approve `
-var "repo_url=$repo" `
-var "dockerfile_content=$dockerfile" `
-var "app_port=$port"

Write-Host ""
Write-Host "Press Escape to close..."
while ($true) {
    $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    if ($key.VirtualKeyCode -eq 27) { break }
}