// Applies dithering from 2 LUT that represents closest and second closest colour from palette
// MMXX ZIK
attribute vec3 in_Position;                  // (x,y,z)
attribute vec4 in_Colour;                    // (r,g,b,a)
attribute vec2 in_TextureCoord;              // (u,v)

varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~//
// Applies dithering from 2 LUT that represents closest and second closest colour from palette
// MMXX ZIK

// #define noweightedcolourdelta
// #define alternativedithering
// #define bluechannelinterp
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec2 uScreenPixelSize; // Size of single pixel / texel of result screen texture
uniform vec2 uThresholdPixelSize; // Size of single pixel / texel of threshold matrix texture
uniform vec2 uLUTSize; // Size of single pixel / texel of LUT
uniform float uLUTCellNum; // Number of LUT's cells
uniform sampler2D uThresholdTex; // Dithering threshold matrix texture
uniform sampler2D uLUT1;
uniform sampler2D uLUT2;

// Returns the colour difference between two colours
// https://bisqwit.iki.fi/story/howto/dither/jy/#PsychovisualModel
float colourDiff (vec3 c1, vec3 c2)
{
    #ifdef noweightedcolourdelta
        // Use euclidean distance, Nothing fancy.
        vec3 delta = c1 - c2;
        delta *= delta;
        return (delta.r + delta.g + delta.b) / 3.0; // normalize it from [0..3] range to [0..1] range
    #else
        // Use luma-weighted sum.
        const vec3 lumaweight = vec3(0.299, 0.587, 0.114);
        float luma1 = dot(c1, lumaweight);
        float luma2 = dot(c2, lumaweight);
        float lumadelta = luma1 - luma2;
        vec3 delta = c1 - c2; // vec3((c1.r - c2.r) * (c1.r - c2.r), (c1.g - c2.g) * (c1.g - c2.g), (c1.b - c2.b) * (c1.b - c2.b));
        delta *= delta;
        return (dot(delta, lumaweight) * 0.75 + (lumadelta * lumadelta)) / 1.75; // normalize it from [0..1.75] range to [0..1] range
    #endif
}

// Returns threshold value from threshold texture at given UV
float getThresholdAt (vec2 uv)
{
    // Calculate threshold matrix-space uv from screen uv
    uv = mod(floor(uv / uScreenPixelSize), 1.0 / uThresholdPixelSize) * uThresholdPixelSize;
    return clamp(texture2D(uThresholdTex, uv).r, 0.0, 1.0);
}

// Samples LUT texture with blue channel interpolation and returns the result
// The celldata parameter consists of following : [1st cell idx., 2st cell idx., cell interpolation factor, cell's size]
vec3 sampleLUTInterp (vec2 uvoff, vec4 celldata, sampler2D lut)
{
    #ifdef bluechannelinterp
        vec2 uv1 = (vec2(mod(celldata.x, uLUTCellNum), floor(celldata.x / uLUTCellNum)) * celldata.w + uvoff) / uLUTSize;
        vec2 uv2 = (vec2(mod(celldata.y, uLUTCellNum), floor(celldata.y / uLUTCellNum)) * celldata.w + uvoff) / uLUTSize;
        vec3 lut1 = texture2D(lut, uv1).rgb;
        vec3 lut2 = texture2D(lut, uv2).rgb;
        return clamp(mix(lut1, lut2, celldata.z), 0.0, 1.0);
    #else
        vec2 uv = (vec2(mod(celldata.x, uLUTCellNum), floor(celldata.x / uLUTCellNum)) * celldata.w + uvoff) / uLUTSize;
        return clamp(texture2D(lut, uv).rgb, 0.0, 1.0);
    #endif
}

// Returns dithered & quantized colour from two LUT textures and screen UV coordinates
// http://alex-charlton.com/posts/Dithering_on_the_GPU/
vec3 ditherPlease (vec3 col, vec2 uv, float threshold)
{
    // 1] Calculate uv for LUT
    // Since we've encoded uv chunk's "local" coordinates to colour's R & G channels,
    // We can do the inverse & use those to get the uv chunk's local coordinates / offsets
    // Also, Don't forget to remap the uvs so that final uv coords lies in center of pixels.
    vec2 cellsize = (uLUTSize / uLUTCellNum);
    vec2 texPixelSizeHalf = 0.5 / uLUTSize;
    vec2 celluvlocal = col.rg * (cellsize - 1.0) + texPixelSizeHalf;
    
    // Now, All it's left to do is to obtain the index from colour's B channel,
    // And use that 1D index to calcualte the original 2D indices.
    // (convert encoded 1D index in 0..1 range to 0..maxindex)
    float maxindex = uLUTCellNum * uLUTCellNum - 1.0;
    float chunkmult = col.b * maxindex;
    vec4 celldata = vec4(floor(chunkmult), ceil(chunkmult), fract(chunkmult), cellsize);
    
    // 2] Get 1st & 2nd closest colour from LUT
    vec3 c1 = sampleLUTInterp(celluvlocal, celldata, uLUT1);
    vec3 c2 = sampleLUTInterp(celluvlocal, celldata, uLUT2);
    
    // 3] Calculate the difference between OG colour & closest colour normalized over between two colours
    float cd = abs(colourDiff(c1, c2));
    float delta = abs(colourDiff(c1, col));
    
    if (cd > 0.0)
    {
        delta /= cd;
    }
    
    // delta = abs((col.r + col.g + col.b) / 3.0 - c1.r);
    
    // 4] If diff. is smaller than threshold then use 1st. colour, And use 2nd colour otherwise.
    return (delta <= threshold ? c1 : c2);
    // return vec3(delta, delta, floor(delta));
    // return mix(c2, c1, clamp(ceil(threshold - delta), 0.0, 1.0));
}

void main()
{
    float threshold = getThresholdAt(v_vTexcoord);
    
    vec4 src = v_vColour * texture2D(gm_BaseTexture, v_vTexcoord);
    vec4 final = vec4(ditherPlease(src.rgb, v_vTexcoord, threshold), 1.0);
    
    // Additionally, We're gonna dither up the alpha, Too.
    final.a = clamp(floor(src.a + (threshold - 0.5) + 0.5), 0.0, 1.0);
    
    gl_FragColor = final;
}

