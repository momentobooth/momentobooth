param ([string] $executablePath, [string] $copyTo)

$libc_libs = "ld-linux-x86-64", "libBrokenLocale", "libanl", "libc", "libc_malloc_debug", "libdl", "libm", "libmemusage", "libmvec", "libnsl", "libnss_compat", "libnss_dns", "libnss_files", "libnss_hesiod", "libpcprofile", "libpthread", "libresolv", "librt", "libthread_db", "libutil"
$skip_libs = $libc_libs # + $other_libs + $more_other_libs

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

$lddtree_output = lddtree "$absolute_path"
$lddtree_output_split = $lddtree_output.Split([Environment]::NewLine)

$libs_to_copy = @()
Set-Location $absolute_copy_to_path
foreach ($lddtree_line in $lddtree_output_split) {
    $lddtree_line_split = $lddtree_line.Split("=>")
    $lib_path = $lddtree_line_split[1].Trim().Replace(" (DEPENDENCY CYCLE)", "")

    if (!$libs_to_copy.contains($lib_path)) {
        $lib_name = (Get-Item $lib_path).Name.ToString().Split(".")[0]

        if ($lib_path.Contains($absolute_path_directory)) {
            Write-Output "Skipping (found at destination): $lib_path"
            continue
        } elseif ($skip_libs.Contains($lib_name)) {
            Write-Output "Skipping (blocklist): $lib_path"
            continue
        }

        # lib was not added to list yet
        $libs_to_copy += $lib_path
        Write-Output "Copying: $lib_path"
        Copy-Item -Path $lib_path -Destination $absolute_copy_to_path

        $symlink_src = $lddtree_line_split[0].Trim()
        $symlink_dst = (Get-Item $lib_path).Name.ToString()
        if ($symlink_src -ne $symlink_dst) {
            Write-Output "Will symlink $symlink_src to $symlink_dst"
            ln -s -r "$symlink_dst" "$symlink_src"
        }
    }
}

Write-Output "Bundling done!"
Write-Output ""
