// tsup.config.ts
import { defineConfig } from "tsup";
var getConfig = (config) => {
  return [
    {
      ...config,
      format: ["cjs", "esm"],
      platform: "node",
      dts: true
    },
    {
      ...config,
      format: ["iife"],
      platform: "browser"
    }
  ];
};
var tsup_config_default = defineConfig([
  // Default entrypoint
  ...getConfig({
    entry: ["src/index.ts"],
    outDir: "dist",
    sourcemap: true,
    clean: false,
    globalName: "sdk.core"
  }),
  ...getConfig({
    entry: ["src/constants/index.ts"],
    outDir: "dist/constants",
    sourcemap: true,
    clean: false,
    globalName: "sdk.core.constants"
  })
]);
export {
  tsup_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidHN1cC5jb25maWcudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9faW5qZWN0ZWRfZmlsZW5hbWVfXyA9IFwiL1VzZXJzL2xpYi11c2VyL3RlbXAva2VuZWUvdW5ydWdnYWJsZS5tZW1lL3BhY2thZ2VzL2NvcmUvdHN1cC5jb25maWcudHNcIjtjb25zdCBfX2luamVjdGVkX2Rpcm5hbWVfXyA9IFwiL1VzZXJzL2xpYi11c2VyL3RlbXAva2VuZWUvdW5ydWdnYWJsZS5tZW1lL3BhY2thZ2VzL2NvcmVcIjtjb25zdCBfX2luamVjdGVkX2ltcG9ydF9tZXRhX3VybF9fID0gXCJmaWxlOi8vL1VzZXJzL2xpYi11c2VyL3RlbXAva2VuZWUvdW5ydWdnYWJsZS5tZW1lL3BhY2thZ2VzL2NvcmUvdHN1cC5jb25maWcudHNcIjsvKiBlc2xpbnQtZGlzYWJsZSBpbXBvcnQvbm8tdW51c2VkLW1vZHVsZXMgKi9cbmltcG9ydCB7IGRlZmluZUNvbmZpZywgT3B0aW9ucyB9IGZyb20gJ3RzdXAnXG5cbmNvbnN0IGdldENvbmZpZyA9IChjb25maWc6IE9wdGlvbnMpOiBPcHRpb25zW10gPT4ge1xuICByZXR1cm4gW1xuICAgIHtcbiAgICAgIC4uLmNvbmZpZyxcbiAgICAgIGZvcm1hdDogWydjanMnLCAnZXNtJ10sXG4gICAgICBwbGF0Zm9ybTogJ25vZGUnLFxuICAgICAgZHRzOiB0cnVlLFxuICAgIH0sXG4gICAge1xuICAgICAgLi4uY29uZmlnLFxuICAgICAgZm9ybWF0OiBbJ2lpZmUnXSxcbiAgICAgIHBsYXRmb3JtOiAnYnJvd3NlcicsXG4gICAgfSxcbiAgXVxufVxuXG5leHBvcnQgZGVmYXVsdCBkZWZpbmVDb25maWcoW1xuICAvLyBEZWZhdWx0IGVudHJ5cG9pbnRcbiAgLi4uZ2V0Q29uZmlnKHtcbiAgICBlbnRyeTogWydzcmMvaW5kZXgudHMnXSxcbiAgICBvdXREaXI6ICdkaXN0JyxcbiAgICBzb3VyY2VtYXA6IHRydWUsXG4gICAgY2xlYW46IGZhbHNlLFxuICAgIGdsb2JhbE5hbWU6ICdzZGsuY29yZScsXG4gIH0pLFxuXG4gIC4uLmdldENvbmZpZyh7XG4gICAgZW50cnk6IFsnc3JjL2NvbnN0YW50cy9pbmRleC50cyddLFxuICAgIG91dERpcjogJ2Rpc3QvY29uc3RhbnRzJyxcbiAgICBzb3VyY2VtYXA6IHRydWUsXG4gICAgY2xlYW46IGZhbHNlLFxuICAgIGdsb2JhbE5hbWU6ICdzZGsuY29yZS5jb25zdGFudHMnLFxuICB9KSxcbl0pXG4iXSwKICAibWFwcGluZ3MiOiAiO0FBQ0EsU0FBUyxvQkFBNkI7QUFFdEMsSUFBTSxZQUFZLENBQUMsV0FBK0I7QUFDaEQsU0FBTztBQUFBLElBQ0w7QUFBQSxNQUNFLEdBQUc7QUFBQSxNQUNILFFBQVEsQ0FBQyxPQUFPLEtBQUs7QUFBQSxNQUNyQixVQUFVO0FBQUEsTUFDVixLQUFLO0FBQUEsSUFDUDtBQUFBLElBQ0E7QUFBQSxNQUNFLEdBQUc7QUFBQSxNQUNILFFBQVEsQ0FBQyxNQUFNO0FBQUEsTUFDZixVQUFVO0FBQUEsSUFDWjtBQUFBLEVBQ0Y7QUFDRjtBQUVBLElBQU8sc0JBQVEsYUFBYTtBQUFBO0FBQUEsRUFFMUIsR0FBRyxVQUFVO0FBQUEsSUFDWCxPQUFPLENBQUMsY0FBYztBQUFBLElBQ3RCLFFBQVE7QUFBQSxJQUNSLFdBQVc7QUFBQSxJQUNYLE9BQU87QUFBQSxJQUNQLFlBQVk7QUFBQSxFQUNkLENBQUM7QUFBQSxFQUVELEdBQUcsVUFBVTtBQUFBLElBQ1gsT0FBTyxDQUFDLHdCQUF3QjtBQUFBLElBQ2hDLFFBQVE7QUFBQSxJQUNSLFdBQVc7QUFBQSxJQUNYLE9BQU87QUFBQSxJQUNQLFlBQVk7QUFBQSxFQUNkLENBQUM7QUFDSCxDQUFDOyIsCiAgIm5hbWVzIjogW10KfQo=
