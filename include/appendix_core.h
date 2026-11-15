#ifndef APPENDIX_CORE_H
#define APPENDIX_CORE_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Creates a new Harper grammar checking engine instance.
 * @param dialect 0 = American English, 1 = British English
 * @return Raw pointer to GrammarEngine
 */
void* appendix_engine_new(int32_t dialect);

/**
 * Frees a GrammarEngine instance.
 */
void appendix_engine_free(void* engine);

/**
 * Updates dialect of an existing GrammarEngine.
 */
void appendix_engine_set_dialect(void* engine, int32_t dialect);

/**
 * Lints English text offline using Harper.
 * @return JSON string of LintResult array. Must be freed with appendix_string_free.
 */
char* appendix_engine_check(void* engine, const char* text);

/**
 * Computes readability metrics (Flesch, Grade Level, TTR, syllable stats).
 * @return JSON string of ReadabilityReport. Must be freed with appendix_string_free.
 */
char* appendix_insights_analyze(const char* text);

/**
 * Generates rephrased text offline using 12 rewriting styles.
 * @return JSON string of RewriteResult. Must be freed with appendix_string_free.
 */
char* appendix_ai_rewrite(const char* text, int32_t mode);

/**
 * Saves a draft snapshot into local SQLite.
 */
int64_t appendix_history_save(const char* db_path, const char* content, size_t word_count, double readability);

/**
 * Lists draft snapshots from local SQLite.
 */
char* appendix_history_list(const char* db_path, size_t limit);

/**
 * Deletes a draft snapshot from local SQLite.
 */
int32_t appendix_history_delete(const char* db_path, int64_t id);

/**
 * Clears all draft history from local SQLite.
 */
int32_t appendix_history_clear(const char* db_path);

/**
 * Frees a C string allocated by appendix_core.
 */
void appendix_string_free(char* ptr);

#ifdef __cplusplus
}
#endif

#endif // APPENDIX_CORE_H

