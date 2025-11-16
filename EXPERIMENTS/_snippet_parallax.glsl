
// given as it would be done in the terrain shader:
#if @parallax

    vec3 eyeTexSpace = normalize(-passViewPos) * normalToViewMatrix;
    float height = texture2D(normalMap, adjustedUV).a; // 0 : deep. 1 : surface.
    vec2 offset = getParallaxOffset(eyeTexSpace, height);
    
    // START: parallax occlusion
    
    float _norm = 0.7;
    vec3 newEyeTexSpace = eyeTexSpace * vec3(-PARALLAX_SCALE, PARALLAX_SCALE, -1.0);
    newEyeTexSpace.xy *= _norm;
    newEyeTexSpace /= -newEyeTexSpace.z;
    
    float _scale_offs = -PARALLAX_BIAS/PARALLAX_SCALE;
    
    vec3 coord3d_origin = vec3(adjustedUV, _scale_offs) - newEyeTexSpace * (1.0 - _scale_offs);
    vec3 coord3d        = vec3(adjustedUV, _scale_offs) + newEyeTexSpace * _scale_offs;
    
    // multipass approach
    float passes = 3.0;
    float h_iter = 6.0;
    float i = 1.0;
    vec3 expected_3d = coord3d_origin;
    
    float h_iter_loop = 1.0 / h_iter;
    for (float j = 0; j < passes; j += 1.0)
    {
        for (; i <= h_iter; i += h_iter * h_iter_loop)
        {
            float t = i / h_iter;
            expected_3d = mix(coord3d_origin, coord3d, t);
            float probe_height = texture2D(normalMap, expected_3d.xy).a;
            if (probe_height > expected_3d.z)
                break;
        }
        i -= h_iter * h_iter_loop;
        h_iter_loop /= h_iter;
    }
    
    offset = expected_3d.xy - adjustedUV;
    height = expected_3d.z;
    
    // END: parallax occlusion
    
    adjustedUV += offset;
    
#endif


// .........
// Shadow offset

    float shadowing = 1.0;
    if (gl_FragData[0].a > 0.0)
    {
    #if @parallax
        vec3 uvWorld = normalToViewMatrix * vec3(origAdjustedUV, 0.0);
        float _x1 = length(dFdx(uvWorld));
        float _y1 = length(dFdy(uvWorld));
        float _x2 = length(dFdx(passViewPos.xyz));
        float _y2 = length(dFdy(passViewPos.xyz));
        float _d = length(vec2(_x2, _y2))/length(vec2(_x1, _y1));
        
        vec3 _offs = vec3(offset.x, -offset.y, 0.0) * _d;
        _offs = normalToViewMatrix * _offs;
        shadowing = unshadowedLightRatioOffset(adjustedDepth, _offs);
    #else
        shadowing = unshadowedLightRatio(adjustedDepth);
    #endif
    }

// ... in shadow fragment shader, make a `float unshadowedLightRatioOffset(float distance, vec3 coord_offset)` that does:
vec4 offs = shadowSpaceMatrix@shadow_texture_unit_index * vec4(coord_offset, 0.0);
// ... use as
shadowSpaceCoords@shadow_texture_unit_index + offs
