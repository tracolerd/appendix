# APPENDIX — EVIDENCE-BASED TECHNICAL AUDIT & GAP ANALYSIS

**Audit Date**: 2026-11-15  
**Auditor**: Senior Software Architect & Technical Co-founder  
**Project Root**: `C:\AA. Disks\Workstation\Project Typing App`  
**GitHub Repository**: `https://github.com/tracolerd/appendix`  
**Inspected Commit**: `82c0f54607623368ae5dba4989b556d5e05d3744` (Tag: `v0.1.0`)

---

## ১. নির্বাহী মূল্যায়ন ও বাস্তবতা (Executive Assessment)

আমরা আমাদের প্রজেক্টের পূর্ববর্তী "Final Engineering Report"-এর প্রতিটি দাবি বাস্তব কোডবেস, কম্পাইলার লগ, টেস্ট রান এবং গিটহাব অ্যাকশনস এক্সিকিউশনের প্রেক্ষিতে কঠোরভাবে অডিট করেছি।

**স্পষ্ট ও দ্ব্যর্থহীন সত্য:**
1. **Core Grammar Engine & FFI**: Harper Core 3.2.0, FST Dictionary, US/UK Dialect, Syllable Counter, Readability Metrics এবং SQLite History **১০০% বাস্তবে কার্যকর ও টেস্টেড**।
2. **Local AI Rewriting**: **বাস্তবে কার্যকর নয় (Placeholder / Heuristic Mock)**। কোনো Neural Inference Engine (`llama.cpp` / ONNX Runtime) ইন্টিগ্রেট করা হয়নি। কোনো GGUF মডেল ফাইল নেই। ১২টি মোডের মধ্যে ৯টি মোড কেবল অপরিবর্তিত মূল টেক্সট ফেরত দেয়, আর বাকি ৩টি মোড সাধারণ স্ট্রিং রিপ্লেসমেন্ট ব্যবহার করে।
3. **Android Application & Keyboard**: Rust Shared Libraries (`arm64-v8a`, `x86_64`), Kotlin IME কোড এবং `app-debug.apk` (১৮৩ MB) বাস্তবে কম্পাইল ও প্যাকেজ হয়েছে। কিন্তু বাস্তব কোনো ফিজিক্যাল ডিভাইসে ইনস্টল করে অ্যান্ড-টু-অ্যান্ড টেস্ট করা হয়নি।
4. **iOS Keyboard Extension**: সুইফট কোড (`KeyboardViewController.swift`) লেখা হলেও Xcode প্রজেক্ট ফাইলে (`project.pbxproj`) কোনো Extension Target যোগ করা হয়নি। ফলে এটি এখনো iOS বাইনারি হিসেবে কম্পাইলযোগ্য নয়।
5. **CI/CD & GitHub Release**: GitHub Actions-এ Windows ও Android বিল্ড সফল হলেও, macOS প্যাকেজিং স্টেপে পাথ সংক্রান্ত ভুলের কারণে রিলিজ ওয়ার্কফ্লো ফেইল করেছে। ফলে GitHub-এ এখনও কোনো অফিশিয়াল রিলিজ আর্টফ্যাক্ট রিলিজ হয়নি।

---

## ২. ফিচারভিত্তিক ক্লাসিফিকেশন মেট্রিক্স (Feature Audit Matrix)

আমরা সমগ্র সিস্টেমের প্রতিটি ফিচারকে ৪টি শ্রেণিতে ভাগ করেছি:

