package io.github.dongyuzhao.composemarkdownsample

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import io.github.dongyuzhao.composemarkdown.MarkdownText

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface {
                    Column(modifier = Modifier.padding(16.dp)) {
                        MarkdownText(
                            markdown = """
                                # Hello, compose-markdown!

                                This is a **sample app** demonstrating the `compose-markdown` package.

                                - Item one
                                - Item two
                                - Item three
                            """.trimIndent()
                        )
                    }
                }
            }
        }
    }
}
