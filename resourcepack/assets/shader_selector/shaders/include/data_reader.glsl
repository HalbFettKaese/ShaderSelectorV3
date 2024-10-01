
float readChannel(int channel) {
    return decodeColor(texelFetch(DataSampler, ivec2(4, channel), 0));
}
