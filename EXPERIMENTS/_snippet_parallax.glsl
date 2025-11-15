
#if @parallax

    vec3 eyeTexSpace = transpose(normalToViewMatrix) * normalize(-passViewPos);
    float height = texture2D(normalMap, adjustedUV).a; // 0 : deep. 1 : surface.
    
    vec2 offset = getParallaxOffset(eyeTexSpace, height);
    
    // START: parallax occlusion
    
    float _norm = 0.7;
    //float _norm = eyeTexSpace.z;
    
    vec3 newEyeTexSpace = eyeTexSpace * vec3(-PARALLAX_SCALE, PARALLAX_SCALE, -1.0);
    newEyeTexSpace.xy *= _norm;
    
    vec3 coord3d_origin = vec3(adjustedUV, 0.0) - newEyeTexSpace * 0.9999;
    
    //vec3 coord3d = vec3(adjustedUV, 0.0);
    vec3 coord3d = coord3d_origin + newEyeTexSpace * (1.0 - height * 0.9) * 0.9999;
    coord3d += (coord3d - coord3d_origin) * 0.9999;
    coord3d += (coord3d - coord3d_origin);
    
    coord3d_origin.z -= PARALLAX_BIAS/PARALLAX_SCALE;
    coord3d.z -= PARALLAX_BIAS/PARALLAX_SCALE;
    
    // two-pass approach
    float h_iter = 5.0;
    float i = 1.0;
    // coarse
    for (; i <= h_iter; i += 1.0)
    {
        float t = i / h_iter;
        vec3 expected_3d = mix(coord3d_origin, coord3d, t);
        float probe_height = texture2D(normalMap, expected_3d.xy).a;
        if (probe_height > expected_3d.z)
            break;
    }
    i -= 1.0;
    // fine
    float plx_end = i + 1.0;
    for (; i < plx_end; i += (1.0 / h_iter))
    {
        float t = i / h_iter;
        vec3 expected_3d = mix(coord3d_origin, coord3d, t);
        float probe_height = texture2D(normalMap, expected_3d.xy).a;
#define ULTRAFINE 1
#if !ULTRAFINE
        if (probe_height > expected_3d.z || i + (1.0 / h_iter) >= plx_end)
#else
        if (probe_height > expected_3d.z)
#endif
        {
            offset = expected_3d.xy - adjustedUV;
            break;
        }
    }
    // ultrafine
#if ULTRAFINE
    i -= 1.0/h_iter;
    plx_end = i + 1.0/h_iter;
    for (; i < plx_end; i += (1.0 / (h_iter*h_iter)))
    {
        float t = i / h_iter;
        vec3 expected_3d = mix(coord3d_origin, coord3d, t);
        float probe_height = texture2D(normalMap, expected_3d.xy).a;
        if (probe_height > expected_3d.z || i + (1.0 / (h_iter*h_iter)) >= plx_end)
        {
            offset = expected_3d.xy - adjustedUV;
            break;
        }
    }
#endif
    
    // END: parallax occlusion
    
    adjustedUV += offset;

#endif
