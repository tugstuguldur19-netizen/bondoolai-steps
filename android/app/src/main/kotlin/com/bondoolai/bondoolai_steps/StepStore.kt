package com.bondoolai.bondoolai_steps

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONObject
import java.time.LocalDate

/**
 * Per-day step totals from the phone's hardware step counter, persisted
 * natively so the background service and the Flutter UI share one source.
 *
 * The hardware counter only reports "steps since boot", so we keep the last
 * raw value and add the difference on every reading.
 */
object StepStore {
    private const val PREFS = "bondoolai_steps"
    private const val KEY_LAST_RAW = "last_raw"
    private const val KEY_LAST_DATE = "last_date"
    private const val KEY_DAYS = "days"
    private const val KEY_GOAL = "goal"
    private const val KEY_ENABLED = "enabled"
    private const val DAYS_KEPT = 400

    /** A gap bigger than this between two readings is treated as bogus. */
    private const val MAX_PLAUSIBLE_DELTA = 100_000L

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun days(p: SharedPreferences) = JSONObject(p.getString(KEY_DAYS, "{}") ?: "{}")

    /** Records a raw counter reading and returns today's total. */
    @Synchronized
    fun record(context: Context, raw: Long): Int {
        val p = prefs(context)
        val today = LocalDate.now()
        val todayKey = today.toString()
        val days = days(p)
        var total = days.optInt(todayKey, 0)

        val lastRaw = p.getLong(KEY_LAST_RAW, -1)
        val lastDate = p.getString(KEY_LAST_DATE, "") ?: ""
        if (lastRaw >= 0) {
            // A lower value than last time means the phone rebooted and the
            // counter restarted from zero.
            val delta = if (raw >= lastRaw) raw - lastRaw else raw
            // Steps since a reading earlier today, or since last night's
            // reading, belong to today. After a longer gap we can't tell which
            // day they happened on, so we skip them.
            val recent = lastDate == todayKey || lastDate == today.minusDays(1).toString()
            if (recent && delta in 0..MAX_PLAUSIBLE_DELTA) total += delta.toInt()
        }

        days.put(todayKey, total)
        trim(days)
        p.edit()
            .putLong(KEY_LAST_RAW, raw)
            .putString(KEY_LAST_DATE, todayKey)
            .putString(KEY_DAYS, days.toString())
            .apply()
        return total
    }

    /** Carries over today's count from before the service existed. */
    @Synchronized
    fun seedToday(context: Context, steps: Int) {
        val p = prefs(context)
        val todayKey = LocalDate.now().toString()
        val days = days(p)
        if (steps > days.optInt(todayKey, 0)) {
            days.put(todayKey, steps)
            p.edit().putString(KEY_DAYS, days.toString()).apply()
        }
    }

    fun today(context: Context): Int = days(prefs(context)).optInt(LocalDate.now().toString(), 0)

    fun snapshot(context: Context): Map<String, Int> {
        val days = days(prefs(context))
        return days.keys().asSequence().associateWith { days.optInt(it, 0) }
    }

    fun goal(context: Context): Int = prefs(context).getInt(KEY_GOAL, 10_000)

    fun setGoal(context: Context, goal: Int) {
        prefs(context).edit().putInt(KEY_GOAL, goal).apply()
    }

    fun enabled(context: Context): Boolean = prefs(context).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()
    }

    private fun trim(days: JSONObject) {
        if (days.length() <= DAYS_KEPT) return
        val keys = days.keys().asSequence().sorted().toList()
        keys.take(keys.size - DAYS_KEPT).forEach { days.remove(it) }
    }
}
