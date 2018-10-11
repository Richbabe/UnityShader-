// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unity Shaders Book/Chapter 7/Chapter7-NormalMapWorldSpace" {
	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Main Tex", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
		_Specular("Specular", Color) = (1,1,1,1)
		_Gloss("Gloss", Range(8.0,256)) = 20
	}
	SubShader{
		Pass{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			//声明Properties中的变量
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;

			//定义顶点着色器输入
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

			//定义顶点着色器输出
			struct v2f {
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;//xy储存_MainTex的纹理坐标，zw储存_BumpMap的纹理坐标
				float4 TtoW0 : TEXCOORD1;
				float4 TtoW1 : TEXCOORD2;
				float4 TtoW2 : TEXCOORD3;
			};

			//定义顶点着色器
			v2f vert(a2v v) {
				v2f o;

				//模型空间到裁剪空间的坐标变化
				o.pos = UnityObjectToClipPos(v.vertex);

				//计算纹理贴图和法线贴图的纹理坐标
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				//计算切线空间到世界空间的转换矩阵(将世界空间的顶点坐标保存在w分量中)
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				return o;
			}

			//定义片段着色器
			fixed4 frag(v2f i) : SV_Target{
				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);

				//计算世界空间下的光照方向和视线方向
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				//获取切线空间的法线
				fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));
				bump.xy *= _BumpScale;
				bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));
				//将法线从切线空间转换到世界空间
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(bump, lightDir));

				fixed3 halfDir = normalize(lightDir + viewDir);

				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(halfDir, bump)), _Gloss);

				fixed3 color = ambient + diffuse + specular;

				return fixed4(color, 1.0);
			}

			ENDCG
		}
	}
	FallBack "Specular"
}