using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class CustomPostProcessRenderFeature : ScriptableRendererFeature
{
    [System.Serializable]
    public class CustomPostProcessSettings
    {
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        public Material postProcessMaterial = null;
    }

    public CustomPostProcessSettings settings = new CustomPostProcessSettings();

    CustomPostProcessRenderPass customPostProcessPass;

    public override void Create()
    {
        customPostProcessPass = new CustomPostProcessRenderPass(settings.postProcessMaterial);
        customPostProcessPass.renderPassEvent = settings.renderPassEvent;
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.postProcessMaterial == null)
        {
            Debug.LogWarning("Missing post process material. CustomPostProcessRenderFeature will not execute.");
            return;
        }
        renderer.EnqueuePass(customPostProcessPass);
    }

    class CustomPostProcessRenderPass : ScriptableRenderPass
    {
        private Material postProcessMaterial;
        private RenderTargetIdentifier source { get; set; }
        private RenderTargetHandle temporaryTexture;

        public CustomPostProcessRenderPass(Material material)
        {
            postProcessMaterial = material;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var cameraTargetDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            cameraTargetDescriptor.depthBufferBits = 0;
            cmd.GetTemporaryRT(temporaryTexture.id, cameraTargetDescriptor);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            CommandBuffer cmd = CommandBufferPool.Get("CustomPostProcess");

            RenderTargetIdentifier cameraColorTargetIdent = renderingData.cameraData.renderer.cameraColorTarget;
            Blit(cmd, cameraColorTargetIdent, temporaryTexture.Identifier(), postProcessMaterial);
            Blit(cmd, temporaryTexture.Identifier(), cameraColorTargetIdent);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            cmd.ReleaseTemporaryRT(temporaryTexture.id);
        }
    }
}
