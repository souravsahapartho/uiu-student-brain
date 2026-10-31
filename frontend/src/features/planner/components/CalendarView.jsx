import { useState, useEffect, useRef } from "react";
import {
  ChevronLeft,
  ChevronRight,
  Calendar as CalendarIcon,
  Clock,
  Layers,
  Sparkles,
} from "lucide-react";
import Badge from "../../../components/Badge";
import Button from "../../../components/Button";
import ScheduleDetailModal from "./ScheduleDetailModal";

const ALL_DAYS = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
];

// Vibrant academic color palettes for subject blocks
const SUBJECT_COLORS = [
  {
    bg: "rgba(242, 101, 34, 0.12)",
    border: "#f26522",
    text: "#c2410c",
    badge: "primary",
    accent: "#f26522",
  },
  {
    bg: "rgba(16, 185, 129, 0.12)",
    border: "#10b981",
    text: "#065f46",
    badge: "success",
    accent: "#10b981",
  },
  {
    bg: "rgba(245, 158, 11, 0.12)",
    border: "#f59e0b",
    text: "#92400e",
    badge: "warning",
    accent: "#f59e0b",
  },
  {
    bg: "rgba(234, 88, 12, 0.12)",
    border: "#ea580c",
    text: "#9a3412",
    badge: "accent",
    accent: "#ea580c",
  },
  {
    bg: "rgba(244, 63, 94, 0.12)",
    border: "#f43f5e",
    text: "#9f1239",
    badge: "danger",
    accent: "#f43f5e",
  },
  {
    bg: "rgba(6, 182, 212, 0.12)",
    border: "#06b6d4",
    text: "#155e75",
    badge: "accent",
    accent: "#06b6d4",
  },
  {
    bg: "rgba(217, 119, 6, 0.12)",
    border: "#d97706",
    text: "#b45309",
    badge: "warning",
    accent: "#d97706",
  },
];

function getSubjectColor(subject) {
  if (!subject) return SUBJECT_COLORS[0];
  let hash = 0;
  for (let i = 0; i < subject.length; i++) {
    hash = subject.charCodeAt(i) + ((hash << 5) - hash);
  }
  const index = Math.abs(hash) % SUBJECT_COLORS.length;
  return SUBJECT_COLORS[index];
}

function timeToMinutes(timeStr) {
  if (!timeStr) return 0;
  const [h, m] = timeStr.split(":").map(Number);
  return h * 60 + (m || 0);
}

