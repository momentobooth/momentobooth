### Output Resolution Multiplier

This setting controls the image resolution multiplier within the photo booth application, which in turn controls the image resolution of the exported photos. A factor of `1.0` results in a resolution of `1000` pixels on the long side of the image and `1000/aspect ratio` on the short side without padding.

The calculation of the total image height is as follows:  
`resolutionMultiplier * (1000 + collagePaddingSetting * 2)`

And the width:  
`resolutionMultiplier * (1000/collageAspectRatioSetting + collagePaddingSetting * 2)`
