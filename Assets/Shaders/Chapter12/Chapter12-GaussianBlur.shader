Shader "Unity Shaders Book/Chapter 12/Chapter12-GaussianBlur" {
	Properties {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BlurSize ("Blur Size", Float) = 1.0
	}
	SubShader {
		CGINCLUDE

		#include "UnityCG.cginc"

		//定义Properties属性
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		float _BlurSize;

		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv[5] : TEXCOORD0;
		};

		//计算垂直方向坐标
		v2f vertBlurVertical(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			half2 uv = v.texcoord;

			o.uv[0] = uv;
			o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
			o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
			o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;

			return o;
		}

		//计算水平方向坐标
		v2f vertBlurHorizontal(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			half2 uv = v.texcoord;

			o.uv[0] = uv;
			o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
			o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
			o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;

			return o;
		}

		//片段着色器
		fixed4 fragBlur(v2f i) : SV_Target{
			float weight[3] = { 0.4026, 0.2442, 0.0545 };//由于对称性，只用保存三个高斯权重

			fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];

			for (int it = 1; it < 3; it++) {
				sum += tex2D(_MainTex, i.uv[it * 2 - 1]).rgb * weight[it];
				sum += tex2D(_MainTex, i.uv[it * 2]).rgb * weight[it];
			}

			return fixed4(sum, 1.0);
		}

		ENDCG

		ZTest Always Cull Off ZWrite Off

		Pass {
			NAME "GAUSSIAN_BLUR_VERTICAL"

			CGPROGRAM

			#pragma vertex vertBlurVertical  
			#pragma fragment fragBlur

			ENDCG
		}

		Pass {
			NAME "GAUSSIAN_BLUR_HORIZONTAL"

			CGPROGRAM

			#pragma vertex vertBlurHorizontal  
			#pragma fragment fragBlur

			ENDCG
		}
	}
	FallBack Off
}
