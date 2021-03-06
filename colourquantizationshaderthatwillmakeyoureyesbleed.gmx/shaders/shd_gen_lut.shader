// Shader that generates LUT texture
// 이 쉐이더는 나중에 색상을 양자화 할 때 쓰일 LUT 텍스쳐를 생성합니다.
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

//######################_==_YOYO_SHADER_MARKER_==_######################@~// Shader that generates LUT texture from UV.
// 이 쉐이더는 UV좌표를 기반으로 나중에 색상을 양자화 할 때 쓰일 LUT 텍스쳐를 생성합니다.
// #define noweightedcolourdelta
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

// Uniform that stores the colours of palette
uniform vec3 uPalette[16];
uniform vec2 uLUTSize; // Size of LUT
uniform float uLUTCellNum; // Number of LUT's cells
uniform float uSecondClosestBlendFactor;

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
// https://en.wikipedia.org/wiki/Color_difference
/*
float ColorCompare(int r1,int g1,int b1, int r2,int g2,int b2)
{
    double luma1 = (r1*299 + g1*587 + b1*114) / (255.0*1000);
    double luma2 = (r2*299 + g2*587 + b2*114) / (255.0*1000);
    double lumadiff = luma1-luma2;
    double diffR = (r1-r2)/255.0, diffG = (g1-g2)/255.0, diffB = (b1-b2)/255.0;
    return (diffR*diffR*0.299 + diffG*diffG*0.587 + diffB*diffB*0.114)*0.75
         + lumadiff*lumadiff;
}
*/
float colourDiff (vec3 c1, vec3 c2)
{
    #ifdef noweightedcolourdelta
        vec3 delta = (c1 - c2);
        delta *= delta;
        return delta.r + delta.g + delta.b;
    #else
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
vec3 quantizePal16 (vec3 col)
{
    // Find the closest colour from the palette
    vec3 bestcol = uPalette[0];
    for (int i=0; i<16; i++)
    {
        vec3 palettecol = uPalette[i];
        float colourdist = colourDiff(col, palettecol);
        
        if (colourdist < colourDiff(col, bestcol))
        {
            bestcol = palettecol;
        }
    }
    
    // Find the second closest colour from the palette
    vec3 secondcol = uPalette[0];
    float seconddist = 999.0;
    for (int i=0; i<16; i++)
    {
        vec3 palettecol = uPalette[i];
        float colourdist = colourDiff(col, palettecol);
        
        if (palettecol != bestcol && colourdist < seconddist)
        {
            secondcol = palettecol;
            seconddist = colourdist;
        }
    }
    /*
    float bestdist = colourDiff(col, bestcol);
    float seconddist = bestdist;
    for (int i=1; i<16; i++)
    {
        vec3 palettecol = uPalette[i];
        float colourdist = colourDiff(col, palettecol);
        
        if (colourdist < bestdist)
        {
            secondcol = bestcol;
            seconddist = bestdist;
            bestcol = palettecol;
            bestdist = colourdist;
        }
        else if (colourdist < seconddist)
        {
            secondcol = palettecol;
            seconddist = colourdist;
        }
    }
    */
    
    // If colour distance is too far, Make secondary colour match the closest colour
    /*
    if (seconddist > 256.0)
    {
        secondcol = bestcol;
        seconddist = bestdist;
    }
    */
    
    return mix(bestcol, secondcol, uSecondClosestBlendFactor);
}

void main()
{
    vec3 encodedColour = uvToColour(v_vTexcoord, vec2(uLUTCellNum));
    vec3 colour = quantizePal16(encodedColour);
    
    gl_FragColor = vec4(colour, 1.0);
}

