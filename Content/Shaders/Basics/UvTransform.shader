Shader "Library/UvTransform"
{
    Properties
    {
        _Texture("_Texture", 2D) = "white" {}
        _Opacity("_Opacity", Float) = 1.0
        _Threshold("_Threshold", Range(0.0, 1.0)) = 0.5
        _Tilling("_Tilling", Float) = 1.0
        [HDR]_Panning("_Panning", Vector) = (0.0, 0.0, 0.0, 0.0)
        [HDR]_PreTileOffset("_PreTileOffset", Vector) = (0.0, 0.0, 0.0, 0.0)
        [HDR]_PostTileOffset("_PostTileOffset", Vector) = (0.0, 0.0, 0.0, 0.0)
        _Speed("_Speed", Float) = 0.1
        [HDR]_UseTexture("_UseTexture", Float) = 0
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
            float _Ratio;
            float _Tilling;
            float4 _Panning;
            float4 _PreTileOffset;
            float4 _PostTileOffset;
            float _Speed;
            int _Function;
            float _UseTexture;
            sampler2D _Texture;

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
                        float2 coords = float2(i.uv.x * _Ratio, i.uv.y);

                        //Rotation
                        float rt = _CustomTime * 0.5;         //Rotate time
                        float rotateAngle = floor(rt) + smoothstep(0, 1, frac(rt) * 2 - 1);

                        //Scale
                        float st = _CustomTime * 0.4;        //Scale time
                        float scale = saturate((abs(frac(st * 0.1) - 0.5) * 2) * 5 - 2.5);

                        //Center 
                        float offset = saturate((abs(frac(_CustomTime * 0.1) - 0.5) * 2) * 5 - 2.5);
                        float2 offset2 = float2(offset * _Ratio, offset);

                        //Apply transform
                        coords -= 0.5 * offset2;
                        coords = mul(Rot(rotateAngle), coords);
                        coords *= 4.1 + scale * 3;
                        coords += 0.5 * offset2;

                        //Build grid
                        float2 grid2 = smoothstep(0.03 * (1.0 + scale), 0.02 * (1.0 + scale), abs(frac(coords) - 0.5));
                        float grid = max(grid2.x, grid2.y);

                        return float4(0.369453, 0.4733736, 0.511, grid * _Opacity);
                    }

                    case 1: return float4(frac(i.uv * _Tilling), 0, _Opacity);
                    case 2: return float4(frac((i.uv + _PreTileOffset) * _Tilling + _PostTileOffset), 0, _Opacity);
                }

                return float4(i.uv, 0, _Opacity);
            }
            ENDCG
        }
    }
}
