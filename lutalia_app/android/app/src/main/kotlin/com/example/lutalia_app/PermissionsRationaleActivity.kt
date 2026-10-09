package com.example.lutalia_app

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.text.Html
import android.util.TypedValue
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/**
 * The privacy screen Health Connect links to from its permission dialog.
 * Reached through ACTION_SHOW_PERMISSIONS_RATIONALE (Android 13 and lower)
 * and the VIEW_PERMISSION_USAGE alias (Android 14+), both declared in the
 * manifest. Without it the grant does not complete.
 */
class PermissionsRationaleActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(buildContent())
    }

    private fun buildContent(): View {
        val pad = dp(24f)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#F5F0EB"))
        }

        val body = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(pad, pad, pad, pad)
        }

        body.addView(
            TextView(this).apply {
                text = getString(R.string.health_rationale_title)
                setTextColor(Color.parseColor("#4A3B32"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            },
            matchWidth(),
        )
        body.addView(View(this).apply { minimumHeight = dp(16f) })
        body.addView(
            TextView(this).apply {
                text = Html.fromHtml(
                    getString(R.string.health_rationale_body),
                    Html.FROM_HTML_MODE_LEGACY,
                )
                setTextColor(Color.parseColor("#6B5B52"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
                setLineSpacing(dp(4f).toFloat(), 1f)
            },
            matchWidth(),
        )

        val scroll = ScrollView(this).apply { addView(body) }
        root.addView(
            scroll,
            LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f),
        )
        root.addView(
            Button(this).apply {
                text = getString(R.string.health_rationale_close)
                setOnClickListener {
                    setResult(RESULT_OK, Intent())
                    finish()
                }
            },
            matchWidth(),
        )
        return root
    }

    private fun matchWidth() = LinearLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.WRAP_CONTENT,
    )

    private fun dp(value: Float): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        value,
        resources.displayMetrics,
    ).toInt()
}
