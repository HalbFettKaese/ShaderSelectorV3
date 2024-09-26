
// avoid duplicate values
#define EXAMPLE_GREYSCALE_CHANNEL 1
#define EXAMPLE_ROTATION_CHANNEL 2

/*
signature:
 ADD_MARKER(channel, pos, green, alpha, op, rate)
*/
// append different marker definitions
#define LIST_MARKERS \
ADD_MARKER(EXAMPLE_GREYSCALE_CHANNEL, ivec2(0,0), 253, 251, 1, 0.1) \
ADD_MARKER(EXAMPLE_ROTATION_CHANNEL, ivec2(0,2), 251, 251, 0, 0.0) \
ADD_MARKER(EXAMPLE_ROTATION_CHANNEL, ivec2(0,2), 252, 251, 4, 0.4)

#define MARKER_RED 254
