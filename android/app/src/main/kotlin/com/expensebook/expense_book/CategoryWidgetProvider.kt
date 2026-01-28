package com.expensebook.expense_book

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import android.graphics.BitmapFactory
import java.io.File

class CategoryWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val categoryId = widgetData.getString("categoryId", null)
            val payload = if (categoryId != null) "expensebook://add_expense?categoryId=$categoryId" else "expensebook://add_expense"
            val filename = widgetData.getString("filename", null)
            
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Open App on Click with payload
               val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    QuickAddActivity::class.java,
                    Uri.parse(payload)
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                
                if (filename != null) {
                    val imageFile = File(filename)
                    if (imageFile.exists()) {
                        setImageViewBitmap(R.id.widget_image, BitmapFactory.decodeFile(imageFile.absolutePath))
                    }
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
