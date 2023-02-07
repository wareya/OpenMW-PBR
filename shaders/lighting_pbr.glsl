#if PER_PIXEL_LIGHTING

#define DEBUG_SHOW_ROUGHNESS 0

#define PBR_BYPASS 0
#define SPECMAP_USE_DIFFUSE_UV 1

#define PI 3.141592653589793
#define DO_PBR 1

#define PBR_NO_SPECULAR 0
// interpret vertex color as shadowing instead of diffuse for sun or indoors
#define PBR_VERTEX_COLOR_HACK 1
// how to interpret color texture to automatically generate roughness
#define PBR_AUTO_ROUGHNESS_MIN 0.35
#define PBR_AUTO_ROUGHNESS_MAX 1.0
// whether pbr specularoty materials have inverted roughness or not
#define PBR_MAT_ROUGHNESS_INVERTED 0
// how many units away from the light is considered "standard" falloff
// used to estimate how bright it should be in quadratic falloff
// note: specularity always uses quadratic falloff
//#define PBR_FALLOFF_REF_DISTANCE 150.0
//#define PBR_QUADRATIC_BOOST 0.2
#define PBR_FALLOFF_REF_DISTANCE 70.0
#define PBR_QUADRATIC_BOOST 1.0
// force quadratic light falloff
#define PBR_FORCE_QUADRATIC_FALLOFF 0
// prevent quadratic light from being infinite at zero distance
#define PBR_FORCE_QUADRATIC_FALLOFF_CONSTANT 4.0
// whether to reinterpret falloff as being gamma-compressed (recommended: on)
#define PBR_COMPRESSED_FALLOFF 1
// match with the light bounding sphere setting under your video options
#define PBR_LIGHT_BOUNDING_SPHERE_MULTIPLIER 5.0

#if DO_PBR && !PBR_BYPASS
#define GAMMA 2.2
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
#define VERTEX_COLOR_ADJUST 0.0


vec3 fresnelSchlick(float incidence, vec3 f0, vec3 f90)
{
    float t = clamp(1.0 - incidence, 0.0, 1.0);
    float t2 = t*t;
    float t5 = t2*t2*t;
    return f0 + (f90 - f0) * t5;
}
float distGGX(float halfIncidence, float r)
{
    r = r*r;
    r = r*r;
    
    float d = (halfIncidence*halfIncidence * (r - 1.0) + 1.0);
    
    return r / (d * d * PI);
}
float geoSchlickGGX(float incidence, float roughness)
{
    roughness += 1.0;
    float k = roughness * roughness * (1.0/8.0);
    return incidence / mix(incidence, 1.0, k);
}
float geoSmith(float viewIncidence, float lightIncidence, float roughness)
{
    return geoSchlickGGX(viewIncidence, roughness) * geoSchlickGGX(lightIncidence, roughness);
}
float BRDF(vec3 normalDir, vec3 viewDir, vec3 lightDir, vec3 halfDir, float roughness)
{
    float lightIncidence = max(dot(normalDir, lightDir), 0.00001);
    float halfIncidence  = max(dot(normalDir,  halfDir), 0.00001);
    float viewIncidence  = max(dot(normalDir,  viewDir), 0.00001);
    
    float NDF = distGGX(halfIncidence, roughness);
    float geo = geoSmith(viewIncidence, lightIncidence, roughness);

    return (NDF * geo) / (4.0 * viewIncidence * lightIncidence);
}

vec3 to_linear(vec3 color)
{
    return sign(color) * pow(abs(color), vec3(GAMMA));
}
vec3 to_srgb(vec3 color)
{
    return sign(color) * pow(abs(color), vec3(1.0/GAMMA));
}

