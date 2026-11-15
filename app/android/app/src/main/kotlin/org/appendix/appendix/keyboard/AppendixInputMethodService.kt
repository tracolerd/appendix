package org.appendix.appendix.keyboard

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.inputmethodservice.InputMethodService
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.HapticFeedbackConstants
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.TextView
import org.json.JSONArray
import org.json.JSONObject

/**
 * 100% Offline English Keyboard with Real-time Harper Grammar & Spell Checking.
 * Completely private - zero network calls, zero telemetry.
 */
class AppendixInputMethodService : InputMethodService() {

    companion object {
        private const val TAG = "AppendixIME"
        private const val PREFS_NAME = "appendix_prefs"
        private const val KEY_DIALECT = "dialect" // 0: US, 1: UK
    }

    private var enginePtr: Long = 0
    private var isShifted = false
    private var isCapsLock = false
    private var isSymbols = false
    private var currentDialect = 0 // 0 = American, 1 = British

    private val mainHandler = Handler(Looper.getMainLooper())
    private var checkDebounceRunnable: Runnable? = null

    // UI Containers
    private lateinit var rootLayout: LinearLayout
    private lateinit var candidateStripScroll: HorizontalScrollView
    private lateinit var candidateContainer: LinearLayout
    private lateinit var keyboardContainer: LinearLayout

    // State
    private val keyButtons = mutableListOf<Button>()
    private var shiftButton: Button? = null

    override fun onCreate() {
        super.onCreate()
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        currentDialect = prefs.getInt(KEY_DIALECT, 0)

        // Initialize Rust Harper engine
        try {
            if (NativeEngine.isAvailable()) {
                enginePtr = NativeEngine.nativeCreateEngine(currentDialect)
                Log.i(TAG, "Native Harper engine initialized successfully. Ptr: $enginePtr")
            }
        } catch (t: Throwable) {
            Log.e(TAG, "Failed to initialize native Harper engine: ${t.message}", t)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (enginePtr != 0L && NativeEngine.isAvailable()) {
            try {
                NativeEngine.nativeFreeEngine(enginePtr)
            } catch (t: Throwable) {
                Log.e(TAG, "Error freeing native engine", t)
            }
            enginePtr = 0L
        }
    }

    override fun onCreateInputView(): View {
        rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#121417")) // Deep dark slate background
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        // 1. Suggestion & Grammar Candidate Strip (Top)
        buildCandidateStrip()

        // 2. Virtual Keyboard View (Bottom)
        keyboardContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(4), dp(4), dp(4), dp(8))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
        rootLayout.addView(keyboardContainer)

        renderKeyboardLayout()
        return rootLayout
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        isShifted = false
        isCapsLock = false
        isSymbols = false
        renderKeyboardLayout()
        scheduleGrammarCheck(100)
    }

    // ==========================================
    // CANDIDATE STRIP (Grammar Suggestions)
    // ==========================================

    private fun buildCandidateStrip() {
        candidateStripScroll = HorizontalScrollView(this).apply {
            isHorizontalScrollBarEnabled = false
            overScrollMode = View.OVER_SCROLL_NEVER
            setBackgroundColor(Color.parseColor("#1A1D23"))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(44)
            )
        }

