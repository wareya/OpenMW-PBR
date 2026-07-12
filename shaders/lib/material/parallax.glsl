#ifndef LIB_MATERIAL_PARALLAX
#define LIB_MATERIAL_PARALLAX

#define PARALLAX_SCALE 0.04
#define PARALLAX_BIAS -(PARALLAX_SCALE*0.5)

#if PBR_POM || PBR_SELF_SHADOW

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

#endif

#if PBR_POM

#define POM_MODE_BASIC 0 // vertex normal and vertex bi/tangent
#define POM_MODE_EXT1 1 // derive bi/tangent from derivative UV info
#define POM_MODE_EXT2 2 // ext1, but force bi/tangent to be exactly perpendicular to normal (not each other)
#define POM_MODE_EXT3 3 // ext1, but force normal to be perpendicular to triangle (instead of vertex)
#define POM_MODE_NONE 10

#ifndef POM_MODE
#define POM_MODE POM_MODE_EXT3
#endif

mat3 calculateTBN(vec3 N, vec3 fragPos, vec2 uv, int mode, mat3 defmat)
{
    vec3 dpdx = dFdx(fragPos);
    vec3 dpdy = dFdy(fragPos);
    vec3 n2 = normalize(cross(dpdx, dpdy));
    if (mode == POM_MODE_EXT3)
    {
        // optional: use triangle normal instead of vertex normal
        N = n2;
    }
    
    vec2 duvdx = dFdx(uv);
    vec2 duvdy = dFdy(uv);
    duvdx += sign(duvdx) * 0.00003;
    duvdy += sign(duvdy) * 0.00003;
    float determinant = duvdx.x * duvdy.y - duvdx.y * duvdy.x;
    //if (abs(sqrt(determinant)) < 0.0001) return defmat;
    //determinant += sign(determinant) * 0.0001;
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
    
    float qs = 1.0 / (min(length(T), length(B)) + 0.00001);
    float vs = 1.0 / (max(length(T), length(B)) + 0.00001);
    // or:
    //float x = 1.0 / (sqrt(length(T) * length(B)) + 0.00001);
    
    // if the scaled matrix is going to be numerically unstable: don't.
    if (qs < 0.0004 || qs > 10000.0)
    {
        // unstable if scaled, do not scale
    }
    else
    {
        T *= qs;
        B *= qs;
    }
    
    mat3 ret = mat3(T, B, normalize(N));
    return ret;
}

vec3 parallaxOcclusionScan(sampler2D refTexture, vec2 uv, vec3 eyeTexSpace, mat3 normalToViewMatrix)
{
    // likely to be glitchy + probably too far away to care about
    if (length(dFdx(uv)) > 0.1 || length(dFdy(uv)) > 0.1) return vec3(uv, 0.0);
    
#if POM_MODE == POM_MODE_NONE
    return vec3(uv, 0.0);
#endif
#if POM_MODE != POM_MODE_BASIC
    mat3 nm = transpose(inverse(mat3(gl_ModelViewMatrix)));
    mat3 realTBN = calculateTBN(normalize(nm * passNormal), passViewPos, uv, POM_MODE, normalToViewMatrix);
    eyeTexSpace = inverse(realTBN) * normalize(-passViewPos);
#else
    eyeTexSpace = inverse(normalToViewMatrix) * normalize(-passViewPos);
#endif

    float scale = PARALLAX_SCALE*0.7;
    
    vec3 newEyeTexSpace = eyeTexSpace * vec3(-scale, scale, -1.0);
    newEyeTexSpace.y = -newEyeTexSpace.y;
    // we need to limit this to a sane pitch, or else near-tangent views get horribly distorted
    if (newEyeTexSpace.z > -0.15) newEyeTexSpace.z = -0.15;
    
    // increase the range of the raymarch at tangential angles, instead of clipping the height/depth effect
    newEyeTexSpace /= abs(newEyeTexSpace.z);
    
    float _scale_offs = -PARALLAX_BIAS/PARALLAX_SCALE;
    
    vec3 coord3d_origin = vec3(uv, _scale_offs) - newEyeTexSpace * (1.0 - _scale_offs);
    vec3 coord3d        = coord3d_origin + newEyeTexSpace;
    
    // multipass approach
    float passes = 3.0;
    float h_iter = 12.0;
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
            #if PBR_POM_NO_TEXTURELOD
            float probe_height = texture2D(refTexture, expected_3d.xy).a;
            #else
            float probe_height = texture2DLod(refTexture, expected_3d.xy, 0.0).a;
            #endif
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
    
    return expected_3d;
}

