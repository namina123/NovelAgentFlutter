# Android Release Signing

For `apps/novel_agent_app/android/app/build.gradle.kts`:

- `android.namespace` and `defaultConfig.applicationId` use `com.novelagent.app`
- `release` signing reads from `android/local.properties` or matching environment variables

## Local properties

Set these keys in `apps/novel_agent_app/android/local.properties`:

- `novel_agent_release_keystore_file`
- `novel_agent_release_keystore_password`
- `novel_agent_release_key_alias`
- `novel_agent_release_key_password`

## Environment variables

You can provide the same values through:

- `NOVEL_AGENT_ANDROID_RELEASE_KEYSTORE_FILE`
- `NOVEL_AGENT_ANDROID_RELEASE_KEYSTORE_PASSWORD`
- `NOVEL_AGENT_ANDROID_RELEASE_KEY_ALIAS`
- `NOVEL_AGENT_ANDROID_RELEASE_KEY_PASSWORD`

## Verification

Run:

```bash
flutter build apk --release
```

If the release signing inputs are missing, the Gradle script fails early with a message that lists the required keys instead of silently falling back to debug signing.
