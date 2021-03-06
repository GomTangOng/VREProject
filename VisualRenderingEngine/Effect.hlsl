//--------------------------------------------------------------------------------------
// @ Structure
// 

struct VS_TEXTURED_INPUT
{
    float3 PosL : POSITION;
    float2 Tex : TEXCOORD;
};

struct VS_TEXTURED_OUTPUT
{
    float4 PosH : SV_Position;
    float2 Tex : TEXCOORD;
};

struct VS_LIGHTING_INPUT
{
	float3 PosL    : POSITION;
	float3 NormalL : NORMAL;
};

struct VS_LIGHTING_TEXTURE_INPUT
{
	float3 PosL : POSITION;
	float3 NormalL : NORMAL;
	float2 Tex : TEXCOORD0;
};

struct VS_LIGHTING_TEXTURE_OUTPUT
{
	float4 PosH : SV_POSITION;
	float3 PosW : POSITION;
	float3 NormalW : NORMAL;
	float2 Tex : TEXCOORD0;
};

struct VS_LIGHTING_OUTPUT
{
	float4 PosH    : SV_POSITION;
	float3 PosW    : POSITION;
	float3 NormalW : NORMAL;
};

struct VS_OUTPUT
{
	float4 Pos : SV_POSITION;
	float4 Color : COLOR0;
};

struct VS_INSTANCED_LIGHTING_TEXTURE_INPUT
{
    float3 PosL : POSITION;
    float3 NormalL : NORMAL;
    float2 Tex : TEXCOORD;
    row_major float4x4 InstancedWorld : INSTANCEPOS;
    uint InstancedId : SV_InstanceID;
};

struct VS_INSTANCED_LIGHTING_TEXTURE_OUTPUT
{
    float4 PosH : SV_POSITION;
    float3 PosW : POSITION;
    float3 NormalW : NORMAL;
    float2 Tex : TEXCOORD;
};

#define MAX_LIGHT 16

struct DirectionalLight
{
	float4 Ambient;
	float4 Diffuse;
	float4 Specular;
	float3 Direction;
	float pad;
};

struct PointLight
{
	float4 Ambient;
	float4 Diffuse;
	float4 Specular;

	float3 Position;
	float Range;

	float3 Att;
	float pad;
};

struct SpotLight
{
	float4 Ambient;
	float4 Diffuse;
	float4 Specular;

	float3 Position;
	float Range;

	float3 Direction;
	float Spot;

	float3 Att;
	float pad;
};

struct Material
{
	float4 Ambient;
	float4 Diffuse;
	float4 Specular; // w = SpecPower
	float4 Reflect;
};

//---------------------------------------------------------------------------------------
// Computes the ambient, diffuse, and specular terms in the lighting equation
// from a directional light.  We need to output the terms separately because
// later we will modify the individual terms.
//---------------------------------------------------------------------------------------
void ComputeDirectionalLight(Material mat, DirectionalLight L,
	float3 normal, float3 toEye,
	out float4 ambient,
	out float4 diffuse,
	out float4 spec)
{
	// Initialize outputs.
	ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
	diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
	spec = float4(0.0f, 0.0f, 0.0f, 0.0f);

	// The light vector aims opposite the direction the light rays travel.
	float3 lightVec = -L.Direction;

	// Add ambient term.
	ambient = mat.Ambient * L.Ambient;

	// Add diffuse and specular term, provided the surface is in 
	// the line of site of the light.

	float diffuseFactor = dot(lightVec, normal);

	// Flatten to avoid dynamic branching.
	[flatten]
	if (diffuseFactor > 0.0f)
	{
		float3 v = reflect(-lightVec, normal);
		float specFactor = pow(max(dot(v, toEye), 0.0f), mat.Specular.w);

		diffuse = diffuseFactor * mat.Diffuse * L.Diffuse;
		spec = specFactor * mat.Specular * L.Specular;
	}
}

