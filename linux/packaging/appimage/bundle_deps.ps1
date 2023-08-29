param ([string] $executablePath, [string] $copyTo)

$absolute_path = Resolve-Path $executablePath
$absolute_copy_to_path = Resolve-Path $copyTo

if (!$absolute_path) {
    Write-Output "Path invalid"
    exit 1
} elseif (!$absolute_copy_to_path) {
    Write-Output "Copy to path invalid"
    exit 1
}

Write-Output "Recursively reading dependencies starting at: $absolute_path"
Write-Output "Libraries will be copied to: $absolute_copy_to_path"
Write-Output ""

$absolute_path_directory = (Get-Item $absolute_path).DirectoryName

$lddtree_output = lddtree $absolute_path
$lddtree_output_split = $lddtree_output.Split([Environment]::NewLine)

$libs_to_copy = @()
foreach ($lddtree_line in $lddtree_output_split) {
    $lddtree_line_split = $lddtree_line.Split("=>")
    $lib_path = $lddtree_line_split[1].Trim().Replace(" (DEPENDENCY CYCLE)", "")

    if (!$libs_to_copy.contains($lib_path)) {
        if ($lib_path.Contains($absolute_path_directory)) {
            Write-Output "Skipping: $lib_path"
            continue
        }

        # lib was not added to list yet
        $libs_to_copy += $lib_path
        Write-Output "Will copy: $lib_path"
    }
}
Write-Output ""

# copy libs
foreach ($lib in $libs_to_copy) {
    Write-Output "Copying: $lib to $absolute_copy_to_path"
    Copy-Item -Path $lib -Destination $absolute_copy_to_path
}
