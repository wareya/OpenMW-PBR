#if PER_PIXEL_LIGHTING

/////////
/////////
// IF YOUR TEXTURES LOOK REALLY SHINY FOR NO REASON, YOU PROBABLY NEED TO CHANGE THIS TO 1
// whether pbr specularity materials have inverted roughness or not
#define PBR_MAT_ROUGHNESS_INVERTED 0
/////////
/////////

/////////
/////////
// IF YOUR TEXTURES LOOK TOTALLY BLACK FOR NO REASON, YOU PROBABLY NEED TO CHANGE THIS TO 1
// whether some of your PBR materials have broken (inverted or fully black) AO channels. negatively affects AO, only use if necessary.
#define PBR_IM_USING_BROKEN_AO_MAPS_PLS_TRASH_THEM_KTHX 0
/////////
/////////

// PERFORMANCE HACKS: switch from 0 to 1 to enable
#define PBR_HIGHPERF 0

#if PBR_HIGHPERF
#define PBR_GAMMA_DEFAULT 2.0
#define PBR_RANGEMUL_DEFAULT 1.0
#define PBR_ACP_DEFAULT 0
#define PBR_AAO_DEFAULT 0
#define PBR_SHITTYBRDF 1
#define PBR_FALLOFF_NO_COMPENSATION 1
#define PBR_AUTO_ROUGHNESS_BASIC 1
#define PBR_ENV_AMBIENT_DEFAULT 0
#define PBR_SPECULAR_AO_HACK_DEFAULT 0
#define PBR_NO_AMBENVGUESS_DEFAULT 1
#define PBR_EDGE_NORMAL_HACK_DEFAULT 0
#else
#define PBR_GAMMA_DEFAULT 2.2
#define PBR_RANGEMUL_DEFAULT 2.0
#define PBR_ACP_DEFAULT 0
#define PBR_AAO_DEFAULT 1
#define PBR_SHITTYBRDF 0
#define PBR_FALLOFF_NO_COMPENSATION 0
#define PBR_AUTO_ROUGHNESS_BASIC 0
#define PBR_ENV_AMBIENT_DEFAULT 1
#define PBR_SPECULAR_AO_HACK_DEFAULT 1
#define PBR_NO_AMBENVGUESS_DEFAULT 0
#define PBR_EDGE_NORMAL_HACK_DEFAULT 1
#endif

// bypass all PBR logic and use vanilla shading
#define PBR_BYPASS 0

// default 2.2, approximation of the sRGB gamma curve
// set to 2.0 for a small performance boost but slightly less accurate lights
#define PBR_GAMMA PBR_GAMMA_DEFAULT
// THIS IS NOT A SCREEN GAMMA ADJUSTMENT. IT DOES NOT MAKE THE SCREEN OVERALL BRIGHTER/DARKER.

#define DEBUG_SHOW_ROUGHNESS 0
#define DEBUG_SHOW_AO 0

// prevent roughness from being less than this amount (reduces speckling on bad textures)
#define PBR_MAT_ROUGHNESS_FLOOR 0.01

// #define NORMAL_RECONSTRUCT_Z 0
// NO LONGER SUPPORTED: this is now an openmw option

// use diffuse UVs for specmaps (allow parallax on specmaps)
#define SPECMAP_USE_DIFFUSE_UV 1

#define PI 3.141592653589793
// whether to do PBR with the PBR-capable lighting system or not
// (a value of 0 is only useful for doing debug comparisons with PBR_BYPASS 1)
#define DO_PBR 1

// use a PBR specular BRDF function inspired by godot's instead of learnopengl's
// it's meaningfully faster, and is closer to what people will see with PBR in other games
#define PBR_GODOT_BRDF 1
// use a PBR specular BRDF function defined by the GLTF2 spec
// note: it is SLOW. only provided for debugging.
// note: PBR_HIGHPERF disables this flag even if this flag is enabled.
#define PBR_GLTF2_BRDF 0
// if the above two are both 0, then a BRDF inspired by learnopengl's PBR series will be used

// interpret vertex color as shadowing instead of diffuse for sun or indoors
// the main use of vertex colors in MW assets is as a GI approximation
// this hack makes vertex colors affect light instead of diffuse
// without this hack, the terrain in places like caldera looks ugly
#define PBR_VERTEX_COLOR_HACK 1
// alternative to the above: make vertex colors half as strong instead (you can use both hacks at once)
#define PBR_VERTEX_COLOR_HACK_ALT 0
// how to interpret color texture to automatically generate roughness
#define PBR_AUTO_ROUGHNESS_MIN 0.35
#define PBR_AUTO_ROUGHNESS_MAX 0.9
// enable or disable PBR specularity entirely (recommended: 0 / (enabled); good specularity is the main aspect of PBR rendering)
#define PBR_NO_SPECULAR 0

