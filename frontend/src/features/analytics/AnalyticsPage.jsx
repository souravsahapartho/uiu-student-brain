import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import {
  BarChart3,
  BookOpen,
  Calendar,
  CheckCircle2,
  Clock,
  Flame,
  GraduationCap,
  Layers,
  RefreshCw,
  Sparkles,
  Target,
  TrendingUp,
  Zap,
} from "lucide-react";
import Badge from "../../components/Badge";
import Button from "../../components/Button";
import Card from "../../components/Card";
import ErrorState from "../../components/ErrorState";
import { StatSkeleton } from "../../components/Skeleton";
import { extractAnalyticsErrorMessage, getAnalyticsDashboard } from "./api";
import GpaTrajectoryCard from "./components/GpaTrajectoryCard";
import ScheduleAdherenceCard from "./components/ScheduleAdherenceCard";
import SubjectDistributionChart from "./components/SubjectDistributionChart";
import WeeklyTrendChart from "./components/WeeklyTrendChart";

export default function AnalyticsPage() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  async function loadDashboard() {
    setLoading(true);
    setError("");

    try {
      const res = await getAnalyticsDashboard();
      setData(res);
    } catch (err) {
      console.error("Failed to load analytics dashboard:", err);
      setError(extractAnalyticsErrorMessage(err));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadDashboard();
  }, []);

  const summary = data?.summary || {};
  const totalStudyMinutes = Number(summary.total_study_minutes) || 0;
  const totalHours = Math.floor(totalStudyMinutes / 60);
  const remainingMins = totalStudyMinutes % 60;
  const totalSessions = Number(summary.total_sessions) || 0;
  const totalSubjects = Number(summary.total_subjects) || 0;
  const avgSessionMinutes = Number(summary.avg_session_minutes) || 0;

  const gpaSummary = data?.gpa_summary || null;
  const adherence = data?.schedule_adherence || {};
  const adherenceRate = Number(adherence.adherence_rate) || 0;
  const coveredCount = Array.isArray(adherence.covered_subjects_this_week)
    ? adherence.covered_subjects_this_week.length
    : 0;
  const scheduledCount = Array.isArray(adherence.scheduled_subjects)
    ? adherence.scheduled_subjects.length
    : 0;

  const insights = Array.isArray(data?.insights) ? data.insights : [];

  return (
    <div className="analytics-page-container">
      {/* Page Header */}
      <div className="page-header">
        <div className="page-header-row">
          <div>
            <h1 className="page-title">
              <BarChart3 size={28} className="text-orange" />
              <span>Academic & Focus Analytics</span>
            </h1>
            <p className="page-description">
              Comprehensive academic intelligence: focus time trends, subject
              distribution, GPA forecast, and routine adherence.
            </p>
          </div>

          <Button
            variant="secondary"
            onClick={loadDashboard}
            icon={RefreshCw}
            disabled={loading}
          >
            {loading ? "Refreshing..." : "Refresh Analytics"}
          </Button>
        </div>
      </div>

      {/* Loading Skeletons */}
      {loading && (
        <div className="stats-cards-row">
          <StatSkeleton />
          <StatSkeleton />
          <StatSkeleton />
          <StatSkeleton />
        </div>
      )}

      {/* Error State */}
      {!loading && error && (
        <ErrorState
          title="Failed to compute analytics"
          message={error}
          onRetry={loadDashboard}
        />
      )}

      {/* Loaded Analytics Dashboard */}
      {!loading && !error && data && (
        <div>
          {/* KPI Summary Grid with 4 dynamic, responsive cards */}
          <div className="stats-cards-row">
            {/* Card 1: Focus Investment */}
            <Card variant="stat" className="stat-orange">
              <div className="stat-top-row">
                <span className="stat-header-label">Focus Investment</span>
                <div className="stat-icon-pill bg-orange-subtle">
                  <Clock size={16} className="text-orange" />
                </div>
              </div>
              <div className="stat-number-row">
                <strong className="stat-metric-value">
                  {totalHours}h {remainingMins}m
                </strong>
              </div>
              {/* Progress bar towards 15h weekly goal */}
              <div className="stat-progress-track">
                <div
                  className="stat-progress-bar bg-orange"
                  style={{
                    width: `${Math.min(100, Math.round((totalStudyMinutes / (15 * 60)) * 100))}%`,
                  }}
                />
              </div>
              <div className="stat-metric-footer">
                <span className="stat-micro-badge badge-orange-subtle">
                  {Math.min(
                    100,
                    Math.round((totalStudyMinutes / (15 * 60)) * 100),
                  )}
                  % of 15h Goal
                </span>
                <span className="stat-footer-subtext">
                  {totalSessions} sessions
                </span>
              </div>
            </Card>

            {/* Card 2: Subject Breadth */}
            <Card variant="stat" className="stat-emerald">
              <div className="stat-top-row">
                <span className="stat-header-label">Subject Breadth</span>
                <div className="stat-icon-pill bg-emerald-subtle">
                  <BookOpen size={16} className="text-emerald" />
                </div>
              </div>
              <div className="stat-number-row">
                <strong className="stat-metric-value">
                  {totalSubjects} Subjects
                </strong>
              </div>
              {/* Progress bar representing subject coverage */}
              <div className="stat-progress-track">
                <div
                  className="stat-progress-bar bg-emerald"
                  style={{ width: `${Math.min(100, totalSubjects * 25)}%` }}
                />
              </div>
              <div className="stat-metric-footer">
                <span className="stat-micro-badge badge-emerald-subtle">
                  {totalSubjects >= 4
                    ? "Broad Mastery"
                    : totalSubjects >= 2
                      ? "Balanced Focus"
                      : totalSubjects === 1
                        ? "Deep Focus"
                        : "No Subjects"}
                </span>
                <span className="stat-footer-subtext">
                  {avgSessionMinutes > 0
                    ? `Avg ${avgSessionMinutes}m`
                    : "No sessions"}
                </span>
              </div>
            </Card>

            {/* Card 3: Academic Standing */}
            <Card variant="stat" className="stat-amber">
              <div className="stat-top-row">
                <span className="stat-header-label">Academic Standing</span>
                <div className="stat-icon-pill bg-amber-subtle">
                  <GraduationCap size={16} className="text-amber" />
                </div>
              </div>
              <div className="stat-number-row">
                <strong className="stat-metric-value">
                  {gpaSummary && typeof gpaSummary.current_gpa === "number"
                    ? `${gpaSummary.current_gpa.toFixed(2)}`
                    : "N/A"}
                </strong>
              </div>
              {/* Progress bar representing GPA on 4.0 scale */}
              <div className="stat-progress-track">
                <div
                  className="stat-progress-bar bg-amber"
                  style={{
                    width: `${gpaSummary && gpaSummary.current_gpa ? Math.min(100, Math.round((gpaSummary.current_gpa / 4.0) * 100)) : 0}%`,
                  }}
                />
              </div>
              <div className="stat-metric-footer">
                <span className="stat-micro-badge badge-amber-subtle">
                  {gpaSummary?.target_gpa && gpaSummary?.current_gpa
                    ? gpaSummary.target_gpa - gpaSummary.current_gpa > 0
                      ? `+${(gpaSummary.target_gpa - gpaSummary.current_gpa).toFixed(2)} to Goal`
                      : "Goal Reached! 🌟"
                    : "Scale / 4.00"}
                </span>
                <span className="stat-footer-subtext">
                  {gpaSummary?.remaining_credits
                    ? `${gpaSummary.remaining_credits} cr left`
                    : "Goal Active"}
                </span>
              </div>
            </Card>

            {/* Card 4: Routine Adherence */}
            <Card variant="stat" className="stat-rose">
              <div className="stat-top-row">
                <span className="stat-header-label">Routine Adherence</span>
                <div className="stat-icon-pill bg-rose-subtle">
                  <Calendar size={16} className="text-rose" />
                </div>
              </div>
              <div className="stat-number-row">
                <strong className="stat-metric-value">{adherenceRate}%</strong>
              </div>
              {/* Progress bar representing adherence */}
              <div className="stat-progress-track">
                <div
                  className="stat-progress-bar bg-rose"
                  style={{ width: `${adherenceRate}%` }}
                />
              </div>
              <div className="stat-metric-footer">
                <span className="stat-micro-badge badge-rose-subtle">
                  {adherenceRate >= 80
                    ? "On Track 🌟"
                    : adherenceRate >= 50
                      ? "Moderate ⚡"
                      : adherenceRate > 0
                        ? "Needs Focus 🎯"
                        : "0% Adherent"}
                </span>
                <span className="stat-footer-subtext">
                  {coveredCount}/{scheduledCount} routines
                </span>
              </div>
            </Card>
          </div>

          {/* Smart AI Academic Intelligence Insights */}
          {insights.length > 0 && (
            <div className="analytics-insights-banner">
              <div className="insights-banner-header">
                <div
                  style={{ display: "flex", alignItems: "center", gap: "8px" }}
                >
                  <Sparkles size={18} className="text-primary" />
                  <h3 className="insights-banner-title">
                    Smart Academic Intelligence & Recommendations
                  </h3>
                </div>
                <span className="badge badge-primary badge-sm">
                  {insights.length} Actionable Insights
                </span>
              </div>
              <div className="insights-cards-grid">
                {insights.map((insight, idx) => {
                  const isGpa =
                    insight.includes("GPA") || insight.includes("🎓");
                  const isRoutine =
                    insight.includes("Routine") ||
                    insight.includes("Adherence") ||
                    insight.includes("Schedule") ||
                    insight.includes("📅");
                  const isSubject =
                    insight.includes("Subject") ||
                    insight.includes("Focus") ||
                    insight.includes("Time");

                  let icon = <Sparkles size={16} className="text-primary" />;
                  let category = "Academic Strategy";
                  let cardClass = "insight-card-primary";

                  if (isGpa) {
                    icon = <GraduationCap size={16} className="text-amber" />;
                    category = "GPA Trajectory Strategy";
                    cardClass = "insight-card-amber";
                  } else if (isRoutine) {
                    icon = <Calendar size={16} className="text-rose" />;
                    category = "Routine & Habit";
                    cardClass = "insight-card-rose";
                  } else if (isSubject) {
                    icon = <BookOpen size={16} className="text-emerald" />;
                    category = "Study Distribution";
                    cardClass = "insight-card-emerald";
                  }

                  return (
                    <div key={idx} className={`insight-rich-card ${cardClass}`}>
                      <div className="insight-card-icon-col">{icon}</div>
                      <div className="insight-card-body">
                        <div className="insight-card-meta">
                          <span className="insight-category-tag">
                            {category}
                          </span>
                        </div>
                        <p className="insight-card-text">{insight}</p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Analytics Visual Charts Grid */}
          <div className="analytics-charts-grid">
            <WeeklyTrendChart trend={data.weekly_trend} />
            <SubjectDistributionChart
              distribution={data.subject_distribution}
            />
            <GpaTrajectoryCard gpaSummary={data.gpa_summary} />
            <ScheduleAdherenceCard adherence={data.schedule_adherence} />
          </div>
        </div>
      )}
    </div>
  );
}
