import { useState, useEffect } from "react";
import {
  Bookmark,
  BookOpen,
  Calendar,
  Check,
  CheckCircle2,
  ChevronDown,
  ChevronUp,
  Clock,
  Code2,
  Copy,
  Edit3,
  ExternalLink,
  FileText,
  HelpCircle,
  Laptop,
  MapPin,
  MessageSquare,
  MoreHorizontal,
  Send,
  Share2,
  Sparkles,
  ThumbsUp,
  Trash2,
  Users,
  Video,
  Wifi,
  X,
  Zap,
} from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";
import Badge from "../../../components/Badge";
import Button from "../../../components/Button";
import Card from "../../../components/Card";
import Spinner from "../../../components/Spinner";
import { formatRichContent } from "../../../lib/markdownHelper";
import ScholarAvatar from "../../auth/components/ScholarAvatar";
import { useAuth } from "../../auth/useAuth";
import {
  createComment,
  deleteComment,
  deletePost,
  extractCommunityErrorMessage,
  getComments,
  markCommentHelpful,
  togglePostReaction,
  updatePost,
} from "../api";

const CATEGORY_CONFIG = {
  "Code Help": {
    icon: Code2,
    variant: "primary",
    label: "Code Help",
    accentColor: "#6366f1",
    themeClass: "post-theme-code",
    gradient: "linear-gradient(90deg, #6366f1, #8b5cf6)",
  },
  "Exam Prep": {
    icon: Zap,
    variant: "accent",
    label: "Exam Prep",
    accentColor: "#f59e0b",
    themeClass: "post-theme-exam",
    gradient: "linear-gradient(90deg, #f59e0b, #ef4444)",
  },
  "Course Help": {
    icon: HelpCircle,
    variant: "primary",
    label: "Course Help",
    accentColor: "#0ea5e9",
    themeClass: "post-theme-course",
    gradient: "linear-gradient(90deg, #0ea5e9, #3b82f6)",
  },
  "Study Group": {
    icon: Users,
    variant: "success",
    label: "Study Group",
    accentColor: "#10b981",
    themeClass: "post-theme-study",
    gradient: "linear-gradient(90deg, #10b981, #06b6d4)",
  },
  Resources: {
    icon: FileText,
    variant: "default",
    label: "Resources",
    accentColor: "#8b5cf6",
    themeClass: "post-theme-resource",
    gradient: "linear-gradient(90deg, #8b5cf6, #ec4899)",
  },
  General: {
    icon: MessageSquare,
    variant: "default",
    label: "General Discussion",
    accentColor: "#64748b",
    themeClass: "post-theme-general",
    gradient: "linear-gradient(90deg, #64748b, #94a3b8)",
  },
};

