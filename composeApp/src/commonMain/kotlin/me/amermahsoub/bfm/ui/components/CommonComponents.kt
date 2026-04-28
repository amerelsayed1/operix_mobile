package me.amermahsoub.bfm.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material.icons.filled.Inbox
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import me.amermahsoub.bfm.ui.theme.OperixError
import me.amermahsoub.bfm.ui.theme.OperixPrimary
import me.amermahsoub.bfm.ui.theme.OperixTextSecondary

@Composable
fun LoadingScreen(message: String = "Loading…") {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
            CircularProgressIndicator(color = OperixPrimary)
            Text(message, color = OperixTextSecondary, style = MaterialTheme.typography.bodyMedium)
        }
    }
}

@Composable
fun ErrorView(message: String, onRetry: (() -> Unit)? = null) {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Icon(Icons.Filled.ErrorOutline, contentDescription = null, tint = OperixError, modifier = Modifier.size(48.dp))
            Text(message, color = OperixTextSecondary, textAlign = TextAlign.Center, modifier = Modifier.padding(horizontal = 32.dp))
            if (onRetry != null) {
                Button(onClick = onRetry) { Text("Retry") }
            }
        }
    }
}

@Composable
fun EmptyView(message: String = "No data found") {
    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Icon(Icons.Filled.Inbox, contentDescription = null, tint = OperixTextSecondary, modifier = Modifier.size(48.dp))
            Text(message, color = OperixTextSecondary, textAlign = TextAlign.Center)
        }
    }
}

@Composable
fun SectionHeader(title: String, actionLabel: String? = null, onAction: (() -> Unit)? = null) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(title, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
        if (actionLabel != null && onAction != null) {
            TextButton(onClick = onAction) { Text(actionLabel, fontSize = 13.sp) }
        }
    }
}

@Composable
fun StatusBadge(status: String, modifier: Modifier = Modifier) {
    val (bg, fg) = when (status.lowercase()) {
        "paid", "approved", "active", "open", "completed" ->
            Color(0xFFDCFCE7) to Color(0xFF166534)
        "posted", "partial" ->
            Color(0xFFDBEAFE) to Color(0xFF1E40AF)
        "draft", "in_progress" ->
            Color(0xFFFEF9C3) to Color(0xFF713F12)
        "cancelled", "suspended", "closed" ->
            Color(0xFFFEE2E2) to Color(0xFF991B1B)
        "submitted" ->
            Color(0xFFEDE9FE) to Color(0xFF5B21B6)
        else ->
            Color(0xFFF1F5F9) to Color(0xFF475569)
    }
    Surface(
        shape = RoundedCornerShape(20.dp),
        color = bg,
        modifier = modifier,
    ) {
        Text(
            status.replaceFirstChar { it.uppercase() }.replace("_", " "),
            color = fg,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp),
        )
    }
}

@Composable
fun AmountText(amount: String, currency: String = "", positive: Boolean = true, large: Boolean = false) {
    val color = if (positive) OperixPrimary else OperixError
    Text(
        text = if (currency.isBlank()) amount else "$currency $amount",
        color = color,
        fontSize = if (large) 20.sp else 14.sp,
        fontWeight = FontWeight.SemiBold,
    )
}

@Composable
fun ListItem(
    title: String,
    subtitle: String? = null,
    trailing: @Composable (() -> Unit)? = null,
    onClick: () -> Unit,
) {
    Row(
        Modifier.fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f)) {
            Text(title, fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis)
            if (subtitle != null) {
                Spacer(Modifier.height(2.dp))
                Text(subtitle, color = OperixTextSecondary, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
        if (trailing != null) {
            trailing()
        } else {
            Icon(Icons.Filled.ChevronRight, contentDescription = null, tint = OperixTextSecondary, modifier = Modifier.size(16.dp))
        }
    }
}

@Composable
fun KpiCard(label: String, value: String, change: String? = null, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = Color.White),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        shape = RoundedCornerShape(12.dp),
    ) {
        Column(Modifier.padding(16.dp)) {
            Text(label, color = OperixTextSecondary, fontSize = 12.sp)
            Spacer(Modifier.height(6.dp))
            Text(value, fontWeight = FontWeight.Bold, fontSize = 20.sp)
            if (change != null) {
                Spacer(Modifier.height(4.dp))
                val isPositive = !change.startsWith("-")
                Text(change, color = if (isPositive) Color(0xFF22C55E) else OperixError, fontSize = 12.sp)
            }
        }
    }
}

@Composable
fun HorizontalDivider(modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().height(1.dp).background(Color(0xFFE2E8F0)))
}

// Alias for backwards compat in agents' generated code
@Composable
fun Divider(modifier: Modifier = Modifier) = HorizontalDivider(modifier)
