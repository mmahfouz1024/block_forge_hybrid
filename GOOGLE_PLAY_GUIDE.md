# Google Play Publishing Guide — Block Forge: Kingdom

## 1. Ready Assets Generated
- App Icon (`512x512`): `store_assets/app_icon_512.png`
- Feature Graphic (`1024x500`): `store_assets/feature_graphic_1024x500.jpg`
- Android Launcher Icons (`mipmap-*`): `android/app/src/main/res/mipmap-*/ic_launcher.png`

## 2. Create Release Upload Keystore (One-Time)
```powershell
keytool -genkey -v -keystore android/app/upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Then copy `android/key.properties.example` to `android/key.properties` and put your real passwords.

## 3. Build Release App Bundle (`.aab`) for Google Play
```powershell
cd d:\app_sechard\block_forge_hybrid
flutter build appbundle --release
```
Output file: `build/app/outputs/bundle/release/app-release.aab`

## 4. Play Console Checklist
- **Target API:** Configured to Android 16 (API 36) via Flutter SDK defaults (`NDK 28.2` supports 16 KB memory page alignment).
- **Data Safety:** Declare "No user data collected or shared" (unless you add AdMob/Analytics later).
- **Content Rating (IARC):** Complete questionnaire (Everyone / PEGI 3).
- **Privacy Policy URL:** Host `PRIVACY_POLICY.md` on GitHub Pages, Firebase Hosting, or your website and paste its URL.
- **Screenshots:** Take 2–6 screenshots of the main menu, active board gameplay, adventure map, and kingdom builder.
