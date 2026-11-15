import UIKit

/**
 * 100% Offline English Keyboard Extension for iOS.
 * Strictly adheres to Apple Keyboard Guidelines:
 * - Includes Next Keyboard (Globe) button
 * - Zero network access (RequestsOpenAccess = NO)
 * - Ultra-lightweight footprint (<40MB RAM)
 * - Real-time Harper grammar checking
 */
public final class KeyboardViewController: UIInputViewController {

    private enum KeyboardMode {
        case letters
        case numbers
    }

    private var mode: KeyboardMode = .letters
    private var isShifted = false
    private var isCapsLock = false
    private var lastShiftTapTime: TimeInterval = 0

    private var checkTimer: Timer?
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .light)

    // UI Elements
    private let candidateScrollView = UIScrollView()
    private let candidateStackView = UIStackView()
    private let keyboardStackView = UIStackView()
    private var letterButtons: [UIButton] = []
    private var shiftButton: UIButton?

    // Shared App Group Preferences
    private let appGroupDefaults = UserDefaults(suiteName: "group.org.appendix.appendix")

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDialectPreference()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDialectPreference()
        triggerGrammarCheck(delay: 0.1)
    }

    private func loadDialectPreference() {
        let dialect = Int32(appGroupDefaults?.integer(forKey: "dialect") ?? 0)
        NativeHarperBridge.shared.setDialect(dialect: dialect)
    }

    // ==========================================
    // UI SETUP
    // ==========================================

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.12, green: 0.13, blue: 0.15, alpha: 1.0)

        // 1. Candidate Bar (Top)
        setupCandidateBar()

        // 2. Keyboard Stack (Bottom)
        keyboardStackView.axis = .vertical
        keyboardStackView.distribution = .fillEqually
        keyboardStackView.spacing = 8
        keyboardStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardStackView)

        NSLayoutConstraint.activate([
            candidateScrollView.topAnchor.constraint(equalTo: view.topAnchor),
            candidateScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            candidateScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            candidateScrollView.heightAnchor.constraint(equalToConstant: 44),

            keyboardStackView.topAnchor.constraint(equalTo: candidateScrollView.bottomAnchor, constant: 4),
            keyboardStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            keyboardStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            keyboardStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])

        renderKeyboard()
    }

    private func setupCandidateBar() {
        candidateScrollView.showsHorizontalScrollIndicator = false
        candidateScrollView.backgroundColor = UIColor(red: 0.16, green: 0.18, blue: 0.22, alpha: 1.0)
        candidateScrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(candidateScrollView)

        candidateStackView.axis = .horizontal
        candidateStackView.alignment = .center
        candidateStackView.spacing = 8
        candidateStackView.translatesAutoresizingMaskIntoConstraints = false
        candidateScrollView.addSubview(candidateStackView)

        NSLayoutConstraint.activate([
            candidateStackView.topAnchor.constraint(equalTo: candidateScrollView.topAnchor),
            candidateStackView.bottomAnchor.constraint(equalTo: candidateScrollView.bottomAnchor),
            candidateStackView.leadingAnchor.constraint(equalTo: candidateScrollView.leadingAnchor, constant: 12),
            candidateStackView.trailingAnchor.constraint(equalTo: candidateScrollView.trailingAnchor, constant: -12),
            candidateStackView.heightAnchor.constraint(equalTo: candidateScrollView.heightAnchor)
        ])

        showDefaultCandidateStatus()
    }

    private func showDefaultCandidateStatus() {
        candidateStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let label = UILabel()
        label.text = "Appendix 🛡️ Offline"
        label.textColor = UIColor(red: 0.55, green: 0.60, blue: 0.68, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        candidateStackView.addArrangedSubview(label)
    }

    private func displaySuggestions(_ lints: [LintSuggestion]) {
        candidateStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if lints.isEmpty {
            showDefaultCandidateStatus()
            return
        }

        for lint in lints {
            for rep in lint.replacements {
                let button = UIButton(type: .system)
                button.setTitle("\(lint.targetWord) -> \(rep)", for: .normal)
                button.setTitleColor(.white, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
                button.backgroundColor = UIColor(red: 0.15, green: 0.39, blue: 0.92, alpha: 1.0)
                button.layer.cornerRadius = 14
                button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

                button.addAction(UIAction { [weak self] _ in
                    self?.applySuggestion(lint: lint, replacement: rep)
                }, for: .touchUpInside)

                candidateStackView.addArrangedSubview(button)
            }
        }
    }

    private func applySuggestion(lint: LintSuggestion, replacement: String) {
        hapticGenerator.impactOccurred()
        guard let proxy = textDocumentProxy as? UITextDocumentProxy else { return }

        // Remove erroneous word
        let beforeText = proxy.documentContextBeforeInput ?? ""
        if beforeText.hasSuffix(lint.targetWord) {
            for _ in 0..<lint.targetWord.count {
                proxy.deleteBackward()
            }
            proxy.insertText(replacement)
        } else {
            proxy.insertText(replacement)
        }

        triggerGrammarCheck(delay: 0.1)
    }

    // ==========================================
    // GRAMMAR ANALYSIS
    // ==========================================

    private func triggerGrammarCheck(delay: TimeInterval = 0.25) {
        checkTimer?.invalidate()
        checkTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            let context = self.textDocumentProxy.documentContextBeforeInput ?? ""
            DispatchQueue.global(qos: .userInitiated).async {
                let suggestions = NativeHarperBridge.shared.checkText(context)
                DispatchQueue.main.async {
                    self.displaySuggestions(suggestions)
                }
            }
        }
    }

    // ==========================================
    // KEYBOARD RENDERING
    // ==========================================

    private func renderKeyboard() {
        keyboardStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        letterButtons.removeAll()

        switch mode {
        case .letters:
            renderLetters()
        case .numbers:
            renderNumbers()
        }
    }

    private func renderLetters() {
        let row1 = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
        let row2 = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
        let row3 = ["z", "x", "c", "v", "b", "n", "m"]

        keyboardStackView.addArrangedSubview(createRow(keys: row1))
        keyboardStackView.addArrangedSubview(createRow(keys: row2, horizontalInset: 16))

        // Row 3: Shift + z-m + Backspace
        let r3 = UIStackView()
        r3.axis = .horizontal
        r3.distribution = .fillProportionally
        r3.spacing = 6

        let shiftBtn = createSpecialKey(title: isCapsLock ? "⇪" : "⇧", flex: 1.4) { [weak self] in
            self?.handleShiftTap()
        }
        self.shiftButton = shiftBtn
        r3.addArrangedSubview(shiftBtn)

        for key in row3 {
            let btn = createKey(char: key)
            letterButtons.append(btn)
            r3.addArrangedSubview(btn)
        }

        let backspaceBtn = createSpecialKey(title: "⌫", flex: 1.4) { [weak self] in
            self?.handleBackspace()
        }
        r3.addArrangedSubview(backspaceBtn)
        keyboardStackView.addArrangedSubview(r3)

        // Row 4: 123 + Globe + Space + Return
        let r4 = UIStackView()
        r4.axis = .horizontal
        r4.distribution = .fillProportionally
        r4.spacing = 6

        let numToggleBtn = createSpecialKey(title: "123", flex: 1.3) { [weak self] in
            self?.hapticGenerator.impactOccurred()
            self?.mode = .numbers
            self?.renderKeyboard()
        }
        r4.addArrangedSubview(numToggleBtn)

        // Next Keyboard (Globe) button — Mandatory for iOS
        if needsInputModeSwitchKey {
            let globeBtn = createSpecialKey(title: "🌐", flex: 1.0) { [weak self] in
                self?.advanceToNextInputMode()
            }
            r4.addArrangedSubview(globeBtn)
        }

        let spaceBtn = createSpecialKey(title: "Space", flex: 4.5, isLight: true) { [weak self] in
            self?.textDocumentProxy.insertText(" ")
            self?.hapticGenerator.impactOccurred()
            self?.triggerGrammarCheck(delay: 0.05)
        }
        r4.addArrangedSubview(spaceBtn)

        let returnBtn = createSpecialKey(title: "return", flex: 1.8, isPrimary: true) { [weak self] in
            self?.textDocumentProxy.insertText("\n")
            self?.hapticGenerator.impactOccurred()
            self?.triggerGrammarCheck(delay: 0.05)
        }
        r4.addArrangedSubview(returnBtn)

        keyboardStackView.addArrangedSubview(r4)
        updateLetterCasing()
    }

    private func renderNumbers() {
        let row1 = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        let row2 = ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""]
        let row3 = [".", ",", "?", "!", "'"]

        keyboardStackView.addArrangedSubview(createRow(keys: row1))
        keyboardStackView.addArrangedSubview(createRow(keys: row2))

        let r3 = UIStackView()
        r3.axis = .horizontal
        r3.distribution = .fillProportionally
        r3.spacing = 6

        for key in row3 {
            r3.addArrangedSubview(createKey(char: key))
        }

        let backspaceBtn = createSpecialKey(title: "⌫", flex: 1.4) { [weak self] in
            self?.handleBackspace()
        }
        r3.addArrangedSubview(backspaceBtn)
        keyboardStackView.addArrangedSubview(r3)

        // Row 4: ABC + Globe + Space + Return
        let r4 = UIStackView()
        r4.axis = .horizontal
        r4.distribution = .fillProportionally
        r4.spacing = 6

        let abcBtn = createSpecialKey(title: "ABC", flex: 1.3) { [weak self] in
            self?.hapticGenerator.impactOccurred()
            self?.mode = .letters
            self?.renderKeyboard()
        }
        r4.addArrangedSubview(abcBtn)

        if needsInputModeSwitchKey {
            let globeBtn = createSpecialKey(title: "🌐", flex: 1.0) { [weak self] in
                self?.advanceToNextInputMode()
            }
            r4.addArrangedSubview(globeBtn)
        }

        let spaceBtn = createSpecialKey(title: "Space", flex: 4.5, isLight: true) { [weak self] in
            self?.textDocumentProxy.insertText(" ")
            self?.hapticGenerator.impactOccurred()
            self?.triggerGrammarCheck(delay: 0.05)
        }
        r4.addArrangedSubview(spaceBtn)

        let returnBtn = createSpecialKey(title: "return", flex: 1.8, isPrimary: true) { [weak self] in
            self?.textDocumentProxy.insertText("\n")
            self?.hapticGenerator.impactOccurred()
            self?.triggerGrammarCheck(delay: 0.05)
        }
        r4.addArrangedSubview(returnBtn)

        keyboardStackView.addArrangedSubview(r4)
    }

    private func createRow(keys: [String], horizontalInset: CGFloat = 0) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 6
        for k in keys {
            let btn = createKey(char: k)
            if k.count == 1 && k.first?.isLetter == true {
                letterButtons.append(btn)
            }
            row.addArrangedSubview(btn)
        }
        return row
    }

    private func createKey(char: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(char, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 21, weight: .regular)
        button.backgroundColor = UIColor(red: 0.22, green: 0.24, blue: 0.28, alpha: 1.0)
        button.layer.cornerRadius = 6
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowRadius = 1

        button.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.hapticGenerator.impactOccurred()
            let title = button.title(for: .normal) ?? char
            self.textDocumentProxy.insertText(title)

            if self.isShifted && !self.isCapsLock {
                self.isShifted = false
                self.updateLetterCasing()
            }
            self.triggerGrammarCheck(delay: 0.25)
        }, for: .touchUpInside)

        return button
    }

    private func createSpecialKey(
        title: String,
        flex: CGFloat,
        isPrimary: BooleanLiteralType = false,
        isLight: BooleanLiteralType = false,
        action: @escaping () -> Void
    ) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        let bg: UIColor
        if isPrimary {
            bg = UIColor(red: 0.15, green: 0.39, blue: 0.92, alpha: 1.0)
        } else if isLight {
            bg = UIColor(red: 0.22, green: 0.24, blue: 0.28, alpha: 1.0)
        } else {
            bg = UIColor(red: 0.16, green: 0.18, blue: 0.21, alpha: 1.0)
        }

        button.backgroundColor = bg
        button.layer.cornerRadius = 6
        button.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return button
    }

    private func handleShiftTap() {
        hapticGenerator.impactOccurred()
        let now = Date().timeIntervalSince1970
        if isShifted && !isCapsLock && (now - lastShiftTapTime) < 0.35 {
            isCapsLock = true
        } else if isCapsLock {
            isCapsLock = false
            isShifted = false
        } else {
            isShifted.toggle()
        }
        lastShiftTapTime = now
        updateLetterCasing()
    }

    private func updateLetterCasing() {
        let isUpper = isShifted || isCapsLock
        for btn in letterButtons {
            if let title = btn.title(for: .normal) {
                btn.setTitle(isUpper ? title.uppercased() : title.lowercased(), for: .normal)
            }
        }
        shiftButton?.setTitle(isCapsLock ? "⇪" : "⇧", for: .normal)
        shiftButton?.backgroundColor = (isShifted || isCapsLock)
            ? UIColor(red: 0.25, green: 0.50, blue: 0.95, alpha: 1.0)
            : UIColor(red: 0.16, green: 0.18, blue: 0.21, alpha: 1.0)
    }

    private func handleBackspace() {
        hapticGenerator.impactOccurred()
        textDocumentProxy.deleteBackward()
        triggerGrammarCheck(delay: 0.2)
    }
}
