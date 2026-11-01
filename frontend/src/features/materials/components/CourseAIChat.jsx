import { useState, useEffect, useRef } from "react";
import { BookOpen, GraduationCap, Send, User } from "lucide-react";
import Button from "../../../components/Button";
import Spinner from "../../../components/Spinner";
import {
  getCourseChat,
  sendCourseChat,
  extractMaterialsErrorMessage,
} from "../api";
import { formatRichContent } from "../../../lib/markdownHelper";

export default function CourseAIChat({
  courseId,
  courseTitle,
  courseCode,
  extractedTopics = [],
}) {
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState("");
  const [loadingHistory, setLoadingHistory] = useState(true);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState("");
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    let isMounted = true;
    const loadChat = async () => {
      try {
        setLoadingHistory(true);
        const data = await getCourseChat(courseId);
        if (isMounted) {
          setMessages(data);
        }
      } catch (err) {
        if (isMounted) setError(extractMaterialsErrorMessage(err));
      } finally {
        if (isMounted) setLoadingHistory(false);
      }
    };

    if (courseId) {
      loadChat();
    }

    return () => {
      isMounted = false;
    };
  }, [courseId]);

  useEffect(() => {
    scrollToBottom();
  }, [messages, sending]);

  const handleSend = async (textToSend) => {
    const text = (textToSend || inputMessage).trim();
    if (!text || sending) return;

    setInputMessage("");
    setError("");

    // Optimistic user bubble
    const tempUserMsg = {
      id: Date.now(),
      role: "user",
      content: text,
      created_at: new Date().toISOString(),
    };
    setMessages((prev) => [...prev, tempUserMsg]);
    setSending(true);

    try {
      const reply = await sendCourseChat(courseId, text);
      setMessages((prev) => [...prev, reply]);
    } catch (err) {
      setError(extractMaterialsErrorMessage(err));
    } finally {
      setSending(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const suggestions = [
    `Summarize the key topics for ${courseTitle}`,
    `Generate 3 diagnostic practice questions`,
    `Explain the most challenging concept in this course`,
    `Create a step-by-step exam revision strategy`,
  ];

  return (
    <div className="course-ai-chat-container">
      {/* Chat Header */}
      <div className="chat-header-bar">
        <div className="chat-header-left">
          <div className="ai-avatar-badge">🎓</div>
          <div className="chat-header-info">
            <h4 className="chat-header-title">
              Study Assistant • {courseCode ? `[${courseCode}] ` : ""}
              {courseTitle}
            </h4>
            <p className="chat-header-subtitle">
              Grounded in your uploaded lecture notes, PDFs, and syllabus
              topics.
            </p>
          </div>
        </div>
        {extractedTopics.length > 0 && (
          <span
            className="badge-concepts-pill"
            title={`${extractedTopics.length} Syllabus Concepts Active`}
          >
            <BookOpen size={12} />
            <span className="badge-concepts-text-full">
              {extractedTopics.length} Syllabus Concepts Active
            </span>
            <span className="badge-concepts-text-short">
              {extractedTopics.length} Concepts
            </span>
          </span>
        )}
      </div>

      {error && (
        <div className="alert-banner alert-banner-error m-3">
          <span>{error}</span>
          <button className="alert-dismiss-btn" onClick={() => setError("")}>
            ✕
          </button>
        </div>
      )}

      {/* Messages Scroll Area */}
      <div className="chat-messages-area">
        {loadingHistory ? (
          <div className="chat-loading-box">
            <Spinner standalone />
            <p className="text-muted text-sm mt-2">
              Loading course consultation history...
            </p>
          </div>
        ) : messages.length === 0 ? (
          <div className="chat-empty-state">
            <div className="chat-empty-icon">
              <GraduationCap size={28} className="text-primary" />
            </div>
            <h4 className="chat-empty-title">
              Ask your Course Study Assistant
            </h4>
            <p className="chat-empty-desc">
              Ask questions about lecture notes, request step-by-step problem
              explanations, or generate interactive quiz questions.
            </p>
            <div className="chat-suggestions-grid">
              {suggestions.map((s, idx) => (
                <button
                  key={idx}
                  type="button"
                  className="chat-suggestion-chip"
                  onClick={() => handleSend(s)}
                >
                  <span className="suggestion-bullet">💡</span> {s}
                </button>
              ))}
            </div>
          </div>
        ) : (
          <div className="chat-messages-stream">
            {messages.map((m, index) => {
              const isUser = m.role === "user";
              return (
                <div
                  key={m.id ?? `message-${index}`}
                  className={`chat-message-row ${isUser ? "chat-row-user" : "chat-row-assistant"}`}
                >
                  {!isUser && (
                    <div className="chat-avatar-assistant">
                      <GraduationCap size={16} />
                    </div>
                  )}
                  <div
                    className={`chat-bubble ${isUser ? "bubble-user" : "bubble-assistant"}`}
                  >
                    <div className="bubble-text">
                      {isUser ? m.content : formatRichContent(m.content)}
                    </div>
                    <span className="bubble-time">
                      {new Date(m.created_at).toLocaleTimeString([], {
                        hour: "2-digit",
                        minute: "2-digit",
                      })}
                    </span>
                  </div>
                  {isUser && (
                    <div className="chat-avatar-user">
                      <User size={16} />
                    </div>
                  )}
                </div>
              );
            })}

            {sending && (
              <div className="chat-message-row chat-row-assistant">
                <div className="chat-avatar-assistant">
                  <GraduationCap size={16} />
                </div>
                <div className="chat-bubble bubble-assistant bubble-typing">
                  <span className="typing-dot"></span>
                  <span className="typing-dot"></span>
                  <span className="typing-dot"></span>
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>
        )}
      </div>

      {/* Suggested Quick Prompts Bar (when messages exist) */}
      {messages.length > 0 && (
        <div className="chat-quick-suggestions-bar">
          {suggestions.slice(0, 3).map((s, idx) => (
            <button
              key={idx}
              type="button"
              className="quick-chip-btn"
              onClick={() => handleSend(s)}
              disabled={sending}
            >
              {s}
            </button>
          ))}
        </div>
      )}

      {/* Chat Input Bar */}
      <div className="chat-input-bar">
        <textarea
          className="chat-input-field"
          rows={1}
          placeholder={`Ask about ${courseCode ? `[${courseCode}] ` : ""}${courseTitle}...`}
          value={inputMessage}
          onChange={(e) => setInputMessage(e.target.value)}
          onKeyDown={handleKeyDown}
          disabled={sending}
        />
        <Button
          type="button"
          variant="primary"
          className="chat-send-btn"
          onClick={() => handleSend()}
          disabled={!inputMessage.trim() || sending}
          loading={sending}
        >
          Send ↗
        </Button>
      </div>
    </div>
  );
}