vec3 perLightPBR(float alpha, vec3 diffuseColor, vec3 diffuseVertexColor, vec3 ambientColor, vec3 shadowing, vec3 normal, vec3 viewPos, vec3 lightPos, float lightDistance, float radius, float falloff, float standard_falloff, float cutoff, vec3 ambientLightColor, vec3 lightColor, float metallicity, float roughness, float ao, vec3 f0, vec3 f90, bool indoors, inout vec3 ambientBias)
{
    vec3 light = vec3(0.0);

    vec3 viewDir = -normalize(viewPos);
    vec3 lightDir = normalize(lightPos);
    vec3 normalDir = normal;
    vec3 halfDir = normalize(viewDir + lightDir);
    
    float lightIncidence = dot(normalDir, lightDir);
    float baseIncidence = lightIncidence;
    
    diffuseColor = to_linear(diffuseColor);
    diffuseVertexColor = to_linear(diffuseVertexColor);
    ambientColor = to_linear(ambientColor);
    ambientLightColor = to_linear(ambientLightColor);
    lightColor = to_linear(lightColor);
    
    if (dot(lightColor, vec3(1.0/3.0)) < 0.0)
        ambientBias += lightColor * max(0.0, baseIncidence) * falloff;
    
    ambientLightColor = max(ambientLightColor, vec3(0.0));
    ambientColor = max(ambientColor, vec3(0.0));
    lightColor = max(lightColor, vec3(0.0));
    falloff = max(falloff, 0.0);
    
#if PBR_VERTEX_COLOR_HACK
    // the main use of vertex colors in MW assets is as a GI approximation, so make it affect light instead of diffuse
    // (otherwise darkened areas get a weird haze)
    // (also, do it if this light is the sun OR we're indoors)
    if (radius < 0.0 || indoors)
    {
        lightColor *= diffuseVertexColor * shadowing;
    }
    else
#endif
    {
        lightColor *= shadowing;
        diffuseColor *= diffuseVertexColor;
    }
        
    f0  = mix(f0 , diffuseColor, metallicity);
    f90 = mix(f90, diffuseColor, metallicity); // FIXME: ????
#if !PBR_NO_SPECULAR
    vec3 fresnel = fresnelSchlick(max(dot(halfDir, viewDir), 0.0), f0, f90);
    float specular = BRDF(normalDir, viewDir, lightDir, halfDir, roughness);
#else
    vec3 fresnel = f0;
    float specular = 0.0;
#endif

#ifndef GROUNDCOVER
    baseIncidence = max(baseIncidence, 0.0);
#else
    float eyeCosine = dot(-normalize(viewDir), normalDir);
    if (baseIncidence < 0.0)
    {
        baseIncidence = -baseIncidence;
        eyeCosine = -eyeCosine;
    }
    baseIncidence *= clamp(-8.0 * (1.0 - 0.3) * eyeCosine + 1.0, 0.3, 1.0);
#endif

    // reduce specularity by plane normal to conserve energy
    specular *= baseIncidence;

#if DO_PBR
    float lambert = baseIncidence * falloff * (1.0/PI);
    vec3 diff = diffuseColor * lambert  * lightColor * (1.0 - fresnel) * (1.0 - metallicity);
    vec3 spec = vec3(1.0)    * specular * lightColor * fresnel;
    if (radius >= 0.0)
    {
        //spec *= falloff;
        // always use quadratic falloff for specularity
        float ref_falloff = clamp(1.0/(PBR_FALLOFF_REF_DISTANCE * PBR_FALLOFF_REF_DISTANCE), 0.0, 1.0);
        float falloff_mod = standard_falloff/ref_falloff;
        spec *= falloff_mod/(lightDistance * lightDistance);
        spec *= LIGHT_STRENGTH_POINT_SPECULAR;
        
        // fade out at end of bounding radius
        radius = radius*5.0;
        spec *= clamp((1.0 - lightDistance/radius)*5.0, 0.0, 1.0);
        spec *= pow(cutoff, 0.1);
    }
    else
    {
        spec *= LIGHT_STRENGTH_SUN_SPECULAR;
    }
    // apply part of ao to rough specularity, because rough specular light is sorta kinda like ambient light
    spec *= mix(1.0, ao, roughness*0.5);
    light += diff;
    light += spec;
    light += diffuseColor * ambientColor * falloff * ao * ambientLightColor;
#else
    float lambert = baseIncidence * falloff;
    light += diffuseColor * lambert * lightColor;
    light += diffuseColor * ambientColor * falloff * ao * ambientLightColor;
#endif
    
    return light;
}

uniform mat4 osg_ViewMatrixInverse;