| ফিচার / কম্পোনেন্ট | স্ট্যাটাস শ্রেণি | বাস্তব কোড লোকেশন | বাস্তব অবস্থা ও সীমাবদ্ধতা |
|---|---|---|---|
| **Harper Grammar Checking** | **1. Fully Implemented & Verified** | `rust/src/lib.rs:49-105` | Harper Core 3.2.0 দিয়ে অফলাইনে সাব-মিলিমিটারে গ্রামার ও বানান চেক কাজ করছে। ৮/৮ টেস্ট পাসড। |
| **US/UK Dialect Switching** | **1. Fully Implemented & Verified** | `rust/src/lib.rs:33-47` | FST ডিকশনারির সাথে আমেরিকান ও ব্রিটিশ ডায়ালেক্ট ডাইনামিক সুইচিং পুরোপুরি কার্যকর। |
| **Readability Metrics** | **1. Fully Implemented & Verified** | `rust/src/insights.rs` | Flesch Reading Ease, Flesch-Kincaid Grade, Syllable কাউন্টার ও TTR কার্যকর। |
| **SQLite Draft History** | **1. Fully Implemented & Verified** | `rust/src/history.rs` | লোকাল `rusqlite` ড্রাফট সেভ, লিস্ট, ডিলিট এবং ক্লিয়ার বাস্তবে কার্যকর। |
| **Flutter Editor UI** | **1. Fully Implemented & Verified** | `app/lib/features/editor/` | ডিবউন্সড টাইপিং, স্কুইগলি মার্কার, সাইডবার, টুলবার ও ডার্ক/লাইট মোড টেস্টেড (১৭/১৭ টেস্ট পাসড)। |
| **Zero Telemetry / Trackers** | **1. Fully Implemented & Verified** | `pubspec.yaml`, `Cargo.toml` | কোডবেসে কোনো থার্ড-পার্টি ট্র্যাকিং এসডিকে (Firebase, Mixpanel, Sentry) বা নেটওয়ার্ক কল নেই। |
| **Android NDK Compilation** | **1. Fully Implemented & Verified** | `app/android/.../jniLibs/` | `arm64-v8a` (২০.২MB) এবং `x86_64` (২০.৮MB) `.so` বাস্তবে কম্পাইলড ও প্যাকেজড। |
| **Android APK Build** | **1. Fully Implemented & Verified** | `app/build/.../app-debug.apk` | ১৮৩ MB APK সফলভাবে তৈরি হয়েছে এবং `.so` লাইব্রেরি ভেতরের `lib/` ডিরেক্টরিতে উপস্থিত। |
| **Android IME (Kotlin Code)** | **2. Partially Implemented** | `AppendixInputMethodService.kt` | সার্ভিস ও ক্যান্ডিডেট বার কোড প্রস্তুত, কিন্তু লাইভ ফিজিক্যাল ডিভাইসে অ্যান্ড-টু-অ্যান্ড টেস্ট করা হয়নি। |
| **Windows Desktop Build** | **2. Partially Implemented** | `app/appendix_core.dll` | C-ABI DLL লোডিং ও FFI টেস্টেড। GitHub Actions-এ বিল্ড হলেও লোকাল মেশিনে Visual Studio instance রেজিস্ট্রেশন না থাকায় লোকাল বিল্ড ব্লকড। |
| **macOS Desktop Build** | **2. Partially Implemented** | `scripts/build_apple.sh` | উইন্ডোজ থেকে ম্যাক বিল্ড সম্ভব নয়। GitHub Actions-এ dylib কম্পাইল হলেও রিলিজ জিপ স্টেপে পাথ এররে ফেইল করেছে। |
| **iOS Keyboard Extension** | **2. Partially Implemented** | `app/ios/AppendixKeyboard/` | সুইফট কোড লেখা আছে, কিন্তু `Runner.xcodeproj/project.pbxproj`-এ টার্গেট ইন্টিগ্রেট করা হয়নি। IPA বিল্ড করা হয়নি। |
| **CI/CD Pipeline** | **2. Partially Implemented** | `.github/workflows/` | CI-তে Windows, Linux ও Android জব সফল। কিন্তু Release পাইপলাইনে macOS জিপ ক্রিয়েশন ফেইল করায় রিলিজ পাবলিশ হয়নি। |
| **Local AI (LLM / SLM)** | **3. Placeholder / Mock Only** | `rust/src/ai_rephrase.rs` | `llama.cpp` বা কোনো নিউরাল ইনফারেন্স নেই। GGUF ফাইল নেই। কোনো মডেল লোডিং নেই। |
| **12 AI Rewriting Modes** | **3. Placeholder / Mock Only** | `rust/src/ai_rephrase.rs:106-178` | ৯টি মোড হুবহু মূল টেক্সট ফেরত দেয়। মাত্র ৩টি মোডে সাধারণ স্ট্রিং রিপ্লেসমেন্ট রুলস আছে। |
| **Model SHA-256 Verification** | **4. Not Implemented** | `models/model_manifest.json` | শুধু JSON স্কিমা ফাইলে উল্লেখ আছে, কোনো কোড ইমপ্লিমেন্টেশন নেই। |
| **Physical Device Verification** | **4. Not Implemented** | — | Android বা iOS ফিজিক্যাল ডিভাইসে টেস্ট চালানো হয়নি। |