// whether to use specular math for non-metallic ambience
// (metallic ambience always uses specular math)
// looks bad because vanilla models have bad vertex normals + the ambient environment map estimation is bad
#define PBR_SPECULAR_AMBIENT 0
// similar but for the diffuse term. looks good enough to enable by default.
#define PBR_ENV_AMBIENT PBR_ENV_AMBIENT_DEFAULT
// disable the "horizon line" ambient environment guess
#define PBR_NO_AMBIENT_ENV_GUESS PBR_NO_AMBENVGUESS_DEFAULT
// for ambience only, darken the f90 component of metallic specularity based on the diffuse texture
// this is physically incorrect, but makes physically impossible assets (e.g. dark metals) designed for dark interiors look less strange against ambient lighting
#define PBR_METAL_F90_DARKENING_HACK 1

// whether to guess an AO value or not (simple clamped offset brightness calculation)
#define PBR_AUTO_AO PBR_AAO_DEFAULT
// make ao affect specularity
// this is physically wrong, but doing it looks better with non-PBR materials than not doing it
#define PBR_SPECULAR_AO_HACK PBR_SPECULAR_AO_HACK_DEFAULT

// bias normals away from edges when doing specular enegy compensation
#define PBR_EDGE_NORMAL_HACK PBR_EDGE_NORMAL_HACK_DEFAULT

// assume color values are always positive, including lights.
// this is wrong, but makes things faster.
#define PBR_ASSUME_COLORS_POSITIVE PBR_ACP_DEFAULT

// how many units away from the light is considered "standard" falloff
// used to estimate how bright it should be in quadratic falloff
// note: specularity always uses quadratic falloff
#define PBR_FALLOFF_REF_DISTANCE 70.0
// general boost for quadratic falloff
#define PBR_QUADRATIC_BOOST 1.0
// force quadratic light falloff (only looks right with gamma values near 2.2)
#define PBR_FORCE_QUADRATIC_FALLOFF 0
// prevent quadratic light from being infinite at zero distance
#define PBR_FORCE_QUADRATIC_FALLOFF_CONSTANT 4.0
// whether to reinterpret falloff as being gamma-compressed (recommended: on)
#define PBR_COMPRESSED_FALLOFF 1
// match with the light bounding sphere setting under your video options, or lower for better performance
// WARNING: affects performance a LOT. set to 1.0 for a performance boost
#define PBR_LIGHT_BOUNDING_SPHERE_MULTIPLIER 1.0
// for groundcover (lower because expensive)
// WARNING: affects performance a LOT.
#define PBR_LIGHT_BOUNDING_SPHERE_MULTIPLIER_GROUNDCOVER 1.0

// similar to above, but only affects the part of a light pointing towards the camera, and never affects groundcover
#define PBR_LIGHT_BOUNDING_SPHERE_MULTIPLIER_TOWARDS_CAMERA PBR_RANGEMUL_DEFAULT

// for debugging. we use lambert because it's cheaper and looks better with non-PBR-intended assets.
#define PBR_DIFFUSE_BURLEY 0
// slightly faster approximation. performance half-ish way between lambret and burley?
#define PBR_DIFFUSE_BURLEY_APPROX 0

// same, but for oren-nayar instead of burley
#define PBR_DIFFUSE_OREN_NAYAR 0
#define PBR_DIFFUSE_OREN_NAYAR_APPROX 0
// brighten the ON luminance function slightly to compensate for non-PBR textures having roughness-darkened albedos
#define PBR_DIFFUSE_OREN_NAYAR_ALBEDO_COMPENSATION 1.1

#if DO_PBR && !PBR_BYPASS
#define GAMMA PBR_GAMMA
#else
#define GAMMA 1.0
#endif

#if DO_PBR && !PBR_BYPASS
#define LIGHT_STRENGTH_POINT 2.4
#define LIGHT_STRENGTH_POINT_SPECULAR 0.5
#define LIGHT_STRENGTH_SUN 2.4
#define LIGHT_STRENGTH_SUN_SPECULAR 0.5
#define LIGHT_STRENGTH_AMBIENT 1.0
#else
#define LIGHT_STRENGTH_POINT 1.0
#define LIGHT_STRENGTH_POINT_SPECULAR 1.0
#define LIGHT_STRENGTH_SUN 1.0
#define LIGHT_STRENGTH_SUN_SPECULAR 1.0
#define LIGHT_STRENGTH_AMBIENT 1.0
#endif

float lcalcCutoff_pbr(int lightIndex, float lightDistance)
{
    return 1.0 - quickstep((lightDistance / lcalcRadius(lightIndex)) - 1.0);
}
float lcalcIlluminationNoCutoff_pbr(int lightIndex, float dist)
{
    float illumination = 1.0 / (lcalcConstantAttenuation(lightIndex) + lcalcLinearAttenuation(lightIndex) * dist + lcalcQuadraticAttenuation(lightIndex) * dist * dist);
    return illumination;
}

