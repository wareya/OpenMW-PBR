#define SHADOWS @shadows_enabled

// set to your shadowmap resolution
#define SHADOWMAP_RES (2048.0)
// set to a number between 1 and 16. values from 2 to 5 are normal, values above 5 are silly. 1 means no filtering.
#define FILTER_SIZE 3

uniform float osg_simulationTime;

#if SHADOWS
    uniform float maximumShadowMapDistance;
    uniform float shadowFadeStart;
    @foreach shadow_texture_unit_index @shadow_texture_unit_list
        uniform mat4 shadowSpaceMatrix@shadow_texture_unit_index;
        uniform sampler2DShadow shadowTexture@shadow_texture_unit_index;
        varying vec4 shadowSpaceCoords@shadow_texture_unit_index;

#if @perspectiveShadowMaps
        varying vec4 shadowRegionCoords@shadow_texture_unit_index;
#endif
    @endforeach
#endif // SHADOWS

float getFilteredShadowing(sampler2DShadow tex, vec4 coord, mat4 matrix)
{
    #define _FILTER_SIZE ((FILTER_SIZE) < 1 ? 1 : (FILTER_SIZE) > 16 ? 16 : (FILTER_SIZE))
    
    float scale = 1.0 / (SHADOWMAP_RES) * coord.w;
    //float scale = 1.0 / (SHADOWMAP_RES);
    vec4 offs = vec4(1.0, 0.0, 0.0, 0.0) * vec4(scale, scale, 1.0, 1.0);
    vec4 offs2 = vec4(0.0, 1.0, 0.0, 0.0) * vec4(scale, scale, 1.0, 1.0);
    
    vec3 x_d = vec3(1.0, 0.0, 0.0);
    vec3 y_d = vec3(0.0, 1.0, 0.0);
    
// plane-dependent filtering
#if 1
    vec3 coordq = coord.xyz / coord.w;
    
#if PER_PIXEL_LIGHTING
    vec3 viewNormal = normalize(gl_NormalMatrix * passNormal);
    vec3 viewTangent = cross(viewNormal, normalize(vec3(0.9153, -0.0115, -0.5141)));
    vec3 viewTangent2 = cross(viewNormal, viewTangent);
    
    vec4 tanbad1 = normalize(matrix * vec4(viewTangent, 0.0));
    vec4 tanbad2 = normalize(matrix * vec4(viewTangent2, 0.0));
    vec4 coord2 = coord + tanbad1;
    vec4 coord3 = coord + tanbad2;
    vec3 coordq2 = coord2.xyz / coord2.w;
    vec3 coordq3 = coord3.xyz / coord3.w;
    x_d = normalize(coordq2.xyz - coordq.xyz);
    y_d = normalize(coordq3.xyz - coordq.xyz);
#else
    x_d = normalize(dFdx(coordq.xyz)) * 0.001;
    y_d = normalize(dFdy(coordq.xyz)) * 0.001;
#endif
    
    // enforce x and y being at a 90 degree angle from each other
    vec3 q = cross(normalize(x_d), normalize(y_d));
    y_d = cross(x_d, q) * 0.001;
    
#endif
    
    float stride_min_px = 1.0;
    offs = vec4(x_d, 0.0) * stride_min_px * scale;
    offs2 = vec4(y_d, 0.0) * stride_min_px * scale;
    
    //// limit filter size to roughly a multiple of its "typical" size
    //float mul_limit = 1.8;
    //float offs_l2 = length(offs);
    //if (offs_l2 > length(scale * mul_limit))
    //    offs *= length(scale * mul_limit)/offs_l2;
    //float offs2_l2 = length(offs2);
    //if (offs2_l2 > length(scale * mul_limit))
    //    offs2 *= length(scale * mul_limit)/offs2_l2;
    
    // require filter taps to cover at least a certain number of texels
    float filter_min_texels = 1.3;
    float texel_size = length(scale * filter_min_texels);
    float offs_l = length(offs.xy);
    if (offs_l < texel_size)
        offs *= texel_size/offs_l;
    float offs2_l = length(offs2.xy);
    if (offs2_l < texel_size)
        offs2 *= texel_size/offs2_l;

    float amount = 0.0;
    float norm = 0.0;
    int size = _FILTER_SIZE;
    float ends = (size - 1.0) / 2.0;

    for (float y = -ends; y < ends + 0.1; y++)
    {
        for (float x = -ends; x < ends + 0.1; x++)
        {
            vec4 innercoord = coord + offs*float(x) + offs2*float(y);
            amount += shadow2DProj(tex, innercoord).r;
            norm += 1.0;
        }
    }
    amount /= norm;

    return amount;
}

