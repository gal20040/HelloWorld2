#if UNITY_ANDROID
using System;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace GoogleMobileAds.Assets.Scripts.Editor
{
    /// <summary>
    /// A fix for building for Android in GameCI when using Build Profiles.
    /// Restores signature passwords, version, and version code that Unity 6+ clears when activating a profile.
    /// https://github.com/game-ci/unity-builder/issues/713
    /// https://github.com/game-ci/unity-builder/issues/691
    /// </summary>
    public class AndroidGameCIBuildProfileFix : IPreprocessBuildWithReport
    {
        private const string _prefix = "[GameCI-Fix] ";

        // Run with very high priority (before other preprocessors)
        public int callbackOrder => -1000;

        public void OnPreprocessBuild(BuildReport report)
        {
            if (report.summary.platform != BuildTarget.Android)
            {
                return;
            }

            Debug.Log($"{_prefix}Starting Android Build Settings Restore...");

            var args = Environment.GetCommandLineArgs();

            // 1. Restore Keystore Signature Settings and Passwords
            var keystoreName = GetArgument(args, "-androidKeystoreName");
            var keystorePass = GetArgument(args, "-androidKeystorePass");
            var keyaliasName = GetArgument(args, "-androidKeyaliasName");
            var keyaliasPass = GetArgument(args, "-androidKeyaliasPass");
            // 2. Restore the version code (androidVersionCode)
            var versionCodeStr = GetArgument(args, "-androidVersionCode");
            // 3. Restore the application version (bundleVersion)
            var buildVersion = GetArgument(args, "-buildVersion");

            if (!string.IsNullOrWhiteSpace(keystoreName))
            {
                PlayerSettings.Android.useCustomKeystore = true;
                PlayerSettings.Android.keystoreName = keystoreName;
                Debug.Log($"{_prefix}Path to keystore restored: {keystoreName}");
            }

            if (!string.IsNullOrWhiteSpace(keystorePass))
            {
                PlayerSettings.Android.keystorePass = keystorePass;
                Debug.Log($"{_prefix}The keystore password has been successfully recovered.");
            }

            if (!string.IsNullOrWhiteSpace(keyaliasName))
            {
                PlayerSettings.Android.keyaliasName = keyaliasName;
                Debug.Log($"{_prefix}Keyalias name restored: {keyaliasName}");
            }

            if (!string.IsNullOrWhiteSpace(keyaliasPass))
            {
                PlayerSettings.Android.keyaliasPass = keyaliasPass;
                Debug.Log($"{_prefix}Password keyalias successfully recovered.");
            }

            if (!string.IsNullOrWhiteSpace(versionCodeStr) && int.TryParse(versionCodeStr, out var versionCode))
            {
                PlayerSettings.Android.bundleVersionCode = versionCode;
                Debug.Log($"{_prefix}Android version code restored: {versionCode}");
            }

            if (!string.IsNullOrWhiteSpace(buildVersion))
            {
                PlayerSettings.bundleVersion = buildVersion;
                Debug.Log($"{_prefix}Application version restored: {buildVersion}");
            }
        }

        private static string GetArgument(string[] args, string name)
        {
            for (var i = 0; i < args.Length - 1; i++)
            {
                if (string.Equals(args[i], name, StringComparison.OrdinalIgnoreCase))
                {
                    return args[i + 1];
                }
            }

            return string.Empty;
        }
    }
}
#endif
