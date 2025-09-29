$bundle_script = (Invoke-WebRequest https://raw.githubusercontent.com/momentobooth/mingw-bundledlls/master/mingw-bundledlls).Content

Write-Output "Running bundling for rust_lib_momento_booth.dll"
Write-Output $bundle_script | python - --copy build\windows\x64\runner\Release\rust_lib_momento_booth.dll
if ($LastExitCode -ne 0) { throw "mingw-bundledlls failed with exit code $LastExitCode" }

# Bundle iolibs and camlibs themselves.
mkdir build\windows\x64\runner\Release\libgphoto2_iolibs
Copy-Item $Env:CLANG64_LIB_PATH\libgphoto2_port\*\*.dll build\windows\x64\runner\Release\libgphoto2_iolibs
mkdir build\windows\x64\runner\Release\libgphoto2_camlibs
Copy-Item $Env:CLANG64_LIB_PATH\libgphoto2\*\*.dll build\windows\x64\runner\Release\libgphoto2_camlibs

# Bundle dependency libs.
Set-Location build\windows\x64\runner\Release\
$lib_folders = @('libgphoto2_iolibs', 'libgphoto2_camlibs')
foreach ($folder in $lib_folders) {
  $libs = Get-ChildItem $folder
  foreach ($lib in $libs) {
    Write-Output "Running bundling for $lib"
    Write-Output $bundle_script | python - --copy $lib.fullName
    if ($LastExitCode -ne 0) { throw "mingw-bundledlls failed with exit code $LastExitCode" }
  }

  # Now move all libraries to the same folder as the executable (except iolibs and camlibs themselves).
  $files = Get-ChildItem $folder
  foreach ($file in $files) {
    if ($libs.Name -notcontains $file.Name) {
      Move-Item -Path $file -Destination $file.Directory.Parent.FullName -force
    }
  }
}
