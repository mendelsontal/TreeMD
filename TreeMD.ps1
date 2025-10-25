<# Run it in PowerShell from your project directory Or specify a custom path and output file:

.\Generate-FolderTree.ps1 -Path "C:\oracle-cli" -OutputFile "structure.md"
#>
param (
    [string]$Path = ".",
    [string]$OutputFile = "tree.md"
)

# Vars
$IconRoot = "📁"
$IconSubFolders = "📂"
$IconFiles = "📄"
$IconMD = "📖"
$ExcludeList = @("tree.md", "files")

### Optinal Common Language File Icons###
$CommonLangIcons = $true
if ($CommonLangIcons -eq $true){
    $IconList = & "$PSScriptRoot\files\IconList.ps1"
}

###

# Tested PS Version
$TestedPSVersion = [version]"5.1.22621.4391"

# Get current version
$currentVersion = $PSVersionTable.PSVersion

if (
    $currentVersion.Major -lt $TestedPSVersion.Major -or
    ($currentVersion.Major -eq $TestedPSVersion.Major -and $currentVersion.Minor -lt $TestedPSVersion.Minor)
){
    Write-Host "This script is tested on PowerShell $TestedPSVersion.`nYour version is $currentVersion"
}

# Get the name of the running script
$scriptName = [System.IO.Path]::GetFileName($PSCommandPath)

function Get-FolderTree {
    param (
        [string]$FolderPath,
        [int]$IndentLevel = 0
    )

    $indent = "  " * $IndentLevel
    $output = @()

    # Get directory info
    $dir = Get-Item -Path $FolderPath
    
    # Calculate relative path safely
    $relativePath = "./"
    if ($dir.FullName -ne $PWD.Path -and $dir.FullName.StartsWith($PWD.Path)) {
        $relativePath = $dir.FullName.Substring($PWD.Path.Length + 1).Replace('\', '/')
        if ($relativePath -eq "") { $relativePath = "./" }
    }
    
    # Add root directory header for first level
    if ($IndentLevel -eq 0) {
        $output += "<details><summary>Folder Structure</summary>"
        $output += ""
        $output += "**$IconRoot <span style=""display: inline-block; margin-right: 20px;"">[$(Split-Path $dir.Name -Leaf)/]($relativePath)</span>** Root directory"
    }

    # Get all items in the directory, excluding the running script
    $items = Get-ChildItem -Path $FolderPath | Where-Object { $_.Name -ne $scriptName -and $_.Name -notin $ExcludeList} | Sort-Object { $_.PSIsContainer } -Descending

    foreach ($item in $items) {
        # Calculate item relative path safely
        $itemRelativePath = "./" + $item.Name
        if ($item.FullName -ne $PWD.Path -and $item.FullName.StartsWith($PWD.Path)) {
            $itemRelativePath = $item.FullName.Substring($PWD.Path.Length + 1).Replace('\', '/')
        }

        $name = $item.Name

        if ($item.PSIsContainer) {
            # Directory
            $output += "$indent- **$IconSubFolders <span style=""display: inline-block; margin-right: 20px;"">[$name/]($itemRelativePath)</span>**"
            # Recursively process subdirectories
            $output += Get-FolderTree -FolderPath $item.FullName -IndentLevel ($IndentLevel + 1)
        } else {
            # File
            if($CommonLangIcons -eq $true){
                # Find the icon entry that matches this extension
                $extension = [System.IO.Path]::GetExtension($name)
                $match = $IconList | Where-Object { $_.extension -ieq $extension }
                if ($match){$output += "$indent- $($match.icon) <span style=""display: inline-block; margin-right: 20px;"">[$name]($itemRelativePath)</span>"}
                elseif ($extension -eq ".md"){$output += "$indent- $IconMD <span style=""display: inline-block; margin-right: 20px;"">[$name]($itemRelativePath)</span>"
            }
                else {
                    $output += "$indent- $IconFiles <span style=""display: inline-block; margin-right: 20px;"">[$name]($itemRelativePath)</span>"
                }

                
            }
            else {
            $output += "$indent- $IconFiles <span style=""display: inline-block; margin-right: 20px;"">[$name]($itemRelativePath)</span>"
            }
        }
    }

    # Close details tag at the end of the root level
    if ($IndentLevel -eq 0) {
        $output += ""
        $output += "</details>"
    }

    return $output
}

# Generate tree and save to file
$treeContent = Get-FolderTree -FolderPath (Resolve-Path $Path)
$treeContent | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "Folder structure has been written to $OutputFile"