float fresnelFactorSchlick(float incidence)
{
    float t = clamp(1.0 - incidence, 0.0, 1.0);
    float t2 = t*t;
    float t5 = t2*t2*t;
    return t5;
}
vec3 fresnelSchlick(float incidence, vec3 f0, vec3 f90)
{
    return mix(f0, f90, fresnelFactorSchlick(incidence));
}
float distGGX(float halfIncidence, float r)
{
    float r2 = r*r;
    
    float d = halfIncidence*halfIncidence * (r2 - 1.0) + 1.0;
    
    return r2 / (d * d * PI);
}
float distGGXApprox(float halfIncidence, float r)
{
    float r2 = r*r;
    return (r*0.5)/(1.0001-halfIncidence+r2*r2);
    //return r/(1.0-halfIncidence*halfIncidence+r*r);
}
float geoSchlickGGX(float incidence, float k)
{
    //return 1.0 / (incidence * (1.0 - k) + k);
    //return incidence / (incidence * (1.0 - k) + k);
    incidence += 0.00004;
    return incidence / mix(incidence, 1.0, k);
}
float geoSmithApprox(float viewIncidence, float lightInsolation, float r)
{
    float k = r + 1.0;
    float j = viewIncidence * lightInsolation;
    //j = 1.0 - j;
    //j *= j;
    //j = 1.0 - j;
    return j * 3.0 / k;
}
float geoSmith(float viewIncidence, float lightInsolation, float r)
{
    r += 1.0;
    float k = (r * r) * (1.0/8.0);
    return geoSchlickGGX(viewIncidence, k) * geoSchlickGGX(lightInsolation, k);
}

// faithful adaptation of the math in the GLTF2 spec
float geoSmithGLTFDenom(float incidence, float roughness)
{
    float a2 = roughness*roughness;
    return abs(incidence) * (2.0 / (abs(incidence) + sqrt(a2 + (1.0-a2)*(incidence*incidence))));
}
float geoSmithGLTF(vec3 normalDir, vec3 viewDir, vec3 lightDir, vec3 halfDir, float roughness)
{
    float halfIncidence  = (dot(normalDir,  halfDir));
    float lightInsolation = (dot(normalDir, lightDir));
    float viewIncidence  = (dot(normalDir,  viewDir));
    float halfLight      = (dot(lightDir ,  halfDir));
    float halfView       = (dot(viewDir  ,  halfDir));
    
    float a = halfLight > 0.0 ? geoSmithGLTFDenom(lightInsolation, roughness) : 0.0;
    float b = halfView > 0.0 ? geoSmithGLTFDenom(viewIncidence, roughness) : 0.0;
    
    return (a * b) / (4.0 * abs(lightInsolation) * abs(viewIncidence));
}

// godot-style
float geoGGX(float viewIncidence, float lightInsolation, float r)
{
    float j = viewIncidence * lightInsolation;
    float i = viewIncidence + lightInsolation;
    return 0.5 / (mix(2.0 * j, i, r) + 0.1);
}

float Burley(vec3 lightDir, vec3 normalDir, vec3 viewDir, vec3 halfDir, float lightInsolation, float roughness)
{
    #if PBR_DIFFUSE_BURLEY_APPROX
    // performance hack
    float halfNormal = max(dot(normalDir, halfDir), 0.0);
    float j = 1.0 - halfNormal;
    float Fd = 1.0 + roughness*1.2*(j*j*(j*j));
    return Fd * Fd * lightInsolation;
    #else
    // real burley
    float halfLight = max(dot(lightDir, halfDir), 0.0);
    float FD90_minus_1 = 2.0 * halfLight * halfLight * roughness - 0.5;
    float halfView = max(dot(viewDir, halfDir), 0.0);
    float viewIncidence = max(dot(normalDir, viewDir), 0.0);
    float FdV = 1.0 + FD90_minus_1 * fresnelFactorSchlick(viewIncidence);
    float FdL = 1.0 + FD90_minus_1 * fresnelFactorSchlick(lightInsolation);
    return FdV * FdL * lightInsolation;
    #endif
}

vec3 project(vec3 u, vec3 v)
{
    return dot(u, v) / dot(v, v) * v;
}
vec3 reject(vec3 u, vec3 v)
{
    return u - project(u, v);
}

