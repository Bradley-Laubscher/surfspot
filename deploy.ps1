# Set the path to the build output directory
$buildDir = "build\web"

# Set the path to your docs folder (where GitHub Pages expects the files)
$docsDir = "docs"

# Remove all files from the docs folder
Remove-Item "$docsDir\*" -Recurse -Force

# Copy the new build files from the build/web folder to the docs folder
Copy-Item "$buildDir\*" -Recurse -Force -Destination $docsDir

# Navigate to the docs folder
Set-Location $docsDir

# Optionally, you can use Git to push these changes to GitHub
git add .
git commit -m "Update GitHub Pages"
git push origin master