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
        [HDR]_Position("_Position", Vector) = (0.5, 0.5, 0.0, 0.0)
        [HDR]_UseAbs("_UseAbs", Float) = 0.0
        _Thickness("_Thickness", Range(0.0, 0.5)) = 0.1
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
            float _Thickness;
            float2 _Position;
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

            fixed4 frag(v2f i) : SV_Target
            {
                float2 r = float2(_Ratio, 1);

                switch (_Function)
                {
                    case 0:
                    {
                        float shape = step(frac(distance(i.uv * r, r * 0.5) * 3 - _CustomTime * 0.5) * 2, 0.3);
                        return float4(0.369453, 0.4733736, 0.511, shape * _Opacity);
                    }
                    case 1:
                    {
                        return float4(distance(i.uv, 0.5).xxx, _Opacity);
                    }
                    case 2:
                    {
                        return float4(distance(i.uv, _Position).xxx, _Opacity);
                    }
                    case 3:
                    {
                        return float4(distance(i.uv, _Position).xxx + _Offset, _Opacity);
                    }
                    case 4:
                    {
                        if (_UseAbs)
                            return float4(abs(distance(i.uv, _Position).xxx + _Offset), _Opacity);
                        return float4(distance(i.uv, _Position).xxx + _Offset, _Opacity);
                    }
                    case 5:
                    {
                        float shape = step(abs(distance(i.uv, _Position).xxx + _Offset), _Thickness);
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
