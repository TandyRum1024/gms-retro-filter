// Shader that generates LUT texture from the palette texture that contains the colours
// MMXX ZIK
attribute vec3 in_Position;
attribute vec4 in_Colour;
attribute vec2 in_TextureCoord;
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

void main()
{
    vec4 object_space_pos = vec4( in_Position.x, in_Position.y, in_Position.z, 1.0);
    gl_Position = gm_Matrices[MATRIX_WORLD_VIEW_PROJECTION] * object_space_pos;
    v_vColour = in_Colour;
    v_vTexcoord = in_TextureCoord;
}

//######################_==_YOYO_SHADER_MARKER_==_######################@~// Shader that generates LUT texture from the palette texture that contains the colours
// The size of palette. Don't forget to change it if your palette texture has different number of colours.
// MMXX ZIK

#define PALETTESIZE 16.0
// #define noweightedcolourdelta
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform sampler2D uPalette; // Texture that contains palette data.
uniform vec2 uPalettePixelSize; // Size of one texel in palette texture
uniform vec2 uLUTSize; // Size of LUT
uniform float uLUTCellNum; // Number of LUT's cells
uniform float uSecondClosestBlendFactor; // if it's 0, the shader returns 1st closest colour. otherwise, it returns 2nd closest colour

// Encodes UV to RGB colour
vec3 uvToColour (vec2 uv, vec2 uvdiv)
{
    // Calculate texture's pixel position
    vec2 texsz = uLUTSize;
    vec2 texuv = floor(uv * uLUTSize);
    vec2 cellsize = floor(texsz / uvdiv);
    
    // Calculate the LUT's "chunk" uvs
    vec2 chunkuv = floor(texuv / cellsize);
    vec2 chunkuvlocal = mod(texuv, cellsize); // fract(chunkuv);
    
    // The "local" UVs determines the Red and Green channel of resulting encoded colour
    vec3 col = vec3(0.0);
    col.rg = chunkuvlocal.xy / (cellsize - 1.0);
    
    // ... And the Blue channel is determined by "index" calculated from chunk uv's x and y coordinates.
    // Where the index is simply calculated as how you would calculate 1D index from 2D indices.
    // Also keep in mind that the index could be in [0 ~ (uvdiv.x * uvdiv.y - 1)] range..
    // We must normalize it into 0..1 space in order to write it properly into the texture. (since the shader uses 0..1 ranged RGB for storing colours ofc)
    float maxindex = (uvdiv.x * uvdiv.y - 1.0);
    col.b = (chunkuv.x + (chunkuv.y * uvdiv.x)) / maxindex;
    
    return clamp(col, 0.0, 1.0);
}

// Returns the colour difference between two colours
// https://bisqwit.iki.fi/story/howto/dither/jy/#PsychovisualModel
float colourDiff (vec3 c1, vec3 c2)
{
    #ifdef noweightedcolourdelta
        // Use euclidean distance, Nothing fancy.
        vec3 delta = (c1 - c2);
        delta *= delta;
        return delta.r + delta.g + delta.b;
    #else
        // Use luma-weighted sum.
        const vec3 lumaweight = vec3(0.299, 0.587, 0.114);
        float luma1 = dot(c1, lumaweight);
        float luma2 = dot(c2, lumaweight);
        float lumadelta = luma1 - luma2;
        vec3 delta = c1 - c2;
        delta *= delta;
        return dot(delta, lumaweight) * 0.75 + (lumadelta * lumadelta);
    #endif
}

// Quantizes given colour to closest colour from the palette
vec3 quantizePal (vec3 col)
{
    vec2 halfpixel = uPalettePixelSize * 0.5;
    float uvstepx = 1.0 / PALETTESIZE;
    
    // Find the closest colour from the palette
    vec3 bestcol = texture2D(uPalette, halfpixel).rgb;
    float bestdist = colourDiff(col, bestcol);
    for (float i=0.0; i<PALETTESIZE; i+=1.0)
    {
        vec3 palettecol = texture2D(uPalette, vec2(i * uvstepx, 0.0) + halfpixel).rgb;
        float colourdist = colourDiff(col, palettecol);
        
        if (colourdist < bestdist)
        {
            bestcol = palettecol;
            bestdist = colourdist;
        }
    }
    
    // Find the second closest colour from the palette
    vec3 secondcol = texture2D(uPalette, halfpixel).rgb;
    float seconddist = 999.0;
    for (float i=0.0; i<PALETTESIZE; i+=1.0)
    {
        vec3 palettecol = texture2D(uPalette, vec2(i * uvstepx, 0.0) + halfpixel).rgb;
        float colourdist = colourDiff(col, palettecol);
        
        if (palettecol != bestcol && colourdist < seconddist)
        {
            secondcol = palettecol;
            seconddist = colourdist;
        }
    }
    
    return mix(bestcol, secondcol, uSecondClosestBlendFactor);
}

void main()
{
    vec3 encodedColour = uvToColour(v_vTexcoord, vec2(uLUTCellNum));
    vec3 colour = quantizePal(encodedColour);
    
    gl_FragColor = vec4(colour, 1.0);
}

