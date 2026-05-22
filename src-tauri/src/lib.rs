use tauri::{
    menu::{Menu, MenuItem, PredefinedMenuItem},
    tray::{MouseButton, MouseButtonState, TrayIconBuilder, TrayIconEvent},
    Manager,
};
use tauri_plugin_global_shortcut::{Code, GlobalShortcutExt, Modifiers, Shortcut, ShortcutState};

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_global_shortcut::Builder::new().build())
        .setup(|app| {
            #[cfg(target_os = "macos")]
            app.set_activation_policy(tauri::ActivationPolicy::Accessory);

            if let Some(window) = app.get_webview_window("main") {
                let _ = window.set_title_bar_style(tauri::TitleBarStyle::Overlay);
                let _ = window.set_title("");

                #[cfg(target_os = "macos")]
                window
                    .with_webview(|webview| unsafe {
                        use objc2_app_kit::{NSWindow, NSWindowButton};

                        let ns_window = &*(webview.ns_window() as *mut NSWindow);
                        for btn in [
                            NSWindowButton::CloseButton,
                            NSWindowButton::MiniaturizeButton,
                            NSWindowButton::ZoomButton,
                        ] {
                            if let Some(btn) = ns_window.standardWindowButton(btn) {
                                btn.setHidden(true);
                            }
                        }
                    })
                    .ok();

                let win = window.clone();
                window.on_window_event(move |event| match event {
                    tauri::WindowEvent::CloseRequested { api, .. } => {
                        api.prevent_close();
                        let _ = win.hide();
                    }
                    tauri::WindowEvent::Focused(false) => {
                        let _ = win.hide();
                    }
                    _ => {}
                });
            }

            let shortcut = Shortcut::new(Some(Modifiers::CONTROL | Modifiers::SHIFT), Code::Space);
            let handle = app.handle().clone();
            app.global_shortcut()
                .on_shortcut(shortcut, move |_app, _shortcut, event| {
                    if event.state != ShortcutState::Pressed {
                        return;
                    }
                    if let Some(window) = handle.get_webview_window("main") {
                        if window.is_visible().unwrap_or(false) {
                            let _ = window.hide();
                        } else {
                            let _ = window.show();
                            let _ = window.set_focus();
                        }
                    }
                })?;

            let open = MenuItem::with_id(app, "open", "Open ftpad", true, Some("Ctrl+Shift+Space"))?;
            let separator = PredefinedMenuItem::separator(app)?;
            let quit = MenuItem::with_id(app, "quit", "Quit", true, None::<&str>)?;
            let menu = Menu::with_items(app, &[&open, &separator, &quit])?;

            let tray = TrayIconBuilder::new()
                .icon(app.default_window_icon().unwrap().clone())
                .icon_as_template(true)
                .menu(&menu)
                .show_menu_on_left_click(false)
                .on_menu_event(|app, event| match event.id().as_ref() {
                    "open" => {
                        if let Some(window) = app.get_webview_window("main") {
                            let _ = window.show();
                            let _ = window.set_focus();
                        }
                    }
                    "quit" => app.exit(0),
                    _ => {}
                })
                .on_tray_icon_event(|tray, event| {
                    if let TrayIconEvent::Click {
                        button: MouseButton::Left,
                        button_state: MouseButtonState::Up,
                        ..
                    } = event
                    {
                        let app = tray.app_handle();
                        if let Some(window) = app.get_webview_window("main") {
                            if window.is_visible().unwrap_or(false) {
                                let _ = window.hide();
                            } else {
                                let _ = window.show();
                                let _ = window.set_focus();
                            }
                        }
                    }
                })
                .build(app)?;

            let _ = tray;

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