//---------------------------------------------------------------------------------------
// Computes the ambient, diffuse, and specular terms in the lighting equation
// from a point light.  We need to output the terms separately because
// later we will modify the individual terms.
//---------------------------------------------------------------------------------------
void ComputePointLight(Material mat, PointLight L, float3 pos, float3 normal, float3 toEye,
	out float4 ambient, out float4 diffuse, out float4 spec)
{
	// Initialize outputs.
	ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
	diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
	spec = float4(0.0f, 0.0f, 0.0f, 0.0f);

	// The vector from the surface to the light.
	float3 lightVec = L.Position - pos;

	// The distance from surface to light.
	float d = length(lightVec);

	// Range test.
	if (d > L.Range)
		return;

	// Normalize the light vector.
	lightVec /= d;

	// Ambient term.
	ambient = mat.Ambient * L.Ambient;

	// Add diffuse and specular term, provided the surface is in 
	// the line of site of the light.

	float diffuseFactor = dot(lightVec, normal);

	// Flatten to avoid dynamic branching.
	[flatten]
	if (diffuseFactor > 0.0f)
	{
		float3 v = reflect(-lightVec, normal);
		float specFactor = pow(max(dot(v, toEye), 0.0f), mat.Specular.w);

		diffuse = diffuseFactor * mat.Diffuse * L.Diffuse;
		spec = specFactor * mat.Specular * L.Specular;
	}

	// Attenuate
	float att = 1.0f / dot(L.Att, float3(1.0f, d, d*d));

	diffuse *= att;
	spec *= att;
}

//---------------------------------------------------------------------------------------
// Computes the ambient, diffuse, and specular terms in the lighting equation
// from a spotlight.  We need to output the terms separately because
// later we will modify the individual terms.
//---------------------------------------------------------------------------------------
void ComputeSpotLight(Material mat, SpotLight L, float3 pos, float3 normal, float3 toEye,
	out float4 ambient, out float4 diffuse, out float4 spec)
{
	// Initialize outputs.
	ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
	diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
	spec = float4(0.0f, 0.0f, 0.0f, 0.0f);

	// The vector from the surface to the light.
	float3 lightVec = L.Position - pos;

	// The distance from surface to light.
	float d = length(lightVec);

	// Range test.
	if (d > L.Range)
		return;

	// Normalize the light vector.
	lightVec /= d;

	// Ambient term.
	ambient = mat.Ambient * L.Ambient;

	// Add diffuse and specular term, provided the surface is in
	// the line of site of the light.

	float diffuseFactor = dot(lightVec, normal);

	// Flatten to avoid dynamic branching.
	[flatten]
	if (diffuseFactor > 0.0f)
	{
		float3 v = reflect(-lightVec, normal);
		float specFactor = pow(max(dot(v, toEye), 0.0f), mat.Specular.w);

		diffuse = diffuseFactor * mat.Diffuse * L.Diffuse;
		spec = specFactor * mat.Specular * L.Specular;
	}

	// Scale by spotlight factor and attenuate.
	float spot = pow(max(dot(-lightVec, L.Direction), 0.0f), L.Spot);

	// Scale by spotlight factor and attenuate.
	float att = spot / dot(L.Att, float3(1.0f, d, d*d));

	ambient *= spot;
	diffuse *= att;
	spec *= att;
}


//-------------------------------------
// @ Textures
//

Texture2D gTexture01 : register(t0);
Texture2D gTextureGrass : register(t1);
Texture2D gHeightMap : register(t2);
TextureCube gCubeMap : register(t3);
Texture2D gTextureRT : register(t4);
//------------------------------------
// @ SamplerState
//
SamplerState gBasicSampler : register(s0);

SamplerState samLinear : register(s1);
SamplerState samHeightmap : register(s2);

//-----------------------------------
// @ Contant Buffer
//

cbuffer cbViewProjectionMtx : register(b0)
{
	matrix view;
	matrix projection;
}

cbuffer cbWorldMtx : register(b1)
{
	matrix world;
}

