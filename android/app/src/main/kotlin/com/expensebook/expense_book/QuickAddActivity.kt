package com.expensebook.expense_book

import io.flutter.embedding.android.FlutterActivity

class QuickAddActivity : FlutterActivity() {
    override fun getDartEntrypointFunctionName(): String {
        return "quickAddMain"
    }

    override fun getRenderMode(): io.flutter.embedding.android.RenderMode {
        return io.flutter.embedding.android.RenderMode.texture
    }
}