        candidateContainer = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(8), 0, dp(8), 0)
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        candidateStripScroll.addView(candidateContainer)
        rootLayout.addView(candidateStripScroll)

        showDefaultCandidateStatus()
    }

    private fun showDefaultCandidateStatus() {
        candidateContainer.removeAllViews()

        val dialectLabel = if (currentDialect == 1) "EN-GB" else "EN-US"
        val badge = TextView(this).apply {
            text = "Appendix 🛡️ Offline ($dialectLabel)"
            setTextColor(Color.parseColor("#7E8B9B"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 12f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
            setPadding(dp(12), dp(4), dp(12), dp(4))
        }
        candidateContainer.addView(badge)
    }

    private fun displaySuggestions(lints: List<LintItem>) {
        candidateContainer.removeAllViews()

        if (lints.isEmpty()) {
            showDefaultCandidateStatus()
            return
        }

        for (lint in lints) {
            for (suggestion in lint.suggestions) {
                val chip = Button(this).apply {
                    val label = if (suggestion.length > 20) suggestion.take(17) + "..." else suggestion
                    text = "${lint.targetWord} -> $label"
                    setTextColor(Color.WHITE)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                    isAllCaps = false
                    typeface = Typeface.DEFAULT_BOLD

                    val bg = GradientDrawable().apply {
                        cornerRadius = dp(16).toFloat()
                        setColor(Color.parseColor("#2563EB")) // Primary Appendix blue
                    }
                    background = bg

                    setPadding(dp(12), 0, dp(12), 0)
                    val params = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.WRAP_CONTENT,
                        dp(32)
                    ).apply {
                        setMargins(dp(4), 0, dp(4), 0)
                    }
                    layoutParams = params

                    setOnClickListener {
                        applySuggestion(lint, suggestion)
                    }
                }
                candidateContainer.addView(chip)
            }
        }
    }

    private fun applySuggestion(lint: LintItem, replacement: String) {
        val ic = currentInputConnection ?: return
        performHapticFeedback()

        // Replace the erroneous text span
        val beforeCursor = ic.getTextBeforeCursor(200, 0)?.toString() ?: ""
        if (beforeCursor.endsWith(lint.targetWord)) {
            ic.deleteSurroundingText(lint.targetWord.length, 0)
            ic.commitText(replacement, 1)
        } else {
            // General replace near cursor
            ic.commitText(replacement, 1)
        }

        // Recheck text immediately
        scheduleGrammarCheck(150)
    }

    // ==========================================
    // GRAMMAR ANALYSIS (Debounced Background Check)
    // ==========================================

    private fun scheduleGrammarCheck(delayMs: Long = 250) {
        checkDebounceRunnable?.let { mainHandler.removeCallbacks(it) }
        checkDebounceRunnable = Runnable {
            val ic = currentInputConnection ?: return@Runnable
            val textBefore = ic.getTextBeforeCursor(300, 0)?.toString() ?: ""
            if (textBefore.isBlank()) {
                showDefaultCandidateStatus()
                return@Runnable
            }

            // Perform check on background thread
            Thread {
                val lints = runGrammarCheck(textBefore)
                mainHandler.post {
                    displaySuggestions(lints)
                }
            }.start()
        }
        mainHandler.postDelayed(checkDebounceRunnable!!, delayMs)
    }

    private fun runGrammarCheck(contextText: String): List<LintItem> {
        val results = mutableListOf<LintItem>()

        if (enginePtr != 0L && NativeEngine.isAvailable()) {
            try {
                val json = NativeEngine.nativeCheckText(enginePtr, contextText)
                val jsonArray = JSONArray(json)
                for (i in 0 until jsonArray.length()) {
                    val obj = jsonArray.getJSONObject(i)
                    val start = obj.getInt("start")
                    val end = obj.getInt("end")
                    val message = obj.optString("message", "")
                    val sugArray = obj.getJSONArray("suggestions")
                    val suggestions = mutableListOf<String>()
                    for (j in 0 until sugArray.length()) {
                        val sugObj = sugArray.getJSONObject(j)
                        val rep = sugObj.getString("replacement")
                        if (rep.isNotBlank()) {
                            suggestions.add(rep)
                        }
                    }

                    val targetWord = if (start < contextText.length && end <= contextText.length && start < end) {
                        contextText.substring(start, end)
                    } else {
                        ""
                    }

                    if (suggestions.isNotEmpty() && targetWord.isNotBlank()) {
                        results.add(LintItem(start, end, targetWord, message, suggestions))
                    }
                }
            } catch (t: Throwable) {
                Log.e(TAG, "Error executing native Harper check: ${t.message}")
            }
        } else {
            // Fallback quick heuristics for common typos
            val words = contextText.trim().split(Regex("\\s+"))
            if (words.isNotEmpty()) {
                val lastWord = words.last().lowercase().replace(Regex("[^a-z]"), "")
                val commonFixes = mapOf(
                    "teh" to "the",
                    "recieve" to "receive",
                    "seperate" to "separate",
                    "untill" to "until",
                    "definately" to "definitely",
                    "occured" to "occurred",
                    "accomodate" to "accommodate",
                    "writting" to "writing",
                    "realy" to "really",
                    "becuase" to "because"
                )
                commonFixes[lastWord]?.let { fix ->
                    results.add(LintItem(0, lastWord.length, lastWord, "Spelling correction", listOf(fix)))
                }
            }
        }

        return results
    }

    // ==========================================
    // KEYBOARD LAYOUT RENDERING
    // ==========================================

    private fun renderKeyboardLayout() {
        keyboardContainer.removeAllViews()
        keyButtons.clear()

        if (isSymbols) {
            renderSymbolsLayout()
        } else {
            renderAlphaLayout()
        }
    }

    private fun renderAlphaLayout() {
        val row1 = listOf("q", "w", "e", "r", "t", "y", "u", "i", "o", "p")
        val row2 = listOf("a", "s", "d", "f", "g", "h", "j", "k", "l")
        val row3 = listOf("z", "x", "c", "v", "b", "n", "m")

        keyboardContainer.addView(createRow(row1))
        keyboardContainer.addView(createRow(row2, horizontalPaddingDp = 16))

        // Row 3: Shift + z-m + Backspace
        val r3 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52))
        }

        shiftButton = createSpecialKey(if (isCapsLock) "⇪" else if (isShifted) "⇧" else "⇧", weight = 1.4f) {
            performHapticFeedback()
            if (isShifted && !isCapsLock) {
                isCapsLock = true
            } else if (isCapsLock) {
                isCapsLock = false
                isShifted = false
            } else {
                isShifted = true
            }
            updateKeyLabels()
        }
        r3.addView(shiftButton)

        for (letter in row3) {
            val btn = createKeyButton(letter, weight = 1.0f)
            keyButtons.add(btn)
            r3.addView(btn)
        }

        val backspaceBtn = createSpecialKey("⌫", weight = 1.4f) {
            performHapticFeedback()
            handleBackspace()
        }
        r3.addView(backspaceBtn)
        keyboardContainer.addView(r3)

        // Row 4: ?123, Comma, Space, Period, Enter
        val r4 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52))
        }

        val symbolBtn = createSpecialKey("?123", weight = 1.4f) {
            performHapticFeedback()
            isSymbols = true
            renderKeyboardLayout()
        }
        r4.addView(symbolBtn)

        val commaBtn = createKeyButton(",", weight = 1.0f)
        r4.addView(commaBtn)

        val spaceLabel = if (currentDialect == 1) "English (UK)" else "English (US)"
        val spaceBtn = createKeyButton(" ", weight = 4.2f, customLabel = spaceLabel)
        r4.addView(spaceBtn)

        val periodBtn = createKeyButton(".", weight = 1.0f)
        r4.addView(periodBtn)

        val enterBtn = createSpecialKey(getEnterActionLabel(), weight = 1.6f, isPrimary = true) {
            performHapticFeedback()
            handleEnter()
        }
        r4.addView(enterBtn)

        keyboardContainer.addView(r4)
        updateKeyLabels()
    }

    private fun renderSymbolsLayout() {
        val row1 = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")
        val row2 = listOf("@", "#", "$", "%", "&", "*", "-", "+", "(", ")")
        val row3 = listOf("!", "\"", "'", ":", ";", "/", "?")

        keyboardContainer.addView(createRow(row1))
        keyboardContainer.addView(createRow(row2))

        val r3 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52))
        }

        val switchMore = createSpecialKey("=\\<", weight = 1.4f) {
            performHapticFeedback()
        }
        r3.addView(switchMore)

        for (sym in row3) {
            val btn = createKeyButton(sym, weight = 1.0f)
            r3.addView(btn)
        }

        val backspaceBtn = createSpecialKey("⌫", weight = 1.4f) {
            performHapticFeedback()
            handleBackspace()
        }
        r3.addView(backspaceBtn)
        keyboardContainer.addView(r3)

        // Row 4: ABC, Comma, Space, Period, Enter
        val r4 = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(52))
        }

        val abcBtn = createSpecialKey("ABC", weight = 1.4f) {
            performHapticFeedback()
            isSymbols = false
            renderKeyboardLayout()
        }
        r4.addView(abcBtn)

        val commaBtn = createKeyButton(",", weight = 1.0f)
        r4.addView(commaBtn)

        val spaceBtn = createKeyButton(" ", weight = 4.2f, customLabel = "Space")
        r4.addView(spaceBtn)

        val periodBtn = createKeyButton(".", weight = 1.0f)
        r4.addView(periodBtn)

        val enterBtn = createSpecialKey(getEnterActionLabel(), weight = 1.6f, isPrimary = true) {
            performHapticFeedback()
            handleEnter()
        }
        r4.addView(enterBtn)

        keyboardContainer.addView(r4)
    }

    private fun createRow(keys: List<String>, horizontalPaddingDp: Int = 0): LinearLayout {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            if (horizontalPaddingDp > 0) {
                setPadding(dp(horizontalPaddingDp), 0, dp(horizontalPaddingDp), 0)
            }
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(52)
            )
        }

        for (k in keys) {
            val btn = createKeyButton(k, weight = 1.0f)
            keyButtons.add(btn)
            row.addView(btn)
        }
        return row
    }

    private fun createKeyButton(keyValue: String, weight: Float, customLabel: String? = null): Button {
        return Button(this).apply {
            text = customLabel ?: keyValue
            tag = keyValue
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, if (keyValue == " ") 12f else 18f)
            isAllCaps = false

            val normalBg = GradientDrawable().apply {
                cornerRadius = dp(6).toFloat()
                setColor(Color.parseColor("#262A33"))
            }
            background = normalBg

            val params = LinearLayout.LayoutParams(0, dp(46), weight).apply {
                setMargins(dp(3), dp(3), dp(3), dp(3))
            }
            layoutParams = params

            setOnClickListener {
                performHapticFeedback()
                val charToSend = if (isShifted || isCapsLock) {
                    keyValue.uppercase()
                } else {
                    keyValue
                }
                currentInputConnection?.commitText(charToSend, 1)

                if (isShifted && !isCapsLock) {
                    isShifted = false
                    updateKeyLabels()
                }

                // If typed space or punctuation, trigger immediate check
                if (charToSend == " " || charToSend == "." || charToSend == "," || charToSend == "?" || charToSend == "!") {
                    scheduleGrammarCheck(50)
                } else {
                    scheduleGrammarCheck(300)
                }
            }
        }
    }

    private fun createSpecialKey(
        label: String,
        weight: Float,
        isPrimary: Boolean = false,
        onClick: () -> Unit
    ): Button {
        return Button(this).apply {
            text = label
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            typeface = Typeface.DEFAULT_BOLD
            isAllCaps = false

            val bg = GradientDrawable().apply {
                cornerRadius = dp(6).toFloat()
                setColor(if (isPrimary) Color.parseColor("#2563EB") else Color.parseColor("#1E2128"))
            }
            background = bg

            val params = LinearLayout.LayoutParams(0, dp(46), weight).apply {
                setMargins(dp(3), dp(3), dp(3), dp(3))
            }
            layoutParams = params

            setOnClickListener {
                onClick()
            }
        }
    }

    private fun updateKeyLabels() {
        for (btn in keyButtons) {
            val base = btn.tag as? String ?: continue
            if (base.length == 1 && base[0].isLetter()) {
                btn.text = if (isShifted || isCapsLock) base.uppercase() else base.lowercase()
            }
        }
        shiftButton?.apply {
            text = when {
                isCapsLock -> "⇪"
                isShifted -> "⇧"
                else -> "⇧"
            }
            (background as? GradientDrawable)?.setColor(
                if (isCapsLock || isShifted) Color.parseColor("#3B82F6") else Color.parseColor("#1E2128")
            )
        }
    }

    private fun handleBackspace() {
        val ic = currentInputConnection ?: return
        val selectedText = ic.getSelectedText(0)
        if (selectedText.isNullOrEmpty()) {
            ic.deleteSurroundingText(1, 0)
        } else {
            ic.commitText("", 1)
        }
        scheduleGrammarCheck(200)
    }

    private fun handleEnter() {
        val ic = currentInputConnection ?: return
        val info = currentInputEditorInfo
        if (info != null && (info.imeOptions and EditorInfo.IME_FLAG_NO_ENTER_ACTION) == 0) {
            val action = info.imeOptions and EditorInfo.IME_MASK_ACTION
            if (action != EditorInfo.IME_ACTION_NONE && action != EditorInfo.IME_ACTION_UNSPECIFIED) {
                ic.performEditorAction(action)
                return
            }
        }
        ic.commitText("\n", 1)
        scheduleGrammarCheck(100)
    }

    private fun getEnterActionLabel(): String {
        val info = currentInputEditorInfo ?: return "↵"
        return when (info.imeOptions and EditorInfo.IME_MASK_ACTION) {
            EditorInfo.IME_ACTION_GO -> "Go"
            EditorInfo.IME_ACTION_SEARCH -> "Search"
            EditorInfo.IME_ACTION_SEND -> "Send"
            EditorInfo.IME_ACTION_NEXT -> "Next"
            EditorInfo.IME_ACTION_DONE -> "Done"
            else -> "↵"
        }
    }

    private fun performHapticFeedback() {
        rootLayout.performHapticFeedback(
            HapticFeedbackConstants.KEYBOARD_TAP,
            HapticFeedbackConstants.FLAG_IGNORE_GLOBAL_SETTING
        )
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }

    data class LintItem(
        val start: Int,
        val end: Int,
        val targetWord: String,
        val message: String,
        val suggestions: List<String>
    )
}

