# THIRD-PARTY SOFTWARE NOTICES AND LICENSES

This document contains licensing and attribution notices for open-source and third-party software components included in, statically linked with, or used by **Appendix**.

---

## 1. Summary of Component Licenses

| Component / Crate / Package | Ecosystem | Primary License | Copyright / Origin |
|---|---|---|---|
| **Harper Core (`harper-core`)** | Rust | Apache-2.0 | Copyright (c) Elijah Potter |
| **Candle (`candle-core`, `candle-transformers`, `candle-nn`)** | Rust | Apache-2.0 | Copyright (c) 2023 Hugging Face, Inc. |
| **Hugging Face Tokenizers (`tokenizers`)** | Rust | Apache-2.0 | Copyright (c) 2019-2024 Hugging Face, Inc. |
| **Rusqlite (`rusqlite`)** | Rust | MIT | Copyright (c) 2014-2024 The Rusqlite Developers |
| **SQLite (bundled)** | C | Public Domain | Dedicated to Public Domain |
| **Serde (`serde`, `serde_json`)** | Rust | MIT / Apache-2.0 | Copyright (c) 2014-2024 David Tolnay |
| **Chrono (`chrono`)** | Rust | MIT / Apache-2.0 | Copyright (c) 2014-2024 Kang Seonghoon, Chrono Developers |
| **JNI (`jni`, `jni-sys`)** | Rust | MIT / Apache-2.0 | Copyright (c) 2016-2024 The Rust-JNI Developers |
| **Sha2 (`sha2`)** | Rust | MIT / Apache-2.0 | Copyright (c) 2016-2024 RustCrypto Developers |
| **Thiserror & Anyhow** | Rust | MIT / Apache-2.0 | Copyright (c) 2019-2024 David Tolnay |
| **Once Cell (`once_cell`)** | Rust | MIT / Apache-2.0 | Copyright (c) 2018-2024 Aleksey Kladov |
| **Flutter SDK** | Dart/Flutter | BSD-3-Clause | Copyright (c) 2014 The Flutter Authors |
| **Dart FFI (`ffi`)** | Dart | BSD-3-Clause | Copyright (c) 2019 The Dart Project Authors |
| **Cupertino Icons (`cupertino_icons`)** | Assets | MIT | Copyright (c) 2016 Flutter Authors |
| **Qwen 2.5 0.5B Instruct (Model Weights)** | Model (Optional) | Apache-2.0 | Copyright (c) Alibaba Cloud / Qwen Team |

---

## 2. Apache License, Version 2.0

Applicable to: `harper-core`, `candle-core`, `candle-transformers`, `candle-nn`, `tokenizers`, `Qwen 2.5` model weights.

```
                              Apache License
                        Version 2.0, January 2004
                     http://www.apache.org/licenses/

TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION

1. Definitions.
   "License" shall mean the terms and conditions for use, reproduction,
   and distribution as defined by Sections 1 through 9 of this document.

   "Licensor" shall mean the copyright owner or entity authorized by
   the copyright owner that is granting the License.

   "Legal Entity" shall mean the union of the acting entity and all
   other entities that control, are controlled by, or are under common
   control with that entity. For the purposes of this definition,
   "control" means (i) the power, direct or indirect, to cause the
   direction or management of such entity, whether by contract or
   otherwise, or (ii) ownership of fifty percent (50%) or more of the
   outstanding shares, or (iii) beneficial ownership of such entity.

   "You" (or "Your") shall mean an individual or Legal Entity
   exercising permissions granted by this License.

   "Source" form shall mean the preferred form for making modifications,
   including but not limited to software source code, documentation
   source, and configuration files.

   "Object" form shall mean any form resulting from mechanical
   transformation or translation of a Source form, including but
   not limited to compiled object code, generated documentation,
   and conversions to other media types.

   "Work" shall mean the work of authorship, whether in Source or
   Object form, made available under the License, as indicated by a
   copyright notice that is included in or attached to the work.

   "Derivative Works" shall mean any work, whether in Source or Object
   form, that is based on (or derived from) the Work and for which the
   editorial revisions, annotations, elaborations, or other modifications
   represent, as a whole, an original work of authorship.

   "Contribution" shall mean any work of authorship, including
   the original version of the Work and any modifications or additions
   to that Work or Derivative Works thereof, that is intentionally
   submitted to Licensor for inclusion in the Work by the copyright owner
   or by an individual or Legal Entity authorized to submit on behalf of
   the copyright owner.

2. Grant of Copyright License. Subject to the terms and conditions of
   this License, each Contributor hereby grants to You a perpetual,
   worldwide, non-exclusive, no-charge, royalty-free, irrevocable
   copyright license to reproduce, prepare Derivative Works of,
   publicly display, publicly perform, sublicense, and distribute the
   Work and such Derivative Works in Source or Object form.

3. Grant of Patent License. Subject to the terms and conditions of
   this License, each Contributor hereby grants to You a perpetual,
   worldwide, non-exclusive, no-charge, royalty-free, irrevocable
   (except as stated in this section) patent license to make, have made,
   use, offer to sell, sell, import, and otherwise transfer the Work.

4. Redistribution. You may reproduce and distribute copies of the
   Work or Derivative Works thereof in any medium, with or without
   modifications, and in Source or Object form, provided that You
   meet the following conditions:

   (a) You must give any other recipients of the Work or Derivative
       Works a copy of this License; and
   (b) You must cause any modified files to carry prominent notices
       stating that You changed the files; and
   (c) You must retain, in the Source form of any Derivative Works
       that You distribute, all copyright, patent, trademark, and
       attribution notices from the Source form of the Work; and
   (d) If the Work includes a "NOTICE" text file as part of its
       distribution, then any Derivative Works that You distribute must
       include a readable copy of the attribution notices contained
       within such NOTICE file.

5. Submission of Contributions. Unless You explicitly state otherwise,
   any Contribution intentionally submitted for inclusion in the Work
   by You to the Licensor shall be under the terms and conditions of
   this License, without any additional terms or conditions.

6. Trademarks. This License does not grant permission to use the trade
   names, trademarks, service marks, or product names of the Licensor,
   except as required for reasonable and customary use in describing the
   origin of the Work and reproducing the content of the NOTICE file.

7. Disclaimer of Warranty. Unless required by applicable law or
   agreed to in writing, Licensor provides the Work (and each
   Contributor provides its Contributions) on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
   implied, including, without limitation, any warranties or conditions
   of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
   PARTICULAR PURPOSE.

8. Limitation of Liability. In no event and under no legal theory,
   whether in tort (including negligence), contract, or otherwise,
   shall any Contributor be liable to You for damages.
```

---

## 3. The MIT License

Applicable to: `rusqlite`, `serde`, `chrono`, `jni`, `sha2`, `thiserror`, `anyhow`, `once_cell`, `cupertino_icons`.

```
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 4. The 3-Clause BSD License

Applicable to: `Flutter SDK`, `Dart FFI`.

```
Copyright 2014 The Flutter Authors. All rights reserved.
Copyright 2019 The Dart Project Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Google LLC nor the names of its contributors
      may be used to endorse or promote products derived from this software
      without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
```

---

## 5. SQLite Public Domain Notice

Applicable to: SQLite (bundled inside `rusqlite`).

```
The author disclaims copyright to this source code. In place of
a legal notice, here is a blessing:

   May you do good and not evil.
   May you find forgiveness for yourself and forgive others.
   May you share freely, never taking more than you give.
```

