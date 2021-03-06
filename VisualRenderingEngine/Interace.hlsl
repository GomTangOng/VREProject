SamplerState gBasicSampler : register(s0);
Texture2D gTextureRT : register(t4);

RWTexture2D<unorm float4> gOutput : register(u0);   // why add unorm...?
//groupshared float4 gCache[]

cbuffer gWindowSize : register(b4)
{
    //float4 gWindowSize;
    float4 gWindowWidth;
    float4 gWindowHeight;
}

#define THREAD_COUNT 32

[numthreads(THREAD_COUNT, THREAD_COUNT, 1)]
void CS_VERTICAL_INTERACE(int3 groupID : SV_GroupID,
						  int3 groudThreadID : SV_GroupThreadID,
						  int3 dispatchThreadID : SV_DispatchThreadID)
{
    int half_window_width = gWindowWidth.x / 2.0f;
   
    if (dispatchThreadID.x < half_window_width) // Left Screen
    {
        gOutput[int2(dispatchThreadID.x * 2 + 1, dispatchThreadID.y)] = gTextureRT[int2(dispatchThreadID.x, dispatchThreadID.y)];
    }
    else                                        // Right Screen
    {
        gOutput[int2((dispatchThreadID.x - half_window_width) * 2, dispatchThreadID.y)] = gTextureRT[int2(dispatchThreadID.x, dispatchThreadID.y)];
    }

    //gOutput[dispatchThreadID.xy] = gTextureRT[int2(dispatchThreadID.x, dispatchThreadID.y)];
    //gOutput[dispatchThreadID.xy] = gTextureRT.SampleLevel(gBasicSampler, int2(dispatchThreadID.x, dispatchThreadID.y), 0);   
}

[numthreads(THREAD_COUNT, THREAD_COUNT, 1)]
void CS_HORIZONTAL_INTERACE(int3 groupID : SV_GroupID,
						  int3 groudThreadID : SV_GroupThreadID,
						  int3 dispatchThreadID : SV_DispatchThreadID)
{
    int half_window_height = gWindowHeight.x / 2.0f;
    
    //[flatten]
    if (dispatchThreadID.y < half_window_height)      // Top Screen --> Odd
    {
        gOutput[int2(dispatchThreadID.x, dispatchThreadID.y * 2 + 1)] = gTextureRT[int2(dispatchThreadID.x, dispatchThreadID.y)];
    }
    else                                              // Bottom Screen --> Even
    {
        gOutput[int2(dispatchThreadID.x, (dispatchThreadID.y - half_window_height) * 2)] = gTextureRT[int2(dispatchThreadID.x, dispatchThreadID.y)];
    }
}

[numthreads(THREAD_COUNT, THREAD_COUNT, 1)]
void CS_HORIZONTAL_INTERACE2(int3 groupID : SV_GroupID,
						     int3 groudThreadID : SV_GroupThreadID,
						     int3 dispatchThreadID : SV_DispatchThreadID)
{
    int half_window_height = gWindowHeight.x / 2.0f;

    //[flatten]
    if (dispatchThreadID.y > half_window_height)      // Bottom Screen --> Odd
    {
        gOutput[int2(dispatchThreadID.x, (dispatchThreadID.y - half_window_height) * 2 + 1)] = gTextureRT[int2(dispatchThreadID.x, dispatchThreadID.y)];
    }
    else // Top Screen --> Even
    {
        gOutput[int2(dispatchThreadID.x, dispatchThreadID.y * 2)] = gTextureRT[int2(dispatchThreadID.x, dispatchThreadID.y)];
    }
}