cbuffer cbLight : register(b0)
{
	DirectionalLight gDirLight[MAX_LIGHT];
	PointLight gPointLight[MAX_LIGHT];
	SpotLight gSpotLight[MAX_LIGHT];
	float3	 gCamPosW;
};

cbuffer cbMaterial : register(b1)
{
	Material gMaterial;
}

cbuffer cbTesslation : register(b3)
{
	float3 gEyePosW;
	float  gMinDist;

	float gMaxDist;
	float gMinTess;
	float gMaxTess;
	float gTexelCellSpaceU;

	float gTexelCellSpaceV;
	float gWorldCellSpace;
	float2 gTexScale;

	float4 gWorldFrustumPlanes[6];
	matrix gViewProj;
}


struct VS_TERRAIN_INPUT
{
	float3 PosL     : POSITION;
	float2 Tex      : TEXCOORD0;
	float2 BoundsY  : TEXCOORD1;
};

struct VS_TERRAIN_OUTPUT
{
	float3 PosW     : POSITION;
	float2 Tex      : TEXCOORD0;
	float2 BoundsY  : TEXCOORD1;
};

struct HS_PATCH_TESS_OUTPUT
{
	float EdgeTess[4]   : SV_TessFactor;
	float InsideTess[2] : SV_InsideTessFactor;
};

struct HS_TERRAIN_OUTPUT
{
	float3 PosW     : POSITION;
	float2 Tex      : TEXCOORD0;
};

struct DS_TERRAIN_OUTPUT
{
	float4 PosH     : SV_POSITION;
	float3 PosW     : POSITION;
	float2 Tex      : TEXCOORD0;
	float2 TiledTex : TEXCOORD1;
};

float CalcTessFactor(float3 p)
{
	float d = distance(p, gEyePosW);

	// max norm in xz plane (useful to see detail levels from a bird's eye).
	//float d = max( abs(p.x-gEyePosW.x), abs(p.z-gEyePosW.z) );

	float s = saturate((d - gMinDist) / (gMaxDist - gMinDist));

	return pow(2, (lerp(gMaxTess, gMinTess, s)));
}

// Returns true if the box is completely behind (in negative half space) of plane.
bool AabbBehindPlaneTest(float3 center, float3 extents, float4 plane)
{
	float3 n = abs(plane.xyz);

	// This is always positive.
	float r = dot(extents, n);

	// signed distance from center point to plane.
	float s = dot(float4(center, 1.0f), plane);

	// If the center point of the box is a distance of e or more behind the
	// plane (in which case s is negative since it is behind the plane),
	// then the box is completely in the negative half space of the plane.
	return (s + r) < 0.0f;
}

// Returns true if the box is completely outside the frustum.
bool AabbOutsideFrustumTest(float3 center, float3 extents, float4 frustumPlanes[6])
{
	for (int i = 0; i < 6; ++i)
	{
		// If the box is completely behind any of the frustum planes
		// then it is outside the frustum.
		if (AabbBehindPlaneTest(center, extents, frustumPlanes[i]))
		{
			return true;
		}
	}

	return false;
}

VS_TERRAIN_OUTPUT VS_TERRAIN(VS_TERRAIN_INPUT vin)
{
	VS_TERRAIN_OUTPUT vout;
	
	//vout.PosW = mul(float4(vin.PosL, 1.0f), gViewProj);
	
	// Terrain specified directly in world space.
	vout.PosW = vin.PosL;

	// Displace the patch corners to world space.  This is to make 
	// the eye to patch distance calculation more accurate.
	vout.PosW.y = gHeightMap.SampleLevel(samHeightmap, vin.Tex, 0).r;

	// Output vertex attributes to next stage.
	vout.Tex = vin.Tex;
	vout.BoundsY = vin.BoundsY;

	return vout;
}

