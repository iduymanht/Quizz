// Quiz Pet — Tauri app: a transparent always-on-top overlay (index.html) shows
// the pet + quiz; a separate settings window (settings.html) has the Pet chooser
// and the question builder.
// Questions are stored durably in the app data dir so they survive restarts and
// are shared between the builder and the overlay.

use tauri::{Emitter, Manager};

/// Show and focus the Settings window (called from a right-click on the pet).
#[tauri::command]
fn show_settings(app: tauri::AppHandle) {
    if let Some(w) = app.get_webview_window("settings") {
        let _ = w.show();
        let _ = w.set_focus();
    }
}

fn questions_path(app: &tauri::AppHandle) -> Option<std::path::PathBuf> {
    let dir = app.path().app_data_dir().ok()?;
    let _ = std::fs::create_dir_all(&dir);
    Some(dir.join("questions.json"))
}

/// Persist the question set (JSON string) and notify the overlay to reload.
#[tauri::command]
fn save_questions(app: tauri::AppHandle, json: String) {
    if let Some(p) = questions_path(&app) {
        let _ = std::fs::write(&p, json.as_bytes());
    }
    // Live-refresh the pet overlay.
    let _ = app.emit_to("main", "questions-updated", json);
}

/// Read the stored question set (returns "[]" when none saved yet).
#[tauri::command]
fn load_questions(app: tauri::AppHandle) -> String {
    questions_path(&app)
        .and_then(|p| std::fs::read_to_string(p).ok())
        .unwrap_or_else(|| "[]".to_string())
}

pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|app, _argv, _cwd| {
            if let Some(w) = app.get_webview_window("main") {
                let _ = w.set_focus();
            }
        }))
        .plugin(tauri_plugin_autostart::init(
            tauri_plugin_autostart::MacosLauncher::LaunchAgent,
            None,
        ))
        .invoke_handler(tauri::generate_handler![
            show_settings,
            save_questions,
            load_questions
        ])
        .run(tauri::generate_context!())
        .expect("error while running quiz app");
}