vec3 OrenNayarNotrig(vec3 albedo, vec3 l, vec3 n, vec3 v, vec3 h, float lambert, float r)
{
    // This particular function is CC0 (public domain), and there are no patents on it.
    // It is not based on any other shader. It is based on the original Oren-Nayar paper.
    if (lambert <= 0.0) return vec3(0.0);
    
    float r2 = r*r;
    
    // big: polar
    // small: azimuthal
    
    vec3 l_pn = normalize(reject(l, n)); // sqrts: 1
    vec3 v_pn = normalize(reject(v, n)); // sqrts: 2
    float cos_small_ir_delta = dot(l_pn, v_pn);
    
    float cos_big_i = dot(l, n);
    float cos_big_r = dot(v, n);
    cos_big_r = abs(cos_big_r); // some fragment normals face "into" the screen
    
    float cos_alpha = min(cos_big_r, cos_big_i);
    float cos_beta = max(cos_big_r, cos_big_i);
    
    float sin_alpha = sqrt(1.0 - cos_alpha*cos_alpha); // sqrts: 3
    float sin_beta = sqrt(1.0 - cos_beta*cos_beta); // sqrts: 4
    float tan_beta = sin_beta/cos_beta;
    
    //float beta_approx = (PI/2.0)*(1.0-cos_beta); // WORSE visual result than the following. for some reason.
    //float alpha_approx = (PI/2.0)*(1.0-cos_alpha); // WORSE visual result than the following. for some reason.
    
    float beta_approx = (PI/2.0)-cos_beta; // lol. lmao. i mean it works, but...
    float alpha_approx = (PI/2.0)-cos_alpha; // lol. lmao i mean it works, but...
    // more accurate approximation, but seemingly visually identical in my tests to the above:
    //float beta_approx = (PI/2.0)-cos_beta-(cos_beta*cos_beta*cos_beta*(PI/6.0));
    //float alpha_approx = (PI/2.0)-cos_alpha-(cos_alpha*cos_alpha*cos_alpha*(PI/6.0));
    
    float c1 = 1.0 - 0.5*(r2 / (r2 + 0.33));
    
    float twobeta_over_pi = (2.0 * beta_approx / PI);
    float _adjust = (cos_small_ir_delta >= 0.0) ? 0.0 : twobeta_over_pi;
    float c2 = 0.45 * (r2/(r2+0.09)) * (sin_alpha - _adjust*_adjust*_adjust);
    
    float _temp = 4.0 * alpha_approx * beta_approx / (PI*PI);
    float c3 = 0.125 * (r2/(r2+0.09)) * _temp*_temp;
    
    float cos_avg_approx = (cos_beta + cos_alpha)*0.5;
    float sin_avg_approx = (sin_beta + sin_alpha)*0.5;
    float tan_avg_approx = sin_avg_approx / cos_avg_approx;
    
    float l1 = lambert * (
        c1 +
        cos_small_ir_delta * c2 * tan_beta +
        (1.0 - abs(cos_small_ir_delta)) * c3 * tan_avg_approx +
        0.0)
    ;
    
    // squaringness of albedo comes from how the output of this function is used (it's factored out)
    vec3 l2 = 0.17 * albedo * lambert * (r2/(r2+0.13)) * (1.0 - cos_small_ir_delta * twobeta_over_pi*twobeta_over_pi);
    
    return vec3(l1) + l2;
    // four total sqrts
}

vec3 OrenNayarApprox(vec3 albedo, vec3 lightDir, vec3 normalDir, vec3 viewDir, vec3 halfDir, float lightInsolation, float roughness)
{
    if (lightInsolation < 0.0) return vec3(0.0);
    
    float c1 = 0.625;
    
    float fake_c2 = dot(reject(lightDir, normalDir), reject(viewDir, normalDir))*0.4;
    float fake_tan = 1.0/max(dot(halfDir, normalDir), 0.2);
    return vec3(mix(lightInsolation, lightInsolation * (
        c1 +
        fake_c2 * fake_tan +
        0.0
    ), roughness));
}

float BRDF(vec3 normalDir, vec3 viewDir, vec3 lightDir, vec3 halfDir, float roughness)
{
    float lightInsolation = max(dot(normalDir, lightDir), 0.0);
    if (lightInsolation <= 0.0)
        return 0.0;
    
    float halfIncidence  = max(dot(normalDir,  halfDir), 0.0);
    float viewIncidence  = max(dot(normalDir,  viewDir), 0.0);
    float halfLight      = max(dot(lightDir ,  halfDir), 0.0);
    float halfView       = max(dot(viewDir  ,  halfDir), 0.0);
    
#if PBR_SHITTYBRDF
    float NDF = distGGXApprox(halfIncidence, roughness);
    float geo = geoGGX(lightInsolation, viewIncidence, roughness) * 0.5;
#else
    float NDF = distGGX(halfIncidence, roughness);
    float geo = geoSmith(viewIncidence, lightInsolation, roughness);
    geo = geo / (4.0 * viewIncidence * lightInsolation + 0.0001);
#endif
    
#if PBR_GODOT_BRDF && !PBR_SHITTYBRDF
    geo = geoGGX(lightInsolation, viewIncidence, roughness);
#endif

#if PBR_GLTF2_BRDF && !PBR_HIGHPERF
    geo = geoSmithGLTF(normalDir, viewDir, lightDir, halfDir, roughness);
#endif
    
    return NDF * geo;
}