vec3 doLightingPBR(float alpha, vec3 diffuseColor, vec3 diffuseVertexColor, vec3 ambientColor, vec3 emissiveColor, vec3 specularTint, vec3 viewPos, vec3 normal, float _shadowing, float metallicity, float roughness, float ao, float f0_scalar)
{
    #if DEBUG_SHOW_ROUGHNESS
        return vec3(roughness);
    #endif
    // indoors detection hack
    bool indoors = normalize((osg_ViewMatrixInverse * vec4(normalize(lcalcPosition(0)), 0.0)).xyz).y > 0.0;
    
    vec3 f90 = vec3(1.0) + specularTint;
    vec3 f0 = vec3(f0_scalar) * f90;
    
    diffuseVertexColor = mix(diffuseVertexColor, vec3(1.0), VERTEX_COLOR_ADJUST);
    
    vec3 ambientBias = vec3(0.0);
    
    vec3 shadowing = vec3(_shadowing);
    vec3 light = vec3(0.0);
    light += perLightPBR(alpha, diffuseColor, diffuseVertexColor, ambientColor, shadowing, normal, viewPos, lcalcPosition(0), 1.0, -1.0, 1.0, 1.0, 1.0, vec3(0.0), lcalcDiffuse(0) * LIGHT_STRENGTH_SUN, metallicity, roughness, ao, f0, f90, indoors, ambientBias);
    light += to_linear(diffuseColor) * to_linear(emissiveColor);

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
        
        float physical_falloff = 1.0/(PBR_FALLOFF_REF_DISTANCE*PBR_FALLOFF_REF_DISTANCE);
        float legacy_falloff = lcalcIlluminationNoCutoff(i, lightDistance);
        float standard_falloff = lcalcIlluminationNoCutoff(i, PBR_FALLOFF_REF_DISTANCE);
#if DO_PBR && PBR_FORCE_QUADRATIC_FALLOFF
        float constant_part = PBR_FORCE_QUADRATIC_FALLOFF_CONSTANT*PBR_FORCE_QUADRATIC_FALLOFF_CONSTANT;
        float falloff = (PBR_QUADRATIC_BOOST)/(lightDistance*lightDistance + constant_part)*(standard_falloff/physical_falloff);
#else
#if DO_PBR && PBR_COMPRESSED_FALLOFF
        float falloff = to_linear(vec3(legacy_falloff)).r;
#else
        float falloff = legacy_falloff;
#endif
#endif
        float cutoff = lcalcCutoff(i, lightDistance/PBR_LIGHT_BOUNDING_SPHERE_MULTIPLIER);
        falloff *= cutoff;
        
        vec3 ambient = lcalcAmbient(i);
        vec3 diffuse = lcalcDiffuse(i);
        
        light += perLightPBR(alpha, diffuseColor, diffuseVertexColor, ambientColor, vec3(1.0), normal, viewPos, lightPos, lightDistance, radius, falloff, standard_falloff, cutoff, ambient, diffuse * LIGHT_STRENGTH_POINT, metallicity, roughness, ao, f0, f90, indoors, ambientBias);
    }
    
    vec3 ambientTerm = max(to_linear(ambientColor) + ambientBias, vec3(0.0));
    light += to_linear(diffuseColor) * to_linear(gl_LightModel.ambient.xyz * LIGHT_STRENGTH_AMBIENT) * ambientTerm * ao;
    
    return to_srgb(light);
}

void fakePbrEstimate(vec3 color, out float metallicity, out float roughness, out float ao, out float f0_scalar)
{
    metallicity = 0.0;
    float color_v = max(0.0, dot(color, vec3(1.0/3.0))-0.4)*5.0;
    float color_part = color.b*4.0 - 0.5 + color.g*0.5 - color.r*0.25;
    float f = clamp(color_part - color_v, 0.0, 1.0);
    roughness = mix(PBR_AUTO_ROUGHNESS_MAX, PBR_AUTO_ROUGHNESS_MIN, f);
    ao = 1.0;
    f0_scalar = 0.04;
}

void specMapToPBR(vec4 specTex, out float metallicity, out float roughness, out float ao, out float f0_scalar)
{
    metallicity = specTex.r;
    #if PBR_MAT_ROUGHNESS_INVERTED
        roughness = clamp(1.0 - specTex.g, 0.02, 0.98);
    #else
        roughness = clamp(specTex.g, 0.02, 0.98);
    #endif
    #if DO_PBR
        ao = 1.0;
    #else
        ao = specTex.b;
    #endif
    f0_scalar = 0.04;
}

#else // PER_PIXEL_LIGHTING
#define PBR_BYPASS 1
#endif // PER_PIXEL_LIGHTING