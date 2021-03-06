#pragma once
#include "Shader.h"

class CInstancedCubeShader : public CShader
{
public:
	CInstancedCubeShader();
	~CInstancedCubeShader() override;

	void CreateShader() override;
	void BuildObject() override;
	void Update(const float fTimeElapsed = 0.0f) override;
	void Render() override;
	void Render(CCamera *pCamera);
	void OnPreRender() override;
};

