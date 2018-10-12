Shader "Unity Shaders Book/Chapter 7/Chapter7-MaskTexture" {
	Properties {
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Main Tex", 2D) = "white" {}
		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Bump Scale", Float) = 1.0
		_SpecularMask("Specular Mask", 2D) = "white"{}
		_SpeuclarScale("Specular Scale", Float) = 1.0
		_Specular("Specular", Color) = (1,1,1,1)
		_Gloss("Gloss", Range(8.0,256)) = 20
	}
	SubShader {
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
			float _BumpScale;
			sampler2D _SpecularMask;
			float _SpecularScale;
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
				float2 uv : TEXCOORD0;//xy储存_MainTex的纹理坐标，zw储存_BumpMap的纹理坐标
				float3 lightDir : TEXCOORD1;
				float3 viewDir :TEXCOORD2;
			};

			//定义顶点着色器
			v2f vert(a2v v) {
				v2f o;

				//模型空间到裁剪空间的坐标变化
				o.pos = UnityObjectToClipPos(v.vertex);

				//计算纹理贴图的纹理坐标
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				/*
				//计算副切线,即切线和法线的叉积，方向保存在切线的w分量重
				float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
				//计算模型空间到切线空间的转换矩阵
				float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
				*/
				//通过Unity内置宏实现模型空间到切线空间的转换
				TANGENT_SPACE_ROTATION;

				//将光照方向从模型空间转换到切线空间
				o.lightDir = mul(rotation, ObjSpaceLightDir(v.vertex)).xyz;
				//将视线方向从模型空间转换到切线空间
				o.viewDir = mul(rotation, ObjSpaceViewDir(v.vertex)).xyz;

				return o;
			}

			//定义片段着色器
			fixed4 frag(v2f i) : SV_Target{
				fixed3 tangentLightDir = normalize(i.lightDir);//切线空间的光照方向
				fixed3 tangentViewDir = normalize(i.viewDir);//切线空间的视线方向

				//获得法线贴图中的纹素
				fixed4 packedNormal = tex2D(_BumpMap, i.uv);
				fixed3 tangentNormal;
				//如果法线贴图的类型没有设置成“Normal map”：
				//tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
				//如果法线贴图的类型设置成“Normal map”，则用Unity内置宏:
				tangentNormal = UnpackNormal(packedNormal);
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);

				//获得遮罩纹理的纹素
				fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(halfDir, tangentNormal)), _Gloss) * specularMask;

				fixed3 color = ambient + diffuse + specular;

				return fixed4(color, 1.0);
			}

			ENDCG
		}
	}
	FallBack "Specular"
}