HS_PATCH_TESS_OUTPUT CONSTANT_HS(InputPatch<VS_TERRAIN_OUTPUT, 4> patch, uint patchID : SV_PrimitiveID)
{
	HS_PATCH_TESS_OUTPUT pt;

	//
	// Frustum cull
	//

	// We store the patch BoundsY in the first control point.
	float minY = patch[0].BoundsY.x;
	float maxY = patch[0].BoundsY.y;

	// Build axis-aligned bounding box.  
	// patch[2] is lower-left corner and patch[1] is upper-right corner.
	float3 vMin = float3(patch[2].PosW.x, minY, patch[2].PosW.z);
	float3 vMax = float3(patch[1].PosW.x, maxY, patch[1].PosW.z);

	float3 boxCenter = 0.5f*(vMin + vMax);
	float3 boxExtents = 0.5f*(vMax - vMin);
	if (AabbOutsideFrustumTest(boxCenter, boxExtents, gWorldFrustumPlanes))
	{
		pt.EdgeTess[0] = 0.0f;
		pt.EdgeTess[1] = 0.0f;
		pt.EdgeTess[2] = 0.0f;
		pt.EdgeTess[3] = 0.0f;

		pt.InsideTess[0] = 0.0f;
		pt.InsideTess[1] = 0.0f;

		return pt;
	}
	//
	// Do normal tessellation based on distance.
	//
	else
	{
		// It is important to do the tess factor calculation based on the
		// edge properties so that edges shared by more than one patch will
		// have the same tessellation factor.  Otherwise, gaps can appear.

		// Compute midpoint on edges, and patch center
		float3 e0 = 0.5f*(patch[0].PosW + patch[2].PosW);
		float3 e1 = 0.5f*(patch[0].PosW + patch[1].PosW);
		float3 e2 = 0.5f*(patch[1].PosW + patch[3].PosW);
		float3 e3 = 0.5f*(patch[2].PosW + patch[3].PosW);
		float3  c = 0.25f*(patch[0].PosW + patch[1].PosW + patch[2].PosW + patch[3].PosW);

		pt.EdgeTess[0] = CalcTessFactor(e0);
		pt.EdgeTess[1] = CalcTessFactor(e1);
		pt.EdgeTess[2] = CalcTessFactor(e2);
		pt.EdgeTess[3] = CalcTessFactor(e3);

		pt.InsideTess[0] = CalcTessFactor(c);
		pt.InsideTess[1] = pt.InsideTess[0];

		return pt;
	}
}

[domain("quad")]
[partitioning("fractional_even")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(4)]
[patchconstantfunc("CONSTANT_HS")]
[maxtessfactor(64.0f)]
HS_TERRAIN_OUTPUT HS_TERRAIN(InputPatch<VS_TERRAIN_OUTPUT, 4> p,
	uint i : SV_OutputControlPointID,
	uint patchId : SV_PrimitiveID)
{
	HS_TERRAIN_OUTPUT hout;

	// Pass through shader.
	hout.PosW = p[i].PosW;
	hout.Tex = p[i].Tex;

	return hout;
}

[domain("quad")]
DS_TERRAIN_OUTPUT DS_TERRAIN(HS_PATCH_TESS_OUTPUT patchTess,
	float2 uv : SV_DomainLocation,
	const OutputPatch<HS_TERRAIN_OUTPUT, 4> quad)
{
	DS_TERRAIN_OUTPUT dout;

	// Bilinear interpolation.
	dout.PosW = lerp(
		lerp(quad[0].PosW, quad[1].PosW, uv.x),
		lerp(quad[2].PosW, quad[3].PosW, uv.x),
		uv.y);

	dout.Tex = lerp(
		lerp(quad[0].Tex, quad[1].Tex, uv.x),
		lerp(quad[2].Tex, quad[3].Tex, uv.x),
		uv.y);

	// Tile layer textures over terrain.
	dout.TiledTex = dout.Tex*gTexScale.x;

	// Displacement mapping
	dout.PosW.y = gHeightMap.SampleLevel(samHeightmap, dout.Tex, 0).r;

	// NOTE: We tried computing the normal in the shader using finite difference, 
	// but the vertices move continuously with fractional_even which creates
	// noticable light shimmering artifacts as the normal changes.  Therefore,
	// we moved the calculation to the pixel shader.  

	// Project to homogeneous clip space.
	dout.PosH = mul(float4(dout.PosW, 1.0f), gViewProj);

	return dout;
}

