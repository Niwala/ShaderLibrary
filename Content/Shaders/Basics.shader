// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Sine"
{
	Properties
	{
		_Speed("Speed", Float) = 1
		_Frequency("Frequency", Float) = 4
		_Speed2("Speed 2", Float) = 1
		[Enum(Sine,0,Cosine,1,Floor,2,Noise Generator,3,Voronoi,4,Power,5,Fract,6,Smoothstep,7)]_Operator("Operator", Int) = 2
		_CustomTime("CustomTime", Float) = 0
		_Float0("Float 0", Float) = 0
		_Opacity("Opacity", Range( 0 , 1)) = 1
		_Ratio("Ratio", Float) = 0

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend SrcAlpha OneMinusSrcAlpha
		AlphaToMask Off
		Cull Back
		ColorMask RGBA
		ZWrite Off
		ZTest Always
		Offset 0 , 0
		
		
		
		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="ForwardBase" }
			CGPROGRAM

			

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_color : COLOR;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform half _Opacity;
			uniform int _Operator;
			uniform half _Ratio;
			uniform half _Speed;
			uniform half _CustomTime;
			uniform half _Frequency;
			uniform half _Speed2;
			uniform half _Float0;
					float2 voronoihash33( float2 p )
					{
						
						p = float2( dot( p, float2( 127.1, 311.7 ) ), dot( p, float2( 269.5, 183.3 ) ) );
						return frac( sin( p ) *43758.5453);
					}
			
					float voronoi33( float2 v, float time, inout float2 id, inout float2 mr, float smoothness, inout float2 smoothId )
					{
						float2 n = floor( v );
						float2 f = frac( v );
						float F1 = 8.0;
						float F2 = 8.0; float2 mg = 0;
						for ( int j = -1; j <= 1; j++ )
						{
							for ( int i = -1; i <= 1; i++ )
						 	{
						 		float2 g = float2( i, j );
						 		float2 o = voronoihash33( n + g );
								o = ( sin( time + o * 6.2831 ) * 0.5 + 0.5 ); float2 r = f - g - o;
								float d = 0.5 * dot( r, r );
						 		if( d<F1 ) {
						 			F2 = F1;
						 			F1 = d; mg = g; mr = r; id = o;
						 		} else if( d<F2 ) {
						 			F2 = d;
						
						 		}
						 	}
						}
						return F1;
					}
			
			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_color = v.color;
				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				half4 color17 = IsGammaSpace() ? half4(0.369453,0.4733736,0.511,0) : half4(0.1124567,0.1902185,0.2243642,0);
				half UvY108 = i.ase_texcoord1.xy.y;
				half UvX107 = ( i.ase_texcoord1.xy.x * _Ratio );
				half smoothstepResult91 = smoothstep( 0.0 , 1.0 , UvX107);
				half T54 = ( _Speed * _CustomTime );
				half lerpResult117 = lerp( UvX107 , smoothstepResult91 , ( ( sin( ( T54 * 2.0 ) ) * 0.5 ) + 0.5 ));
				half frequency83 = _Frequency;
				half time33 = 0.0;
				half2 voronoiSmoothId33 = 0;
				half temp_output_38_0 = ( ( UvX107 * _Frequency ) + T54 );
				half temp_output_96_0 = ( _Speed2 * _Float0 );
				half2 appendResult49 = (half2(temp_output_38_0 , temp_output_96_0));
				float2 coords33 = appendResult49 * 1.0;
				float2 id33 = 0;
				float2 uv33 = 0;
				float voroi33 = voronoi33( coords33, time33, id33, uv33, 0, voronoiSmoothId33 );
				half2 appendResult47 = (half2(temp_output_38_0 , temp_output_96_0));
				half simplePerlin2D34 = snoise( appendResult47 );
				simplePerlin2D34 = simplePerlin2D34*0.5 + 0.5;
				half temp_output_9_0 = ( ( UvX107 * _Frequency ) + T54 );
				half4 appendResult16 = (half4(color17.r , color17.g , color17.b , ( _Opacity * ( (float)_Operator == 7.0 ? step( UvY108 , lerpResult117 ) : ( (float)_Operator == 6.0 ? step( UvY108 , ( frac( ( T54 + ( UvX107 * frequency83 ) ) ) * 0.8 ) ) : ( (float)_Operator == 5.0 ? step( UvY108 , pow( UvX107 , ( ( sin( T54 ) * 0.5 ) + 1.5 ) ) ) : ( (float)_Operator == 4.0 ? step( UvY108 , ( voroi33 * 2.0 ) ) : ( (float)_Operator == 3.0 ? step( UvY108 , simplePerlin2D34 ) : ( (float)_Operator == 2.0 ? step( ( ( UvY108 * _Frequency ) + T54 ) , floor( temp_output_9_0 ) ) : ( (float)_Operator == 1.0 ? step( UvY108 , ( ( cos( temp_output_9_0 ) * 0.5 ) + 0.5 ) ) : step( UvY108 , ( ( sin( temp_output_9_0 ) * 0.5 ) + 0.5 ) ) ) ) ) ) ) ) ) )));
				
				
				finalColor = ( i.ase_color * appendResult16 );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18917
1941;4;1899;1053;1919.906;-1604.437;1;True;False
Node;AmplifyShaderEditor.RangedFloatNode;104;-2349.414,798.0786;Inherit;False;Property;_Ratio;Ratio;9;0;Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;105;-2404.656,665.4891;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;106;-2189.812,675.3103;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;12;-1894.95,266.0864;Inherit;False;Property;_Speed;Speed;0;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;94;-1927.271,367.3543;Inherit;False;Property;_CustomTime;CustomTime;6;0;Create;True;0;0;0;False;0;False;0;411.6582;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;95;-1721.089,283.9243;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;107;-1950.413,680.2214;Inherit;False;UvX;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;112;-1120.332,-110.1197;Inherit;False;107;UvX;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;54;-1571.902,273.1258;Inherit;False;T;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;7;-1357.909,135.159;Inherit;False;Property;_Frequency;Frequency;1;0;Create;True;0;0;0;False;0;False;4;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;57;-913.7867,92.662;Inherit;False;54;T;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;6;-873.8308,-26.2138;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;9;-716.8334,-28.21452;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode;21;-529.0945,177.3091;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;108;-1954.609,760.7973;Inherit;False;UvY;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;4;-523.2109,-34.1029;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;109;-1405.087,657.2062;Inherit;False;107;UvX;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;55;-1176.677,779.5544;Inherit;False;54;T;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-321.7712,180.7556;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;48;-1169.749,879.249;Inherit;False;Property;_Speed2;Speed 2;2;0;Create;True;0;0;0;False;0;False;1;0.2;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;36;-1123.825,683.0188;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;97;-1179.949,991.74;Inherit;False;Property;_Float0;Float 0;7;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;114;-1110.12,409.9089;Inherit;False;108;UvY;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;13;-328.4199,-30.01397;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;116;-188.2236,826.4035;Inherit;False;108;UvY;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;58;-1163.092,1346.184;Inherit;False;54;T;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;56;-920.1872,548.6618;Inherit;False;54;T;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;14;-167.1199,-23.41397;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;30;-155.2716,182.1555;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-837.399,425.475;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;96;-991.7668,930.3101;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;83;-1174.643,138.9062;Inherit;False;frequency;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;38;-980.7292,735.3325;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;27;-680.4012,423.4742;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;118;-1012.659,2104.417;Inherit;False;54;T;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;49;-741.7485,805.2488;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;47;-749.7485,665.2488;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;84;-894.5587,1614.518;Inherit;False;83;frequency;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;67;-994.0916,1347.184;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;31;31.81344,314.324;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;111;-902.2404,1504.003;Inherit;False;107;UvX;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;18;80.51389,20.49055;Inherit;False;Property;_Operator;Operator;5;1;[Enum];Create;True;0;8;Sine;0;Cosine;1;Floor;2;Noise Generator;3;Voronoi;4;Power;5;Fract;6;Smoothstep;7;0;False;0;False;2;4;False;0;1;INT;0
Node;AmplifyShaderEditor.StepOpNode;5;27.88497,101.4684;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FloorOpNode;24;-525.3268,398.1718;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.VoronoiNode;33;-546.476,891.8489;Inherit;True;0;0;1;0;1;False;1;False;False;False;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT2;1;FLOAT2;2
Node;AmplifyShaderEditor.StepOpNode;28;39.27076,525.1534;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;79;-818.6736,1733.021;Inherit;False;54;T;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;20;272.7922,163.3697;Inherit;False;0;4;0;INT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;62;-842.0921,1339.184;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;82;-646.873,1542.952;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;124;-854.6589,2121.417;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode;34;-582.821,635.6693;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;42;39.75006,746.9656;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;23;278.8338,312.2052;Inherit;False;0;4;0;INT;0;False;1;FLOAT;2;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;81;-522.873,1722.952;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;50;-320.7485,947.2488;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;63;-699.6883,1353.527;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;110;-725.4407,1253.403;Inherit;False;107;UvX;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;129;-676.9058,2127.437;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;130;-522.9058,2122.437;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;44;48.32153,977.7453;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;43;281.2312,477.5385;Inherit;False;0;4;0;INT;0;False;1;FLOAT;3;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;52;-526.3219,1274.999;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;80;-419.48,1604.769;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;91;-427.2403,1977.742;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;131;-384.9058,2120.437;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;88;-259.9644,1635.571;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.8;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;51;283.7676,637.0143;Inherit;False;0;4;0;INT;0;False;1;FLOAT;4;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;66;50.57056,1210.373;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;70;289.9436,1151.106;Inherit;False;0;4;0;INT;0;False;1;FLOAT;5;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;117;-129.1777,1957.44;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;77;55.36624,1434.523;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;87;284.5178,1413.756;Inherit;False;0;4;0;INT;0;False;1;FLOAT;6;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;92;61.4319,1696.96;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Compare;93;301.0446,1711.871;Inherit;False;0;4;0;INT;0;False;1;FLOAT;7;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RelayNode;98;538.2162,712.4985;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;102;248.9762,65.43188;Inherit;False;Property;_Opacity;Opacity;8;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;103;519.7062,140.1471;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;17;33.79666,-162.7917;Inherit;False;Constant;_Color;Color;1;0;Create;True;0;0;0;False;0;False;0.369453,0.4733736,0.511,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;99;458.9762,-212.5681;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;16;623.9289,-24.52489;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0.5;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ColorNode;74;818.8077,208.2225;Inherit;False;Property;_HeaderLeft;Header Left;3;0;Create;True;0;0;0;False;0;False;0.2078432,0.2784314,0.3529412,1;0.2078431,0.2784314,0.3529412,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;76;818.8078,391.2226;Inherit;False;Property;_HeaderRight;Header Right;4;0;Create;True;0;0;0;False;0;False;0.09803922,0.1333333,0.1686275,1;0.09803922,0.1333333,0.1686275,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;113;853.9762,571.2961;Inherit;False;107;UvX;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;100;863.9762,-28.56812;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;71;1265.808,274.2226;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StepOpNode;72;1089.808,662.2227;Inherit;False;2;0;FLOAT;0.82;False;1;FLOAT;0.8;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;75;1074.808,357.2226;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;1492.397,43.97684;Half;False;True;-1;2;ASEMaterialInspector;100;1;Sine;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;True;2;5;False;-1;10;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;2;False;-1;True;7;False;-1;True;True;0;False;-1;0;False;-1;True;1;RenderType=Opaque=RenderType;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;False;0
WireConnection;106;0;105;1
WireConnection;106;1;104;0
WireConnection;95;0;12;0
WireConnection;95;1;94;0
WireConnection;107;0;106;0
WireConnection;54;0;95;0
WireConnection;6;0;112;0
WireConnection;6;1;7;0
WireConnection;9;0;6;0
WireConnection;9;1;57;0
WireConnection;21;0;9;0
WireConnection;108;0;105;2
WireConnection;4;0;9;0
WireConnection;29;0;21;0
WireConnection;36;0;109;0
WireConnection;36;1;7;0
WireConnection;13;0;4;0
WireConnection;14;0;13;0
WireConnection;30;0;29;0
WireConnection;26;0;114;0
WireConnection;26;1;7;0
WireConnection;96;0;48;0
WireConnection;96;1;97;0
WireConnection;83;0;7;0
WireConnection;38;0;36;0
WireConnection;38;1;55;0
WireConnection;27;0;26;0
WireConnection;27;1;56;0
WireConnection;49;0;38;0
WireConnection;49;1;96;0
WireConnection;47;0;38;0
WireConnection;47;1;96;0
WireConnection;67;0;58;0
WireConnection;31;0;116;0
WireConnection;31;1;30;0
WireConnection;5;0;116;0
WireConnection;5;1;14;0
WireConnection;24;0;9;0
WireConnection;33;0;49;0
WireConnection;28;0;27;0
WireConnection;28;1;24;0
WireConnection;20;0;18;0
WireConnection;20;2;31;0
WireConnection;20;3;5;0
WireConnection;62;0;67;0
WireConnection;82;0;111;0
WireConnection;82;1;84;0
WireConnection;124;0;118;0
WireConnection;34;0;47;0
WireConnection;42;0;116;0
WireConnection;42;1;34;0
WireConnection;23;0;18;0
WireConnection;23;2;28;0
WireConnection;23;3;20;0
WireConnection;81;0;79;0
WireConnection;81;1;82;0
WireConnection;50;0;33;0
WireConnection;63;0;62;0
WireConnection;129;0;124;0
WireConnection;130;0;129;0
WireConnection;44;0;116;0
WireConnection;44;1;50;0
WireConnection;43;0;18;0
WireConnection;43;2;42;0
WireConnection;43;3;23;0
WireConnection;52;0;110;0
WireConnection;52;1;63;0
WireConnection;80;0;81;0
WireConnection;91;0;111;0
WireConnection;131;0;130;0
WireConnection;88;0;80;0
WireConnection;51;0;18;0
WireConnection;51;2;44;0
WireConnection;51;3;43;0
WireConnection;66;0;116;0
WireConnection;66;1;52;0
WireConnection;70;0;18;0
WireConnection;70;2;66;0
WireConnection;70;3;51;0
WireConnection;117;0;111;0
WireConnection;117;1;91;0
WireConnection;117;2;131;0
WireConnection;77;0;116;0
WireConnection;77;1;88;0
WireConnection;87;0;18;0
WireConnection;87;2;77;0
WireConnection;87;3;70;0
WireConnection;92;0;116;0
WireConnection;92;1;117;0
WireConnection;93;0;18;0
WireConnection;93;2;92;0
WireConnection;93;3;87;0
WireConnection;98;0;93;0
WireConnection;103;0;102;0
WireConnection;103;1;98;0
WireConnection;16;0;17;1
WireConnection;16;1;17;2
WireConnection;16;2;17;3
WireConnection;16;3;103;0
WireConnection;100;0;99;0
WireConnection;100;1;16;0
WireConnection;71;0;16;0
WireConnection;71;1;75;0
WireConnection;71;2;72;0
WireConnection;72;1;98;0
WireConnection;75;0;74;0
WireConnection;75;1;76;0
WireConnection;75;2;113;0
WireConnection;1;0;100;0
ASEEND*/
//CHKSM=5E2BF5608415F2348E817735D57EB8F8E8DD363A