Shader "Unity Shaders Book/Chapter6-DiffusePixelLevel" {
	Properties{
		_Diffuse("Diffuse",Color) = (1,1,1,1)
	}
		SubShader{
		Pass{
		Tags{ "LightMode" = "ForwardBase" }

		CGPROGRAM

#pragma vertex vert
#pragma fragment frag

#include "Lighting.cginc"

		fixed4 _Diffuse;

	//定义顶点着色器输入结构体
	struct a2v {
		float4 vertex : POSITION;
		float3 normal : NORMAL;
	};

	//定义顶点着色器输出结构体
	struct v2f {
		float4 pos : SV_POSITION;
		float3 worldNormal : TEXCOORD0;
	};

	//顶点着色器函数
	v2f vert(a2v v) {
		v2f o;

		o.pos = UnityObjectToClipPos(v.vertex);
		o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

		return o;
	}

	//片段着色器函数
	fixed4 frag(v2f i) : SV_Target{
		//获得环境光
		fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

		//归一化法线
		fixed3 worldNormal = normalize(i.worldNormal);


		//获得世界空间下的光照方向
		fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

		//计算漫反射光照
		fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

		fixed3 color = ambient + diffuse;

		return fixed4(color,1.0);
	}

		ENDCG
	}

	}
		Fallback "Diffuse"
}
