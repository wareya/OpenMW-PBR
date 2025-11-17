// NOTE: you must add:
//   #define CASTING_SHADOWS
// before
//   #include "lib/material/alpha.glsl"
// in shadowcasting.frag

#ifndef LIB_MATERIAL_ALPHA
#define LIB_MATERIAL_ALPHA

#define FUNC_NEVER                          512 // 0x0200
#define FUNC_LESS                           513 // 0x0201
#define FUNC_EQUAL                          514 // 0x0202
#define FUNC_LEQUAL                         515 // 0x0203
#define FUNC_GREATER                        516 // 0x0204
#define FUNC_NOTEQUAL                       517 // 0x0205
#define FUNC_GEQUAL                         518 // 0x0206
#define FUNC_ALWAYS                         519 // 0x0207

float mipmapLevel(vec2 scaleduv)
{
    vec2 dUVdx = dFdx(scaleduv);
    vec2 dUVdy = dFdy(scaleduv);
    float maxDUVSquared = max(dot(dUVdx, dUVdx), dot(dUVdy, dUVdy));
    return max(0.0, 0.5 * log2(maxDUVSquared));
}

float coveragePreservingAlphaScale(sampler2D diffuseMap, vec2 uv)
{
    #if @adjustCoverage
        vec2 textureSize;
        #if @useGPUShader4
            textureSize = textureSize2D(diffuseMap, 0);
        #else
            textureSize = vec2(256.0);
        #endif
            return 1.0 + mipmapLevel(uv * textureSize) * 0.25;
    #else
        return 1.0;
    #endif
}

float _tri(float x)
{
    return abs(abs(mod(x, 2.0))-1.0);
}
float _a_hash(vec2 p)
{
    return fract(p.x * -0.55 + fract(p.y * 0.7));
}
vec4 _a_noise_ign(vec2 uv)
{
    vec2 p = uv;
    p.x = p.x - fract(p.x);
    p.y = p.y - fract(p.y);
    return vec4(_a_hash(p), _a_hash(p + 3.1141), _a_hash(p + 5.2593), _a_hash(p + 7.3815)) - 0.5;
}

//uniform float osg_SimulationTime;
float alphaTest(float alpha, float ref)
{
#ifndef CASTING_SHADOWS
    #if @alphaFunc != FUNC_ALWAYS
        int asdfx = int(gl_FragCoord.x);
        int asdfy = int(gl_FragCoord.y);
        float offset = 0.0;
        //offset += float((asdfx+asdfy)&1) * 0.5;
        //offset += float(asdfy&1) * 0.25;
        //offset += float((asdfx/2+asdfy/2)&1) * 0.125;
        //offset += float((asdfy/2)&1) * 0.0625;
        //offset += float((asdfx/4+asdfy/4)&1) * (0.125*0.25);
        //offset += float((asdfy/4)&1) * (0.0625*0.25);
        //offset = _a_noise_ign(vec2(float(asdfx), float(asdfy))).x * 0.9 + 0.55;
        offset = _a_noise_ign(vec2(float(asdfx), float(asdfy))).x * 0.9 + 0.55;
        offset -= 0.5;
        offset -= 0.0625 * 0.125;
        offset *= 0.98;
        offset *= min(ref, 1.0-ref) * 2.0;
        alpha += offset;
        alpha = clamp(alpha, 0.0, 1.0);
    #endif
#endif

    #if @alphaToCoverage 
        float coverageAlpha = (alpha - clamp(ref, 0.0001, 0.9999)) / max(fwidth(alpha), 0.0001) + 0.5;

        // Some functions don't make sense with A2C or are a pain to think about and no meshes use them anyway
        // Use regular alpha testing in such cases until someone complains.
        #if @alphaFunc == FUNC_NEVER
            discard;
        #elif @alphaFunc == FUNC_LESS
            return 1.0 - coverageAlpha;
        #elif @alphaFunc == FUNC_EQUAL
            if (alpha != ref)
                discard;
        #elif @alphaFunc == FUNC_LEQUAL
            return 1.0 - coverageAlpha;
        #elif @alphaFunc == FUNC_GREATER
            return coverageAlpha;
        #elif @alphaFunc == FUNC_NOTEQUAL
            if (alpha == ref)
                discard;
        #elif @alphaFunc == FUNC_GEQUAL
            return coverageAlpha;
        #endif
    #else
        #if @alphaFunc == FUNC_NEVER
            discard;
        #elif @alphaFunc == FUNC_LESS
            if (alpha >= ref)
                discard;
        #elif @alphaFunc == FUNC_EQUAL
            if (alpha != ref)
                discard;
        #elif @alphaFunc == FUNC_LEQUAL
            if (alpha > ref)
                discard;
        #elif @alphaFunc == FUNC_GREATER
            if (alpha <= ref)
                discard;
        #elif @alphaFunc == FUNC_NOTEQUAL
            if (alpha == ref)
                discard;
        #elif @alphaFunc == FUNC_GEQUAL
            if (alpha < ref)
                discard;
        #endif
    #endif

    return alpha;
}

#endif

