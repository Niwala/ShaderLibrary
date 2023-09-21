Shader "Library/Frac"
{
    Properties
    {
        _Texture("_Texture", 2D) = "white" {}
        _Opacity("_Opacity", Float) = 1.0
        _Threshold("_Threshold", Range(0.0, 1.0)) = 0.5
        _Frequency("_Frequency", Float) = 1.0
        _Amplitude("_Amplitude", Range(0.0, 1.0)) = 1.0
        _Offset("_Offset", Float) = 0.0
        [HDR]_UseFloor("_UseFloor", Float) = 0.0
        _Speed("_Speed", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "../Library/SimplexNoise.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 color : COLOR;
            };

            float _Opacity;
            float _CustomTime;
            float _Threshold;
            float _Frequency;
            float _Amplitude;
            float _Speed;
            float _Ratio;
            float _UseFloor;
            float _UseAbs;
            float _Offset;
            int _Function;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.color = v.color;
                return o;
            }

            float2x2 Rot(float a)
            {
                float sa = sin(a);
                float ca = cos(a);
                return float2x2(ca, -sa, sa, ca);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                switch (_Function)
                {
                    case 0:
                    {
				        float shape = step(i.uv.y * 3 + _CustomTime * 0.5, floor(i.uv.x * 3 * _Ratio + _CustomTime * 0.5));
                        return float4(0.369453, 0.4733736, 0.511, shape * _Opacity);
                    }
                    case 1:
                    {
				        return float4((floor(i.uv.y * _Frequency) / _Frequency).xxx, _Opacity);
			        }
                    case 2:
                    {
                        return float4(frac(floor(_CustomTime) * 0.2).xxx, _Opacity);
			        }
                    case 3:
                    {
                        int loopValue = floor(_CustomTime * _Speed) % 4;
                        
                        float diskA = smoothstep(0.11, 0.1, length(i.uv - 0.2));
                        float diskB = smoothstep(0.11, 0.1, length(i.uv - 0.4));
                        float diskC = smoothstep(0.11, 0.1, length(i.uv - 0.6));
                        float diskD = smoothstep(0.11, 0.1, length(i.uv - 0.8));
                        float shape = 0;
                        
                        shape += diskA * (1-abs(0 - loopValue));
                        shape += diskB * (1-abs(1 - loopValue));
                        shape += diskC * (1-abs(2 - loopValue));
                        shape += diskD * (1-abs(3 - loopValue));
                        
				        return float4(shape.xxx, _Opacity);
                    }
                    case 4:
                    {
                    
                        float bands = floor(i.uv.x * 7);
                        float t = lerp(-3, 10, frac(_CustomTime));
                        float factor = 1.0 - saturate(abs(bands - t) * 0.33);
                    
                        return float4(factor.xxx, _Opacity);
			        }
                    case 5:
                    {
                        float2 channels = floor(i.uv * _Frequency);
                        int i = channels.x + channels.y;
                        return  float4(step(i % 2, 0.5).xxx, _Opacity);
                        
                    }
                    case 6:
                    {
                        float value = abs(frac(i.uv.x * _Ratio + _CustomTime) - 0.5) * 2;
                        float shape = step(i.uv.y, value);
                        return float4(shape.xxx, _Opacity);
                    }
                    case 7:
                    {
                        return float4(abs(frac(_CustomTime).xxx - 0.5) * 2, _Opacity);
                    }
                }

                return float4(i.uv, 0, _Opacity);
            }
            ENDCG
        }
    }
}
