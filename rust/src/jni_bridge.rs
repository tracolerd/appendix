use jni::objects::{JClass, JString};
use jni::sys::{jint, jlong, jstring};
use jni::JNIEnv;

use crate::ai_rephrase::RewriteMode;
use crate::insights::InsightsEngine;
use crate::{EnglishDialect, GrammarEngine};

/// JNI bridge to allow native Android Kotlin code to directly interact with appendix_core
#[no_mangle]
pub extern "system" fn Java_org_appendix_appendix_keyboard_NativeEngine_nativeCreateEngine(
    _env: JNIEnv,
    _class: JClass,
    dialect: jint,
) -> jlong {
    let dialect = if dialect == 1 {
        EnglishDialect::British
    } else {
        EnglishDialect::American
    };
    let engine = Box::new(GrammarEngine::new(dialect));
    Box::into_raw(engine) as jlong
}

#[no_mangle]
pub extern "system" fn Java_org_appendix_appendix_keyboard_NativeEngine_nativeCheckText(
    mut env: JNIEnv,
    _class: JClass,
    engine_ptr: jlong,
    text: JString,
) -> jstring {
    if engine_ptr == 0 {
        return env
            .new_string("[]")
            .map(|s| s.into_raw())
            .unwrap_or(std::ptr::null_mut());
    }
    let engine = unsafe { &*(engine_ptr as *const GrammarEngine) };
    let input: String = match env.get_string(&text) {
        Ok(s) => s.into(),
        Err(_) => {
            return env
                .new_string("[]")
                .map(|s| s.into_raw())
                .unwrap_or(std::ptr::null_mut())
        }
    };

    let lints = engine.check_text(&input);
    let json = serde_json::to_string(&lints).unwrap_or_else(|_| "[]".to_string());
    env.new_string(json)
        .map(|s| s.into_raw())
        .unwrap_or(std::ptr::null_mut())
}

#[no_mangle]
pub extern "system" fn Java_org_appendix_appendix_keyboard_NativeEngine_nativeAnalyzeInsights(
    mut env: JNIEnv,
    _class: JClass,
    text: JString,
) -> jstring {
    let input: String = match env.get_string(&text) {
        Ok(s) => s.into(),
        Err(_) => {
            return env
                .new_string("{}")
                .map(|s| s.into_raw())
                .unwrap_or(std::ptr::null_mut())
        }
    };

    let insights = InsightsEngine::analyze(&input);
    let json = serde_json::to_string(&insights).unwrap_or_else(|_| "{}".to_string());
    env.new_string(json)
        .map(|s| s.into_raw())
        .unwrap_or(std::ptr::null_mut())
}

#[no_mangle]
pub extern "system" fn Java_org_appendix_appendix_keyboard_NativeEngine_nativeRephrase(
    mut env: JNIEnv,
    _class: JClass,
    text: JString,
    mode: jint,
) -> jstring {
    let input: String = match env.get_string(&text) {
        Ok(s) => s.into(),
        Err(_) => {
            return env
                .new_string("{}")
                .map(|s| s.into_raw())
                .unwrap_or(std::ptr::null_mut())
        }
    };

    let rewrite_mode = RewriteMode::from_i32(mode);
    let result = crate::ai_engine::AiEngine::rewrite(&input, rewrite_mode, None);

    let json = serde_json::to_string(&result).unwrap_or_else(|_| "{}".to_string());
    env.new_string(json)
        .map(|s| s.into_raw())
        .unwrap_or(std::ptr::null_mut())
}

#[no_mangle]
pub extern "system" fn Java_org_appendix_appendix_keyboard_NativeEngine_nativeFreeEngine(
    _env: JNIEnv,
    _class: JClass,
    engine_ptr: jlong,
) {
    if engine_ptr != 0 {
        unsafe {
            drop(Box::from_raw(engine_ptr as *mut GrammarEngine));
        }
    }
}