vec3 fast_sign(vec3 x)
{
    return vec3(
        x.x >= 0.0 ? 1.0 : -1.0,
        x.y >= 0.0 ? 1.0 : -1.0,
        x.z >= 0.0 ? 1.0 : -1.0
    );
}

vec3 to_linear(vec3 color)
{
#if PBR_ASSUME_COLORS_POSITIVE
    if (GAMMA == 2.0)
        return color*color;
#endif
    if (GAMMA == 2.0)
        return color*abs(color);
    if (GAMMA == 1.0)
        return color;
#if PBR_ASSUME_COLORS_POSITIVE
    return fast_sign(color) * pow(max(vec3(0.0), color), vec3(GAMMA));
#else
    return fast_sign(color) * pow(abs(color), vec3(GAMMA));
#endif
}
vec3 to_srgb(vec3 color)
{
    if (GAMMA == 2.0)
        return sqrt(color);
    if (GAMMA == 1.0)
        return color;
    return pow(max(vec3(0.0), color), vec3(1.0/GAMMA));
}

vec3 perLightPBR(float alpha, vec3 diffuseColor, vec3 diffuseVertexColor, vec3 ambientColor, vec3 shadowing, vec3 normal, vec3 viewDir, vec3 lightDir, float lightDistance, float radius, float falloff, float standard_falloff, float cutoff, vec3 ambientLightColor, vec3 lightColor, float metallicity, float roughness, float ao, vec3 f0, vec3 f90, bool indoors, inout vec3 ambientBias)
{
    vec3 light = vec3(0.0);

    vec3 normalDir = normal;
    vec3 halfDir = normalize(viewDir + lightDir);
    
    float lightInsolation = dot(normalDir, lightDir);
    float baseIncidence = lightInsolation;
    
    // FIXME: what was this originally for?
    if (dot(lightColor, vec3(1.0)) < 0.0)
        ambientBias += lightColor * max(0.0, baseIncidence) * falloff;
    
    ambientLightColor = max(ambientLightColor, vec3(0.0));
    lightColor = max(lightColor, vec3(0.0));
    falloff = max(falloff, 0.0);
    
    light += diffuseColor * ambientColor * falloff * ao * ambientLightColor;
    
#if PBR_VERTEX_COLOR_HACK && DO_PBR
    // the main use of vertex colors in MW assets is as a GI approximation, so make it affect light instead of diffuse
    // (otherwise darkened areas get a weird haze)
    // (also, do it if this light is the sun OR we're indoors)
    if (radius < 0.0 || indoors)
    {
        lightColor *= diffuseVertexColor;
    }
    else
#endif
    {
        diffuseColor *= diffuseVertexColor;
    }
    
#if !PBR_NO_SPECULAR
    vec3 fresnel = fresnelSchlick(max(dot(halfDir, viewDir), 0.0), f0, f90);
    float specular = BRDF(normalDir, viewDir, lightDir, halfDir, roughness);
#else
    vec3 fresnel = 0.0;
    float specular = 0.0;
#endif
    
#ifndef GROUNDCOVER
    baseIncidence = max(baseIncidence, 0.0);
#else
    float eyeCosine = dot(-viewDir, normalDir);
    if (baseIncidence < 0.0)
    {
        baseIncidence = -baseIncidence;
        eyeCosine = -eyeCosine;
    }
    baseIncidence *= clamp(-8.0 * (1.0 - 0.3) * eyeCosine + 1.0, 0.3, 1.0);
#endif
    
    if (baseIncidence == 0.0)
        return light;
    
    float adjust = baseIncidence;
    #if PBR_EDGE_NORMAL_HACK
        // reduce specularity by incidence against plane normal to conserve energy
        adjust = clamp((adjust-0.07)*4.0, 0.0, adjust);
    #endif
    specular *= adjust;

#if DO_PBR
    vec3 lambert = vec3(baseIncidence * (falloff * (1.0/PI)));
    
    #if PBR_DIFFUSE_BURLEY || PBR_DIFFUSE_BURLEY_APPROX
    lambert = vec3(Burley(lightDir, normalDir, viewDir, halfDir, baseIncidence, roughness) * (falloff * (1.0/PI)));
    #endif
    #if PBR_DIFFUSE_OREN_NAYAR
    lambert = OrenNayarNotrig(diffuseColor, lightDir, normalDir, viewDir, halfDir, baseIncidence, roughness*roughness)
        * (falloff * (1.0/PI)) * PBR_DIFFUSE_OREN_NAYAR_ALBEDO_COMPENSATION;
    #endif
    #if PBR_DIFFUSE_OREN_NAYAR_APPROX
    lambert = OrenNayarApprox(diffuseColor, lightDir, normalDir, viewDir, halfDir, baseIncidence, roughness*roughness)
        * (falloff * (1.0/PI)) * PBR_DIFFUSE_OREN_NAYAR_ALBEDO_COMPENSATION;
    #endif
    
    vec3 diff = diffuseColor * lambert  * (lightColor * shadowing) * (1.0 - fresnel) * (1.0 - metallicity);
    vec3 spec = vec3(1.0)    * specular * (lightColor * shadowing) * fresnel;
    // the specular term was already divided by pi in the BRDF function (distGGX specifically)
    // likewise, metallicity was taken into account when calculating the f0 component for specularity
    
    if (radius >= 0.0)
    {
        //spec *= falloff;
        
        // always use quadratic falloff for specularity
        float ref_falloff = clamp(1.0/(PBR_FALLOFF_REF_DISTANCE * PBR_FALLOFF_REF_DISTANCE), 0.0, 1.0);
        float falloff_mod = standard_falloff*(1.0/ref_falloff);

#if PBR_FALLOFF_NO_COMPENSATION
        // Chosen to make highperf mode look more like normal mode.
        falloff_mod = 2000.0;
#endif
        
        falloff_mod *= mix(LIGHT_STRENGTH_POINT_SPECULAR, 1.0, metallicity);
        
        // fade out at end of bounding radius
        falloff_mod *= min(1.0, cutoff*2.0);
        
        spec *= falloff_mod/(lightDistance * lightDistance);
    }
    else
    {
        spec *= mix(LIGHT_STRENGTH_SUN_SPECULAR, 1.0, metallicity);
    }
    #if PBR_SPECULAR_AO_HACK
    spec = mix(spec, spec*ao, 1.0-lightInsolation*lightInsolation);
    #endif
    // now apply lighting
    light += diff;
    light += spec;
#else
    float lambert = baseIncidence * falloff;
    light += diffuseColor * lambert * (lightColor * shadowing);
#endif
    return light;
}