---

## ৩. Local AI-এর অকাট্য প্রমাণভিত্তিক অডিট (Evidence-Based AI Audit)

আমরা একই টেস্ট সেন্টেন্স দিয়ে `appendix_core.dll`-এর `appendix_ai_rewrite()` ফাংশন বাস্তবে ১২টি মোডে রান করিয়েছি:

**Sample Input:**  
`"In order to achieve great results, we don't wanna buy cheap stuff on a daily basis."`

### বাস্তব ফলাফল পরীক্ষা:

| মোড আইডি ও নাম | প্রকৃত আউটপুট (Actual Output) | স্ট্যাটাস | বাস্তব রূপায়ণ |
|---|---|---|---|
| **Mode 0: Rephrase** | `"In order to achieve great results, we don't wanna buy cheap stuff on a daily basis."` | ❌ **Not Implemented** | হুবহু মূল টেক্সট ফেরত দিয়েছে (`revised == original`) |
| **Mode 1: Make Professional** | `"In order to achieve great results, we don't wanna buy cheap stuff on a daily basis."` | ❌ **Not Implemented** | হুবহু মূল টেক্সট ফেরত দিয়েছে (`revised == original`) |
| **Mode 2: Make Academic** | `"In order to achieve great results, we don't wanna buy cheap stuff on a daily basis."` | ❌ **Not Implemented** | হুবহু মূল টেক্সট ফেরত দিয়েছে (`revised == original`) |
| **Mode 3: Make Formal** | `"In order to achieve great results, we do not want to purchase cheap stuff on a daily basis."` | ⚠️ **Heuristic Rule** | সাধারণ স্ট্রিং রিপ্লেস (`don't->do not`, `wanna->want to`, `buy->purchase`) |
| **Mode 4: Make Casual** | `"In order to achieve great results, we don't wanna buy cheap stuff on a daily basis."` | ⚠️ **Heuristic Rule** | সাধারণ স্ট্রিং রিপ্লেস (`cannot->can't` ইত্যাদি খুঁজছিল, না পেয়ে অপরিবর্তিত ফেরত দিয়েছে) |
| **Mode 5: Make Concise** | `"To achieve great results, we don't wanna buy cheap stuff daily."` | ⚠️ **Heuristic Rule** | সাধারণ স্ট্রিং রিপ্লেস (`In order to->To`, `on a daily basis->daily`) |
| **Mode 6: Expand Sentence** | `"In order to achieve great results, we don't wanna buy cheap stuff on a daily basis."` | ❌ **Not Implemented** | হুবহু মূল টেক্সট ফেরত দিয়েছে (`revised == original`) |
| **Mode 7: Improve Clarity** | `"In order to achieve great results, we don't wanna buy cheap stuff on a daily basis."` | ❌ **Not Implemented** | হুবহু মূল টেক্সট ফেরত দিয়েছে (`revised == original`) |
| **Mode 8: Improve Vocabulary**| `"In order to achieve great results, we don't wanna buy cheap stuff on a daily basis."` | ❌ **Not Implemented** | হুবহু মূল টেক্সট ফেরত দিয়েছে (`revised == original`) |
| **Mode 9: Simplify** | `"In order to achieve great results, we don't wanna buy cheap stuff on a daily basis."` | ❌ **Not Implemented** | হুবহু মূল টেক্সট ফেরত দিয়েছে (`revised == original`) |
| **Mode 10: Active to Passive** | `"In order to achieve great results, we don't wanna buy cheap stuff on a daily basis."` | ❌ **Not Implemented** | হুবহু মূল টেক্সট ফেরত দিয়েছে (`revised == original`) |
| **Mode 11: Passive to Active** | `"In order to achieve great results, we don't wanna buy cheap stuff on a daily basis."` | ❌ **Not Implemented** | হুবহু মূল টেক্সট ফেরত দিয়েছে (`revised == original`) |

