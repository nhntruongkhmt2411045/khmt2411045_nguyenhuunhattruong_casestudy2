package com.example.khmt2411045_nguyenhuunhattruong_casestudy2

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import com.example.khmt2411045_nguyenhuunhattruong_casestudy2.ui.screens.TaskListScreen
import com.example.khmt2411045_nguyenhuunhattruong_casestudy2.ui.screens.CreateTaskScreen

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    // Trạng thái chuyển đổi màn hình đơn giản
                    var currentScreen by remember { mutableStateOf("list") }

                    if (currentScreen == "list") {
                        TaskListScreen(
                            tasks = emptyList(), // Truyền danh sách task lấy từ API vào đây
                            onAddTaskClick = { currentScreen = "create" }
                        )
                    } else {
                        CreateTaskScreen(
                            onCreateTask = { title, desc ->
                                // Gọi API tạo Task tại đây
                                currentScreen = "list"
                            },
                            onBack = { currentScreen = "list" }
                        )
                    }
                }
            }
        }
    }
}