uniform mat4 osg_ViewMatrixInverse;

// replace ambient with a quasi horizon-and-sky-and-ground reflection
vec3 ambientGuess(float height, vec3 ambientTerm, float roughness)
{
#if PBR_NO_AMBIENT_ENV_GUESS || !DO_PBR
    return ambientTerm;
#endif
    //float t = clamp(height/(roughness*roughness + 0.01), -1.0, 1.0);
    float t = clamp(height/(roughness + 0.01), -1.0, 1.0);
    t = mix(t, 0.0, clamp(roughness*2.0-1.0, 0.0, 1.0));
    float gradient = mix(mix(0.2, 1.8, height*0.5+0.5), 1.0, roughness);
    return mix(ambientTerm*(0.3 + roughness * 0.2), ambientTerm*1.5, t*0.5+0.5) * gradient;
}

vec3 perAmbientPBR(vec3 diffuseColor, vec3 ambientColor, vec3 ambientBias, vec3 ambientAdjust, float ao, float metallicity, float roughness, vec3 normal, vec3 viewDir, vec3 f0, vec3 f90)
{
    vec3 light = vec3(0.0);
    
    vec3 origAmbientTerm = max(ambientColor + ambientBias, vec3(0.0));
    
    vec3 reflection = reflect(-viewDir, normal);
    vec3 reflectionWorld = (osg_ViewMatrixInverse * vec4(reflection, 0.0)).xyz;
    vec3 ambientTerm = origAmbientTerm;
    
    vec3 ambientDiffuseTerm = ambientTerm;
    
#if PBR_ENV_AMBIENT
    vec3 nworld = (osg_ViewMatrixInverse * vec4(normal, 0.0)).xyz;
    ambientDiffuseTerm = ambientGuess(nworld.z, ambientDiffuseTerm, 0.7);
#endif
    
#if !PBR_SPECULAR_AMBIENT || !DO_PBR
    light += diffuseColor * ambientAdjust * ambientDiffuseTerm * ao * (1.0 - metallicity);
#endif

#if DO_PBR
    vec3 ambientTermOrig = ambientTerm;
    ambientTerm = ambientGuess(reflectionWorld.z, ambientTerm, roughness);
    
    // FIXME: HACK: evil, physically meaningless: ambient metallic specularity guesstimate
    // HERE BE DRAGONS
#if !PBR_SPECULAR_AMBIENT
    if (metallicity > 0.0)
#endif
    {
        // FIXME: HACK: if ambientColor is exactly black, make it light grey first
        // this fixes metallic armor in the inventory character preview
        if (ambientAdjust == vec3(0.0))
        {
            ambientAdjust = vec3(0.5);
            // FIXME: HACK: inventory preview is rendered in the same space as the world, so the normals are pointing in the wrong direction
            // so, make the fake horizon only happen if we don't think this is the inventory character preview
            ambientTerm = origAmbientTerm;
        }
        
        float vdot = max(dot(normal, viewDir), 0.0);
        float inv_roughness = 1.0 - roughness;
        float inv_roughness_2 = inv_roughness*inv_roughness;
        
        #if !PBR_NO_AMBIENT_ENV_GUESS
        // extremely awful terible estimation of the environmental BRDF, non-hacky seen here:
        // https://google.github.io/filament/Filament.md.html#toc5.3.4.3
        // https://learnopengl.com/PBR/IBL/Specular-IBL
        // red is f0, green is f90
        
        float inv_vdot = max(0.0, 1.0 - vdot*2.0);
        float bad_dfg = inv_roughness_2 * (inv_vdot * inv_vdot);
        float f90_part = bad_dfg;
        float f0_part = mix((1.0 - bad_dfg), 0.5, roughness);
        
        #else
        float inv_vdot = 1.0 - vdot;
        float bad_dfg = inv_roughness_2 * (inv_vdot * inv_vdot);
        float f90_part = bad_dfg * bad_dfg;
        float f0_part = (1.0 - f90_part)*0.8;
        #endif
        
#if PBR_METAL_F90_DARKENING_HACK
        f90 *= sqrt(diffuseColor) * 0.8 + 0.2;
#endif
        
        light += ambientAdjust * ambientTerm * ao * (f0*f0_part + f90*f90_part) * metallicity;
        
#if PBR_SPECULAR_AMBIENT
        light += diffuseColor * ambientAdjust * ambientDiffuseTerm * ao * (1.0 - metallicity) * f0_part;
        
        light += ambientAdjust * ambientTerm * ao * (1.0 - metallicity) * f90_part * LIGHT_STRENGTH_POINT_SPECULAR;
#endif
    }

#endif // DO_PBR
    return light;
}