float4 PS_TERRAIN(DS_TERRAIN_OUTPUT pin) : SV_Target
{
	
	// Estimate normal and tangent using central differences.
	
	//float2 leftTex = pin.Tex + float2(-gTexelCellSpaceU, 0.0f);
	//float2 rightTex = pin.Tex + float2(gTexelCellSpaceU, 0.0f);
	//float2 bottomTex = pin.Tex + float2(0.0f, gTexelCellSpaceV);
	//float2 topTex = pin.Tex + float2(0.0f, -gTexelCellSpaceV);

	//float leftY = gHeightMap.SampleLevel(samHeightmap, leftTex, 0).r;
	//float rightY = gHeightMap.SampleLevel(samHeightmap, rightTex, 0).r;
	//float bottomY = gHeightMap.SampleLevel(samHeightmap, bottomTex, 0).r;
	//float topY = gHeightMap.SampleLevel(samHeightmap, topTex, 0).r;

	//float3 tangent = normalize(float3(2.0f*gWorldCellSpace, rightY - leftY, 0.0f));
	//float3 bitan = normalize(float3(0.0f, bottomY - topY, -2.0f*gWorldCellSpace));
	//float3 normalW = cross(tangent, bitan);


	//// The toEye vector is used in lighting.
	//float3 toEye = gCamPosW - pin.PosW;

	//// Cache the distance to the eye from this surface point.
	//float distToEye = length(toEye);

	//// Normalize.
	//toEye /= distToEye;

	////
	//// Texturing
	////

	//// Blend the layers on top of each other.
	//float4 texColor = gTextureGrass.Sample(samLinear, pin.Tex);

	//float4 A, D, S;
	//float4 litColor = texColor;
	//float4 ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
	//float4 diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
	//float4 spec = float4(0.0f, 0.0f, 0.0f, 0.0f);
	//[unroll]
	//for (int i = 0; i < MAX_LIGHT; ++i)
	//{
	//	[flatten]
	//	if (gDirLight[i].pad == 1.0f)
	//	{
	//		ComputeDirectionalLight(gMaterial, gDirLight[i], normalW, toEye, A, D, S);
	//		ambient += A;
	//		diffuse += D;
	//		spec += S;
	//	}

	//	[flatten]
	//	if (gPointLight[i].pad == 1.0f)
	//	{
	//		ComputePointLight(gMaterial, gPointLight[i], pin.PosW, normalW, gCamPosW, A, D, S);
	//		ambient += A;
	//		diffuse += D;
	//		spec += S;
	//	}

	//	[flatten]
	//	if (gSpotLight[i].pad == 1.0f)
	//	{
	//		ComputeSpotLight(gMaterial, gSpotLight[i], pin.PosW, normalW, gCamPosW, A, D, S);
	//		ambient += A;
	//		diffuse += D;
	//		spec += S;
	//	}
	//}

	//litColor = texColor * (ambient + diffuse) + spec;
	//litColor.a = gMaterial.Diffuse.a * texColor.a;
	//return litColor;
	return float4(1.0f,1.0f, 0.0f, 0.0f);
}


float4 VS(float4 pos : POSITION) : SV_POSITION
{
	return pos;
}

float4 PS(float4 pos : SV_POSITION) : SV_Target
{
	return float4(1.0f, 1.0f, 0.0f, 1.0f);
}

VS_TEXTURED_OUTPUT VS_TEXTURED(VS_TEXTURED_INPUT v)
{
    VS_TEXTURED_OUTPUT o;
    o.PosH = float4(v.PosL, 1.0f);
   // o.PosH = mul(o.PosH, view);
   // o.PosH = mul(o.PosH, projection);
    o.Tex = v.Tex;
    return o;
}