export default function CalendarView({
  schedules,
  onEditSchedule,
  onDeleteSchedule,
  onSlotClick,
}) {
  const [currentWeekOffset, setCurrentWeekOffset] = useState(0); // 0 = current week, -1 = last week, +1 = next week
  const [selectedSchedule, setSelectedSchedule] = useState(null);

  // Calculate week dates starting from Sunday of the active week
  const today = new Date();
  const currentDayOfWeek = today.getDay(); // 0 = Sunday, 1 = Monday, ...

  const startOfWeek = new Date(today);
  startOfWeek.setDate(
    today.getDate() - currentDayOfWeek + currentWeekOffset * 7,
  );
  startOfWeek.setHours(0, 0, 0, 0);

  const weekDays = ALL_DAYS.map((dayName, idx) => {
    const dayDate = new Date(startOfWeek);
    dayDate.setDate(startOfWeek.getDate() + idx);
    const isToday =
      dayDate.toDateString() === today.toDateString() &&
      currentWeekOffset === 0;

    return {
      dayName,
      date: dayDate,
      dateFormatted: dayDate.toLocaleDateString(undefined, {
        month: "short",
        day: "numeric",
      }),
      dayNumber: dayDate.getDate(),
      isToday,
    };
  });

  const endOfWeek = new Date(startOfWeek);
  endOfWeek.setDate(startOfWeek.getDate() + 6);

  const weekRangeLabel = `${startOfWeek.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
  })} – ${endOfWeek.toLocaleDateString(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
  })}`;

  const [isMobile, setIsMobile] = useState(
    () => typeof window !== "undefined" && window.innerWidth <= 640,
  );
  const [isTablet, setIsTablet] = useState(
    () =>
      typeof window !== "undefined" &&
      window.innerWidth > 640 &&
      window.innerWidth <= 1024,
  );

  useEffect(() => {
    const handleResize = () => {
      const w = window.innerWidth;
      setIsMobile(w <= 640);
      setIsTablet(w > 640 && w <= 1024);
    };
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  const gridWrapperRef = useRef(null);
  const [activeJumpDay, setActiveJumpDay] = useState(() => today.getDay());

  const scrollToDay = (dayIndex) => {
    setActiveJumpDay(dayIndex);
    if (!gridWrapperRef.current) return;
    const colWidth = isMobile ? 80 : isTablet ? 95 : 110;
    const targetScroll = Math.max(
      0,
      dayIndex * colWidth - (isMobile ? 12 : 30),
    );
    gridWrapperRef.current.scrollTo({ left: targetScroll, behavior: "smooth" });
  };

  // Time Axis configuration (from 07:00 to 22:00)
  const START_HOUR = 7;
  const END_HOUR = 22;
  const TOTAL_HOURS = END_HOUR - START_HOUR;
  // Compact, responsive hour heights
  const HOUR_HEIGHT = isMobile ? 38 : isTablet ? 46 : 56;
  const PIXELS_PER_MINUTE = HOUR_HEIGHT / 60;

  const hoursArray = Array.from(
    { length: TOTAL_HOURS + 1 },
    (_, i) => START_HOUR + i,
  );

  // Group schedules by day
  const schedulesByDay = {};
  ALL_DAYS.forEach((d) => (schedulesByDay[d] = []));

  let totalWeeklyMinutes = 0;
  const activeSubjectsSet = new Set();

  schedules.forEach((sch) => {
    activeSubjectsSet.add(sch.subject);
    const dur = timeToMinutes(sch.end_time) - timeToMinutes(sch.start_time);
    sch.days?.forEach((d) => {
      if (schedulesByDay[d]) {
        schedulesByDay[d].push(sch);
        totalWeeklyMinutes += Math.max(0, dur);
      }
    });
  });

  // Calculate planned hours per day
  const dailyHoursMap = {};
  ALL_DAYS.forEach((d) => {
    const dayMins = schedulesByDay[d].reduce((acc, sch) => {
      return (
        acc +
        Math.max(0, timeToMinutes(sch.end_time) - timeToMinutes(sch.start_time))
      );
    }, 0);
    dailyHoursMap[d] = (dayMins / 60).toFixed(1);
  });

  return (
    <div className="planner-calendar-container">
      {/* Calendar Header / Navigation Bar */}
      <div className="calendar-header-bar">
        <div className="calendar-nav-controls">
          <div className="week-switch-buttons">
            <button
              type="button"
              className="cal-nav-btn"
              onClick={() => setCurrentWeekOffset((prev) => prev - 1)}
              title="Previous Week"
            >
              <ChevronLeft size={15} />
              <span className="cal-nav-btn-text">Prev</span>
            </button>
            <button
              type="button"
              className={`cal-nav-btn ${
                currentWeekOffset === 0 ? "cal-nav-today-active" : ""
              }`}
              onClick={() => setCurrentWeekOffset(0)}
            >
              Today
            </button>
            <button
              type="button"
              className="cal-nav-btn"
              onClick={() => setCurrentWeekOffset((prev) => prev + 1)}
              title="Next Week"
            >
              <span className="cal-nav-btn-text">Next</span>
              <ChevronRight size={15} />
            </button>
          </div>

          <h2 className="calendar-range-title">
            <span className="cal-range-emoji">🗓️</span>
            <span>{weekRangeLabel}</span>
          </h2>
        </div>

        {/* Quick Weekly Statistics Pills */}
        <div className="calendar-summary-chips">
          <span className="cal-stat-chip">
            ⏱️ <strong>{(totalWeeklyMinutes / 60).toFixed(1)}h</strong> planned
          </span>
          <span className="cal-stat-chip">
            📚 <strong>{activeSubjectsSet.size}</strong> courses
          </span>
          <span className="cal-stat-chip">
            🎯 <strong>{schedules.length}</strong> routines
          </span>
        </div>
      </div>

      {/* Quick Day Jump Bar (Phone & Tablet) */}
      <div className="calendar-quick-jump-container">
        <div className="quick-jump-label-row">
          <div className="quick-jump-badge">
            <CalendarIcon size={12} className="text-orange" />
            <span>Quick Day Jump:</span>
          </div>
          <span className="quick-jump-hint">Tap day to center timeline</span>
        </div>
        <div className="quick-jump-chips-track">
          {weekDays.map((day, i) => {
            const hasRoutines = Number(dailyHoursMap[day.dayName]) > 0;
            const isSelected = activeJumpDay === i;
            return (
              <button
                key={day.dayName}
                type="button"
                className={`quick-jump-chip ${
                  isSelected ? "chip-selected" : ""
                } ${day.isToday ? "chip-today" : ""}`}
                onClick={() => scrollToDay(i)}
              >
                <span className="chip-day-name">{day.dayName.slice(0, 3)}</span>
                <span className="chip-day-num">{day.dayNumber}</span>
                {hasRoutines && (
                  <span
                    className="chip-hours-dot"
                    title={`${dailyHoursMap[day.dayName]} hrs scheduled`}
                  />
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Main Calendar Grid */}
      <div className="calendar-grid-wrapper" ref={gridWrapperRef}>
        <div className="calendar-scroll-area">
          {/* Day Headers Row */}
          <div className="calendar-days-header-row">
            {/* Empty corner cell above time column */}
            <div className="time-axis-header-cell">
              <span className="time-zone-label">GMT+6</span>
            </div>

            {/* 7 Day Column Headers */}
            {weekDays.map((day) => (
              <div
                key={day.dayName}
                className={`day-header-cell ${
                  day.isToday ? "day-header-today" : ""
                }`}
              >
                <div className="day-name-row">
                  <span className="day-name-label">
                    {day.dayName.slice(0, 3)}
                  </span>
                  <span
                    className={`day-date-number ${
                      day.isToday ? "date-number-today" : ""
                    }`}
                  >
                    {day.dayNumber}
                  </span>
                </div>
                <div className="day-hours-pill">
                  {dailyHoursMap[day.dayName] > 0
                    ? `${dailyHoursMap[day.dayName]}h`
                    : "0h"}
                </div>
              </div>
            ))}
          </div>

          {/* Timetable Body (Time Axis + 7 Day Columns) */}
          <div
            className="calendar-body-grid"
            style={{ height: `${TOTAL_HOURS * HOUR_HEIGHT}px` }}
          >
            {/* Left Time Axis */}
            <div className="calendar-time-axis">
              {hoursArray.map((hour) => {
                const hourFormatted = `${hour.toString().padStart(2, "0")}:00`;
                return (
                  <div
                    key={hour}
                    className="time-axis-slot"
                    style={{ height: `${HOUR_HEIGHT}px` }}
                  >
                    <span className="time-axis-label">{hourFormatted}</span>
                  </div>
                );
              })}
            </div>

            {/* 7 Day Event Lanes */}
            <div className="calendar-lanes-container">
              {weekDays.map((day, dayIndex) => {
                const daySchedules = schedulesByDay[day.dayName] || [];

                return (
                  <div
                    key={day.dayName}
                    className={`calendar-day-lane ${
                      day.isToday ? "lane-today" : ""
                    }`}
                    onClick={(e) => {
                      // Click on empty space in lane triggers quick add
                      if (e.target === e.currentTarget && onSlotClick) {
                        const rect = e.currentTarget.getBoundingClientRect();
                        const clickY = e.clientY - rect.top;
                        const clickedHour =
                          START_HOUR + Math.floor(clickY / HOUR_HEIGHT);
                        const safeHour = Math.min(
                          Math.max(clickedHour, START_HOUR),
                          END_HOUR - 1,
                        );
                        onSlotClick(day.dayName, safeHour);
                      }
                    }}
                  >
                    {/* Background Hour Lines */}
                    {hoursArray.slice(0, -1).map((hour) => (
                      <div
                        key={hour}
                        className="lane-hour-row"
                        style={{ height: `${HOUR_HEIGHT}px` }}
                      >
                        <div className="lane-half-hour-line" />
                      </div>
                    ))}

                    {/* Blocked Schedule Cards for this day */}
                    {daySchedules.map((schedule) => {
                      const startMins = timeToMinutes(schedule.start_time);
                      const endMins = timeToMinutes(schedule.end_time);

                      const topMinutes = Math.max(
                        0,
                        startMins - START_HOUR * 60,
                      );
                      const durationMinutes = Math.max(30, endMins - startMins);

                      const topPx = topMinutes * PIXELS_PER_MINUTE;
                      const heightPx = Math.max(
                        isMobile ? 36 : 42,
                        durationMinutes * PIXELS_PER_MINUTE - 4,
                      );

                      const colorTheme = getSubjectColor(schedule.subject);
                      const durationHours = (durationMinutes / 60).toFixed(1);

                      return (
                        <div
                          key={`${schedule.id}-${day.dayName}`}
                          className="calendar-time-block"
                          style={{
                            top: `${topPx}px`,
                            height: `${heightPx}px`,
                            backgroundColor: colorTheme.bg,
                            borderLeft: `${isMobile ? 3 : 4}px solid ${colorTheme.accent}`,
                            boxShadow: "0 2px 8px rgba(0,0,0,0.06)",
                          }}
                          onClick={(e) => {
                            e.stopPropagation();
                            setSelectedSchedule(schedule);
                          }}
                        >
                          <div className="time-block-header">
                            <h4
                              className="time-block-subject"
                              style={{ color: colorTheme.text }}
                            >
                              {schedule.subject}
                            </h4>
                          </div>

                          <div className="time-block-meta">
                            <span
                              className="time-block-time-pill"
                              style={{
                                color: colorTheme.text,
                                background: "rgba(255,255,255,0.7)",
                              }}
                            >
                              ⏰ {schedule.start_time.slice(0, 5)}–
                              {schedule.end_time.slice(0, 5)}
                            </span>

                            {heightPx >= (isMobile ? 38 : 60) && (
                              <span className="time-block-dur-pill">
                                {durationHours}h
                              </span>
                            )}
                          </div>

                          {schedule.deadline &&
                            heightPx >= (isMobile ? 55 : 75) && (
                              <div className="time-block-deadline">
                                🎯 Due {schedule.deadline.slice(5)}
                              </div>
                            )}
                        </div>
                      );
                    })}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      {/* Detail Popover Modal when time block is clicked */}
      {selectedSchedule && (
        <ScheduleDetailModal
          schedule={selectedSchedule}
          onClose={() => setSelectedSchedule(null)}
          onEdit={(sch) => {
            setSelectedSchedule(null);
            onEditSchedule(sch);
          }}
          onDelete={(id) => {
            setSelectedSchedule(null);
            onDeleteSchedule(id);
          }}
        />
      )}
    </div>
  );
}
