#version 330

#moj_import <shader_selector:marker_settings.glsl>
#moj_import <shader_selector:utils.glsl>

uniform sampler2D ParticlesSampler;
uniform sampler2D DataSampler;

uniform float GameTime;

out vec4 fragColor;

float deltaTime;

void manageTime() {
    fragColor = encodeFloat(GameTime * 1200.0);
}

void readMarker(ivec2 iCoord, ivec2 pixelPos, float green, int op, float rate) {
    ivec4 particleColor = ivec4(round(texelFetch(ParticlesSampler, pixelPos, 0)*255.));
    if (particleColor.rga == ivec3(MARKER_RED, green, 255)) {
        if (iCoord.x == 0) {
            fragColor = vec4(MARKER_RED, op, particleColor.b, 255) / 255.;
            return;
        }
        ivec4 previousColor = ivec4(round(texelFetch(DataSampler, ivec2(0, iCoord.y), 0)*255.));
        int lastOp = previousColor.g;
        // write "rate" into speed (row 3) if op is not 3 or 4,
        // write "rate" into acceleration (row 2) if op is 3 or 4
        if (iCoord.x == 2 // acceleration
         || iCoord.x == 3 && !(op == 3 || op == 4) // speed
        ) {
            fragColor = encodeFloat(rate);
            return;
        }
        if (iCoord.x == 1) {
            
            if (previousColor.b == particleColor.b) {
                return;
            }
            fragColor = encodeFloat(GameTime * 1200.0);
            return;
        }
    }
}

void acceleratedMotion(ivec2 iCoord, int op, float targetValue) {
    float a = decodeColor(texelFetch(DataSampler, ivec2(2, iCoord.y), 0));
    float v = decodeColor(texelFetch(DataSampler, ivec2(3, iCoord.y), 0));
    float x = decodeColor(texelFetch(DataSampler, ivec2(4, iCoord.y), 0));
    float dx = targetValue - x;
    if (op == 4) {
        dx = fract(dx + 0.5) - 0.5;
    }
    if (abs(v) < 0.01 && abs(dx) < 0.01) {
        // Fix to target if target is reached
        if (iCoord.x == 3) {
            fragColor = encodeFloat(0.0);
        } else {
            fragColor = encodeFloat(targetValue);
        }
        return;
    }
    // If breaking at full force doesn't overshoot, keep accelerating.
    // question: is extremum of x(t)=-a/2 * (t - t0)² + v * (t - t0) larger than dx?
    // -a (t - t0) + v = 0
    // t = v/a + t0
    // extremum: -a/2 * (v/a)² + v * (v/a)
    // = 1/2 * v²/a
    // Check becomes:
    // 1/2 * v²/a < dx
    // 1/2 * v²/a - dx < 0
    float sv = v > 0.0 ? 1.0 : -1.0;
    // if v points against dx, always decelerate
    if (sv * sign(dx) == -1.0) {
        a *= -sv;
    } else {
        a *= sign(abs(dx) - 0.5 * v * v / a) * sign(dx);
    }

    if (iCoord.x == 3) {
        // v(t) = a * (t - t0) + v0
        //      = a *deltaTime + v0
        v += a * deltaTime;
        v = sign(v) * min(0.3, abs(v));
        fragColor = encodeFloat(v);
        return;
    }
    // iCoord.x is 4
    // x(t) = +-a/2 * (t - t0)² + v * (t - t0) + f(t0)
    //      = +-a/2 * deltaTime² + v *deltaTime + x0
    x += (a*0.5 * deltaTime + v)*deltaTime;
    if (op == 4) {
        x = fract(x);
    }
    fragColor = encodeFloat(x);
    return;
}
void constantMotion(ivec2 iCoord, int op, float targetValue) {
    // op 1 or 2
    float v = decodeColor(texelFetch(DataSampler, ivec2(3, iCoord.y), 0));
    float x = decodeColor(texelFetch(DataSampler, ivec2(4, iCoord.y), 0));
    float dx = targetValue - x;
    if (op == 2) {
        dx = fract(dx + 0.5) - 0.5;
    }
    if (abs(v) < 0.01 && abs(x) < 0.01) {
        // Fix to target if target is reached
        if (iCoord.x == 3) {
            fragColor = encodeFloat(0.0);
        } else {
            fragColor = encodeFloat(targetValue);
        }
        return;
    }
    if (iCoord.x == 3) {
        return;
    }
    // iCoord.x is 4
    float stepSize = min(v * deltaTime, abs(dx));
    x += sign(dx) * stepSize;
    if (op == 2) {
        x = fract(x);
    }
    fragColor = encodeFloat(x);
}

/*
data sampler layout:
row 0: time
row 1..n: selector values
within a row of selector values:
column 0: last seen marker (green: operation of marker, blue: value of marker)
column 1: time when last change in marker
column 2: interpolate acceleration
column 3: interpolate speed
column 4: interpolated value
*/
void main() {
    ivec2 iCoord = ivec2(gl_FragCoord.xy);
    fragColor = texelFetch(DataSampler, iCoord, 0);

    float lastTime = decodeColor(texelFetch(DataSampler, ivec2(0), 0));
    deltaTime = mod(GameTime * 1200.0 - lastTime, 1200.0);

    if (iCoord.y == 0) {
        manageTime();
        return;
    }
    if (iCoord.x < 4) {
        #define ADD_MARKER(row, green, alpha, op, rate) if (iCoord.y == row) readMarker(iCoord, MARKER_POS(row), green, op, rate);
        LIST_MARKERS

        // Clamp timestamp to be at most 600 seconds (10 minutes) behind GameTime
        if (iCoord.x == 1) {
            float switchTime = decodeColor(fragColor);
            switchTime = max(switchTime, mod(GameTime * 1200.0 - switchTime, 1200.0));
            fragColor = encodeFloat(switchTime);
        }
    }
    if (deltaTime == 0.0 || deltaTime > 0.1) {
        return;
    }
    if (iCoord.x > 2){ // iCoord.x is 3 or 4
        ivec4 iTargetColor = ivec4(round(texelFetch(DataSampler, ivec2(0, iCoord.y), 0) * 255.));
        if (iTargetColor.r != MARKER_RED) {
            fragColor = encodeFloat(0.0);
            return;
        }
        int op = iTargetColor.g;
        float targetValue;
        // When cyclic, 1 = 0, so 255/255 would become redundant.
        // Taking 1/256 instead gives accurate representation of all multiples of 1/256
        if (op == 2 || op == 4) {
            targetValue = float(iTargetColor.b) / 256.;
        } else {
            targetValue = float(iTargetColor.b) / 255.;
        }
        if (op == 0) { // op 0: set
            if (iCoord.x == 3) {
                // set speed to 0
                fragColor = encodeFloat(0.0);
                return;
            } 
            // iCoord.x is 4
            fragColor = encodeFloat(targetValue);
            return;
        }
        if (op == 3 || op == 4) {
            acceleratedMotion(iCoord, op, targetValue);
            return;
        } else {
            // op 1 or 2
            constantMotion(iCoord, op, targetValue);
        }
    }
}