vec3 doLightingPBR(float alpha, vec3 diffuseColor, vec3 diffuseVertexColor, vec3 ambientColor, vec3 emissiveColor, vec3 specularTint, vec3 viewPos, vec3 normal, float _shadowing, float metallicity, float roughness, float ao, float f0_scalar)
{
#if !DO_PBR
    metallicity = 0.0;
    ao = 1.0;
#endif
    
    diffuseColor = to_linear(diffuseColor);
#if PBR_VERTEX_COLOR_HACK_ALT && DO_PBR
    vec3 oldVC = diffuseVertexColor;
    diffuseVertexColor = mix(diffuseVertexColor, vec3(1.0), 0.33);
    ambientColor *= diffuseVertexColor / (oldVC + vec3(0.01));
#endif
    diffuseVertexColor = to_linear(diffuseVertexColor);
    ambientColor = to_linear(ambientColor);
    emissiveColor = to_linear(emissiveColor);
    
    vec3 viewDir = -normalize(viewPos);
    
    vec3 sunColor = to_linear(lcalcDiffuse(0) * LIGHT_STRENGTH_SUN);
    vec3 ambientAdjust = to_linear(gl_LightModel.ambient.xyz * LIGHT_STRENGTH_AMBIENT);
    
    #if DEBUG_SHOW_ROUGHNESS
        return vec3(roughness);
    #endif
    #if DEBUG_SHOW_AO
        return vec3(ao);
    #endif
    // indoors detection hack
    bool indoors = (osg_ViewMatrixInverse * vec4(normalize(lcalcPosition(0)), 0.0)).y > 0.0;
    
    vec3 f90 = vec3(1.0) + specularTint;
    vec3 f0 = vec3(f0_scalar) * f90;
    
    // should be:
    //f0 = mix(f0, max(f0, diffuseColor), metallicity);
    // but game engines (including godot) usually do:
    //f0 = mix(f0, diffuseColor, metallicity);
    // compromise:
    f0 = mix(f0, max(vec3(0.01), diffuseColor), metallicity);
    
    vec3 ambientBias = vec3(0.0);
    
    vec3 shadowing = vec3(_shadowing);
    //shadowing.r = pow(shadowing.r, 0.7);
    vec3 light = vec3(0.0);
    
    light += perLightPBR(alpha, diffuseColor, diffuseVertexColor, ambientColor, shadowing, normal, viewDir, normalize(lcalcPosition(0)), 1.0, -1.0, 1.0, 1.0, 1.0, vec3(0.0), sunColor, metallicity, roughness, ao, f0, f90, indoors, ambientBias);
    light += diffuseColor * emissiveColor;

    for (int _i = @startLight; _i < @endLight; ++_i)
    {
#if @lightingMethodUBO
        int i = PointLightIndex[_i];
#else
        int i = _i;
#endif
        float radius = lcalcRadius(i);
        vec3 lightPos = lcalcPosition(i) - viewPos;
        float lightDistance = length(lightPos);
        
        vec3 lightDir = normalize(lightPos);
// groundcover is too expensive to give the boosted cutoff
#if DO_PBR
#ifdef GROUNDCOVER
        float cutoff = lcalcCutoff_pbr(i, lightDistance/PBR_LIGHT_BOUNDING_SPHERE_MULTIPLIER_GROUNDCOVER);
#else
        float f_fac = clamp(-dot(lightDir, viewDir), 0.0, 1.0);
        f_fac *= f_fac;
        f_fac = mix(1.0, PBR_LIGHT_BOUNDING_SPHERE_MULTIPLIER_TOWARDS_CAMERA, f_fac);
        f_fac = max(f_fac, PBR_LIGHT_BOUNDING_SPHERE_MULTIPLIER);
        float cutoff = lcalcCutoff_pbr(i, lightDistance/f_fac);
#endif
#else
        float cutoff = lcalcCutoff_pbr(i, lightDistance);
#endif
        
        if (cutoff == 0.0)
            continue;
        
        float legacy_falloff = lcalcIlluminationNoCutoff_pbr(i, lightDistance);
        float standard_falloff = lcalcIlluminationNoCutoff_pbr(i, PBR_FALLOFF_REF_DISTANCE);
#if DO_PBR && PBR_FORCE_QUADRATIC_FALLOFF
        float physical_falloff = 1.0/(PBR_FALLOFF_REF_DISTANCE*PBR_FALLOFF_REF_DISTANCE);
        float constant_part = PBR_FORCE_QUADRATIC_FALLOFF_CONSTANT*PBR_FORCE_QUADRATIC_FALLOFF_CONSTANT;
        float falloff = (PBR_QUADRATIC_BOOST)/(lightDistance*lightDistance + constant_part)*(standard_falloff/physical_falloff);
#else
#if DO_PBR && PBR_COMPRESSED_FALLOFF
        float falloff = to_linear(vec3(legacy_falloff)).r;
#else
        float falloff = legacy_falloff;
#endif
#endif
        falloff *= cutoff;
        
        vec3 ambient = lcalcAmbient(i);
        vec3 diffuse = lcalcDiffuse(i);
        
        ambient = to_linear(ambient);
        vec3 lightColor = to_linear(diffuse * LIGHT_STRENGTH_POINT);
        
        light += perLightPBR(alpha, diffuseColor, diffuseVertexColor, ambientColor, vec3(1.0), normal, viewDir, lightDir, lightDistance, abs(radius) + 0.0001, falloff, standard_falloff, cutoff, ambient, lightColor, metallicity, roughness, ao, f0, f90, indoors, ambientBias);
    }
    
    light += perAmbientPBR(diffuseColor, ambientColor, ambientBias, ambientAdjust, ao, metallicity, roughness, normal, viewDir, f0, f90);
    
    return to_srgb(light);
}

