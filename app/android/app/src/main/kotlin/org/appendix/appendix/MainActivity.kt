package org.appendix.appendix

import android.content.Context
import android.content.Intent
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "org.appendix.appendix/ime"
    private val PREFS_NAME = "appendix_prefs"
    private val KEY_DIALECT = "dialect"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isImeEnabled" -> {
                    result.success(isImeEnabled())
                }
                "isImeSelected" -> {
                    result.success(isImeSelected())
                }
                "openImeSettings" -> {
                    openImeSettings()
                    result.success(true)
                }
                "openImePicker" -> {
                    openImePicker()
                    result.success(true)
                }
                "setDialect" -> {
                    val dialect = call.argument<Int>("dialect") ?: 0
                    setDialect(dialect)
                    result.success(true)
                }
                "getDialect" -> {
                    result.success(getDialect())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun isImeEnabled(): Boolean {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager ?: return false
        val enabledImes = imm.enabledInputMethodList
        val targetPackage = packageName
        return enabledImes.any { it.packageName == targetPackage }
    }

    private fun isImeSelected(): Boolean {
        val defaultIme = Settings.Secure.getString(contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD)
        return defaultIme?.startsWith(packageName) == true
    }

    private fun openImeSettings() {
        val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun openImePicker() {
        val imm = getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
        imm?.showInputMethodPicker()
    }

    private fun setDialect(dialect: Int) {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putInt(KEY_DIALECT, dialect).apply()
    }

    private fun getDialect(): Int {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getInt(KEY_DIALECT, 0)
    }
}
