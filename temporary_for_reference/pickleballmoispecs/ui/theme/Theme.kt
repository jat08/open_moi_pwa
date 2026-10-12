package com.example.pickleballmoispecs.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import com.example.pickleballmoispecs.data.ThemeMode

private val BlueCore = Color(0xFF34A4EB)
private val BlueContainer = Color(0xFFD1E9FF)
private val BlueOnContainer = Color(0xFF001D33)

private val LightColorScheme = lightColorScheme(
    primary = BlueCore,
    onPrimary = Color.White,
    primaryContainer = BlueContainer,
    onPrimaryContainer = BlueOnContainer,
    secondary = Color(0xFF00796B),
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFB2DFDB),
    onSecondaryContainer = Color(0xFF00201A),
    background = Color.White,
    surface = Color.White,
    onSurface = Color.Black,
    surfaceVariant = Color(0xFFF0F7FF)
)

private val DarkColorScheme = darkColorScheme(
    primary = BlueCore,
    onPrimary = Color.Black,
    primaryContainer = Color(0xFF004977),
    onPrimaryContainer = BlueContainer,
    secondary = Color(0xFF80CBC4),
    onSecondary = Color.Black,
    background = Color(0xFF121212),
    surface = Color(0xFF1E1E1E),
    onSurface = Color.White,
    surfaceVariant = Color(0xFF2B2B2B)
)

@Composable
fun OpenMOITheme(
    themeMode: ThemeMode,
    content: @Composable () -> Unit
) {
    val darkTheme = when (themeMode) {
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
    }

    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    MaterialTheme(
        colorScheme = colorScheme,
        content = content
    )
}