### AI গ্যাপ বিশ্লেষণ:
1. `rust/Cargo.toml`-এ কোনো `llama-cpp-rs`, `candle`, বা `ort` ক্রেট নেই।
2. `models/` ডিরেক্টরিতে কোনো `.gguf` মডেল ফাইল নেই।
3. `RewriteResult.engine` সবসময় হার্ডকোডেড `"Heuristic (Offline)"` স্ট্রিং প্রদান করে।
4. **সিদ্ধান্ত:** লোকাল এআই নিউরাল ইনফারেন্স বর্তমান কোডবেসে সম্পূর্ণ অনুপস্থিত।

---

## ৪. প্ল্যাটফর্ম ও বিল্ড ভেরিফিকেশন ফলাফল

### Windows
- **লোকাল বিল্ড**: `appendix_core.dll` সম্পূর্ণ কার্যকর। Dart FFI দিয়ে গ্রামার চেক ও রিডাবিলিটি অ্যানালাইসিস পুরোপুরি কাজ করে। তবে Flutter Windows executable তৈরির জন্য স্থানীয় Visual Studio C++ workload `vswhere`-এ আনরেজিস্টার্ড থাকায় লোকাল `flutter build windows` ব্যর্থ হয়।
- **GitHub Actions**: ক্লাউড রানারে Windows Release সম্পূর্ণ সফল (`appendix-windows-x64.zip` তৈরি হয়েছে)।

### Android
- **কম্পাইলেশন**: NDK 27.2 দিয়ে `libappendix_core.so` (arm64-v8a ও x86_64) কম্পাইল হয়েছে।
- **APK বিল্ড**: `flutter build apk --debug` সফলভাবে ১৮৩ MB APK তৈরি করেছে।
- **সীমাবদ্ধতা**: কোড প্রস্তুত থাকলেও কোনো ফিজিক্যাল স্মার্টফোনে কিবোর্ড চালু করে দীর্ঘমেয়াদি টাইপিং ও স্ট্যাবিলিটি টেস্ট করা হয়নি।

### macOS
- **লোকাল বিল্ড**: উইন্ডোজ হোস্ট থেকে ম্যাক ওএস বাইনারি কম্পাইল করা অসম্ভব।
- **GitHub Actions**: `cargo build` দিয়ে ইউনিভার্সাল dylib তৈরি এবং `flutter build macos` সফল হয়েছে।
- **ত্রুটি**: `.github/workflows/release.yml`-এর ১৮৩ নং লাইনে `cd app/build/macos/Build/Products/Release` করার পর `zip -r ../../../../../dist/appendix-macos.zip` কল করা হয়েছে। এখানে রিলেটিভ পাথ এক ধাপ বেশি (`../../../../../` এর বদলে `../../../../` হওয়া উচিত ছিল), যার ফলে জিপ তৈরি ব্যর্থ হয়ে জব এক্সিট কোড ১৫ দিয়ে ক্র্যাশ করেছে।

