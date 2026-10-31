import { useState, useEffect } from "react";
import {
  Code2,
  ExternalLink,
  Laptop,
  Sparkles,
  Zap,
  MessageSquare,
  Users,
  BookOpen,
  FileText,
} from "lucide-react";
import Button from "../../../components/Button";
import Input from "../../../components/Input";
import FormError from "../../../components/FormError";
import { createPost, extractCommunityErrorMessage } from "../api";

const CATEGORIES = [
  { name: "General", icon: MessageSquare, label: "General" },
  { name: "Code Help", icon: Code2, label: "Code Help", highlight: true },
  { name: "Exam Prep", icon: Zap, label: "Exam Prep" },
  { name: "Study Group", icon: Users, label: "Study Group" },
  { name: "Course Help", icon: BookOpen, label: "Course Help" },
  { name: "Resources", icon: FileText, label: "Resources" },
];

const CODE_LANGUAGES = [
  { value: "python", label: "Python" },
  { value: "javascript", label: "JavaScript" },
  { value: "typescript", label: "TypeScript" },
  { value: "cpp", label: "C++" },
  { value: "c", label: "C" },
  { value: "java", label: "Java" },
  { value: "csharp", label: "C#" },
  { value: "html", label: "HTML / CSS" },
  { value: "sql", label: "SQL" },
  { value: "php", label: "PHP" },
  { value: "go", label: "Go" },
  { value: "rust", label: "Rust" },
  { value: "plaintext", label: "Other / Plain Text" },
];

const EXAM_TYPES = [
  "Midterm Exam",
  "Final Term Exam",
  "Class Quiz / Assessment",
  "Lab Test & Viva",
  "Assignment Review",
];

const RESOURCE_TYPES = [
  "Lecture Notes / Handouts",
  "Formula Sheet / Cheatsheet",
  "Previous Question Solve",
  "Video Tutorial Playlist",
  "Google Drive / Cloud Folder",
  "GitHub Repository / Codebase",
];

