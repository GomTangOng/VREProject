#pragma once

enum VertexElementType : UINT
{
	VERTEX_POSITION_ELEMENT = 1,
	VERTEX_COLOR_ELEMENT = 2,
	VERTEX_NORMAL_ELEMENT = 4,
	VERTEX_TEXTURE_ELEMENT_0 = 8,
	VERTEX_TEXTURE_ELEMENT_1 = 16,
	VERTEX_BONE_ID_ELEMENT = 32,
	VERTEX_BONE_WEIGHT_ELEMENT = 64,
	VERTEX_INSTANCING_ELEMENT = 128,
};

enum CameraDualMode : UCHAR
{
	INTERACE = 1,
};

enum RenderState : UCHAR
{

};