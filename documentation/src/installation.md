# Installation

MomentoBooth is cross platform and supports Windows, Linux, and macOS. The installation steps differ per platform. Windows is as of yet the easiest.

> [!NOTE]
> Just acquiring and executing the software is enough to use webcams, but digital cameras need additional driver configuration.

## Windows

On Windows, there a few methods are available to acquire the software.

> [!IMPORTANT]
> In all cases, the [Visual C++ Redistributable runtime libraries](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170) need to be installed for MomentoBooth to work on Windows.

### Download from GitHub
When you go to the [releases page on GitHub](https://github.com/momentobooth/momentobooth/releases), a few assets are available per release.

#### Windows installer application
When you download the `MomentoBooth-X.XX.X-XXX-Win-x64-Setup.exe` file from the assets, you can execute it to install MomentoBooth as a system program. A start menu item will be created.

#### `zip` archive with portable application files inside
Just extract the files anywhere you want and run the `photobooth.exe` executable.

### Using `h3xup`
The [`h3xup`](https://github.com/h3x4d3c1m4l/h3xUpdtr) tool can be used to easily update and switch between different releases of MomentoBooth. Make sure that the `h3xup` command is available in the `PATH` and run the following command in the directory that you want the program files to reside in.
```sh
h3xup switch --s3-url https://nbg1.your-objectstorage.com/momentobooth-app --filestore-path-prefix Photobooth-Win-x64 release
```

Whenever a new release is available, just run
```sh
h3xup update
```

### Set up development environment
This is not recommended if you just want to try out the software. However, if you want to make edits to the software or test in-development features, you can [set up a development environment](dev_setup.md#requirements).

## Linux
For Linux, an `appimage` is available on the [releases page on GitHub](https://github.com/momentobooth/momentobooth/releases). Though you *should* be able to download this file and run it directly (making sure the file is executable with `chmod`), there seems to be an issue where the appimage does not work unless a `flutter run` has been done in a development environment. Fixing this issue, and a Flatpak application image for easier updates and possible space saving, are on the to-do list, but not available yet.

You can also choose to [set up the development environment](dev_setup.md#requirements).

## macOS

For macOS, an automatic build pipeline is available for the application, but currently not in use. This is due to the fact that Apple requires all applications to be signed, and to do this an active Apple developers account is required, which costs $99 per year at the time of writing. Since we make no money with this software, doing this is not (yet) worth it. Therefore, *right now* unfortunately your only option is to [set up the development environment](dev_setup.md#requirements) and build it locally. We are looking into other options, however.