export default function PostForm({
  onSubmit,
  onCreated,
  onCancel,
  initialCategory = "General",
}) {
  const [category, setCategory] = useState(initialCategory);

  // General & Code Help fields
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [showCodeFields, setShowCodeFields] = useState(
    initialCategory === "Code Help",
  );
  const [codeSnippet, setCodeSnippet] = useState("");
  const [codeLanguage, setCodeLanguage] = useState("python");
  const [vsCodeUrl, setVsCodeUrl] = useState("");

  // Course Help fields
  const [courseCode, setCourseCode] = useState("");
  const [courseTopic, setCourseTopic] = useState("");
  const [courseDoubt, setCourseDoubt] = useState("");

  // Exam Prep fields
  const [examCourse, setExamCourse] = useState("");
  const [examType, setExamType] = useState("Midterm Exam");
  const [examTopics, setExamTopics] = useState("");
  const [examQuestions, setExamQuestions] = useState("");

  // Study Group fields
  const [groupGoal, setGroupGoal] = useState("");
  const [groupMode, setGroupMode] = useState("offline"); // "offline" | "online"
  const [groupLocation, setGroupLocation] = useState(
    "Campus Library 4th Floor",
  );
  const [onlinePlatform, setOnlinePlatform] = useState("Google Meet");
  const [onlineMeetingLink, setOnlineMeetingLink] = useState("");
  const [groupSize, setGroupSize] = useState("2-3 Members Needed");
  const [groupSchedule, setGroupSchedule] = useState("");

  // Resources fields
  const [resourceTitle, setResourceTitle] = useState("");
  const [resourceCourse, setResourceCourse] = useState("");
  const [resourceType, setResourceType] = useState("Lecture Notes / Handouts");
  const [resourceLink, setResourceLink] = useState("");
  const [resourceOverview, setResourceOverview] = useState("");

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  useEffect(() => {
    if (initialCategory) {
      setCategory(initialCategory);
      if (initialCategory === "Code Help") {
        setShowCodeFields(true);
      }
    }
  }, [initialCategory]);

  function handleSelectCategory(catName) {
    setCategory(catName);
    if (catName === "Code Help") {
      setShowCodeFields(true);
    } else {
      setShowCodeFields(false);
    }
  }

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");

    let finalTitle = "";
    let finalContent = "";
    let snippet = null;
    let liveUrl = null;

    if (category === "Code Help") {
      if (!title.trim() || !content.trim()) {
        setError("Please enter both a question title and details.");
        return;
      }
      finalTitle = title.trim();
      finalContent = content.trim();
      snippet = codeSnippet.trim() ? codeSnippet : null;
      liveUrl = vsCodeUrl.trim() ? vsCodeUrl.trim() : null;
    } else if (category === "General") {
      if (!title.trim() || !content.trim()) {
        setError("Please enter a discussion title and question details.");
        return;
      }
      finalTitle = title.trim();
      finalContent = content.trim();
      if (showCodeFields && codeSnippet.trim()) {
        snippet = codeSnippet;
        liveUrl = vsCodeUrl.trim() ? vsCodeUrl.trim() : null;
      }
    } else if (category === "Course Help") {
      if (!courseCode.trim() || !courseTopic.trim() || !courseDoubt.trim()) {
        setError(
          "Please fill in course code/title, topic, and your specific question.",
        );
        return;
      }
      finalTitle = `[${courseCode.trim()}] ${courseTopic.trim()}`;
      finalContent = `**Course**: ${courseCode.trim()}\n**Topic / Chapter**: ${courseTopic.trim()}\n\n### Question & Problem Details:\n${courseDoubt.trim()}`;
    } else if (category === "Exam Prep") {
      if (!examCourse.trim() || !examTopics.trim() || !examQuestions.trim()) {
        setError(
          "Please provide course name, target topics, and your exam inquiries.",
        );
        return;
      }
      finalTitle = `[${examCourse.trim()} - ${examType}] ${examTopics.trim().slice(0, 50)}`;
      finalContent = `**Course / Subject**: ${examCourse.trim()}\n**Target Exam**: ${examType}\n**Key Focus Topics**: ${examTopics.trim()}\n\n### Exam Prep Discussion & Questions:\n${examQuestions.trim()}`;
    } else if (category === "Study Group") {
      if (!groupGoal.trim() || !groupSchedule.trim()) {
        setError(
          "Please describe the study group goal and preferred meeting schedule.",
        );
        return;
      }
      if (groupMode === "offline" && !groupLocation.trim()) {
        setError(
          "Please specify the campus location / room for the in-person study session.",
        );
        return;
      }
      const modeLabel = groupMode === "online" ? "🌐 Online" : "📍 In-Person";
      finalTitle = `[Study Group - ${modeLabel}] ${groupGoal.trim()} • ${groupSize}`;

      let locationDetails = "";
      if (groupMode === "online") {
        locationDetails = `**Format**: Online Virtual Session\n**Platform**: ${onlinePlatform}\n${onlineMeetingLink.trim() ? `**Meeting Link**: [Join Online Session](${onlineMeetingLink.trim()})\n` : ""}`;
      } else {
        locationDetails = `**Format**: In-Person (Offline Campus)\n**Campus Location / Room**: ${groupLocation.trim()}\n`;
      }

      finalContent = `**Group Purpose / Course**: ${groupGoal.trim()}\n${locationDetails}**Target Capacity**: ${groupSize}\n\n### Schedule & Roadmap:\n${groupSchedule.trim()}`;
    } else if (category === "Resources") {
      if (!resourceTitle.trim() || !resourceOverview.trim()) {
        setError("Please provide a resource title and overview description.");
        return;
      }
      finalTitle = `[Resource] ${resourceTitle.trim()}${resourceCourse.trim() ? ` (${resourceCourse.trim()})` : ""}`;
      finalContent = `**Resource Name**: ${resourceTitle.trim()}\n**Course / Subject**: ${resourceCourse.trim() || "General Academic"}\n**Resource Type**: ${resourceType}\n${resourceLink.trim() ? `**Link / URL**: [Access Resource](${resourceLink.trim()})\n` : ""}\n### Overview & Contents:\n${resourceOverview.trim()}`;
    }

    setLoading(true);

    try {
      const payload = {
        title: finalTitle,
        category,
        content: finalContent,
        code_snippet: snippet || "",
        code_language: codeLanguage || "python",
        vscode_liveshare_url: liveUrl || "",
      };

      if (onSubmit) {
        await onSubmit(payload);
      } else if (onCreated) {
        const newPost = await createPost(payload);
        onCreated(newPost);
      } else {
        await createPost(payload);
      }
    } catch (err) {
      setError(extractCommunityErrorMessage(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="academic-form"
      style={{ display: "flex", flexDirection: "column", gap: "16px" }}
    >
      {error && <FormError message={error} />}

      {/* Visual Category Selection Grid */}
      <div className="form-group" style={{ marginBottom: 0 }}>
        <label
          className="form-label"
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
            marginBottom: "8px",
          }}
        >
          <span>Select Post Category</span>
        </label>

        <div className="post-category-selector-grid">
          {CATEGORIES.map((cat) => {
            const Icon = cat.icon;
            const isSelected = category === cat.name;
            return (
              <button
                key={cat.name}
                type="button"
                className={`category-selector-card ${
                  isSelected ? "is-selected" : ""
                } ${cat.highlight ? "highlight-code-card" : ""}`}
                onClick={() => handleSelectCategory(cat.name)}
              >
                <div className="category-card-left">
                  <Icon
                    size={16}
                    className={
                      isSelected
                        ? "text-primary"
                        : cat.highlight
                          ? "text-emerald"
                          : "text-muted"
                    }
                  />
                  <span className="category-card-label">{cat.label}</span>
                </div>
                {cat.highlight && <span className="code-pill-tag">Live</span>}
              </button>
            );
          })}
        </div>
      </div>

      {/* 1. CODE HELP SPECIFIC FORM */}
      {category === "Code Help" && (
        <>
          <div className="form-group" style={{ marginBottom: 0 }}>
            <label className="form-label">Code Problem Title *</label>
            <input
              type="text"
              className="form-input"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g., Recursion stack overflow in quicksort with large inputs"
              disabled={loading}
              required
            />
          </div>

          <div className="code-collaboration-box" style={{ marginTop: 0 }}>
            <div className="code-box-header">
              <div
                style={{ display: "flex", alignItems: "center", gap: "6px" }}
              >
                <Code2 size={16} className="text-emerald" />
                <span style={{ fontWeight: 700, fontSize: "0.85rem" }}>
                  Code Editor & Live Share Setup
                </span>
              </div>
              <span
                style={{
                  fontSize: "0.75rem",
                  color: "var(--color-text-muted)",
                }}
              >
                Peers can test or execute your code
              </span>
            </div>

            <div className="code-config-grid">
              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label" style={{ fontSize: "0.8rem" }}>
                  Programming Language
                </label>
                <select
                  value={codeLanguage}
                  onChange={(e) => setCodeLanguage(e.target.value)}
                  className="form-input"
                  style={{
                    width: "100%",
                    padding: "8px 12px",
                    borderRadius: "var(--radius-md)",
                  }}
                  disabled={loading}
                >
                  {CODE_LANGUAGES.map((lang) => (
                    <option key={lang.value} value={lang.value}>
                      {lang.label}
                    </option>
                  ))}
                </select>
              </div>

              <div className="form-group" style={{ marginBottom: 0 }}>
                <label className="form-label" style={{ fontSize: "0.8rem" }}>
                  VS Code Live Share Link{" "}
                  <span
                    style={{
                      fontWeight: "normal",
                      color: "var(--color-text-muted)",
                    }}
                  >
                    (Optional)
                  </span>
                </label>
                <input
                  type="url"
                  value={vsCodeUrl}
                  onChange={(e) => setVsCodeUrl(e.target.value)}
                  placeholder="https://prod.liveshare.vsengine.io/..."
                  className="form-input"
                  style={{
                    width: "100%",
                    padding: "8px 12px",
                    borderRadius: "var(--radius-md)",
                  }}
                  disabled={loading}
                />
              </div>
            </div>

            <div
              className="form-group"
              style={{ marginTop: "12px", marginBottom: 0 }}
            >
              <label className="form-label" style={{ fontSize: "0.8rem" }}>
                Problematic Code Snippet *
              </label>
              <textarea
                value={codeSnippet}
                onChange={(e) => setCodeSnippet(e.target.value)}
                placeholder="// Paste the code block where the error or bug occurs..."
                rows={5}
                className="form-input code-textarea"
                disabled={loading}
                required
              />
            </div>
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label className="form-label">Error Output & Details *</label>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="What error did you receive? What expected vs actual output are you seeing?"
              rows={3}
              className="form-input"
              style={{
                width: "100%",
                padding: "10px 14px",
                borderRadius: "var(--radius-md)",
                resize: "vertical",
              }}
              disabled={loading}
              required
            />
          </div>
        </>
      )}

      {/* 2. GENERAL SPECIFIC FORM */}
      {category === "General" && (
        <>
          <div className="form-group" style={{ marginBottom: 0 }}>
            <label className="form-label">Discussion Title / Question *</label>
            <input
              type="text"
              className="form-input"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g., Recommended electives for AI/ML specialization in junior year?"
              disabled={loading}
              required
            />
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label className="form-label">Discussion Details *</label>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="Share background, what you have explored so far, and questions for fellow scholars..."
              rows={4}
              className="form-input"
              style={{
                width: "100%",
                padding: "10px 14px",
                borderRadius: "var(--radius-md)",
                resize: "vertical",
              }}
              disabled={loading}
              required
            />
          </div>

          {/* Optional Code Snippet accordion */}
          <div className="code-attach-banner" style={{ marginTop: 0 }}>
            <button
              type="button"
              className={`code-attach-toggle-bar ${showCodeFields ? "is-open" : ""}`}
              onClick={() => setShowCodeFields(!showCodeFields)}
            >
              <div className="code-attach-left">
                <div
                  className={`code-icon-round ${showCodeFields ? "round-active" : ""}`}
                >
                  <Code2 size={16} />
                </div>
                <div className="code-attach-text-wrap">
                  <div className="code-attach-title">
                    {showCodeFields
                      ? "✓ Code Attachment Enabled"
                      : "+ Attach Code Snippet (Optional)"}
                  </div>
                  <div className="code-attach-desc">
                    Include a code snippet or script in your general discussion
                  </div>
                </div>
              </div>
              <span className="code-toggle-pill-btn">
                {showCodeFields ? "Hide" : "+ Add Code"}
              </span>
            </button>
          </div>

          {showCodeFields && (
            <div className="code-collaboration-box">
              <div className="code-config-grid">
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label" style={{ fontSize: "0.8rem" }}>
                    Language
                  </label>
                  <select
                    value={codeLanguage}
                    onChange={(e) => setCodeLanguage(e.target.value)}
                    className="form-input"
                    style={{ width: "100%", padding: "8px 12px" }}
                  >
                    {CODE_LANGUAGES.map((lang) => (
                      <option key={lang.value} value={lang.value}>
                        {lang.label}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="form-group" style={{ marginBottom: 0 }}>
                  <label className="form-label" style={{ fontSize: "0.8rem" }}>
                    VS Code Live Share (Optional)
                  </label>
                  <input
                    type="url"
                    value={vsCodeUrl}
                    onChange={(e) => setVsCodeUrl(e.target.value)}
                    placeholder="https://prod.liveshare.vsengine.io/..."
                    className="form-input"
                    style={{ width: "100%", padding: "8px 12px" }}
                  />
                </div>
              </div>
              <div
                className="form-group"
                style={{ marginTop: "10px", marginBottom: 0 }}
              >
                <textarea
                  value={codeSnippet}
                  onChange={(e) => setCodeSnippet(e.target.value)}
                  placeholder="// Paste your optional code snippet here..."
                  rows={4}
                  className="form-input code-textarea"
                />
              </div>
            </div>
          )}
        </>
      )}

      {/* 3. COURSE HELP SPECIFIC FORM */}
      {category === "Course Help" && (
        <>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1fr 1fr",
              gap: "12px",
            }}
          >
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Course Code & Name *</label>
              <input
                type="text"
                className="form-input"
                value={courseCode}
                onChange={(e) => setCourseCode(e.target.value)}
                placeholder="e.g., CSE 220 Data Structures"
                disabled={loading}
                required
              />
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Topic / Chapter *</label>
              <input
                type="text"
                className="form-input"
                value={courseTopic}
                onChange={(e) => setCourseTopic(e.target.value)}
                placeholder="e.g., AVL Tree Double Rotations"
                disabled={loading}
                required
              />
            </div>
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label className="form-label">
              Specific Doubt / Explanation Needed *
            </label>
            <textarea
              value={courseDoubt}
              onChange={(e) => setCourseDoubt(e.target.value)}
              placeholder="Explain what part of the theorem, lecture slide, or lab exercise is confusing..."
              rows={4}
              className="form-input"
              style={{
                width: "100%",
                padding: "10px 14px",
                borderRadius: "var(--radius-md)",
                resize: "vertical",
              }}
              disabled={loading}
              required
            />
          </div>
        </>
      )}

      {/* 4. EXAM PREP SPECIFIC FORM */}
      {category === "Exam Prep" && (
        <>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1.2fr 1fr",
              gap: "12px",
            }}
          >
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Course / Subject *</label>
              <input
                type="text"
                className="form-input"
                value={examCourse}
                onChange={(e) => setExamCourse(e.target.value)}
                placeholder="e.g., MAT 121 Linear Algebra"
                disabled={loading}
                required
              />
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Exam Type *</label>
              <select
                className="form-input"
                value={examType}
                onChange={(e) => setExamType(e.target.value)}
                style={{ width: "100%", padding: "10px 12px" }}
                disabled={loading}
              >
                {EXAM_TYPES.map((t) => (
                  <option key={t} value={t}>
                    {t}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label className="form-label">Key Topics Tested *</label>
            <input
              type="text"
              className="form-input"
              value={examTopics}
              onChange={(e) => setExamTopics(e.target.value)}
              placeholder="e.g., Eigenvalues, Orthogonal Projections, Gram-Schmidt"
              disabled={loading}
              required
            />
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label className="form-label">
              Exam Questions & Discussion Points *
            </label>
            <textarea
              value={examQuestions}
              onChange={(e) => setExamQuestions(e.target.value)}
              placeholder="Share high-yield exam practice questions, syllabus doubts, or review tips..."
              rows={4}
              className="form-input"
              style={{
                width: "100%",
                padding: "10px 14px",
                borderRadius: "var(--radius-md)",
                resize: "vertical",
              }}
              disabled={loading}
              required
            />
          </div>
        </>
      )}

      {/* 5. STUDY GROUP SPECIFIC FORM */}
      {category === "Study Group" && (
        <>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1.4fr 1fr",
              gap: "12px",
            }}
          >
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Study Group Goal / Course *</label>
              <input
                type="text"
                className="form-input"
                value={groupGoal}
                onChange={(e) => setGroupGoal(e.target.value)}
                placeholder="e.g., CSE 327 Final Project Sprint"
                disabled={loading}
                required
              />
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Target Capacity / Needed *</label>
              <input
                type="text"
                className="form-input"
                value={groupSize}
                onChange={(e) => setGroupSize(e.target.value)}
                placeholder="e.g., 2 Members Needed"
                disabled={loading}
                required
              />
            </div>
          </div>

          {/* Study Group Mode Selector: Offline vs Online */}
          <div className="form-group" style={{ marginBottom: 0 }}>
            <label className="form-label">Study Session Format *</label>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1fr 1fr",
                gap: "10px",
                marginBottom: "10px",
              }}
            >
              <button
                type="button"
                className={`category-selector-card ${
                  groupMode === "offline" ? "is-selected" : ""
                }`}
                style={{
                  justifyContent: "center",
                  padding: "10px 14px",
                  cursor: "pointer",
                }}
                onClick={() => setGroupMode("offline")}
              >
                <div
                  style={{ display: "flex", alignItems: "center", gap: "8px" }}
                >
                  <span style={{ fontSize: "1.1rem" }}>📍</span>
                  <div style={{ textAlign: "left" }}>
                    <div style={{ fontWeight: 600, fontSize: "0.85rem" }}>
                      In-Person (Offline)
                    </div>
                    <div
                      style={{
                        fontSize: "0.7rem",
                        color: "var(--color-text-muted)",
                      }}
                    >
                      Campus library, study room, or lab
                    </div>
                  </div>
                </div>
              </button>

              <button
                type="button"
                className={`category-selector-card ${
                  groupMode === "online" ? "is-selected" : ""
                }`}
                style={{
                  justifyContent: "center",
                  padding: "10px 14px",
                  cursor: "pointer",
                }}
                onClick={() => setGroupMode("online")}
              >
                <div
                  style={{ display: "flex", alignItems: "center", gap: "8px" }}
                >
                  <span style={{ fontSize: "1.1rem" }}>🌐</span>
                  <div style={{ textAlign: "left" }}>
                    <div style={{ fontWeight: 600, fontSize: "0.85rem" }}>
                      Virtual (Online)
                    </div>
                    <div
                      style={{
                        fontSize: "0.7rem",
                        color: "var(--color-text-muted)",
                      }}
                    >
                      Google Meet, Discord, Zoom
                    </div>
                  </div>
                </div>
              </button>
            </div>

            {/* Offline-specific options */}
            {groupMode === "offline" && (
              <div>
                <label
                  className="form-label"
                  style={{ fontSize: "0.8rem", marginBottom: "4px" }}
                >
                  Campus Location & Room *
                </label>
                <input
                  type="text"
                  className="form-input"
                  value={groupLocation}
                  onChange={(e) => setGroupLocation(e.target.value)}
                  placeholder="e.g., Campus Library 4th Floor Study Room A"
                  disabled={loading}
                  required
                />
                <div
                  style={{
                    display: "flex",
                    flexWrap: "wrap",
                    gap: "6px",
                    marginTop: "6px",
                  }}
                >
                  {[
                    "Library 4th Floor",
                    "Campus Study Room B",
                    "Cafeteria Discussion Zone",
                    "Department Lab 402",
                  ].map((preset) => (
                    <button
                      key={preset}
                      type="button"
                      onClick={() => setGroupLocation(preset)}
                      style={{
                        fontSize: "0.7rem",
                        padding: "3px 8px",
                        borderRadius: "12px",
                        border: "1px solid var(--color-border)",
                        background:
                          groupLocation === preset
                            ? "var(--color-primary-light)"
                            : "var(--color-bg-secondary)",
                        color:
                          groupLocation === preset
                            ? "var(--color-primary)"
                            : "var(--color-text-muted)",
                        cursor: "pointer",
                      }}
                    >
                      + {preset}
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* Online-specific options */}
            {groupMode === "online" && (
              <div
                style={{
                  display: "grid",
                  gridTemplateColumns: "1.2fr 1.8fr",
                  gap: "10px",
                }}
              >
                <div>
                  <label
                    className="form-label"
                    style={{ fontSize: "0.8rem", marginBottom: "4px" }}
                  >
                    Platform *
                  </label>
                  <select
                    className="form-input"
                    value={onlinePlatform}
                    onChange={(e) => setOnlinePlatform(e.target.value)}
                    style={{ width: "100%", padding: "8px 12px" }}
                    disabled={loading}
                  >
                    <option value="Google Meet">Google Meet</option>
                    <option value="Discord">Discord Voice / Stage</option>
                    <option value="Zoom">Zoom Meeting</option>
                    <option value="Microsoft Teams">Microsoft Teams</option>
                    <option value="Slack">Slack Huddle</option>
                    <option value="Other Virtual Room">
                      Other Virtual Room
                    </option>
                  </select>
                </div>
                <div>
                  <label
                    className="form-label"
                    style={{ fontSize: "0.8rem", marginBottom: "4px" }}
                  >
                    Meeting / Channel Link (Optional)
                  </label>
                  <input
                    type="url"
                    className="form-input"
                    value={onlineMeetingLink}
                    onChange={(e) => setOnlineMeetingLink(e.target.value)}
                    placeholder="https://meet.google.com/xyz-abcd-efg"
                    disabled={loading}
                  />
                </div>
              </div>
            )}
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label className="form-label">Weekly Schedule & Agenda *</label>
            <textarea
              value={groupSchedule}
              onChange={(e) => setGroupSchedule(e.target.value)}
              placeholder="e.g., Meeting every Tuesday and Friday from 5 PM to 7 PM to solve past assignments..."
              rows={3}
              className="form-input"
              style={{
                width: "100%",
                padding: "10px 14px",
                borderRadius: "var(--radius-md)",
                resize: "vertical",
              }}
              disabled={loading}
              required
            />
          </div>
        </>
      )}

      {/* 6. RESOURCES SPECIFIC FORM */}
      {category === "Resources" && (
        <>
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1.2fr 1fr",
              gap: "12px",
            }}
          >
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Resource Title *</label>
              <input
                type="text"
                className="form-input"
                value={resourceTitle}
                onChange={(e) => setResourceTitle(e.target.value)}
                placeholder="e.g., DBMS Normalization Hand-written Cheatsheet"
                disabled={loading}
                required
              />
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Course / Subject (Optional)</label>
              <input
                type="text"
                className="form-input"
                value={resourceCourse}
                onChange={(e) => setResourceCourse(e.target.value)}
                placeholder="e.g., CSE 311"
                disabled={loading}
              />
            </div>
          </div>

          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1fr 1fr",
              gap: "12px",
            }}
          >
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Resource Type *</label>
              <select
                className="form-input"
                value={resourceType}
                onChange={(e) => setResourceType(e.target.value)}
                style={{ width: "100%", padding: "10px 12px" }}
                disabled={loading}
              >
                {RESOURCE_TYPES.map((t) => (
                  <option key={t} value={t}>
                    {t}
                  </option>
                ))}
              </select>
            </div>
            <div className="form-group" style={{ marginBottom: 0 }}>
              <label className="form-label">Resource Link / Download URL</label>
              <input
                type="url"
                className="form-input"
                value={resourceLink}
                onChange={(e) => setResourceLink(e.target.value)}
                placeholder="https://drive.google.com/... or https://github.com/..."
                disabled={loading}
              />
            </div>
          </div>

          <div className="form-group" style={{ marginBottom: 0 }}>
            <label className="form-label">
              Resource Overview & Topics Covered *
            </label>
            <textarea
              value={resourceOverview}
              onChange={(e) => setResourceOverview(e.target.value)}
              placeholder="Brief description of what is included, who will benefit, and tips for studying it..."
              rows={3}
              className="form-input"
              style={{
                width: "100%",
                padding: "10px 14px",
                borderRadius: "var(--radius-md)",
                resize: "vertical",
              }}
              disabled={loading}
              required
            />
          </div>
        </>
      )}

      {/* Bottom Submit Action */}
      <div
        className="form-actions-row"
        style={{
          marginTop: "6px",
          display: "flex",
          justifyContent: "flex-end",
          gap: "10px",
        }}
      >
        <Button
          type="button"
          variant="secondary"
          onClick={onCancel}
          disabled={loading}
        >
          Cancel
        </Button>
        <Button type="submit" variant="primary" loading={loading}>
          {loading ? "Publishing..." : `🚀 Publish ${category} Post`}
        </Button>
      </div>
    </form>
  );
}