float4 PS_TEXTURED(VS_TEXTURED_OUTPUT o) : SV_Target
{
    float4 color = float4(1.0f, 1.0f, 1.0f, 1.0f);
    color = gTextureRT.Sample(gBasicSampler, o.Tex);
    return color;
};


VS_OUTPUT VS2(float4 Pos : POSITION, float4 Color : COLOR)
{
	VS_OUTPUT output = (VS_OUTPUT)0;
	output.Pos = mul(Pos, world);
	output.Pos = mul(output.Pos, view);
	output.Pos = mul(output.Pos, projection);
	output.Color = Color;
	return output;
}

float4 PS2(VS_OUTPUT input) : SV_Target
{
	return input.Color;
}

VS_LIGHTING_OUTPUT VS_LIGHTING(VS_LIGHTING_INPUT input)
{
	VS_LIGHTING_OUTPUT output = (VS_LIGHTING_OUTPUT)output;
	output.PosW = mul(float4(input.PosL, 1.0f), world).xyz;
	output.PosH = mul(mul(mul(float4(input.PosL, 1.0f), world), view), projection);
	output.NormalW = mul(input.NormalL, (float3x3)world);
	return output;
}

VS_LIGHTING_TEXTURE_OUTPUT VS_LIGHTING_TEXTURED(VS_LIGHTING_TEXTURE_INPUT input)
{
	VS_LIGHTING_TEXTURE_OUTPUT output = (VS_LIGHTING_TEXTURE_OUTPUT)output;
	output.PosW    = mul(float4(input.PosL, 1.0f), world).xyz;
	output.PosH    = mul(mul(mul(float4(input.PosL, 1.0f), world), view), projection);
	output.NormalW = mul(input.NormalL, (float3x3)world);
	output.Tex     = input.Tex;
	return output;
}

VS_INSTANCED_LIGHTING_TEXTURE_OUTPUT VS_INSTANCED_LIGHTING_TEXTURED(VS_INSTANCED_LIGHTING_TEXTURE_INPUT input)
{
    VS_INSTANCED_LIGHTING_TEXTURE_OUTPUT o;
    o.PosH = mul(float4(input.PosL, 1.0f), input.InstancedWorld);
    o.PosH = mul(o.PosH, view);
    o.PosH = mul(o.PosH, projection);
    o.PosW = mul(float4(input.PosL, 1.0f), world);
    o.NormalW = mul(input.NormalL, (float3x3) input.InstancedWorld);
    o.Tex = input.Tex;
    return o;
}

float4 PS_INTANECD_LIGHTING_TEXTURED(VS_INSTANCED_LIGHTING_TEXTURE_OUTPUT input) : SV_Target
{
    input.NormalW = normalize(input.NormalW);
    float3 toEyeW = normalize(gCamPosW - input.PosW);
	// Start with a sum of zero. 
    float4 ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
    float4 diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
    float4 spec = float4(0.0f, 0.0f, 0.0f, 0.0f);

	// Sum the light contribution from each light source.
    float4 A, D, S;
    float4 texColor = float4(1, 1, 1, 1);
    texColor = gTexture01.Sample(gBasicSampler, input.Tex);
    float4 litColor = texColor;

	[unroll]
    for (int i = 0; i < MAX_LIGHT; ++i)
    {
		[flatten]
        if (gDirLight[i].pad == 1.0f)
        {
            ComputeDirectionalLight(gMaterial, gDirLight[i], input.NormalW, toEyeW, A, D, S);
            ambient += A;
            diffuse += D;
            spec += S;
        }

		[flatten]
        if (gPointLight[i].pad == 1.0f)
        {
            ComputePointLight(gMaterial, gPointLight[i], input.PosW, input.NormalW, gCamPosW, A, D, S);
            ambient += A;
            diffuse += D;
            spec += S;
        }

		[flatten]
        if (gSpotLight[i].pad == 1.0f)
        {
            ComputeSpotLight(gMaterial, gSpotLight[i], input.PosW, input.NormalW, gCamPosW, A, D, S);
            ambient += A;
            diffuse += D;
            spec += S;
        }
    }

    litColor = texColor * (ambient + diffuse) + spec;

	// Common to take alpha from diffuse material.
    litColor.a = gMaterial.Diffuse.a * texColor.a;

    return litColor;
}

