package io.github.dongyuzhao.composemarkdown

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable

@Composable
fun MarkdownText(markdown: String) {
    Text(text = markdown)
}
