#pragma once

enum VS_SLOT
{
	//VS_CB_SLOT_WORLD_VIEW_PROJECTION_MATRIX = 0,
	VS_CB_SLOT_CAMERA_PROJECTION_MATRIX,
	VS_CB_SLOT_WORLD_MATRIX,
};

enum PS_SLOT
{
	PS_CB_SLOT_LIGHT,
	PS_CB_SLOT_MATERIAL
};

enum HS_SLOT
{
	HS_CB_SLOT_TESSLATION = 3
};

enum TextureSlot : UCHAR
{
	TEXTURE_BOX01,
	TEXTURE_GRASS,
	TEXTURE_HEIGHTMAP
};

enum SamplerSlot : UCHAR
{
	SAMPLER_BASIC,
	SAMPLER_LINEAR,
	SAMPLER_HEIGHTMAP
};