float unshadowedLightRatio(float distance)
{
    float shadowing = 1.0;
#if SHADOWS
#if @limitShadowMapDistance
    float fade = clamp((distance - shadowFadeStart) / (maximumShadowMapDistance - shadowFadeStart), 0.0, 1.0);
    if (fade == 1.0)
        return shadowing;
#endif
    bool doneShadows = false;
    @foreach shadow_texture_unit_index @shadow_texture_unit_list
        if (!doneShadows)
        {
            vec3 shadowXYZ = shadowSpaceCoords@shadow_texture_unit_index.xyz / shadowSpaceCoords@shadow_texture_unit_index.w;
#if @perspectiveShadowMaps
            vec3 shadowRegionXYZ = shadowRegionCoords@shadow_texture_unit_index.xyz / shadowRegionCoords@shadow_texture_unit_index.w;
#endif
            if (all(lessThan(shadowXYZ.xy, vec2(1.0, 1.0))) && all(greaterThan(shadowXYZ.xy, vec2(0.0, 0.0))))
            {
                float amount = getFilteredShadowing(
                    shadowTexture@shadow_texture_unit_index,
                    shadowSpaceCoords@shadow_texture_unit_index,
                    shadowSpaceMatrix@shadow_texture_unit_index
                );
                shadowing = min(amount, shadowing);

                doneShadows = all(lessThan(shadowXYZ, vec3(0.95, 0.95, 1.0))) && all(greaterThan(shadowXYZ, vec3(0.05, 0.05, 0.0)));
#if @perspectiveShadowMaps
                doneShadows = doneShadows && all(lessThan(shadowRegionXYZ, vec3(1.0, 1.0, 1.0))) && all(greaterThan(shadowRegionXYZ.xy, vec2(-1.0, -1.0)));
#endif
            }
        }
    @endforeach
#if @limitShadowMapDistance
    shadowing = mix(shadowing, 1.0, fade);
#endif
#endif // SHADOWS
    return shadowing;
}

void applyShadowDebugOverlay()
{
#if SHADOWS && @useShadowDebugOverlay
    bool doneOverlay = false;
    float colourIndex = 0.0;
    @foreach shadow_texture_unit_index @shadow_texture_unit_list
        if (!doneOverlay)
        {
            vec3 shadowXYZ = shadowSpaceCoords@shadow_texture_unit_index.xyz / shadowSpaceCoords@shadow_texture_unit_index.w;
#if @perspectiveShadowMaps
            vec3 shadowRegionXYZ = shadowRegionCoords@shadow_texture_unit_index.xyz / shadowRegionCoords@shadow_texture_unit_index.w;
#endif
            if (all(lessThan(shadowXYZ.xy, vec2(1.0, 1.0))) && all(greaterThan(shadowXYZ.xy, vec2(0.0, 0.0))))
            {
                colourIndex = mod(@shadow_texture_unit_index.0, 3.0);
                if (colourIndex < 1.0)
                    gl_FragData[0].x += 0.1;
                else if (colourIndex < 2.0)
                    gl_FragData[0].y += 0.1;
                else
                    gl_FragData[0].z += 0.1;

                doneOverlay = all(lessThan(shadowXYZ, vec3(0.95, 0.95, 1.0))) && all(greaterThan(shadowXYZ, vec3(0.05, 0.05, 0.0)));
#if @perspectiveShadowMaps
                doneOverlay = doneOverlay && all(lessThan(shadowRegionXYZ.xyz, vec3(1.0, 1.0, 1.0))) && all(greaterThan(shadowRegionXYZ.xy, vec2(-1.0, -1.0)));
#endif
            }
        }
    @endforeach
#endif // SHADOWS
}
