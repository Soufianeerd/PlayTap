package com.playtap.wear

import androidx.compose.runtime.Composable
import androidx.wear.compose.material3.MaterialTheme

/**
 * Wraps content in the Wear Compose Material3 default theme, which is dark
 * by design. Custom PlayTap tokens (see CLAUDE.md) land here once a Figma
 * source of truth exists — no invented color scheme before that.
 */
@Composable
fun PlayTapWearTheme(content: @Composable () -> Unit) {
    MaterialTheme(content = content)
}