### iOS
- **প্রজেক্ট স্টেটাস**: `app/ios/AppendixKeyboard/` ডিরেক্টরিতে সুইফট কোড আছে। কিন্তু `Runner.xcodeproj/project.pbxproj` ফাইলে এই এক্সটেনশনটি কোনো Xcode Target হিসেবে কনফিগার করা হয়নি।
- **সীমাবদ্ধতা**: উইন্ডোজ থেকে iOS বিল্ড বা ভেরিফাই করা প্রযুক্তিগতভাবে অসম্ভব। ম্যাকওএস এবং Xcode ছাড়া এটিকে কার্যকর আইওএস কিবোর্ড হিসেবে গণ্য করা যাবে না।

---

## ৫. প্রাইভেসি ও অফলাইন আইসোলেশন অডিট

1. **অ্যান্ড্রয়েড নেটওয়ার্ক অ্যাক্সেস**: `AndroidManifest.xml`-এ `android.permission.INTERNET` অনুপস্থিত। এটি একটি চমৎকার ও নিখুঁত হার্ডওয়্যার-লেভেল গ্যারান্টি।
2. **আইওএস কিবোর্ড অ্যাক্সেস**: `Info.plist`-এ `RequestsOpenAccess = false` কিবোর্ড এক্সটেনশনকে শতভাগ অফলাইন রাখে। **তবে সতর্কতা:** এটি শুধুমাত্র কিবোর্ড এক্সটেনশনের ক্ষেত্রে প্রযোজ্য, মূল কন্টেইনার অ্যাপের ক্ষেত্রে নয়। মূল অ্যাপে ইন্টারনেট পারমিশন নিষিদ্ধ করার কোনো আইওএস প্রোফাইল সেট করা হয়নি (যদিও আমাদের ডার্ট কোডে কোনো নেটওয়ার্ক কল নেই)।
3. **টেলিমেট্রি উপস্থিতি**: কোডবেসে কোনো অ্যানালিটিক্স, ক্র্যাশ রিপোর্টার বা টেলিমেট্রি লাইব্রেরি নেই। এই দাবিটি ১০০% সত্য।

---

## ৬. লাইভ টেস্ট রান ফলাফল (Live Test Verification)

আমরা অডিট চলাকালে লোকাল মেশিনে সরাসরি টেস্ট রান করেছি:

### Rust Core Unit Tests
- **কমান্ড**: `cargo test -- --nocapture`
- **ফলাফল**:
  - `ai_rephrase::tests::test_chatml_formatting ... ok`
  - `ai_rephrase::tests::test_heuristic_fallback_formal ... ok`
  - `insights::tests::test_syllable_counter ... ok`
  - `ai_rephrase::tests::test_heuristic_fallback_concise ... ok`
  - `insights::tests::test_insights_analysis ... ok`
  - `tests::test_c_abi_insights_and_rewrite ... ok`
  - `history::tests::test_history_crud ... ok`
  - `tests::test_grammar_engine_detects_error ... ok`
- **মোট**: **8 passed, 0 failed, 0 ignored** (সময়: 4.15s)

### Flutter Widget & Unit Tests
- **কমান্ড**: `flutter test --reporter expanded`
- **ফলাফল**:
  - `WritingEditorController Tests (7 tests) ... ok`
  - `FFI Native Integration Tests (2 tests) ... ok`
  - `KeyboardSettingsScreen Tests (6 tests) ... ok`
  - `Appendix app boots and renders main editor (2 tests) ... ok`
- **মোট**: **17 passed, 0 failed, 0 skipped** (সময়: 2.5s)

### Flutter Static Analysis
- **কমান্ড**: `flutter analyze`
- **ফলাফল**: **No issues found!** (সময়: 4.2s)

---

## ৭. পূর্ববর্তী রিপোর্টের অতিরঞ্জিত দাবিসমূহ ও প্রকৃত সত্য (Correction of Exaggerations)

