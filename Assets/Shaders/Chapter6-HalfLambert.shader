// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter6-HalfLambert" {
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
		fixed3 color : COLOR;
	};

	//顶点着色器函数
	v2f vert(a2v v) {
		v2f o;

		o.pos = UnityObjectToClipPos(v.vertex);

		//获得环境光
		fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

		//将法线从模型空间转换到世界空间
		fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));;

		//获得世界空间下的光照方向
		fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

		//计算漫反射光照
		fixed halfLambert = dot(worldNormal, worldLight) * 0.5 + 0.5;
		fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambert;

		o.color = ambient + diffuse;

		return o;
	}

	//片段着色器函数
	fixed4 frag(v2f i) : SV_Target{
		return fixed4(i.color,1.0);
	}

		ENDCG
	}

	}
		Fallback "Diffuse"
}
