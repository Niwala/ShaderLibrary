Shader "Library/Lerp"
{
    Properties
    {
        _Texture("_Texture", 2D) = "white" {}
        _Opacity("_Opacity", Float) = 1.0
        _Threshold("_Threshold", Range(0.0, 1.0)) = 0.5
        _Frequency("_Frequency", Float) = 1.0
        _Amplitude("_Amplitude", Range(0.0, 1.0)) = 1.0
        _ColorA("_ColorA", Color) = (1.0, 0.0, 0.0, 1.0)
        _ColorB("_ColorB", Color) = (0.0, 0.0, 1.0, 1.0)
        _T("_T", Range(0.0, 1.0)) = 0.0
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
            float4 _ColorA;
            float4 _ColorB;
            float _T;
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

            float RectangeSDF(float2 p, float2 position, float2 size)
            {
                p -= position;
                p = abs(p) - size;
                return max(p.x, p.y);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                switch (_Function)
                {
                    case 0:
                    {
                        float2 r = float2(_Ratio, 1);
                        float2 p = i.uv * r;
                        float t = smoothstep(-0.8, 0.8, sin(_CustomTime));

                        float2 center = lerp(float2(0.4, 0.2), float2(0.7, 0.7), t) * r;
                        float shape = lerp(RectangeSDF(p, center, float2(0.3, 0.1)), length(p - center) - 0.2, t);

                        return float4(0.369453, 0.4733736, 0.511, step(shape, 0) * _Opacity);
                    }
                    case 1:
                    {
                        return float4(lerp(_ColorA, _ColorB, _T).xyz, _Opacity);
                    }
                    case 2:
                    {
                        return float4(cos(_CustomTime).xxx * 0.5 + 0.5, _Opacity);
                    }
                    case 3:
                    {
                        return float4(cos(_CustomTime * _Speed).xxx * 0.5 + 0.5, _Opacity);
                    }
                    case 4:
                    {
                        float shape = step(i.uv.y, cos(i.uv.x * 3.1415 * _Ratio + _CustomTime) * 0.5 + 0.5);
                        return float4(shape.xxx, _Opacity);
                    }
                    case 5:
                    {
                        float shape = step(i.uv.y, (cos(i.uv.x * 3.1415 * _Ratio * _Frequency + _CustomTime * _Speed) * _Amplitude) * 0.5 + 0.5);
                        return float4(shape.xxx, _Opacity);
                    }
                }

                return float4(i.uv, 0, _Opacity);
            }
            ENDCG
        }
    }
}