#if PBR_POM_SHADOW
vec3 getParallaxShadowOffset(vec2 offset, vec2 uv, mat3 TBN)
{
    // for the shadow offset we need to modify the coordinates exactly coplanar,
    // so we need to use a triangle-derived TBN
    mat3 nm = transpose(inverse(mat3(gl_ModelViewMatrix)));
    TBN = calculateTBN(normalize(nm * passNormal), passViewPos, uv, POM_MODE, TBN);
    
    vec3 uvWorld = TBN * vec3(uv, 0.0);
    float _dx = length(dFdx(passViewPos.xyz)) / (length(dFdx(uvWorld)) + 0.00000001);
    float _dy = length(dFdy(passViewPos.xyz)) / (length(dFdy(uvWorld)) + 0.00000001);
    
    vec2 _offs2 = vec2(offset.x * _dx, offset.y * _dy);
    
    vec3 _offs = vec3(_offs2, 0.0);
#if PBR_POM_SHADDOW_ARTIFACT_BODGE != 0
    _offs.z += length(_offs2)*(float(PBR_POM_SHADDOW_ARTIFACT_BODGE) * 0.1);
#endif
    _offs = TBN * _offs;
    return _offs;
}
#endif // PBR_POM_SHADOW

#if PBR_POM_GRAD
void parallaxDerivativeHelper(vec2 adjustedUV, vec2 origAdjustedUV, out vec2 dX, out vec2 dY)
{
    vec2 dA = dFdx(adjustedUV);
    vec2 dB = dFdy(adjustedUV);
    
    // dX = dA * 0.5; // dummy: for debugging
    // dY = dB * 0.5;
    // return;
    
    float l1 = length(dA) + 0.000001;
    float l2 = length(dB) + 0.000001;
    dA /= l1;
    dB /= l2;
    
    float la = length(dFdx(origAdjustedUV));
    float lb = length(dFdy(origAdjustedUV));
    float lx = min(l1, la);
    float ly = min(l2, lb);
    
    dX = dA*lx;
    dY = dB*ly;
}
#endif // PBR_POM_GRAD

#endif // PBR_POM

#if PBR_SELF_SHADOW

struct DirectionalLight {
    vec4 position;
    vec4 diffuse;
    vec4 ambient;
    vec4 specular;
};
uniform DirectionalLight sun;

float selfShadowApprox(float shadowing, sampler2D tx, vec2 uv, mat3 normalToViewMatrix)
{
    // The math here is almost entirely "practical bodge".
    // It has a basis in physical reality, but that basis is paper-thin.
    // Don't try too hard to understand it.
    
    vec3 sun_ld_view = normalize(sun.position.xyz);
    vec3 sun_ld_tan = inverse(normalToViewMatrix) * sun_ld_view;
    // We intentionally use the spherical instead of planar light direction
    //  to limit the light skew angle to ~45 degrees. If we were to not implicitly
    //  have this limit, we would uncomment this line.
    //sun_ld_tan /= sun_ld_tan.z;
    // EDIT: It makes some sense to do a partial version of the spherical-to-planar
    //  transformation, to keep near-perpendicular (do not misread as "near-tangent")
    //  lights from being too shadowed. We reduce _bodge from 0.06 to 0.03 to compensate.
    // Truly near-tangent cases are going to have very dark lambert terms and lots of
    //  normal-mapped "light occlusion", so being mildly inaccurate here is fine.
    sun_ld_tan /= abs(sun_ld_tan.z) + 0.2;
    
    float _strength = 6.0;
    float _bodge = 0.03;
    float _threshold = 0.0;
    #if PBR_POM_NO_TEXTURELOD
    float sun_h_0 = texture2D(tx, uv).a;
    float sun_h_1 = texture2D(tx, uv + sun_ld_tan.xy * _bodge).a;
    #else
    float _lod = 2.0;
    float sun_h_0 = texture2DLod(tx, uv, _lod).a;
    float sun_h_1 = texture2DLod(tx, uv + sun_ld_tan.xy * _bodge, _lod).a;
    #endif
    float _len = length(sun_ld_tan.xy);
    float sun_h_1_expect = sun_h_0 + _len * abs(_bodge*1.1);
    
    if (sun_h_1_expect < sun_h_1) shadowing *= clamp(1.0 - (sun_h_1 - sun_h_1_expect - _threshold) * _strength, 0.0, 1.0);
    return shadowing;
}

#endif // PBR_SELF_SHADOW

vec2 getParallaxOffset(vec3 eyeDir, float height)
{
    return vec2(eyeDir.x, eyeDir.y) * ( height * PARALLAX_SCALE + PARALLAX_BIAS );
}

#endif