function parseStructuredPost(category, content = "") {
  if (!content) return { isStructured: false };

  if (category === "Study Group") {
    const formatMatch = content.match(/\*\*Format\*\*:\s*([^\n]+)/i);
    const purposeMatch = content.match(
      /\*\*Group Purpose \/ Course\*\*:\s*([^\n]+)/i,
    );
    const platformMatch = content.match(/\*\*Platform\*\*:\s*([^\n]+)/i);
    const locationMatch = content.match(
      /\*\*Campus Location \/ Room\*\*:\s*([^\n]+)/i,
    );
    const linkMatch = content.match(
      /\[(?:Join Online Session|Meeting Link|Join Session)\]\(([^)]+)\)/i,
    );
    const capacityMatch = content.match(/\*\*Target Capacity\*\*:\s*([^\n]+)/i);
    const scheduleParts = content.split(/### Schedule & Roadmap:\s*/i);
    const schedule = scheduleParts.length > 1 ? scheduleParts[1].trim() : "";

    if (formatMatch || purposeMatch || schedule) {
      const formatStr = formatMatch ? formatMatch[1].trim() : "";
      const isOnline =
        formatStr.toLowerCase().includes("online") ||
        Boolean(platformMatch) ||
        Boolean(linkMatch);

      return {
        isStructured: true,
        type: "study-group",
        isOnline,
        format:
          formatStr ||
          (isOnline ? "Online Virtual Session" : "In-Person (Offline Campus)"),
        purpose: purposeMatch ? purposeMatch[1].trim() : "",
        platform: platformMatch ? platformMatch[1].trim() : "",
        location: locationMatch ? locationMatch[1].trim() : "",
        meetingLink: linkMatch ? linkMatch[1].trim() : "",
        capacity: capacityMatch ? capacityMatch[1].trim() : "",
        schedule,
      };
    }
  }

  if (category === "Course Help") {
    const courseMatch = content.match(/\*\*Course\*\*:\s*([^\n]+)/i);
    const topicMatch = content.match(/\*\*Topic \/ Chapter\*\*:\s*([^\n]+)/i);
    const doubtParts = content.split(/### Question & Problem Details:\s*/i);
    const doubt = doubtParts.length > 1 ? doubtParts[1].trim() : "";

    if (courseMatch || topicMatch || doubt) {
      return {
        isStructured: true,
        type: "course-help",
        course: courseMatch ? courseMatch[1].trim() : "",
        topic: topicMatch ? topicMatch[1].trim() : "",
        doubt: doubt || content,
      };
    }
  }

  if (category === "Exam Prep") {
    const courseMatch = content.match(/\*\*Course \/ Subject\*\*:\s*([^\n]+)/i);
    const examMatch = content.match(/\*\*Target Exam\*\*:\s*([^\n]+)/i);
    const topicsMatch = content.match(/\*\*Key Focus Topics\*\*:\s*([^\n]+)/i);
    const questionParts = content.split(
      /### Exam Prep Discussion & Questions:\s*/i,
    );
    const questions = questionParts.length > 1 ? questionParts[1].trim() : "";

    if (courseMatch || examMatch || questions) {
      return {
        isStructured: true,
        type: "exam-prep",
        course: courseMatch ? courseMatch[1].trim() : "",
        examType: examMatch ? examMatch[1].trim() : "",
        topics: topicsMatch ? topicsMatch[1].trim() : "",
        questions: questions || content,
      };
    }
  }

  if (category === "Resources") {
    const nameMatch = content.match(/\*\*Resource Name\*\*:\s*([^\n]+)/i);
    const courseMatch = content.match(/\*\*Course \/ Subject\*\*:\s*([^\n]+)/i);
    const typeMatch = content.match(/\*\*Resource Type\*\*:\s*([^\n]+)/i);
    const linkMatch = content.match(/\[Access Resource\]\(([^)]+)\)/i);
    const overviewParts = content.split(/### Overview & Contents:\s*/i);
    const overview = overviewParts.length > 1 ? overviewParts[1].trim() : "";

    if (nameMatch || typeMatch || overview) {
      return {
        isStructured: true,
        type: "resource",
        name: nameMatch ? nameMatch[1].trim() : "",
        course: courseMatch ? courseMatch[1].trim() : "",
        resourceType: typeMatch ? typeMatch[1].trim() : "Reference",
        link: linkMatch ? linkMatch[1].trim() : "",
        overview: overview || content,
      };
    }
  }

  return { isStructured: false };
}

function renderThemedContent(post) {
  const structured = parseStructuredPost(post.category, post.content);

  if (structured.isStructured && structured.type === "study-group") {
    const rawLink = structured.meetingLink;
    const cleanUrl = rawLink
      ? rawLink.startsWith("http")
        ? rawLink
        : `https://${rawLink}`
      : null;

    return (
      <div className="themed-post-container theme-study-group-body">
        {/* Meta Badge Ribbon */}
        <div className="study-ribbon-bar">
          <div className="study-ribbon-left">
            {structured.isOnline ? (
              <span className="live-status-pill online-pill">
                <span className="live-pulse-dot" />
                <Wifi size={12} />
                <span>Online Session</span>
              </span>
            ) : (
              <span className="live-status-pill offline-pill">
                <MapPin size={12} />
                <span>In-Person Campus</span>
              </span>
            )}

            {structured.platform && (
              <span className="study-tag-chip">
                <Laptop size={12} />
                <span>{structured.platform}</span>
              </span>
            )}

            {structured.location && (
              <span className="study-tag-chip location-chip">
                <MapPin size={12} />
                <span>{structured.location}</span>
              </span>
            )}
          </div>

          {structured.capacity && (
            <span className="capacity-tag-chip">
              <Users size={12} />
              <span>{structured.capacity}</span>
            </span>
          )}
        </div>

        {/* Live Meeting Join Card (if meeting link present) */}
        {cleanUrl && (
          <motion.div
            whileHover={{ scale: 1.01 }}
            className="study-meeting-action-banner"
          >
            <div className="meeting-banner-info">
              <div className="meeting-icon-bubble">
                <Video size={16} />
              </div>
              <div className="meeting-banner-text">
                <strong className="meeting-banner-title">
                  Virtual Study Room Ready
                </strong>
                <span className="meeting-banner-sub">
                  Platform: {structured.platform || "Online Video Conference"}
                </span>
              </div>
            </div>
            <a
              href={cleanUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="meeting-direct-join-btn"
            >
              <ExternalLink size={13} />
              <span>Join Online Room</span>
            </a>
          </motion.div>
        )}

        {/* Goal / Purpose */}
        {structured.purpose && (
          <div className="study-purpose-box">
            <span className="study-field-label">Group Focus / Course:</span>
            <span className="study-field-value">{structured.purpose}</span>
          </div>
        )}

        {/* Schedule & Roadmap */}
        {structured.schedule && (
          <div className="study-schedule-card">
            <div className="study-schedule-header">
              <Calendar size={14} className="text-emerald" />
              <strong>Schedule & Session Roadmap</strong>
            </div>
            <div className="study-schedule-body">
              {formatRichContent(structured.schedule)}
            </div>
          </div>
        )}
      </div>
    );
  }

  if (structured.isStructured && structured.type === "course-help") {
    return (
      <div className="themed-post-container theme-course-help-body">
        <div className="course-help-ribbon">
          {structured.course && (
            <span className="course-code-badge">
              <BookOpen size={12} />
              <span>{structured.course}</span>
            </span>
          )}
          {structured.topic && (
            <span className="course-topic-badge">
              <span>Topic: {structured.topic}</span>
            </span>
          )}
        </div>

        {structured.doubt && (
          <div className="course-doubt-box">
            <div className="course-doubt-header">
              <HelpCircle size={14} className="text-sky" />
              <strong>Question & Problem Details</strong>
            </div>
            <div className="course-doubt-content">
              {formatRichContent(structured.doubt)}
            </div>
          </div>
        )}
      </div>
    );
  }

  if (structured.isStructured && structured.type === "exam-prep") {
    const topicList = structured.topics
      ? structured.topics
          .split(/[,;\n]+/)
          .map((t) => t.trim())
          .filter(Boolean)
      : [];

    return (
      <div className="themed-post-container theme-exam-prep-body">
        <div className="exam-ribbon-bar">
          {structured.examType && (
            <span className="exam-target-badge">
              <Zap size={12} />
              <span>{structured.examType}</span>
            </span>
          )}
          {structured.course && (
            <span className="exam-course-badge">
              <BookOpen size={12} />
              <span>{structured.course}</span>
            </span>
          )}
        </div>

        {topicList.length > 0 && (
          <div className="exam-topics-container">
            <span className="exam-topics-label">Focus Topics:</span>
            <div className="exam-topics-chips">
              {topicList.map((t, i) => (
                <span key={i} className="exam-topic-chip">
                  #{t}
                </span>
              ))}
            </div>
          </div>
        )}

        {structured.questions && (
          <div className="exam-questions-box">
            <div className="exam-questions-header">
              <FileText size={14} className="text-amber" />
              <strong>Exam Prep Inquiries & Discussion</strong>
            </div>
            <div className="exam-questions-content">
              {formatRichContent(structured.questions)}
            </div>
          </div>
        )}
      </div>
    );
  }

  if (structured.isStructured && structured.type === "resource") {
    const rawLink = structured.link;
    const cleanUrl = rawLink
      ? rawLink.startsWith("http")
        ? rawLink
        : `https://${rawLink}`
      : null;

    return (
      <div className="themed-post-container theme-resource-body">
        <div className="resource-ribbon-bar">
          <span className="resource-type-badge">
            <FileText size={12} />
            <span>{structured.resourceType}</span>
          </span>
          {structured.course && (
            <span className="resource-course-badge">
              <BookOpen size={12} />
              <span>{structured.course}</span>
            </span>
          )}
        </div>

        {cleanUrl && (
          <motion.a
            whileHover={{ scale: 1.01 }}
            href={cleanUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="resource-access-banner"
          >
            <div className="resource-access-info">
              <ExternalLink size={16} />
              <div>
                <strong>Access Study Material</strong>
                <span>Open external resource link</span>
              </div>
            </div>
            <span className="resource-open-pill">
              <span>Open Link</span>
              <ExternalLink size={12} />
            </span>
          </motion.a>
        )}

        {structured.overview && (
          <div className="resource-overview-box">
            <div className="resource-overview-header">
              <Sparkles size={13} className="text-purple" />
              <strong>Overview & Contents</strong>
            </div>
            <div className="resource-overview-content">
              {formatRichContent(structured.overview)}
            </div>
          </div>
        )}
      </div>
    );
  }

  // Fallback for standard or General posts
  return (
    <div className="social-post-markdown-content">
      {formatRichContent(post.content)}
    </div>
  );
}

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
  { value: "plaintext", label: "Other" },
];

function formatSafeDate(val) {
  if (!val) return "Recently";
  const d = new Date(val);
  return isNaN(d.getTime())
    ? "Recently"
    : d.toLocaleDateString(undefined, {
        month: "short",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });
}

// The null check lives in this wrapper so every hook in PostCardContent
// runs on every render (hooks after an early return break React's hook order).
export default function PostCard(props) {
  if (!props.post) return null;
  return <PostCardContent {...props} />;
}

function PostCardContent({ post, onDeleted, onUpdated }) {
  const { user } = useAuth();
  const [currentPost, setCurrentPost] = useState(post);

  useEffect(() => {
    if (!post) return;
    setCurrentPost(post);
    setIsPostSolved(Boolean(post.is_solved));
    setLikesCount(post.likes_count || 0);
    setIsLiked(Boolean(post.is_liked || post.has_reacted));
    setCommentsCount(post.comments_count || 0);
  }, [post]);

  const [likesCount, setLikesCount] = useState(post?.likes_count || 0);
  const [isLiked, setIsLiked] = useState(
    Boolean(post?.is_liked || post?.has_reacted),
  );
  const [likeLoading, setLikeLoading] = useState(false);
  const bookmarkStorageKey = `student_brain_bookmarks_${user?.id || "global"}`;
  const [isBookmarked, setIsBookmarked] = useState(() => {
    try {
      const saved = JSON.parse(
        localStorage.getItem(bookmarkStorageKey) || "[]",
      );
      return Array.isArray(saved) && post?.id ? saved.includes(post.id) : false;
    } catch {
      return false;
    }
  });

  function handleToggleBookmark() {
    setIsBookmarked((prev) => {
      const next = !prev;
      try {
        const saved = JSON.parse(
          localStorage.getItem(bookmarkStorageKey) || "[]",
        );
        let updated = Array.isArray(saved) ? saved : [];
        if (next) {
          if (!updated.includes(currentPost.id)) updated.push(currentPost.id);
        } else {
          updated = updated.filter((id) => id !== currentPost.id);
        }
        localStorage.setItem(bookmarkStorageKey, JSON.stringify(updated));
      } catch (e) {
        console.error("Bookmark storage error:", e);
      }
      return next;
    });
  }

  const [copiedLink, setCopiedLink] = useState(false);
  const [copiedCode, setCopiedCode] = useState(false);
  const [copiedCommentCodeId, setCopiedCommentCodeId] = useState(null);
  const [showMenu, setShowMenu] = useState(false);

  // Solved state
  const [isPostSolved, setIsPostSolved] = useState(Boolean(post.is_solved));
  const [solvedCommentId, setSolvedCommentId] = useState(
    post.solved_comment || null,
  );

  // Edit state
  const [isEditing, setIsEditing] = useState(false);
  const [editTitle, setEditTitle] = useState(post.title || "");
  const [editContent, setEditContent] = useState(post.content || "");
  const [editCategory, setEditCategory] = useState(post.category || "General");
  const [editHasCode, setEditHasCode] = useState(Boolean(post.code_snippet));
  const [editCodeSnippet, setEditCodeSnippet] = useState(
    post.code_snippet || "",
  );
  const [editCodeLanguage, setEditCodeLanguage] = useState(
    post.code_language || "python",
  );
  const [editLiveShareUrl, setEditLiveShareUrl] = useState(
    post.vscode_liveshare_url || "",
  );
  const [editSubmitting, setEditSubmitting] = useState(false);
  const [editError, setEditError] = useState("");

  // Comments state
  const [showComments, setShowComments] = useState(false);
  const [comments, setComments] = useState([]);
  const [commentsCount, setCommentsCount] = useState(post.comments_count || 0);
  const [commentsLoading, setCommentsLoading] = useState(false);
  const [newComment, setNewComment] = useState("");
  const [commentSubmitting, setCommentSubmitting] = useState(false);
  const [commentError, setCommentError] = useState("");

  // Code solution in comment
  const [isSolutionMode, setIsSolutionMode] = useState(false);
  const [solutionCode, setSolutionCode] = useState("");
  const [solutionLang, setSolutionLang] = useState(
    post.code_language || "python",
  );

  const isAuthor = user?.id === currentPost.author?.id;

  async function handleToggleReaction() {
    if (likeLoading) return;
    setLikeLoading(true);
    try {
      const res = await togglePostReaction(currentPost.id);
      setIsLiked(res.liked ?? res.has_reacted ?? !isLiked);
      setLikesCount(
        res.likes_count ??
          res.reactions_count ??
          (isLiked ? likesCount - 1 : likesCount + 1),
      );
    } catch (err) {
      console.error("Error toggling upvote:", err);
    } finally {
      setLikeLoading(false);
    }
  }

  async function handleToggleComments() {
    if (!showComments && comments.length === 0) {
      setCommentsLoading(true);
      try {
        const data = await getComments(currentPost.id);
        setComments(data);
      } catch (err) {
        console.error("Error fetching comments:", err);
      } finally {
        setCommentsLoading(false);
      }
    }
    setShowComments((prev) => !prev);
  }

  async function handleAddComment(e) {
    e.preventDefault();
    if (!newComment.trim() && !solutionCode.trim()) return;

    setCommentSubmitting(true);
    setCommentError("");
    try {
      const payload = {
        content:
          newComment.trim() || (solutionCode.trim() ? "Code solution:" : ""),
      };
      if (isSolutionMode && solutionCode.trim()) {
        payload.code_solution = solutionCode.trim();
        payload.code_language = solutionLang;
      }

      const created = await createComment(currentPost.id, payload);
      setComments((prev) => [...prev, created]);
      setCommentsCount((prev) => prev + 1);
      setNewComment("");
      setSolutionCode("");
      setIsSolutionMode(false);
    } catch (err) {
      setCommentError(extractCommunityErrorMessage(err));
    } finally {
      setCommentSubmitting(false);
    }
  }

  async function handleMarkHelpful(commentId) {
    try {
      const res = await markCommentHelpful(commentId);
      setIsPostSolved(Boolean(res.is_solved));
      setSolvedCommentId(res.is_helpful ? commentId : null);
      setComments((prev) =>
        prev.map((c) => ({
          ...c,
          is_helpful: c.id === commentId ? res.is_helpful : false,
        })),
      );
    } catch (err) {
      console.error("Failed to mark comment as helpful:", err);
    }
  }

  function handleCopyCode(code) {
    if (!code) return;
    navigator.clipboard.writeText(code);
    setCopiedCode(true);
    setTimeout(() => setCopiedCode(false), 2000);
  }

  function handleCopyCommentCode(commentId, code) {
    if (!code) return;
    navigator.clipboard.writeText(code);
    setCopiedCommentCodeId(commentId);
    setTimeout(() => setCopiedCommentCodeId(null), 2000);
  }

  async function handleDeleteComment(commentId) {
    try {
      await deleteComment(commentId);
      setComments((prev) => prev.filter((c) => c.id !== commentId));
      setCommentsCount((prev) => Math.max(0, prev - 1));
      if (solvedCommentId === commentId) {
        setIsPostSolved(false);
        setSolvedCommentId(null);
      }
    } catch (err) {
      console.error("Error deleting reply:", err);
    }
  }

  async function handleDeletePost() {
    if (!window.confirm("Remove this discussion thread from the community?")) {
      return;
    }
    try {
      await deletePost(currentPost.id);
      if (onDeleted) {
        onDeleted(currentPost.id);
      }
    } catch (err) {
      console.error("Error deleting post:", err);
    }
  }

  async function handleSharePost() {
    setShowMenu(false);
    const postUrl = `${window.location.origin}/community#post-${currentPost.id}`;
    const shareTitle = currentPost.title || "Student Brain Community Post";
    const shareSnippet = currentPost.content
      ? currentPost.content
          .replace(/[#*`_]/g, "")
          .slice(0, 140)
          .trim()
      : "Check out this discussion on Student Brain!";

    // Direct Native Web Share (opens native Windows Share Sheet / mobile sheet)
    if (
      typeof navigator !== "undefined" &&
      typeof navigator.share === "function"
    ) {
      try {
        await navigator.share({
          title: shareTitle,
          text: `${shareTitle} • ${shareSnippet}`,
          url: postUrl,
        });
        return;
      } catch (err) {
        if (err.name !== "AbortError") {
          console.warn("Native share error, falling back to clipboard:", err);
        } else {
          return;
        }
      }
    }

    // Fallback: Copy link with feedback toast
    try {
      await navigator.clipboard.writeText(postUrl);
      setCopiedLink(true);
      setTimeout(() => setCopiedLink(false), 2200);
    } catch (err) {
      console.error("Failed to copy link:", err);
    }
  }

  function handleCopyPostLink() {
    return handleSharePost();
  }

  async function handleToggleSolved() {
    setShowMenu(false);
    try {
      const nextSolved = !isPostSolved;
      const res = await updatePost(currentPost.id, { is_solved: nextSolved });
      setIsPostSolved(nextSolved);
      setCurrentPost((prev) => ({ ...prev, is_solved: nextSolved }));
      if (onUpdated) onUpdated(res);
    } catch (err) {
      console.error("Failed to update solved status:", err);
    }
  }

  async function handleSaveEdit(e) {
    if (e) e.preventDefault();
    if (!editContent.trim()) {
      setEditError("Post content cannot be empty.");
      return;
    }
    setEditSubmitting(true);
    setEditError("");
    try {
      const payload = {
        title: editTitle.trim(),
        content: editContent.trim(),
        category: editCategory,
        code_snippet: editHasCode ? editCodeSnippet : "",
        code_language: editHasCode ? editCodeLanguage : "plaintext",
        vscode_liveshare_url: editLiveShareUrl.trim(),
      };
      const updated = await updatePost(currentPost.id, payload);
      setCurrentPost(updated);
      setIsEditing(false);
      if (onUpdated) onUpdated(updated);
    } catch (err) {
      setEditError(extractCommunityErrorMessage(err));
    } finally {
      setEditSubmitting(false);
    }
  }

  function handleCancelEdit() {
    setEditTitle(currentPost.title || "");
    setEditContent(currentPost.content || "");
    setEditCategory(currentPost.category || "General");
    setEditHasCode(Boolean(currentPost.code_snippet));
    setEditCodeSnippet(currentPost.code_snippet || "");
    setEditCodeLanguage(currentPost.code_language || "python");
    setEditLiveShareUrl(currentPost.vscode_liveshare_url || "");
    setEditError("");
    setIsEditing(false);
  }

  const formattedDate = formatSafeDate(currentPost?.created_at);

  const catConfig = CATEGORY_CONFIG[currentPost.category] || {
    icon: MessageSquare,
    variant: "default",
    label: currentPost.category || "Discussion",
  };
  const CatIcon = catConfig.icon;

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={{ y: -3 }}
      transition={{ duration: 0.22, ease: "easeOut" }}
      style={{ marginBottom: "20px" }}
      id={`post-${currentPost.id}`}
    >
      <Card
        className={`premium-social-post-card ${catConfig.themeClass || ""}`}
      >
        {/* Animated Top Category Accent Ribbon */}
        <div
          className="social-card-accent-bar"
          style={{ background: catConfig.gradient }}
        />

        {/* Top Header Row */}
        <div className="social-post-header">
          <div className="social-post-author-row">
            <div className="author-avatar-container">
              <ScholarAvatar user={currentPost.author} size={48} />
              <div className="author-online-indicator" />
            </div>

            <div className="author-text-meta">
              <div className="author-name-line">
                <strong className="author-name">
                  {currentPost.author?.full_name ||
                    currentPost.author?.email?.split("@")[0] ||
                    "Scholar"}
                </strong>
                <span
                  className="scholar-verified-badge"
                  title="Verified University Scholar"
                >
                  ✓
                </span>
                {currentPost.author?.department && (
                  <span className="author-dept-chip">
                    {currentPost.author.department}
                  </span>
                )}
              </div>

              <div className="author-sub-line">
                <Clock size={12} className="text-muted" />
                <span>{formattedDate}</span>
              </div>
            </div>
          </div>

          {/* Right Header Actions */}
          <div className="social-header-right">
            {isPostSolved && (
              <span className="solved-status-badge">
                <CheckCircle2 size={13} />
                <span>Solved</span>
              </span>
            )}

            <Badge variant={catConfig.variant} size="sm">
              <CatIcon size={12} />
              <span>{catConfig.label}</span>
            </Badge>

            <div style={{ position: "relative" }}>
              <button
                type="button"
                className="social-options-btn"
                onClick={() => setShowMenu(!showMenu)}
                title="Options"
              >
                <MoreHorizontal size={16} />
              </button>

              {showMenu && (
                <div className="social-options-dropdown">
                  <button
                    type="button"
                    className="dropdown-item-btn"
                    onClick={handleSharePost}
                  >
                    {copiedLink ? (
                      <Check size={14} className="text-emerald" />
                    ) : (
                      <Share2 size={14} />
                    )}
                    <span>{copiedLink ? "Link Copied" : "Share (Native)"}</span>
                  </button>

                  <button
                    type="button"
                    className="dropdown-item-btn"
                    onClick={() => {
                      handleToggleBookmark();
                      setShowMenu(false);
                    }}
                  >
                    <Bookmark
                      size={14}
                      fill={isBookmarked ? "currentColor" : "none"}
                      strokeWidth={isBookmarked ? 2.8 : 2}
                      className={isBookmarked ? "text-amber" : ""}
                    />
                    <span>{isBookmarked ? "Bookmarked" : "Bookmark"}</span>
                  </button>

                  {isAuthor && (
                    <>
                      <button
                        type="button"
                        className="dropdown-item-btn"
                        onClick={handleToggleSolved}
                      >
                        <CheckCircle2
                          size={14}
                          className={isPostSolved ? "text-emerald" : ""}
                        />
                        <span>
                          {isPostSolved ? "Mark as Unsolved" : "Mark as Solved"}
                        </span>
                      </button>

                      <button
                        type="button"
                        className="dropdown-item-btn"
                        onClick={() => {
                          setIsEditing(true);
                          setShowMenu(false);
                        }}
                      >
                        <Edit3 size={14} />
                        <span>Edit Post</span>
                      </button>

                      <button
                        type="button"
                        className="dropdown-item-btn text-danger"
                        onClick={handleDeletePost}
                      >
                        <Trash2 size={14} />
                        <span>Delete Discussion</span>
                      </button>
                    </>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Middle Content or Inline Edit Form */}
        {isEditing ? (
          <form onSubmit={handleSaveEdit} className="post-inline-edit-form">
            {editError && (
              <div
                className="form-error-banner"
                style={{ marginBottom: "12px" }}
              >
                {editError}
              </div>
            )}

            <div className="inline-edit-row">
              <div className="inline-edit-field" style={{ flex: 1 }}>
                <label className="inline-edit-label">Title (Optional)</label>
                <input
                  type="text"
                  value={editTitle}
                  onChange={(e) => setEditTitle(e.target.value)}
                  placeholder="Thread title / Question..."
                  className="form-input-control"
                />
              </div>

              <div className="inline-edit-field" style={{ width: "160px" }}>
                <label className="inline-edit-label">Category</label>
                <select
                  value={editCategory}
                  onChange={(e) => setEditCategory(e.target.value)}
                  className="form-input-control"
                >
                  <option value="General">General</option>
                  <option value="Code Help">Code Help</option>
                  <option value="Exam Prep">Exam Prep</option>
                  <option value="Course Help">Course Help</option>
                  <option value="Study Group">Study Group</option>
                  <option value="Resources">Resources</option>
                </select>
              </div>
            </div>

            <div className="inline-edit-field">
              <label className="inline-edit-label">Discussion Content</label>
              <textarea
                rows={4}
                value={editContent}
                onChange={(e) => setEditContent(e.target.value)}
                placeholder="What would you like to discuss or ask?"
                className="form-input-control"
                required
              />
            </div>

            {/* Code Snippet & Live Share Controls */}
            <div className="inline-edit-field">
              <div className="inline-checkbox-label">
                <label
                  style={{
                    display: "inline-flex",
                    alignItems: "center",
                    gap: "6px",
                    cursor: "pointer",
                    fontSize: "0.8125rem",
                    fontWeight: 600,
                  }}
                >
                  <input
                    type="checkbox"
                    checked={editHasCode}
                    onChange={(e) => setEditHasCode(e.target.checked)}
                  />
                  <span>Attach Code Snippet</span>
                </label>
              </div>

              {editHasCode && (
                <div className="inline-code-editor-wrap">
                  <div style={{ marginBottom: "6px" }}>
                    <select
                      value={editCodeLanguage}
                      onChange={(e) => setEditCodeLanguage(e.target.value)}
                      className="form-input-control"
                      style={{
                        width: "auto",
                        display: "inline-block",
                        fontSize: "0.78rem",
                        padding: "4px 8px",
                      }}
                    >
                      {CODE_LANGUAGES.map((lang) => (
                        <option key={lang.value} value={lang.value}>
                          {lang.label}
                        </option>
                      ))}
                    </select>
                  </div>
                  <textarea
                    rows={5}
                    value={editCodeSnippet}
                    onChange={(e) => setEditCodeSnippet(e.target.value)}
                    placeholder="Paste code snippet here..."
                    className="form-input-control code-editor-input"
                  />
                </div>
              )}
            </div>

            <div className="inline-edit-field">
              <label className="inline-edit-label">
                VS Code Live Share Link (Optional)
              </label>
              <input
                type="url"
                value={editLiveShareUrl}
                onChange={(e) => setEditLiveShareUrl(e.target.value)}
                placeholder="https://prod.liveshare.vsengsaas.visualstudio.com/join?..."
                className="form-input-control"
              />
            </div>

            <div className="inline-edit-actions">
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={handleCancelEdit}
                disabled={editSubmitting}
              >
                Cancel
              </Button>
              <Button
                type="submit"
                variant="primary"
                size="sm"
                disabled={editSubmitting}
              >
                {editSubmitting ? "Saving..." : "Save Changes"}
              </Button>
            </div>
          </form>
        ) : (
          <div className="social-post-body">
            {currentPost.title && (
              <h3 className="social-post-title">{currentPost.title}</h3>
            )}

            {/* Specialized Category Themed Body & Rich Content */}
            {renderThemedContent(currentPost)}

            {/* VS Code Live Share Banner */}
            {currentPost.vscode_liveshare_url && (
              <div className="vscode-liveshare-banner">
                <div className="liveshare-info">
                  <div className="liveshare-pulse-container">
                    <span className="liveshare-pulse-dot" />
                    <strong className="liveshare-title">
                      VS Code Live Share Collaboration
                    </strong>
                  </div>
                  <span className="liveshare-subtitle">
                    Click to join this live peer programming session directly in
                    VS Code
                  </span>
                </div>
                <a
                  href={currentPost.vscode_liveshare_url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="liveshare-join-btn"
                >
                  <ExternalLink size={14} />
                  <span>Join in VS Code</span>
                </a>
              </div>
            )}

            {/* Code Snippet Box */}
            {currentPost.code_snippet && (
              <div className="code-snippet-box">
                <div className="code-snippet-header">
                  <div className="code-header-left">
                    <Code2 size={14} className="text-indigo" />
                    <span className="code-lang-tag">
                      {currentPost.code_language || "CODE"}
                    </span>
                    <span className="code-line-counter">
                      {currentPost.code_snippet.split("\n").length} lines
                    </span>
                  </div>
                  <button
                    type="button"
                    className="code-copy-btn"
                    onClick={() => handleCopyCode(currentPost.code_snippet)}
                    title="Copy code snippet"
                  >
                    {copiedCode ? (
                      <Check size={13} className="text-emerald" />
                    ) : (
                      <Copy size={13} />
                    )}
                    <span>{copiedCode ? "Copied" : "Copy Code"}</span>
                  </button>
                </div>
                <pre className="code-snippet-pre">
                  <code>{currentPost.code_snippet}</code>
                </pre>
              </div>
            )}
          </div>
        )}

        {/* Bottom Interactive Action Bar - Responsive For All Devices */}
        <div className="social-post-footer">
          <div className="social-action-buttons">
            <motion.button
              type="button"
              whileTap={{ scale: 0.9 }}
              className={`social-action-pill ${isLiked ? "pill-upvoted" : ""}`}
              onClick={handleToggleReaction}
              disabled={likeLoading}
            >
              <motion.div
                animate={isLiked ? { scale: [1, 1.35, 1] } : { scale: 1 }}
                transition={{ duration: 0.2 }}
              >
                <ThumbsUp
                  size={15}
                  className={isLiked ? "text-primary fill-primary" : ""}
                />
              </motion.div>
              <span className="desktop-action-label">
                {isLiked ? "Upvoted" : "Upvote"}
              </span>
              <span className="pill-count-badge">{likesCount}</span>
            </motion.button>

            <motion.button
              type="button"
              whileTap={{ scale: 0.92 }}
              className={`social-action-pill ${showComments ? "pill-active-drawer" : ""}`}
              onClick={handleToggleComments}
            >
              <MessageSquare size={15} />
              <span className="desktop-action-label">
                Discussion & Solutions
              </span>
              <span className="mobile-action-label">Solutions</span>
              <span className="pill-count-badge">{commentsCount}</span>
              {showComments ? (
                <ChevronUp size={13} />
              ) : (
                <ChevronDown size={13} />
              )}
            </motion.button>

            <button
              type="button"
              className="social-action-pill social-share-btn"
              onClick={handleSharePost}
              title="Native Share"
            >
              {copiedLink ? (
                <Check size={14} className="text-emerald" />
              ) : (
                <Share2 size={14} />
              )}
              <span className="desktop-action-label">
                {copiedLink ? "Copied" : "Share"}
              </span>
            </button>

            <button
              type="button"
              className={`social-action-pill social-bookmark-btn ${isBookmarked ? "pill-bookmarked" : ""}`}
              onClick={handleToggleBookmark}
              title={isBookmarked ? "Remove Bookmark" : "Save Bookmark"}
            >
              <Bookmark
                size={15}
                fill={isBookmarked ? "currentColor" : "none"}
                strokeWidth={isBookmarked ? 2.8 : 2}
                className={isBookmarked ? "text-amber" : ""}
              />
              <span className="desktop-action-label">
                {isBookmarked ? "Bookmarked" : "Bookmark"}
              </span>
            </button>
          </div>
        </div>

        {/* Expandable Threaded Discussion Drawer */}
        <AnimatePresence>
          {showComments && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: "auto" }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.22, ease: "easeOut" }}
              className="threaded-comments-drawer"
            >
              {/* Reply / Solution Mode Bar */}
              <div className="reply-type-switcher">
                <button
                  type="button"
                  className={`reply-type-pill ${!isSolutionMode ? "is-active" : ""}`}
                  onClick={() => setIsSolutionMode(false)}
                >
                  <MessageSquare size={13} />
                  <span>Discussion Reply</span>
                </button>
                <button
                  type="button"
                  className={`reply-type-pill ${isSolutionMode ? "is-active" : ""}`}
                  onClick={() => setIsSolutionMode(true)}
                >
                  <Code2 size={13} />
                  <span>Submit Code Solution</span>
                </button>
              </div>

              {/* Reply Composer */}
              <form
                onSubmit={handleAddComment}
                className="threaded-composer-box"
              >
                <ScholarAvatar user={user} size={36} />

                {!isSolutionMode ? (
                  <div className="threaded-composer-input-row">
                    <input
                      type="text"
                      value={newComment}
                      onChange={(e) => setNewComment(e.target.value)}
                      placeholder="Contribute a helpful reply, insight, or suggestion..."
                      className="form-input-control threaded-input"
                      disabled={commentSubmitting}
                    />
                    <Button
                      type="submit"
                      size="sm"
                      variant="primary"
                      disabled={commentSubmitting || !newComment.trim()}
                      icon={Send}
                    >
                      Reply
                    </Button>
                  </div>
                ) : (
                  <div className="solution-composer-panel">
                    <div className="solution-composer-header">
                      <div
                        style={{
                          display: "flex",
                          alignItems: "center",
                          gap: "8px",
                        }}
                      >
                        <span style={{ fontSize: "0.8rem", fontWeight: 600 }}>
                          Language:
                        </span>
                        <select
                          value={solutionLang}
                          onChange={(e) => setSolutionLang(e.target.value)}
                          className="form-input"
                          style={{
                            padding: "4px 8px",
                            fontSize: "0.8rem",
                            borderRadius: "var(--radius-sm)",
                          }}
                          disabled={commentSubmitting}
                        >
                          {CODE_LANGUAGES.map((lang) => (
                            <option key={lang.value} value={lang.value}>
                              {lang.label}
                            </option>
                          ))}
                        </select>
                      </div>
                      <span
                        style={{
                          fontSize: "0.75rem",
                          color: "var(--color-text-muted)",
                        }}
                      >
                        Formatted code solution with syntax styling
                      </span>
                    </div>

                    <textarea
                      value={solutionCode}
                      onChange={(e) => setSolutionCode(e.target.value)}
                      placeholder="// Write or paste your verified solution code here..."
                      rows={5}
                      className="form-input code-textarea"
                      style={{
                        width: "100%",
                        padding: "10px 12px",
                        borderRadius: "var(--radius-md)",
                        fontFamily: "monospace",
                        fontSize: "0.85rem",
                        marginTop: "8px",
                        resize: "vertical",
                      }}
                      disabled={commentSubmitting}
                    />

                    <div
                      style={{ display: "flex", gap: "8px", marginTop: "8px" }}
                    >
                      <input
                        type="text"
                        value={newComment}
                        onChange={(e) => setNewComment(e.target.value)}
                        placeholder="Explain your approach, algorithm logic, or complexity..."
                        className="form-input-control threaded-input"
                        disabled={commentSubmitting}
                      />
                      <Button
                        type="submit"
                        size="sm"
                        variant="primary"
                        disabled={
                          commentSubmitting ||
                          (!newComment.trim() && !solutionCode.trim())
                        }
                        icon={Send}
                      >
                        Submit Solution
                      </Button>
                    </div>
                  </div>
                )}
              </form>

              {commentError && (
                <div className="comment-error-alert">{commentError}</div>
              )}

              {/* Nested Comments Stream */}
              <div className="threaded-comments-stream">
                {commentsLoading ? (
                  <div style={{ padding: "16px", textAlign: "center" }}>
                    <Spinner size="sm" standalone />
                  </div>
                ) : comments.length === 0 ? (
                  <div className="threaded-empty-state">
                    <MessageSquare size={20} className="text-muted" />
                    <span>
                      No replies or solutions yet. Be the first scholar to
                      contribute!
                    </span>
                  </div>
                ) : (
                  comments.map((comment) => {
                    const isCommentAuthor = user?.id === comment.author?.id;
                    const isCommentHelpful =
                      comment.is_helpful || solvedCommentId === comment.id;
                    const commentDate = formatSafeDate(comment?.created_at);

                    return (
                      <div
                        key={comment.id}
                        className={`threaded-comment-node ${isCommentHelpful ? "node-accepted-solution" : ""}`}
                      >
                        {/* Colored reply line */}
                        <div className="thread-line" />

                        <div className="thread-avatar-col">
                          <ScholarAvatar user={comment.author} size={32} />
                        </div>

                        <div
                          className={`thread-bubble-content ${isCommentHelpful ? "bubble-accepted-solution" : ""}`}
                        >
                          {/* Accepted Solution Ribbon */}
                          {isCommentHelpful && (
                            <div className="helpful-solution-ribbon">
                              <CheckCircle2 size={13} />
                              <span>
                                Accepted Solution • Marked Helpful by Author
                              </span>
                            </div>
                          )}

                          <div className="thread-bubble-header">
                            <div
                              style={{
                                display: "flex",
                                alignItems: "center",
                                gap: "6px",
                              }}
                            >
                              <strong className="thread-author-name">
                                {comment.author?.full_name ||
                                  comment.author?.email?.split("@")[0] ||
                                  "Scholar"}
                              </strong>
                              {comment.author?.department && (
                                <span className="thread-dept-badge">
                                  {comment.author.department}
                                </span>
                              )}
                            </div>

                            <div
                              style={{
                                display: "flex",
                                alignItems: "center",
                                gap: "8px",
                              }}
                            >
                              <span className="thread-timestamp">
                                {commentDate}
                              </span>

                              {/* Author can mark as helpful if not already marked */}
                              {isAuthor && !isCommentHelpful && (
                                <button
                                  type="button"
                                  className="mark-helpful-btn"
                                  onClick={() => handleMarkHelpful(comment.id)}
                                  title="Mark this answer as helpful / accepted solution"
                                >
                                  <Check size={12} />
                                  <span>Mark Helpful</span>
                                </button>
                              )}

                              {isCommentAuthor && (
                                <button
                                  type="button"
                                  className="thread-delete-btn"
                                  onClick={() =>
                                    handleDeleteComment(comment.id)
                                  }
                                  title="Delete Reply"
                                >
                                  <Trash2 size={13} />
                                </button>
                              )}
                            </div>
                          </div>

                          <div className="thread-comment-body">
                            {formatRichContent(comment.content)}
                          </div>

                          {/* Render Code Solution if comment includes code */}
                          {comment.code_solution && (
                            <div className="code-snippet-box solution-snippet-box">
                              <div className="code-snippet-header">
                                <div className="code-header-left">
                                  <Code2 size={13} className="text-emerald" />
                                  <span className="code-lang-tag solution-lang">
                                    {comment.code_language || "CODE"} SOLUTION
                                  </span>
                                </div>
                                <button
                                  type="button"
                                  className="code-copy-btn"
                                  onClick={() =>
                                    handleCopyCommentCode(
                                      comment.id,
                                      comment.code_solution,
                                    )
                                  }
                                  title="Copy solution code"
                                >
                                  {copiedCommentCodeId === comment.id ? (
                                    <Check size={13} className="text-emerald" />
                                  ) : (
                                    <Copy size={13} />
                                  )}
                                  <span>
                                    {copiedCommentCodeId === comment.id
                                      ? "Copied"
                                      : "Copy Solution"}
                                  </span>
                                </button>
                              </div>
                              <pre className="code-snippet-pre">
                                <code>{comment.code_solution}</code>
                              </pre>
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </Card>
    </motion.div>
  );
}