| পূর্ববর্তী ভুল বা অতিরঞ্জিত দাবি | প্রকৃত বাস্তব সত্য (Audit Reality) |
|---|---|
| *"Fully integrated Local AI (Qwen 2.5 SLM)"* | **সম্পূর্ণ অসত্য**। কোনো নিউরাল ইঞ্জিন বা মডেল ফাইল যুক্ত নেই। |
| *"১২টি কার্যকর AI rewriting mode"* | **অতিরঞ্জিত**। মাত্র ৩টি মোডে প্রাথমিক রুলস আছে, বাকি ৯টি মোড মূল টেক্সট হুবহু ফিরিয়ে দেয়। |
| *"সম্পূর্ণ কার্যকর iOS Deployment"* | **অসত্য**। কোড ড্রাফট করা হলেও Xcode টার্গেটে যুক্ত করা হয়নি এবং কোনো IPA বিল্ড হয়নি। |
| *"রিলিজ v0.1.0 প্রকাশিত হয়েছে"* | **অসম্পূর্ণ**। গিট ট্যাগ পুশ হলেও GitHub Actions-এ ম্যাক জিপ পাথের ভুলের কারণে কোনো ফাইল রিলিজ পেজে ওঠেনি। |
| *"প্রোডাকশন-রেডি ক্রস-প্ল্যাটফর্ম রিলিজ"* | **অকালপক্ব দাবি**। হার্পার গ্রামার ও অ্যান্ড্রয়েড এপিকে কম্পাইলেশন চমৎকার হলেও সামগ্রিক সিস্টেম এখনো আলফা/প্রোটোটাইপ স্টেজে রয়েছে। |

---

## ৮. সংশোধিত ডেভেলপমেন্ট রোডম্যাপ ও পরবর্তী অগ্রাধিকার (Corrected Roadmap)

প্রজেক্টকে সত্যিকার অর্থে একটি শক্তিশালী ও বাস্তব সফটওয়্যার হিসেবে প্রতিষ্ঠা করতে নিচের অগ্রাধিকার অনুযায়ী কাজ করা আবশ্যক:

### Priority 1: GitHub Actions Release Workflow ফিক্স (সহজ ও তাৎক্ষণিক)
- `.github/workflows/release.yml`-এর পাথ ফিক্স করা যাতে `appendix-macos.zip` সঠিকভাবে তৈরি হয় এবং GitHub Release-এ Windows, Android ও macOS আর্টফ্যাক্ট স্বয়ংক্রিয়ভাবে আপলোড হয়।

### Priority 2: Real Local AI Inference Engine ইন্টিগ্রেশন (সবচেয়ে গুরুত্বপূর্ণ টেকনিক্যাল গ্যাপ)
- Rust ক্রেটে `llama-cpp-2` অথবা `ort` (ONNX Runtime) যুক্ত করা।
- Qwen 2.5 0.5B / 1.5B GGUF মডেল ডাউনলোডার বা বান্ডলার তৈরি করা।
- ১২টি রিরাইটিং মোডকে প্রকৃত SLM ইনফারেন্সে সংযুক্ত করা।
- হার্ডকোডেড heuristic fallback-কে শুধুমাত্র মডেল না থাকার ক্ষেত্রে ব্যাকআপ হিসেবে রাখা।

### Priority 3: Xcode Project-এ iOS Keyboard Extension টার্গেট ইন্টিগ্রেশন
- `project.pbxproj` ফাইলে `AppendixKeyboard` টার্গেট যুক্ত করা, যাতে ম্যাক রানারে বা Xcode-এ সরাসরি iOS কিবোর্ড ও অ্যাপ বিল্ড করা সম্ভব হয়।

### Priority 4: বাস্তব ডিভাইসে ফিল্ড টেস্ট ও ফিডব্যাক
- তৈরি হওয়া `app-debug.apk` একটি ফিজিক্যাল অ্যান্ড্রয়েড ফোনে সাইডলোড করে কিবোর্ড অ্যাক্টিভেশন, সাজেশন এবং মেমরি কনজাম্পশন পরীক্ষা করা।

