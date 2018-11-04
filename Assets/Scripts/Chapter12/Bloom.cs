using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bloom : PostEffectsBase{
    public Shader bloomShader;
    private Material bloomMaterial = null;
    public Material material
    {
        get
        {
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }

    [Range(0, 4)]
    public int iterations = 3;//高斯模糊迭代次数

    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;//模糊范围

    [Range(1, 8)]
    public int downSample = 2;//缩放系数

    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;//控制提取较亮区域时使用的阈值

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);

            int rtW = src.width / downSample;
            int rtH = src.height / downSample;

            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
            buffer0.filterMode = FilterMode.Bilinear;

            Graphics.Blit(src, buffer0, material, 0);//不经下采样，先提取较亮区域存于buffer0中

            //迭代进行高斯模糊
            for (int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // Render the vertical pass（用第2个Pass来进行垂直方向上的高斯模糊）
                Graphics.Blit(buffer0, buffer1, material, 1);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                // Render the horizontal pass（用第3个Pass来进行水平方向上的高斯模糊）
                Graphics.Blit(buffer0, buffer1, material, 2);

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            material.SetTexture("_Bloom", buffer0);//已经高斯模糊的Bloom纹理
            Graphics.Blit(src, dest, material, 3);//用第4个Pass混合原图和已经高斯模糊的Bloom纹理

            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
