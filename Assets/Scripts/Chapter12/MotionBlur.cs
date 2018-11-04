using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : PostEffectsBase{
    public Shader motionBlurShader;
    private Material motionBlurMaterial = null;
    public Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    [Range(0.0f, 0.9f)]
    public float blurAmount = 0.5f;//模糊参数，值越大运动拖尾效果越明显

    private RenderTexture accumulationTexture;//保存之前图像叠加的效果

    void OnDisable()
    {
        DestroyImmediate(accumulationTexture);//在下一次开始应用运动模糊时重新叠加图像
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            // Create the accumulation texture
            if (accumulationTexture == null || accumulationTexture.width != src.width || accumulationTexture.height != src.height)
            {
                DestroyImmediate(accumulationTexture);
                accumulationTexture = new RenderTexture(src.width, src.height, 0);
                accumulationTexture.hideFlags = HideFlags.HideAndDontSave;//使得accumulationTexture的销毁由自己控制
                Graphics.Blit(src, accumulationTexture);//将当前帧图像初始化accumulationTexture
            }

            // We are accumulating motion over frames without clear/discard
            // by design, so silence any performance warnings from Unity
            accumulationTexture.MarkRestoreExpected();

            material.SetFloat("_BlurAmount", 1.0f - blurAmount);

            Graphics.Blit(src, accumulationTexture, material);//将当前屏幕图像叠加到accumulationTexture中
            Graphics.Blit(accumulationTexture, dest);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