void fakePbrEstimate(inout vec3 color, out float metallicity, out float roughness, out float ao, out float f0_scalar)
{
    metallicity = 0.0;
    float brightness = dot(color, vec3(1.0/3.0));
    #if PBR_AUTO_ROUGHNESS_BASIC
    roughness = mix(PBR_AUTO_ROUGHNESS_MIN, PBR_AUTO_ROUGHNESS_MAX, abs(brightness - 0.5) * 2.0);
    #else
    float color_v = max(0.0, brightness-0.4)*5.0;
    float color_part = color.b*4.0 - 0.5 + color.g*0.5 - color.r*0.25;
    float f = clamp(color_part - color_v, 0.0, 1.0);
    roughness = mix(PBR_AUTO_ROUGHNESS_MAX, PBR_AUTO_ROUGHNESS_MIN, f);
    #endif
    #if PBR_AUTO_AO
    ao = min(1.0, brightness * 2.0 + 0.5);
    //ao = min(1.0, sqrt(brightness) * 0.8 + 0.5);
    color /= ao;
    #else
    ao = 1.0;
    #endif
    f0_scalar = 0.04;
}

void specMapToPBR(vec4 specTex, out float metallicity, out float roughness, out float ao, out float f0_scalar)
{
    metallicity = specTex.r;
    
    #if PBR_MAT_ROUGHNESS_INVERTED
        roughness = 1.0 - specTex.g;
    #else
        roughness = specTex.g;
    #endif
    roughness *= roughness;
    roughness = max(roughness, PBR_MAT_ROUGHNESS_FLOOR);
    
    #if DO_PBR
        ao = specTex.b;
        #if PBR_IM_USING_BROKEN_AO_MAPS_PLS_TRASH_THEM_KTHX
            ao = max(1.0-ao, ao);
        #endif
    #else
        ao = 1.0;
    #endif
    
    f0_scalar = 0.04;
}

#else // PER_PIXEL_LIGHTING
#define PBR_BYPASS 1
#endif // PER_PIXEL_LIGHTING
