Shader "Library/UvCoords"
{
    Properties
    {
        _Texture("_Texture", 2D) = "white" {}
        _Opacity("_Opacity", Float) = 1.0
        _Threshold("_Threshold", Range(0.0, 1.0)) = 0.5
        _Tilling("_Tilling", Float) = 1.0
        [HDR]_Panning("_Panning", Vector) = (0.0, 0.0, 0.0, 0.0)
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

            fixed4 frag (v2f i) : SV_Target
            {
                switch (_Function)
                {
                    case 0:
                    {
                        float maskX = step(abs(i.uv.x - (sin(_CustomTime * 0.4) * 0.5 + 0.5)), 0.02 / _Ratio);
                        float maskY = step(abs(i.uv.y - (sin(_CustomTime * 0.637) * 0.5 + 0.5)), 0.02);
                        return float4(0.369453, 0.4733736, 0.511, max(maskX, maskY) * _Opacity);
                    }

                    case 1: return float4(i.uv, 0, _Opacity);
                    case 2: return float4(i.uv.xxx, _Opacity);
                    case 3: return float4(i.uv.yyy, _Opacity);
                    case 4: return float4(step(i.uv.x, _Threshold).xxx, _Opacity);
                    case 5: return float4(step(i.uv.y, _Threshold).xxx, _Opacity);
                    case 6: return _UseTexture ? float4(tex2Dlod(_Texture, float4(frac(i.uv * _Tilling), 0, 0)).xyz, _Opacity) : float4(frac(i.uv * _Tilling), 0, _Opacity);
                    case 7: return _UseTexture ? float4(tex2Dlod(_Texture, float4(frac(i.uv + _Panning), 0, 0)).xyz, _Opacity) : float4(frac(i.uv + _Panning.xy), 0, _Opacity);
                    case 8: return _UseTexture ? float4(tex2Dlod(_Texture, float4(frac(i.uv.x + _CustomTime * _Speed), i.uv.y, 0, 0)).xyz, _Opacity) : float4(frac(i.uv.x + _CustomTime * _Speed), i.uv.y, 0, _Opacity);
                }

                return float4(i.uv, 0, _Opacity);
            }
            ENDCG
        }
    }
}
