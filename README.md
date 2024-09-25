# ShaderSelectorV3
 An easy framework for sending information to post processing shaders using commands in Minecraft.

## What is this used for?
 The attached resource pack includes not only a framework for letting commands communicate with post processing shaders, but also a simple example of how to use that to do cool things.

 Here is a video showcasing these demonstration features:
 ![Demonstration video](media\example_video.mp4)

 If you want to try it out yourself, install the resource pack and run one of these commands:
 ```hs
 # Turn on greyscale
 /particle minecraft:entity_effect{color:[0.996078431372549, 0.9921568627450981, 1.0, 0.984313725490196],scale:1f}
 # Turn off greyscale
 /particle minecraft:entity_effect{color:[0.996078431372549, 0.9921568627450981, 0.0, 0.984313725490196],scale:1f}
 # Rotate screen by 90°
 /particle minecraft:entity_effect{color:[0.996078431372549, 0.9882352941176471, 0.25098039215686274, 0.984313725490196],scale:1f}
 # Rotate screen back to normal
 /particle minecraft:entity_effect{color:[0.996078431372549, 0.9882352941176471, 0.0, 0.984313725490196],scale:1f}
 ```

 The good thing about everything being controlled through particles is that the `/particle` command has an argument that lets you determine which players are able to see a particle.

## How does this work?
 At its core, this framework is structured around a data buffer that is defined in the `transparency` post effect pipeline. This buffer saves the inputs that are given using commands, and processes them to create an output. How many channels there are and how they are used can be changed, but in the given example, this data buffer looks like this:
 ![Data buffer layout](media\data_layout.png)
 In this, each row is responsible for one "channel" which is in control of one effect. Within a row that handles a channel, each column has its own responsibility:
 * Column 0 (input) saves the last input that was received from a command. This includes:
   * Whether there has been an input on this channel since the buffer was created (red component)
   * The operation applied by the input (green component)
   * The target value of the input (blue component)
 * Column 1 (startTime) captures the value of GameTime (in seconds) from the last moment when the target value changed on the same channel.\
 This time is clamped to always be at most 600 seconds behind the current GameTime, to avoid overflow.
 * Column 2 and 3 (acceleration and speed) are used internally to manage the smooth interpolation of the output value.
 * Column 4 (output) contains a value that changes to move closer to the target value that was given in the last input. What this movement looks like depends on the operation applied by the last input.
  
 In this, column 1 to 4 each store a single 32-bit float that has its bits split between the components of the color that is stored on the pixel. To get the single value that is represented by the color of a pixel, you can use the `decodeColor(vec4 color)` function that is defined in the `shader_selector:utils.glsl` include file.

 The output of a channel will also be referred to as the "value" of that channel.

 For example, the given resource pack uses the following instruction to be able to read the interpolated output (column 4) from channel 2 inside the `shader.fsh` post shader:
 ```glsl
 float rotationChannel = decodeColor(texelFetch(DataSampler, ivec2(4, 2), 0));
 ```

### How is a new channel defined?
 In principle, all that a channel needs is to have space on the data buffer. The size of the data buffer (as well as the `data_swap` buffer, which is used internally and should always have the same size as the `data` buffer) is set in the buffers' definitions in the `targets` list of the `assets/minecraft/post_effect/transparency.json` file.
 
 In the given example, there are 2 channels as well as the internally used `GameTime` row, making for a total of 3 rows. That's why it says `"height": 3` in both the definition of the targets `data` and `data_swap`.

