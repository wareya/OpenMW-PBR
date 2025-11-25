// note: you must also look at _snippet_parallax.glsl -- this is incomplete without changes to other files

#ifndef LIB_MATERIAL_PARALLAX
#define LIB_MATERIAL_PARALLAX

#define PARALLAX_SCALE 0.04
#define PARALLAX_BIAS -(PARALLAX_SCALE*0.5)

#define POM_MODE_BASIC 0
#define POM_MODE_EXT1 1 // as-is normal and bi/tangent
#define POM_MODE_EXT2 2 // force bi/tangent to be exactly perpendicular to normal (not each other)
#define POM_MODE_EXT3 3 // force normal to be perpendicular to triangle (instead of vertex)

#define POM_MODE POM_MODE_EXT2

float det(mat2 matrix)
{
    return matrix[0].x * matrix[1].y - matrix[0].y * matrix[1].x;
}

mat3 inverse(mat3 matrix)
{
    vec3 row0 = matrix[0];
    vec3 row1 = matrix[1];
    vec3 row2 = matrix[2];

    vec3 minors0 = vec3(
        det(mat2(row1.y, row1.z, row2.y, row2.z)),
        det(mat2(row1.z, row1.x, row2.z, row2.x)),
        det(mat2(row1.x, row1.y, row2.x, row2.y))
    );
    vec3 minors1 = vec3(
        det(mat2(row2.y, row2.z, row0.y, row0.z)),
        det(mat2(row2.z, row2.x, row0.z, row0.x)),
        det(mat2(row2.x, row2.y, row0.x, row0.y))
    );
    vec3 minors2 = vec3(
        det(mat2(row0.y, row0.z, row1.y, row1.z)),
        det(mat2(row0.z, row0.x, row1.z, row1.x)),
        det(mat2(row0.x, row0.y, row1.x, row1.y))
    );

    return transpose(mat3(minors0, minors1, minors2)) / dot(row0, minors0);
}

mat3 calculateTBN(vec3 N, vec3 fragPos, vec2 uv, int mode)
{
    vec3 dpdx = dFdx(fragPos);
    vec3 dpdy = dFdy(fragPos);

    if (mode == POM_MODE_EXT3)
    {
        // optional: use triangle normal instead of vertex normal
        N = normalize(cross(dpdx, dpdy));
    }
    
    vec2 duvdx = dFdx(uv);
    vec2 duvdy = dFdy(uv);
    
    float determinant = duvdx.x * duvdy.y - duvdx.y * duvdy.x;
    if (determinant == 0.0) determinant = 0.00001;
    float invDet = 1.0 / determinant;
    
    vec3 T = (dpdx * duvdy.y - dpdy * duvdx.y) * invDet;
    vec3 B = (dpdy * duvdx.x - dpdx * duvdy.x) * invDet;
    
    if (mode == POM_MODE_EXT2)
    {
        // optional: force T and B to be perpendicular to N (not to each other). reduces seams.
        float T_len = length(T);
        float B_len = length(B);
        vec3 T_temp = normalize(cross(N, T));
        vec3 B_temp = normalize(cross(N, B));
        T = -normalize(cross(N, T_temp)) * T_len;
        B = -normalize(cross(N, B_temp)) * B_len;
    }
    
    float x = 1.0 / (min(length(T), length(B)) + 0.00001);
    // or:
    //float x = 1.0 / (sqrt(length(T) * length(B)) + 0.00001);
    
    // if the scaled matrix is going to be numerically unstable: don't.
    if (x < 0.00001)
    {
        // unstable if scaled, do not scale
    }
    else
    {
        T *= x;
        B *= x;
    }
    
    return mat3(T, -B, normalize(N));
}

vec3 parallaxOcclusionScan(sampler2D refTexture, vec2 uv, vec3 eyeTexSpace, mat3 normalToViewMatrix)
{
#if POM_MODE != POM_MODE_BASIC
    mat3 asdf;
    asdf = inverse(calculateTBN(normalize(gl_NormalMatrix * passNormal), passViewPos, uv, POM_MODE));
    eyeTexSpace = asdf * normalize(-passViewPos);
#endif
    
    vec3 newEyeTexSpace = eyeTexSpace * vec3(-PARALLAX_SCALE, PARALLAX_SCALE, -1.0);
    // we need to limit this to a sane pitch, or else near-tangent views get horribly distorted
    if (newEyeTexSpace.z > -0.15) newEyeTexSpace.z = -0.15;
    
    // increase the range of the raymarch at tangential angles, instead of clipping the height/depth effect
    newEyeTexSpace /= abs(newEyeTexSpace.z);
    
    float _scale_offs = -PARALLAX_BIAS/PARALLAX_SCALE;
    
    vec3 coord3d_origin = vec3(uv, _scale_offs) - newEyeTexSpace * (1.0 - _scale_offs);
    vec3 coord3d        = vec3(uv, _scale_offs) + newEyeTexSpace * _scale_offs;
    
    // multipass approach
    float passes = 3.0;
    float h_iter = 16.0;
    float i = 1.0;
    vec3 expected_3d = coord3d_origin;
    
    float h_iter_loop = 1.0 / h_iter;
    for (float j = 0; j < passes; j += 1.0)
    {
        float prev_height = 0.0;
        for (; i <= h_iter; i += h_iter * h_iter_loop)
        {
            float t = i / h_iter;
            expected_3d = mix(coord3d_origin, coord3d, t);
            float probe_height = texture2DLod(refTexture, expected_3d.xy, 0.0).a;
            //float probe_height = texture2D(refTexture, expected_3d.xy).a;
            if (probe_height > expected_3d.z)
            {
                if (j + 1 == passes)
                {
                    // linear contact estimation
                    float prev_3d_z = mix(coord3d_origin, coord3d, t - h_iter_loop).z;
                    float a = prev_3d_z - prev_height;
                    float b = probe_height - expected_3d.z;
                    
                    expected_3d = mix(coord3d_origin, coord3d, t - (b/(abs(a+b)+0.0001)) * h_iter_loop);
                }
                break;
            }
            prev_height = probe_height;
        }
        i -= h_iter * h_iter_loop;
        h_iter_loop /= h_iter;
    }
    
    //return vec3(uv, 0.0);
    return expected_3d;
}

vec3 getParallaxShadowOffset(vec2 offset, vec2 uv, mat3 TBN)
{
    // for the shadow offset we need to modify the coordinates exactly coplanar,
    // so we need to use a triangle-derived TBN
    TBN = calculateTBN(normalize(gl_NormalMatrix * passNormal), passViewPos, uv, POM_MODE_EXT3);
    
    vec3 uvWorld = TBN * vec3(uv, 0.0);
    float _dx = length(dFdx(passViewPos.xyz)) / (length(dFdx(uvWorld)) + 0.00000001);
    float _dy = length(dFdy(passViewPos.xyz)) / (length(dFdy(uvWorld)) + 0.00000001);
    
    vec3 _offs = vec3(offset.x * _dx, -offset.y * _dy, 0.0);
    return TBN * _offs;
}

vec2 getParallaxOffset(vec3 eyeDir, float height)
{
    return vec2(eyeDir.x, -eyeDir.y) * ( height * PARALLAX_SCALE + PARALLAX_BIAS );
}

#endif
