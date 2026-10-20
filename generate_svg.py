import os

def generate_svg():
    svg_content = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1100 1450" width="100%" height="100%" style="background-color: #ffffff; font-family: 'Segoe UI', Arial, sans-serif;">
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1.5 L 8 5 L 0 8.5 z" fill="#000000" />
    </marker>
  </defs>

  <!-- Title -->
  <text x="550" y="45" text-anchor="middle" font-size="24" font-weight="bold" fill="#000000">StudentBrain: System Architecture Overview</text>
  <text x="550" y="72" text-anchor="middle" font-size="14" fill="#555555">A Cross-Platform Academic Command Center &amp; Study Network (CSE 3422)</text>
  <line x1="100" y1="95" x2="1000" y2="95" stroke="#cccccc" stroke-width="1.5" />

  <!-- User Layer -->
  <rect x="350" y="115" width="400" height="55" rx="8" fill="#f8fafc" stroke="#000000" stroke-width="2" />
  <text x="550" y="137" text-anchor="middle" font-size="15" font-weight="bold" fill="#000000">Scholars &amp; University Students</text>
  <text x="550" y="157" text-anchor="middle" font-size="12" fill="#555555">Web Browser Client | Android Mobile Device</text>

  <!-- Arrow User to Presentation -->
  <line x1="550" y1="170" x2="550" y2="205" stroke="#000000" stroke-width="2" marker-end="url(#arrow)" />
  <text x="560" y="192" font-size="11" font-weight="bold" fill="#000000">User Interaction</text>

  <!-- Presentation Tier Outer -->
  <rect x="60" y="210" width="710" height="150" rx="10" fill="#ffffff" stroke="#000000" stroke-width="2" />
  <text x="80" y="232" font-size="15" font-weight="bold" fill="#000000">CROSS-PLATFORM PRESENTATION TIER</text>

  <!-- React Web -->
  <rect x="80" y="245" width="330" height="100" rx="6" fill="#f8fafc" stroke="#333333" stroke-width="1.5" />
  <text x="95" y="265" font-size="13" font-weight="bold" fill="#000000">React 19 SPA (Web Client)</text>
  <text x="95" y="285" font-size="11" fill="#333333">• React 19.2 + TypeScript 5.8 (Vite 8.1)</text>
  <text x="95" y="303" font-size="11" fill="#333333">• Tailwind CSS &amp; Glassmorphic UI</text>
  <text x="95" y="321" font-size="11" fill="#333333">• Recharts Visualizer &amp; Axios Client</text>

  <!-- Flutter Mobile -->
  <rect x="430" y="245" width="320" height="100" rx="6" fill="#f8fafc" stroke="#333333" stroke-width="1.5" />
  <text x="445" y="265" font-size="13" font-weight="bold" fill="#000000">Flutter Android App (Mobile Client)</text>
  <text x="445" y="285" font-size="11" fill="#333333">• Flutter 3.47 + Dart 3.13 Binary</text>
  <text x="445" y="303" font-size="11" fill="#333333">• Riverpod 2.6 State &amp; GoRouter</text>
  <text x="445" y="321" font-size="11" fill="#333333">• Dio Client &amp; Offline Token Cache</text>

  <!-- External Services (Right Box) -->
  <rect x="790" y="210" width="250" height="150" rx="10" fill="#f1f5f9" stroke="#000000" stroke-width="2" />
  <text x="805" y="232" font-size="13" font-weight="bold" fill="#000000">EXTERNAL &amp; NATIVE SERVICES</text>
  <text x="805" y="258" font-size="11" font-weight="bold" fill="#000000">• Google Gemini 2.0 Flash AI</text>
  <text x="815" y="274" font-size="10" fill="#444444">- Document Parsing &amp; MCQs</text>
  <text x="815" y="289" font-size="10" fill="#444444">- Grounded Course Tutor Chat</text>
  <text x="805" y="312" font-size="11" font-weight="bold" fill="#000000">• Android Hardware Native</text>
  <text x="815" y="328" font-size="10" fill="#444444">- Audio TTS Voice Coach</text>
  <text x="815" y="343" font-size="10" fill="#444444">- Scheduled Push Alerts</text>

  <!-- Arrow Mobile to Native -->
  <line x1="750" y1="315" x2="785" y2="315" stroke="#000000" stroke-width="1.5" marker-end="url(#arrow)" />

  <!-- Arrow Presentation to Gateway -->
  <line x1="415" y1="360" x2="415" y2="405" stroke="#000000" stroke-width="2" marker-end="url(#arrow)" />
  <text x="425" y="387" font-size="11" font-weight="bold" fill="#000000">HTTPS REST (JWT)</text>

  <!-- Reverse Proxy Layer -->
  <rect x="200" y="410" width="640" height="55" rx="8" fill="#f8fafc" stroke="#000000" stroke-width="2" />
  <text x="520" y="432" text-anchor="middle" font-size="14" font-weight="bold" fill="#000000">REVERSE PROXY &amp; API GATEWAY (NGINX)</text>
  <text x="520" y="452" text-anchor="middle" font-size="11" fill="#444444">SSL Termination (:443) | Rate Limiting | Media Delivery | Gunicorn WSGI Proxy</text>

  <!-- Arrow Gateway to Application Server -->
  <line x1="520" y1="465" x2="520" y2="505" stroke="#000000" stroke-width="2" marker-end="url(#arrow)" />
  <text x="530" y="488" font-size="11" font-weight="bold" fill="#000000">WSGI Proxy (:8000)</text>

  <!-- Application Server Outer -->
  <rect x="60" y="510" width="980" height="570" rx="10" fill="#ffffff" stroke="#000000" stroke-width="2" />
  <text x="80" y="535" font-size="15" font-weight="bold" fill="#000000">APPLICATION SERVER (DJANGO REST FRAMEWORK &amp; GUNICORN)</text>
  <text x="80" y="555" font-size="11" fill="#555555">Python 3.12 Core | Django 6.0 | Service-Layer Architecture | Modular Domain Pattern</text>

  <!-- Module 1: Accounts -->
  <rect x="80" y="570" width="290" height="130" rx="6" fill="#f8fafc" stroke="#334155" stroke-width="1.5" />
  <text x="95" y="592" font-size="12" font-weight="bold" fill="#000000">accounts: Auth &amp; Identity</text>
  <text x="95" y="612" font-size="10.5" fill="#333333">• Custom SimpleJWT Token Engine</text>
  <text x="95" y="628" font-size="10.5" fill="#333333">• Sub-5ms Email Pre-Check</text>
  <text x="95" y="644" font-size="10.5" fill="#333333">• Single-Roundtrip Auth Payload</text>
  <text x="95" y="660" font-size="10.5" fill="#333333">• Persistent 24h &amp; 1h Event Reminders</text>

  <!-- Module 2: Planner -->
  <rect x="390" y="570" width="300" height="130" rx="6" fill="#f8fafc" stroke="#334155" stroke-width="1.5" />
  <text x="405" y="592" font-size="12" font-weight="bold" fill="#000000">planner: Routine &amp; Curriculum</text>
  <text x="405" y="612" font-size="10.5" fill="#333333">• 12-Trimester UIU BSCSE Matrix</text>
  <text x="405" y="628" font-size="10.5" fill="#333333">• Smart Autocomplete &amp; Credits</text>
  <text x="405" y="644" font-size="10.5" fill="#333333">• Prerequisite Conflict Verification</text>
  <text x="405" y="660" font-size="10.5" fill="#333333">• Exam Slot Clash Prevention</text>

  <!-- Module 3: Tracker -->
  <rect x="710" y="570" width="310" height="130" rx="6" fill="#f8fafc" stroke="#334155" stroke-width="1.5" />
  <text x="725" y="592" font-size="12" font-weight="bold" fill="#000000">tracker: Focus &amp; Streaks</text>
  <text x="725" y="612" font-size="10.5" fill="#333333">• Pomodoro &amp; Continuous Timers</text>
  <text x="725" y="628" font-size="10.5" fill="#333333">• Dynamic Streak Continuity Math</text>
  <text x="725" y="644" font-size="10.5" fill="#333333">• Milestone Badges &amp; Trophy Engine</text>
  <text x="725" y="660" font-size="10.5" fill="#333333">• Quantitative Adherence Audit</text>

  <!-- Module 4: Grades -->
  <rect x="80" y="720" width="290" height="130" rx="6" fill="#f8fafc" stroke="#334155" stroke-width="1.5" />
  <text x="95" y="742" font-size="12" font-weight="bold" fill="#000000">grades: GPA Forecaster</text>
  <text x="95" y="762" font-size="10.5" fill="#333333">• Weighted Quality-Point Math</text>
  <text x="95" y="778" font-size="10.5" fill="#333333">• Retake Simulation &amp; Replacement</text>
  <text x="95" y="794" font-size="10.5" fill="#333333">• Required Semester GPA Projections</text>
  <text x="95" y="810" font-size="10.5" fill="#333333">• Real-Time Feasibility Badges</text>

  <!-- Module 5: Materials -->
  <rect x="390" y="720" width="300" height="130" rx="6" fill="#f8fafc" stroke="#334155" stroke-width="1.5" />
  <text x="405" y="742" font-size="12" font-weight="bold" fill="#000000">materials: Lecture Hub &amp; PDF</text>
  <text x="405" y="762" font-size="10.5" fill="#333333">• Ingestion of .pdf, .docx, .txt, .md</text>
  <text x="405" y="778" font-size="10.5" fill="#333333">• Distraction-Free In-Browser Reader</text>
  <text x="405" y="794" font-size="10.5" fill="#333333">• Python ReportLab Study Guide PDF</text>
  <text x="405" y="810" font-size="10.5" fill="#333333">• Multi-format Document Chunking</text>

  <!-- Module 6: AI Diagnostics -->
  <rect x="710" y="720" width="310" height="130" rx="6" fill="#f8fafc" stroke="#334155" stroke-width="1.5" />
  <text x="725" y="742" font-size="12" font-weight="bold" fill="#000000">ai: Gemini Cognitive Pipeline</text>
  <text x="725" y="762" font-size="10.5" fill="#333333">• Google Gemini 2.0 Flash SDK</text>
  <text x="725" y="778" font-size="10.5" fill="#333333">• Strict JSON Schema Formatting</text>
  <text x="725" y="794" font-size="10.5" fill="#333333">• Automated 5-MCQ Diagnostic Quiz</text>
  <text x="725" y="810" font-size="10.5" fill="#333333">• Weak Topic Assessment Reports</text>

  <!-- Module 7: Community -->
  <rect x="80" y="870" width="440" height="185" rx="6" fill="#f8fafc" stroke="#334155" stroke-width="1.5" />
  <text x="95" y="895" font-size="12" font-weight="bold" fill="#000000">community: Scholar Network &amp; Leaderboard</text>
  <text x="95" y="920" font-size="10.5" fill="#333333">• Scholar Discussion Feeds &amp; In-Place Post Editing</text>
  <text x="95" y="940" font-size="10.5" fill="#333333">• Live Follower/Following Count Sync &amp; Unfollow Modals</text>
  <text x="95" y="960" font-size="10.5" fill="#333333">• Privacy-Preserving Global Study Leaderboard</text>
  <text x="95" y="980" font-size="10.5" fill="#333333">• Multi-Tier Deterministic Tie-Breaking Ranking</text>
  <text x="95" y="1000" font-size="10.5" fill="#333333">• Default Opt-in &amp; Special Character Sanitization</text>

  <!-- Module 8: Analytics -->
  <rect x="540" y="870" width="480" height="185" rx="6" fill="#f8fafc" stroke="#334155" stroke-width="1.5" />
  <text x="555" y="895" font-size="12" font-weight="bold" fill="#000000">analytics: Cross-Module Aggregator</text>
  <text x="555" y="920" font-size="10.5" fill="#333333">• 7-Day Focus Duration Histograms &amp; Trend Curves</text>
  <text x="555" y="940" font-size="10.5" fill="#333333">• Subject-Wise Study Time Doughnut Distribution</text>
  <text x="555" y="960" font-size="10.5" fill="#333333">• Quantitative Schedule Adherence Audit Metric</text>
  <text x="555" y="980" font-size="10.5" fill="#333333">• Trimester Milestone Progress Summaries</text>
  <text x="555" y="1000" font-size="10.5" fill="#333333">• Consolidated Diagnostic Knowledge Mastery Scores</text>

  <!-- Arrow AI to External -->
  <line x1="930" y1="720" x2="930" y2="368" stroke="#000000" stroke-width="2" marker-end="url(#arrow)" />
  <text x="940" y="440" font-size="11" font-weight="bold" fill="#000000">REST AI Calls</text>

  <!-- Arrow App to Database -->
  <line x1="520" y1="1080" x2="520" y2="1125" stroke="#000000" stroke-width="2" marker-end="url(#arrow)" />
  <text x="530" y="1105" font-size="11" font-weight="bold" fill="#000000">ORM Queries / SQL Transactions / File I/O</text>

  <!-- Persistence Tier Outer -->
  <rect x="60" y="1130" width="980" height="175" rx="10" fill="#ffffff" stroke="#000000" stroke-width="2" />
  <text x="80" y="1155" font-size="15" font-weight="bold" fill="#000000">PERSISTENCE &amp; DATA STORAGE TIER</text>

  <!-- PostgreSQL -->
  <rect x="80" y="1170" width="450" height="120" rx="6" fill="#f8fafc" stroke="#333333" stroke-width="1.5" />
  <text x="95" y="1192" font-size="13" font-weight="bold" fill="#000000">PostgreSQL 16 Relational Database</text>
  <text x="95" y="1215" font-size="11" fill="#333333">• Normalized Schema with 20+ Data Models</text>
  <text x="95" y="1235" font-size="11" fill="#333333">• ACID Transactions &amp; Foreign Key Integrity</text>
  <text x="95" y="1255" font-size="11" fill="#333333">• B-Tree Indexes on email, user_id, timestamps</text>
  <text x="95" y="1275" font-size="11" fill="#333333">• Fast Lookup Queries &amp; Relational Consistency</text>

  <!-- Media Storage -->
  <rect x="550" y="1170" width="470" height="120" rx="6" fill="#f8fafc" stroke="#333333" stroke-width="1.5" />
  <text x="565" y="1192" font-size="13" font-weight="bold" fill="#000000">Persistent Media Storage (/media)</text>
  <text x="565" y="1215" font-size="11" fill="#333333">• Course Lecture Slides, Notes &amp; Handouts</text>
  <text x="565" y="1235" font-size="11" fill="#333333">• Generated PDF Study Guides (ReportLab)</text>
  <text x="565" y="1255" font-size="11" fill="#333333">• Android APK Artifacts (StudentBrain.apk)</text>
  <text x="565" y="1275" font-size="11" fill="#333333">• Secure File Permissions &amp; Isolated Storage Volumes</text>

  <!-- Caption -->
  <text x="550" y="1340" text-anchor="middle" font-size="13" font-weight="bold" fill="#000000">Figure 15: StudentBrain End-to-End System Architecture Overview (Clean Monochrome Academic Format)</text>
</svg>"""
    with open("architecture_diagram.svg", "w", encoding="utf-8") as f:
        f.write(svg_content)
    print("SVG generated successfully: architecture_diagram.svg")

if __name__ == "__main__":
    generate_svg()

