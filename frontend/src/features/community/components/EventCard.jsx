import { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import {
  Calendar,
  CheckCircle2,
  Clock,
  Download,
  ExternalLink,
  MapPin,
  Sparkles,
  Trash2,
  Users,
  Video,
  AlertCircle,
  ChevronRight,
} from "lucide-react";
import { motion } from "framer-motion";
import Badge from "../../../components/Badge";
import Card from "../../../components/Card";
import ScholarAvatar from "../../auth/components/ScholarAvatar";
import { useAuth } from "../../auth/useAuth";
import {
  deleteEvent,
  toggleEventRSVP,
  extractCommunityErrorMessage,
} from "../api";

// The null check lives in this wrapper so every hook in EventCardContent
// runs on every render (hooks after an early return break React's hook order).
export default function EventCard(props) {
  if (!props.event) return null;
  return <EventCardContent {...props} />;
}

function EventCardContent({ event, onToggleRSVP, onDeleted }) {
  const { user } = useAuth();
  const [userStatus, setUserStatus] = useState(
    event.user_rsvp_status || (event.is_attending ? "going" : null),
  );
  const [goingCount, setGoingCount] = useState(
    event.going_count !== undefined
      ? event.going_count
      : event.is_attending
        ? event.rsvps_count || 1
        : event.rsvps_count || 0,
  );
  const [interestedCount, setInterestedCount] = useState(
    event.interested_count || 0,
  );
  const [loading, setLoading] = useState(false);
  const [rsvpError, setRsvpError] = useState("");

  const maxSlots = event.max_participants || 0;
  const isCapped = maxSlots > 0;
  const isFull = isCapped && goingCount >= maxSlots;
  const spotsLeft = isCapped ? Math.max(0, maxSlots - goingCount) : null;

  useEffect(() => {
    if (!event) return;
    setUserStatus(
      event.user_rsvp_status || (event.is_attending ? "going" : null),
    );
    setGoingCount(
      event.going_count !== undefined
        ? event.going_count
        : event.is_attending
          ? event.rsvps_count || 1
          : event.rsvps_count || 0,
    );
    setInterestedCount(event.interested_count || 0);
  }, [event]);

  const isCreator = user?.id === event.creator?.id;

  async function handleToggleStatus(targetStatus) {
    if (loading) return;
    setRsvpError("");

    // If attempting to mark going when slots are full and user is not already going
    if (targetStatus === "going" && isFull && userStatus !== "going") {
      setRsvpError(
        `All ${maxSlots} Going spots are currently booked! You can still mark as 'Interested' to stay updated.`,
      );
      return;
    }

    setLoading(true);
    try {
      if (onToggleRSVP) {
        const res = await onToggleRSVP(event.id, targetStatus);
        if (res) {
          setUserStatus(res.user_rsvp_status);
          setGoingCount(res.going_count);
          setInterestedCount(res.interested_count);
        } else {
          // Fallback optimistic update
          if (userStatus === targetStatus) {
            setUserStatus(null);
            if (targetStatus === "going")
              setGoingCount((c) => Math.max(0, c - 1));
            else setInterestedCount((c) => Math.max(0, c - 1));
          } else {
            if (userStatus === "going")
              setGoingCount((c) => Math.max(0, c - 1));
            if (userStatus === "interested")
              setInterestedCount((c) => Math.max(0, c - 1));
            setUserStatus(targetStatus);
            if (targetStatus === "going") setGoingCount((c) => c + 1);
            else setInterestedCount((c) => c + 1);
          }
        }
      } else {
        const res = await toggleEventRSVP(event.id, targetStatus);
        setUserStatus(res.user_rsvp_status);
        setGoingCount(res.going_count);
        setInterestedCount(res.interested_count);
      }
    } catch (err) {
      setRsvpError(extractCommunityErrorMessage(err));
    } finally {
      setLoading(false);
    }
  }

  async function handleDelete() {
    if (!window.confirm("Cancel and remove this campus study event?")) {
      return;
    }
    try {
      await deleteEvent(event.id);
      if (onDeleted) {
        onDeleted(event.id);
      }
    } catch (err) {
      console.error("Error deleting event:", err);
    }
  }

  // Parse date into Month and Day safely
  const dateObj = event?.event_date ? new Date(event.event_date) : null;
  const isValidDate = dateObj && !isNaN(dateObj.getTime());
  const monthStr = isValidDate
    ? dateObj.toLocaleDateString(undefined, { month: "short" }).toUpperCase()
    : "OCT";
  const dayStr = isValidDate ? dateObj.getDate() : "15";
  const dayName = isValidDate
    ? dateObj.toLocaleDateString(undefined, { weekday: "short" })
    : "Monday";

  const isOnline =
    event.location?.toLowerCase().includes("meet") ||
    event.location?.toLowerCase().includes("zoom") ||
    event.location?.toLowerCase().includes("http");

  function getGoogleCalendarUrl() {
    if (!event?.event_date) return "#";
    const dateStr = (event.event_date || "").replace(/-/g, "");
    const startTime =
      (event.start_time || "10:00").replace(/:/g, "").slice(0, 4) + "00";
    const endTime =
      (event.end_time || "12:00").replace(/:/g, "").slice(0, 4) + "00";
    const dates = `${dateStr}T${startTime}/${dateStr}T${endTime}`;
    const details = `${event.description || ""}\n\nCourse: ${event.subject || ""}\nOrganized by: ${event.creator?.full_name || "Scholar"}`;
    return `https://calendar.google.com/calendar/render?action=TEMPLATE&text=${encodeURIComponent(event.title || "Study Session")}&dates=${dates}&details=${encodeURIComponent(details)}&location=${encodeURIComponent(event.location || "")}`;
  }

  function handleDownloadIcs() {
    const dateStr = (event.event_date || "").replace(/-/g, "");
    const startTime =
      (event.start_time || "10:00").replace(/:/g, "").slice(0, 4) + "00";
    const endTime =
      (event.end_time || "12:00").replace(/:/g, "").slice(0, 4) + "00";
    const icsLines = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//Student Brain//Study Planner Calendar//EN",
      "CALSCALE:GREGORIAN",
      "METHOD:PUBLISH",
      "BEGIN:VEVENT",
      `SUMMARY:${(event.title || "Study Session").replace(/\n/g, " ")}`,
      `DESCRIPTION:${(event.description || event.subject || "").replace(/\n/g, "\\n")}`,
      `LOCATION:${(event.location || "").replace(/\n/g, " ")}`,
      `DTSTART:${dateStr}T${startTime}`,
      `DTEND:${dateStr}T${endTime}`,
      "STATUS:CONFIRMED",
      "END:VEVENT",
      "END:VCALENDAR",
    ];
    const blob = new Blob([icsLines.join("\r\n")], {
      type: "text/calendar;charset=utf-8",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `${(event.title || "study-event").toLowerCase().replace(/[^a-z0-9]/g, "-")}.ics`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }

  return (
    <motion.div
      whileHover={{ y: -6 }}
      transition={{ duration: 0.22, ease: "easeOut" }}
      style={{ height: "100%" }}
    >
      <Card className="premium-event-booking-card">
        <div className="event-booking-layout">
          {/* Left Vertical Date Stamp */}
          <div className="event-vertical-date-stamp">
            <span className="stamp-day-name">{dayName}</span>
            <span className="stamp-month-abbr">{monthStr}</span>
            <strong className="stamp-day-num">{dayStr}</strong>
            <div className="stamp-glow-blob" />
          </div>

          {/* Right Event Content Details */}
          <div className="event-booking-right-content">
            {/* Top Badges & Actions */}
            <div className="event-booking-top-row">
              <div
                style={{
                  display: "flex",
                  gap: "6px",
                  alignItems: "center",
                  flexWrap: "wrap",
                }}
              >
                <Badge variant="primary" size="sm">
                  {event.subject || "Study Session"}
                </Badge>
                {isOnline && (
                  <Badge variant="success" size="sm">
                    <Video size={11} />
                    <span>Virtual Meet</span>
                  </Badge>
                )}
                {isCapped && isFull && (
                  <Badge variant="danger" size="sm">
                    <span>⛔ Slots Full</span>
                  </Badge>
                )}
                {isCapped && !isFull && spotsLeft <= 3 && spotsLeft > 0 && (
                  <Badge variant="warning" size="sm">
                    <span>
                      🔥 {spotsLeft} Spot{spotsLeft > 1 ? "s" : ""} Left
                    </span>
                  </Badge>
                )}
              </div>

              {isCreator && (
                <button
                  type="button"
                  className="event-delete-ghost-btn"
                  onClick={handleDelete}
                  title="Cancel Event"
                >
                  <Trash2 size={15} />
                </button>
              )}
            </div>

            {/* Title */}
            <h3 className="event-booking-title">{event.title}</h3>

            {/* Description */}
            {event.description && (
              <p className="event-booking-desc">{event.description}</p>
            )}

            {/* Host Section */}
            <div className="event-host-row">
              <ScholarAvatar user={event.creator} size={26} />
              <span className="event-host-text">
                Organized by{" "}
                <strong>
                  {event.creator?.full_name ||
                    event.creator?.email?.split("@")[0] ||
                    "Scholar"}
                </strong>
              </span>
            </div>

            {/* Meta Pills */}
            <div className="event-booking-pills-row">
              <div className="event-info-pill">
                <Clock size={13} className="text-indigo" />
                <span>
                  {event.start_time?.slice(0, 5)} -{" "}
                  {event.end_time?.slice(0, 5)}
                </span>
              </div>

              <div className="event-info-pill">
                {isOnline ? (
                  <Video size={13} className="text-emerald" />
                ) : (
                  <MapPin size={13} className="text-amber" />
                )}
                <span>{event.location || "Campus Library"}</span>
              </div>
            </div>

            {/* Social Response Counters & Capacity */}
            <div className="event-capacity-section">
              <div className="event-response-stats-row">
                <span className="response-stat-item stat-going">
                  <CheckCircle2 size={13} className="text-emerald" />
                  <strong>{goingCount}</strong> Going
                </span>
                <span className="response-stat-dot">•</span>
                <span className="response-stat-item stat-interested">
                  <Sparkles size={13} className="text-amber" />
                  <strong>{interestedCount}</strong> Interested
                </span>

                {isCapped ? (
                  <span className="capacity-seats-label">
                    ({goingCount} / {maxSlots} seats {isFull ? "• Full" : ""})
                  </span>
                ) : (
                  <span className="capacity-seats-label">
                    ({goingCount} Going • Open capacity)
                  </span>
                )}
              </div>

              {isCapped && (
                <div className="capacity-bar-track">
                  <div
                    className="capacity-bar-fill"
                    style={{
                      width: `${Math.min(100, Math.round((goingCount / maxSlots) * 100))}%`,
                      backgroundColor: isFull
                        ? "var(--color-danger, #ef4444)"
                        : spotsLeft <= 3
                          ? "var(--color-warning, #f59e0b)"
                          : "var(--color-primary, #f26522)",
                    }}
                  />
                </div>
              )}
            </div>

            {rsvpError && (
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "6px",
                  fontSize: "0.76rem",
                  color: "var(--color-danger, #ef4444)",
                  background: "rgba(239, 68, 68, 0.08)",
                  padding: "6px 10px",
                  borderRadius: "var(--radius-sm)",
                  marginTop: "8px",
                }}
              >
                <AlertCircle size={13} />
                <span>{rsvpError}</span>
              </div>
            )}

            {/* Bottom Facebook-Style Action Buttons */}
            <div className="event-booking-footer-action">
              <div className="event-fb-actions-row">
                <motion.button
                  type="button"
                  whileTap={{ scale: 0.95 }}
                  className={`event-fb-btn event-btn-going ${userStatus === "going" ? "is-active" : ""}`}
                  onClick={() => handleToggleStatus("going")}
                  disabled={loading}
                  title={
                    userStatus === "going"
                      ? "You are going (Click to remove)"
                      : isFull
                        ? "Going slots are full"
                        : "Mark as Going"
                  }
                  style={
                    isFull && userStatus !== "going"
                      ? { opacity: 0.7, cursor: "not-allowed" }
                      : {}
                  }
                >
                  <CheckCircle2 size={15} />
                  <span>
                    {userStatus === "going"
                      ? "Going ✓"
                      : isFull
                        ? "Slots Full"
                        : "Going"}
                  </span>
                </motion.button>

                <motion.button
                  type="button"
                  whileTap={{ scale: 0.95 }}
                  className={`event-fb-btn event-btn-interested ${userStatus === "interested" ? "is-active" : ""}`}
                  onClick={() => handleToggleStatus("interested")}
                  disabled={loading}
                  title={
                    userStatus === "interested"
                      ? "You are interested (Click to remove)"
                      : "Mark as Interested (Unlimited)"
                  }
                >
                  <Sparkles size={15} />
                  <span>
                    {userStatus === "interested"
                      ? "Interested ★"
                      : "Interested"}
                  </span>
                </motion.button>
              </div>

              {/* Added to Calendar & Planner Actions */}
              {(userStatus === "going" || userStatus === "interested") && (
                <div className="event-sync-section">
                  <div className="event-planner-sync-banner">
                    <div className="sync-banner-text">
                      <CheckCircle2 size={14} className="text-emerald" />
                      <span>
                        Added to your <strong>Study Planner</strong>
                      </span>
                    </div>
                    <Link
                      to="/planner"
                      className="sync-banner-link"
                      title="Open in Study Planner"
                    >
                      <span>Planner</span>
                      <ChevronRight size={12} />
                    </Link>
                  </div>

                  <div className="event-cal-action-row">
                    <a
                      href={getGoogleCalendarUrl()}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="event-cal-btn-outline"
                      title="Add this event to Google Calendar"
                    >
                      <Calendar size={13} className="text-primary" />
                      <span>Google Calendar</span>
                      <ExternalLink size={10} style={{ opacity: 0.6 }} />
                    </a>

                    <button
                      type="button"
                      onClick={handleDownloadIcs}
                      className="event-cal-btn-outline"
                      title="Download iCal file for Apple Calendar or Microsoft Outlook"
                    >
                      <Download size={13} className="text-amber" />
                      <span>Apple / Outlook (.ics)</span>
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </Card>
    </motion.div>
  );
}
