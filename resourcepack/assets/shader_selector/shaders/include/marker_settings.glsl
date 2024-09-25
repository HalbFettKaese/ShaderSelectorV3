
/*
Operations:
0: set
1: interpolate at rate per second
2: interpolate at rate per second with overflow
3: interpolate with acceleration
4: interpolate with acceleration and overflow
signature:
ADD_MARKER(
|          data_row,
|          |  ivec2(screen_x,screen_y),
|          |  |           marker_green,
|          |  |           |    operation,
|          |  |           |    |  interpolation_rate)
|          |  |           |    |  |
*/
#define LIST_MARKERS \
ADD_MARKER(1, ivec2(0,0), 253, 1, 0.1) \
ADD_MARKER(2, ivec2(0,2), 251, 0, 0.0) \
ADD_MARKER(2, ivec2(0,2), 252, 4, 0.4)

#define MARKER_RED 254
#define MARKER_GREEN_MIN 251
#define MARKER_GREEN_MAX 253
#define MARKER_ALPHA 251
#define PIXEL_X_MAX 0
#define PIXEL_Y_MAX 2