float4 PS_LIGHTING_TEXTURED(VS_LIGHTING_TEXTURE_OUTPUT input) : SV_TARGET
{
	input.NormalW = normalize(input.NormalW);
	float3 toEyeW = normalize(gCamPosW - input.PosW);
	// Start with a sum of zero. 
	float4 ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
	float4 diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
	float4 spec    = float4(0.0f, 0.0f, 0.0f, 0.0f);

	// Sum the light contribution from each light source.
	float4 A, D, S;
	float4 texColor = float4(1, 1, 1, 1);
    texColor = gTextureGrass.Sample(gBasicSampler, input.Tex);
	float4 litColor = texColor;

	[unroll]
	for (int i = 0; i < MAX_LIGHT; ++i)
	{
		[flatten]
		if (gDirLight[i].pad == 1.0f)
		{
			ComputeDirectionalLight(gMaterial, gDirLight[i], input.NormalW, toEyeW, A, D, S);
			ambient += A;
			diffuse += D;
			spec += S;
		}

		[flatten]
		if (gPointLight[i].pad == 1.0f)
		{
			ComputePointLight(gMaterial, gPointLight[i], input.PosW, input.NormalW, gCamPosW, A, D, S);
			ambient += A;
			diffuse += D;
			spec += S;
		}

		[flatten]
		if (gSpotLight[i].pad == 1.0f)
		{
			ComputeSpotLight(gMaterial, gSpotLight[i], input.PosW, input.NormalW, gCamPosW, A, D, S);
			ambient += A;
			diffuse += D;
			spec += S;
		}
	}

	litColor = texColor * (ambient + diffuse) + spec;

	// Common to take alpha from diffuse material.
	litColor.a = gMaterial.Diffuse.a * texColor.a;

	return litColor;
}

float4 PS_LIGHTING(VS_LIGHTING_OUTPUT input) : SV_Target
{
	input.NormalW = normalize(input.NormalW);
	float3 toEyeW = normalize(gCamPosW - input.PosW);
	// Start with a sum of zero. 
	float4 ambient = float4(0.0f, 0.0f, 0.0f, 0.0f);
	float4 diffuse = float4(0.0f, 0.0f, 0.0f, 0.0f);
	float4 spec = float4(0.0f, 0.0f, 0.0f, 0.0f);

	// Sum the light contribution from each light source.
	float4 A, D, S;

	[unroll]
	for (int i = 0; i < MAX_LIGHT; ++i)
	{
		[flatten]
		if (gDirLight[i].pad == 1.0f)
		{
			ComputeDirectionalLight(gMaterial, gDirLight[i], input.NormalW, toEyeW, A, D, S);
			ambient += A;
			diffuse += D;
			spec += S;
		}
		
		[flatten]
		if (gPointLight[i].pad == 1.0f)
		{
			ComputePointLight(gMaterial, gPointLight[i], input.PosW, input.NormalW, gCamPosW, A, D, S);
			ambient += A;
			diffuse += D;
			spec += S;
		}
		
		[flatten]
		if (gSpotLight[i].pad == 1.0f)
		{
			ComputeSpotLight(gMaterial, gSpotLight[i], input.PosW, input.NormalW, gCamPosW, A, D, S);
			ambient += A;
			diffuse += D;
			spec += S;
		}
	}
	

	float4 litColor = ambient + diffuse + spec;

	// Common to take alpha from diffuse material.
	litColor.a = gMaterial.Diffuse.a;

	return litColor;
}

