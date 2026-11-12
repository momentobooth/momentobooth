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
For Linux, MomentoBooth is distributed as a [Flatpak](https://flatpak.org/). The [releases page on GitHub](https://github.com/momentobooth/momentobooth/releases) has a bundle for x86_64 PCs (`MomentoBooth-X.XX.X-XXX-Linux-x86_64.flatpak`) and one for arm64 devices (`MomentoBooth-X.XX.X-XXX-Linux-aarch64.flatpak`), such as a Raspberry Pi with a 64-bit OS.

1. Make sure Flatpak is installed and the Flathub repository is added, see the [Flathub setup guide](https://flathub.org/setup) for your distribution. MomentoBooth runs on the GNOME runtime, which is downloaded from Flathub during the installation.
2. Install the downloaded bundle:

   ```sh
   flatpak install --user MomentoBooth-X.XX.X-XXX-Linux-x86_64.flatpak
   ```

3. Start MomentoBooth from the application menu, or with `flatpak run io.github.momentobooth.MomentoBooth`.

To update, download the bundle of the new release and install it in the same way.

Some notes on the Flatpak:

* Settings and other application data are stored in `~/.var/app/io.github.momentobooth.MomentoBooth`.
* MomentoBooth has access to USB devices and webcams, the home directory, and removable drives under `/media` and `/run/media`. To use a folder elsewhere, give MomentoBooth access to it with `flatpak override --user --filesystem=/path/to/folder io.github.momentobooth.MomentoBooth`.
* Digital cameras (gPhoto2) need the udev rules of libgphoto2 on the system itself, which give the logged in user access to the camera. Most distributions install them along with the libgphoto2 package (e.g. `libgphoto2-6t64` on Ubuntu).
* The ping health check of external systems only works when the system allows ping for regular users, as the Flatpak cannot use the elevated privileges the system's own `ping` has. Some distributions, such as Ubuntu 24.04, do not allow it by default; the check then fails with "Operation not permitted". To allow it, run:

  ```sh
  echo 'net.ipv4.ping_group_range = 0 2147483647' | sudo tee /etc/sysctl.d/60-ping-group-range.conf
  sudo sysctl --system
  ```

* The experimental recording of video message audio (through FFmpeg) is not available in the Flatpak.

You can also choose to [set up the development environment](dev_setup.md#requirements).

## macOS

For macOS, an automatic build pipeline is available for the application, but currently not in use. This is due to the fact that Apple requires all applications to be signed, and to do this an active Apple developers account is required, which costs $99 per year at the time of writing. Since we make no money with this software, doing this is not (yet) worth it. Therefore, *right now* unfortunately your only option is to [set up the development environment](dev_setup.md#requirements) and build it locally. We are looking into other options, however.
