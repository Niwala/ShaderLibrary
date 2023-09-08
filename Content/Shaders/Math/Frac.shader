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
        [HDR]_UseAbs("_UseAbs", Float) = 0.0
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
                        float shape = step(i.uv.y, frac(i.uv.x * _Ratio + _CustomTime * 0.5));
                        return float4(0.369453, 0.4733736, 0.511, shape * _Opacity);
                    }
                    case 1:
                    {
                        return float4(frac(_CustomTime).xxx, _Opacity);
                    }
                    case 2:
                    {
                        return float4(frac(_CustomTime * _Speed).xxx * _Amplitude, _Opacity);
                    }
                    case 3:
                    {
                        return float4(frac(i.uv.x * _Frequency).xxx * _Amplitude, _Opacity);
                    }
                    case 4:
                    {
                        float shape = step(i.uv.y, frac(i.uv.x * _Ratio * _Frequency + _CustomTime * _Speed) * _Amplitude);
                        return float4(shape.xxx, _Opacity);
                    }
                    case 5:
                    {
                        float value = frac(i.uv.x * 2 * _Ratio + _CustomTime);
                        value += _Offset;
                        if (_UseAbs)
                            value = abs(value);
                        float shape = step(i.uv.y, value * 0.5 + 0.5);
                        return float4(shape.xxx, _Opacity);
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
