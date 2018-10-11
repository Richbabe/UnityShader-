Shader "Unity Shaders Book/Chapter6-SpecularPixelLevel" {
	Properties {
		_Diffuse("Diffuse",Color) = (1,1,1,1)
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8.0,256)) = 20
	}
	SubShader {
		Pass{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

		//顶点着色器输入
		struct a2v {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
		};

		//顶点着色器输出
		struct v2f {
			float4 pos : SV_POSITION;
			float3 worldNormal : TEXCOORD0;
			float3 worldPos : TEXCOORD1;
		};

		//顶点着色器
		v2f vert(a2v v) {
			v2f o;

			//模型空间到裁剪空间的坐标变化
			o.pos = UnityObjectToClipPos(v.vertex);

			o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

			o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

			return o;
		}

		//片段着色器函数
		fixed4 frag(v2f i) : SV_Target{
			//获取环境光
			fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

			//将法线从模型空间转换到世界空间
			fixed3 worldNormal = normalize(i.worldNormal);

			//获得世界空间下的光照方向
			fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

			//计算漫反射光照
			fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

			//获取世界空间下的反射方向
			fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));

			//获取世界空间下的视线方向
			fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

			//计算镜面反射光照
			fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

			fixed3 color = ambient + diffuse + specular;

			return fixed4(color,1.0);
		}

			ENDCG
		}
	}
	FallBack "Diffuse"
}