### How do I give an input to a channel?
 When a particle is recognized as an input that is sent to the post shader, I will call it a "marker particle". A marker particle is identified by a core shader based on its color, and will be transformed to fill a specific pixel coordinate on the screen, which is then read by the post shader.

 Which particle colors are recognized as marker particles, as well as which channel they target and other information is all defined in `assets/shader_selector/shaders/include/marker_settings.glsl`.

 A marker is then defined by adding it to the ´LIST_MARKERS´ macro as `ADD_MARKER(<channel>, <screen pixel position>, <wanted green component>, <operation>, <interpolation rate>)`.

 If the `MARKER_GREEN_MIN` and `MARKER_GREEN_MAX` macros get adjusted so that `min <= wanted green <= max`, a particle that has the color `(MARKER_RED, <wanted green component>, <any blue value>, MARKER_ALPHA)/255` will then be recognized as a marker particle that applies the instructions that are given in the `ADD_MARKER` statement to the specified channel. \
 `MARKER_RED` and `MARKER_ALPHA` remain constant throughout all markers and should preferably not be changed.

 The chosen blue value that the particle is displayed with will then be the "target value" that is written to the data buffer.

 The arguments of the `ADD_MARKER` function have the following meaning:
 * `<channel>`: The channel that is written to when the marker is detected.
 * `<screen pixel position>`: The pixel position on the screen on which the information is sent to the post shader. Is useful to change when two different markers should be possible to use at the same time, for example when controlling different channels. A pixel position is only valid if `pixel.x + pixel.y` is an even number.
 * `<wanted green component>`: A particle is only recognized as this marker if its green component matches the given value.
 * `<operation>`: Changes the mode of how the value of the channel on the data buffer will follow the target value that is given in the particle's blue component.\
   Valid operations are:
    * `0`: Set value to input. Set speed to 0.
    * `1`: Interpolate value to follow the target value at a constant rate, given by `<rate>`.
    * `2`: Interpolate by the same method as operation `1`, but use overflow to pick the shortest path from the current value to the target value.
    * `3`: Interpolate value to follow the target value at a constant acceleration given by `<rate>`. 
    * `4`: Interpolate by the same method as operation `3`, but use overflow to pick the shortest path from the current value to the target value.
  * `<rate>`:
    * If `<operation>` is `1` or `2`, `<rate>` gives the rate of change of the value in `units/second`.
    * If `<operation>` is `3` or `4`, `<rate>` gives the acceleration of the change of the value in `units/second²`.
 
 In this, what is meant by "overflow" needs some further explanation:

 When I say that an operation uses overflow, that simply means that the value is set to wrap back to 0 when it goes above 1, and vice versa. So to get from 0.9 to 0.1, you can simply add 0.2, which is a shorter path than subtracting 0.8.

 A peculiarity that this introduces is that under this mapping, 0 is the same value as 1, and the value that normally represents 1, namely 255/255, would become redundant. That's why, when using an operation that uses overflow, the target value is no longer interpreted on a scale from 0/255 to 255/255, but instead, from 0/256 to 255/256. This has the effect that a marker that uses overflow operations will be able to target values like `0.5=128/256` or `0.25=64/256` with perfect precision, while other operations can only approximate them, as `127/255≈0.498` and `128/255≈0.502`. But this also has the effect that the color code that you enter into the particle will be slightly different from the target value that this is interpreted as. This results in the rule:

 When using an operation that uses overflow and you want to target the value `x`, set the marker particle to have a blue component of `x*256/255`.

## History

This framework is based on a [previous version](https://github.com/HalbFettKaese/common-shaders) that was used in an earlier project. That version had been extracted into its own repository by [CloudWolfYT](https://github.com/CloudWolfYT) to create [ShaderSelectorV2](https://github.com/CloudWolfYT/ShaderSelectorV2), and the current repository, ShaderSelectorV3, is a complete rewrite that includes some notable changes:
* ShaderSelectorV2 was using the post shader format from before Minecraft 1.21.2, while V3 was developed in 24w38a (a 1.21.2 snapshot).
* The data sampler has a changed layout.
* Interpolation counts in real time instead of frames (`rate` is in `1/seconds` instead of `1/frames`).
* Every channel saves how much time passed since its target value was last changed.
* Apart from the previous interpolation that only used constant motion, there's a new interpolation mode that uses smoothly accelerated motion.
* Interpolation can be set to use overflow (so to get from 0.1 to 0.9, it goes 0.1-0.2=0.9 instead of 0.1+0.8=0.9).
* Adding/editing a channel needs you to only change a single config file (`assets/shader_selector/include/marker_settings.gls`) and change the height of the data buffer (`assets/minecraft/post_effect/transparency.json`) to accommodate the new channel.

## Credits

Everything inside the current state of this repository was created by me on my own. However, many of the added features have been inspired by different interactions with people who were using the previous versions of this resource pack, so I want to thank them as well as everyone else who has been using and sharing it in the past or in the future.