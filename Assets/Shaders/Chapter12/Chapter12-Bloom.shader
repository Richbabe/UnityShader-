Shader "Unity Shaders Book/Chapter 12/Chapter12-Bloom" {
	Properties {
		_MainTex("Base (RGB)", 2D) = "white" {}
		_Bloom("Bloom (RGB)", 2D) = "black" {}
		_LuminanceThreshold("Luminance Threshold", Float) = 0.5
		_BlurSize("Blur Size", Float) = 1.0
	}
	SubShader {
		CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _Bloom;
		float _LuminanceThreshold;
		float _BlurSize;

		//***定义提取较亮区域需要的顶点着色器和片段着色器Begin***
		//顶点着色器输出
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
		};

		//顶点着色器
		v2f vertExtractBright(appdata_img v) {
			v2f o;

			o.pos = UnityObjectToClipPos(v.vertex);

			o.uv = v.texcoord;

			return o;
		}

		//计算灰度值
		fixed luminance(fixed4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
		}

		//片段着色器
		fixed4 fragExtractBright(v2f i) : SV_Target{
			fixed4 c = tex2D(_MainTex, i.uv);
			fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);//clamp将值限定在0.0~1.0

			return c * val;
		}
		//***定义提取较亮区域需要的顶点着色器和片段着色器End***

		//***定义混合经过高斯模糊后的亮部图像和原图需要的顶点着色器和片段着色器Begin***
		//顶点着色器输出
		struct v2fBloom {
			float4 pos : SV_POSITION;
			half4 uv : TEXCOORD0;
		};

		//顶点着色器
		v2fBloom vertBloom(appdata_img v) {
			v2fBloom o;

			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv.xy = v.texcoord;//原图的纹理坐标
			o.uv.zw = v.texcoord;//高斯模糊后亮部图像的纹理坐标

			//对纹理坐标进行平台差异化（D3D和OpenGL屏幕空间坐标y轴不同）处理
			#if UNITY_UV_STARTS_AT_TOP			
						if (_MainTex_TexelSize.y < 0.0)
							o.uv.w = 1.0 - o.uv.w;
			#endif

			return o;
		}

		//片段着色器
		fixed4 fragBloom(v2fBloom i) : SV_Target{
			return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);//混合
		}
		//***定义混合经过高斯滤波后的亮部图像和原图需要的顶点着色器和片段着色器End***
		ENDCG

		ZTest Always Cull Off ZWrite Off

		//第一个Pass用于提取亮部图像
		Pass {
			CGPROGRAM
			#pragma vertex vertExtractBright  
			#pragma fragment fragExtractBright  

			ENDCG
		}

		//第二第三个Pass用于高斯模糊亮部图像
		UsePass "Unity Shaders Book/Chapter 12/Chapter12-GaussianBlur/GAUSSIAN_BLUR_VERTICAL"
		UsePass "Unity Shaders Book/Chapter 12/Chapter12-GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"

		//第四个Pass用于混合原图和高斯模糊后的亮部图像
		Pass{
			CGPROGRAM
			#pragma vertex vertBloom  
			#pragma fragment fragBloom  

			ENDCG
		}
	}
	FallBack Off
}
