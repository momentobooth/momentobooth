# Camera

Camera usage within MomentoBooth constists of two parts:

* Live view
* Photo capture

For both aspects a few options are available. In general you either work with a webcam, or a separate camera.

## Webcam

This is the easiest option to set up. Connect a supported webcam, and use it for both live view and photo capture. This method does not usually result in great image quality, but is great for testing.

## Camera

For using a external camera, two methods are available at the moment.

1. Using the `gphoto2` implementation
2. Using a vendor remote tethering program (Windows only)

### gphoto2

[Camera support overview](http://www.gphoto.org/doc/remote/) – Needs at least `capture support` and `liveview`.
Alternatively, see the [libgphoto2 supported cameras](http://www.gphoto.org/proj/libgphoto2/support.php) – Needs at least `Image Capture` and `Liveview`.

Using the `gphoto2` implementation is very convenient, as it allows for both live view and high quality photo capture through a single USB connection. Check the above link for which cameras are supported.

### Vendor tethering

When a camera is not suported by `gphoto2`, it may be an option to use a vendor tethering program for photo capture through an [AutoIt](https://www.autoitscript.com/site/) script. This works as long as the vendor program writes JPG images to a specified directory.
Live view must then be obtained from a camera feed.

* This can either be with a video capture device (usually HDMI)
  You need the capture device and camera video out cable.
* or by capturing the tethering software with [OBS Studio](https://obsproject.com/) and working with the [OSB virtual webcam](https://obsproject.com/kb/virtual-camera-guide) output.

The right webcam source can then be selected in the live view settings.

To activate the AutoIt script, select `Sony Imaging Edge Remote` as capture source and set the image input directory.

### Physical camera set-up

When running a photo booth at an event, the camera will likely need to be turned on for several hours. A normal battery will not be able to supply energy for that long. It is therefore recommended to get a **dc dummy battery**, which is connected to an external power supply. The most convenient solution is one that works with USB C Power Delivery, as it can be connected to any PD power supply and so does not require a specific adapter. These usually run between €15~€30.

It is also recommended to mount your camera firmly on either a big or a small tripod so it is stable and can be aimed in the right direction.
