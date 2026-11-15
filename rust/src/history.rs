use chrono::Utc;
use rusqlite::{params, Connection};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HistoryEntry {
    pub id: i64,
    pub timestamp: String,
    pub content: String,
    pub word_count: usize,
    pub readability_score: f64,
}

pub struct HistoryStorage;

impl HistoryStorage {
    fn open(db_path: &str) -> Result<Connection, String> {
        let conn = Connection::open(db_path).map_err(|e| format!("Failed to open SQLite db: {}", e))?;
        conn.execute(
            "CREATE TABLE IF NOT EXISTS writing_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                content TEXT NOT NULL,
                word_count INTEGER NOT NULL,
                readability_score REAL NOT NULL
            )",
            [],
        )
        .map_err(|e| format!("Failed to initialize writing_history table: {}", e))?;
        Ok(conn)
    }

    pub fn save(
        db_path: &str,
        content: &str,
        word_count: usize,
        readability_score: f64,
    ) -> Result<i64, String> {
        let conn = Self::open(db_path)?;
        let now = Utc::now().to_rfc3339();

        conn.execute(
            "INSERT INTO writing_history (timestamp, content, word_count, readability_score)
             VALUES (?1, ?2, ?3, ?4)",
            params![now, content, word_count as i64, readability_score],
        )
        .map_err(|e| format!("Failed to insert history entry: {}", e))?;

        Ok(conn.last_insert_rowid())
    }

    pub fn list(db_path: &str, limit: usize) -> Result<Vec<HistoryEntry>, String> {
        let conn = Self::open(db_path)?;
        let mut stmt = conn
            .prepare(
                "SELECT id, timestamp, content, word_count, readability_score 
                 FROM writing_history 
                 ORDER BY id DESC 
                 LIMIT ?1",
            )
            .map_err(|e| format!("Failed to prepare history select query: {}", e))?;

        let rows = stmt
            .query_map(params![limit as i64], |row| {
                Ok(HistoryEntry {
                    id: row.get(0)?,
                    timestamp: row.get(1)?,
                    content: row.get(2)?,
                    word_count: row.get::<_, i64>(3)? as usize,
                    readability_score: row.get(4)?,
                })
            })
            .map_err(|e| format!("Failed to execute history query: {}", e))?;

        let mut results = Vec::new();
        for entry in rows {
            if let Ok(item) = entry {
                results.push(item);
            }
        }
        Ok(results)
    }

    pub fn delete(db_path: &str, id: i64) -> Result<(), String> {
        let conn = Self::open(db_path)?;
        conn.execute("DELETE FROM writing_history WHERE id = ?1", params![id])
            .map_err(|e| format!("Failed to delete history item: {}", e))?;
        Ok(())
    }

    pub fn clear(db_path: &str) -> Result<(), String> {
        let conn = Self::open(db_path)?;
        conn.execute("DELETE FROM writing_history", [])
            .map_err(|e| format!("Failed to clear history: {}", e))?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_history_crud() {
        let temp_dir = std::env::temp_dir();
        let db_file = temp_dir.join(format!("test_history_{}.db", Utc::now().timestamp_nanos_opt().unwrap_or(12345)));
        let db_path = db_file.to_str().unwrap();

        let id1 = HistoryStorage::save(db_path, "Draft one", 2, 85.0).unwrap();
        let id2 = HistoryStorage::save(db_path, "Draft two", 2, 90.0).unwrap();
        assert!(id2 > id1);

        let list = HistoryStorage::list(db_path, 10).unwrap();
        assert_eq!(list.len(), 2);
        assert_eq!(list[0].content, "Draft two");

        HistoryStorage::delete(db_path, id1).unwrap();
        let list_after_delete = HistoryStorage::list(db_path, 10).unwrap();
        assert_eq!(list_after_delete.len(), 1);

        HistoryStorage::clear(db_path).unwrap();
        let list_after_clear = HistoryStorage::list(db_path, 10).unwrap();
        assert_eq!(list_after_clear.len(), 0);

        let _ = std::fs::remove_file(db_file);
    }
}
