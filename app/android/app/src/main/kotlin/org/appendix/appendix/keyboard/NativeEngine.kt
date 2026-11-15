package org.appendix.appendix.keyboard

import android.util.Log

/**
 * JNI Bridge to appendix_core shared library (libappendix_core.so / appendix_core.dll).
 * Communicates directly with the offline Rust Harper grammar engine, readability insights,
 * and AI rewriting heuristics with zero overhead and 100% offline privacy.
 */
object NativeEngine {
    private const val TAG = "AppendixNativeEngine"
    private var isLoaded = false

    init {
        try {
            System.loadLibrary("appendix_core")
            isLoaded = true
            Log.i(TAG, "Successfully loaded native library: appendix_core")
        } catch (e: UnsatisfiedLinkError) {
            Log.w(TAG, "Native library 'appendix_core' not found on this architecture. Fallback mode enabled: ${e.message}")
            isLoaded = false
        }
    }

    fun isAvailable(): Boolean = isLoaded

    // Native C-ABI / JNI declarations matching rust/src/jni_bridge.rs
    external fun nativeCreateEngine(dialect: Int): Long
    external fun nativeCheckText(enginePtr: Long, text: String): String
    external fun nativeAnalyzeInsights(text: String): String
    external fun nativeRephrase(text: String, mode: Int): String
    external fun nativeFreeEngine(enginePtr: Long)
}

