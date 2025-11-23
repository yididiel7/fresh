//! Test cursor visibility with ANSI escape codes in file content
//!
//! Bug: When a file starts with ANSI escape codes (like log files with colors),
//! the hardware cursor position is incorrectly set to (0, 0) instead of the
//! actual cursor position in the content area.

use crate::common::harness::EditorTestHarness;
use tempfile::TempDir;

/// Compare cursor position between ANSI and plain text files.
/// Both should have the cursor on the first character of content (row 2, after gutter).
///
/// This test reproduces a bug where files starting with ANSI escape codes
/// cause the cursor to be positioned at (0, 0) instead of the correct location.
#[test]
fn test_cursor_ansi_vs_plain_comparison() {
    let temp_dir = TempDir::new().unwrap();

    // Create both files
    let plain_path = temp_dir.path().join("plain.txt");
    let ansi_path = temp_dir.path().join("ansi.log");

    std::fs::write(&plain_path, "Hello world\n").unwrap();
    // ANSI content: \x1b[2m is "dim", \x1b[0m is "reset"
    std::fs::write(&ansi_path, "\x1b[2m2025-11-23T17:51:33Z\x1b[0m INFO test\n").unwrap();

    // Test plain text first (baseline)
    let mut plain_harness = EditorTestHarness::new(80, 24).unwrap();
    plain_harness.open_file(&plain_path).unwrap();
    plain_harness.render().unwrap();
    let plain_cursor_pos = plain_harness.screen_cursor_position();

    // Test ANSI file
    let mut ansi_harness = EditorTestHarness::new(80, 24).unwrap();
    ansi_harness.open_file(&ansi_path).unwrap();
    ansi_harness.render().unwrap();
    let ansi_cursor_pos = ansi_harness.screen_cursor_position();

    // The Y coordinate (row) should be the same for both - cursor on content row
    assert_eq!(
        plain_cursor_pos.1, ansi_cursor_pos.1,
        "Cursor row should be the same for plain ({:?}) and ANSI ({:?}) files. \
         ANSI cursor is at (0,0) which indicates a bug in cursor position calculation \
         when file starts with escape codes.",
        plain_cursor_pos, ansi_cursor_pos
    );
}
