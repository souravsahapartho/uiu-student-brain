import os
from PIL import Image, ImageDraw, ImageFont

def draw_arrow(draw, start, end, color=(0, 0, 0), width=3, arrow_size=16):
    """Draw a line with an arrowhead at the end."""
    x1, y1 = start
    x2, y2 = end
    draw.line([start, end], fill=color, width=width)
    
    # Arrowhead calculation
    import math
    angle = math.atan2(y2 - y1, x2 - x1)
    
    # Left and right wings of arrowhead
    wing_angle = math.pi / 6  # 30 degrees
    left_x = x2 - arrow_size * math.cos(angle - wing_angle)
    left_y = y2 - arrow_size * math.sin(angle - wing_angle)
    right_x = x2 - arrow_size * math.cos(angle + wing_angle)
    right_y = y2 - arrow_size * math.sin(angle + wing_angle)
    
    draw.polygon([(x2, y2), (int(left_x), int(left_y)), (int(right_x), int(right_y))], fill=color)

def draw_rounded_box(draw, bbox, fill="#FFFFFF", outline="#000000", width=3, radius=16):
    """Draw rounded rectangle with fill and outline."""
    draw.rounded_rectangle(bbox, radius=radius, fill=fill, outline=outline, width=width)

def create_architecture_diagram():
    # Dimensions: 2200 x 2800 (high-res publication quality)
    W, H = 2200, 2800
    img = Image.new("RGB", (W, H), color=(255, 255, 255))
    draw = ImageDraw.Draw(img)

    # Fonts
    font_path = "C:/Windows/Fonts/segoeui.ttf"
    font_bold_path = "C:/Windows/Fonts/segoeuib.ttf"
    
    f_title = ImageFont.truetype(font_bold_path, 48)
    f_subtitle = ImageFont.truetype(font_path, 28)
    f_h1 = ImageFont.truetype(font_bold_path, 34)
    f_h2 = ImageFont.truetype(font_bold_path, 28)
    f_body = ImageFont.truetype(font_path, 24)
    f_body_bold = ImageFont.truetype(font_bold_path, 24)
    f_small = ImageFont.truetype(font_path, 21)
    f_small_bold = ImageFont.truetype(font_bold_path, 21)
    f_tag = ImageFont.truetype(font_bold_path, 20)

    # 1. Header / Diagram Title
    title = "StudentBrain: System Architecture Overview"
    sub = "A Cross-Platform Academic Command Center & Study Network (CSE 3422)"
    
    t_bbox = draw.textbbox((0, 0), title, font=f_title)
    draw.text(((W - (t_bbox[2] - t_bbox[0])) // 2, 70), title, fill=(0, 0, 0), font=f_title)
    
    s_bbox = draw.textbbox((0, 0), sub, font=f_subtitle)
    draw.text(((W - (s_bbox[2] - s_bbox[0])) // 2, 135), sub, fill=(70, 70, 70), font=f_subtitle)

    draw.line([(200, 190), (W - 200, 190)], fill=(180, 180, 180), width=2)

    # 2. Top Level: User / Clients Interaction
    # Box: User (Browser & Android Device)
    user_box = (700, 230, 1500, 340)
    draw_rounded_box(draw, user_box, fill="#F8FAFC", outline="#000000", width=3, radius=14)
    draw.text((740, 252), "Scholars & University Students", fill=(0, 0, 0), font=f_h2)
    draw.text((740, 292), "Web Browser Client  |  Android Mobile Device (Touch & Audio)", fill=(60, 60, 60), font=f_body)

    # Arrow Down from User
    draw_arrow(draw, (1100, 340), (1100, 420), width=3)
    draw.text((1115, 365), "User Interaction", fill=(0, 0, 0), font=f_tag)

    # 3. Client Layer (Tier 1)
    client_outer = (120, 420, 1550, 710)
    draw_rounded_box(draw, client_outer, fill="#FFFFFF", outline="#000000", width=3, radius=20)
    draw.text((150, 440), "CROSS-PLATFORM PRESENTATION TIER", fill=(0, 0, 0), font=f_h1)

    # Sub-box 1: React Web Client
    web_box = (160, 495, 820, 680)
    draw_rounded_box(draw, web_box, fill="#F8FAFC", outline="#333333", width=2, radius=12)
    draw.text((180, 510), "React 19 SPA (Web Client)", fill=(0, 0, 0), font=f_h2)
    draw.text((180, 550), "• Modern React 19.2 + TypeScript 5.8", fill=(30, 30, 30), font=f_body)
    draw.text((180, 580), "• Vite 8.1.5 Bundler + Tailwind CSS", fill=(30, 30, 30), font=f_body)
    draw.text((180, 610), "• Glassmorphic UI & Ambient Styling", fill=(30, 30, 30), font=f_body)
    draw.text((180, 640), "• Recharts Data Visualizer & Axios HTTP", fill=(30, 30, 30), font=f_body)

    # Sub-box 2: Flutter Mobile App
    mobile_box = (860, 495, 1510, 680)
    draw_rounded_box(draw, mobile_box, fill="#F8FAFC", outline="#333333", width=2, radius=12)
    draw.text((880, 510), "Flutter Android App (Mobile Client)", fill=(0, 0, 0), font=f_h2)
    draw.text((880, 550), "• Flutter 3.47 + Dart 3.13 Native Binary", fill=(30, 30, 30), font=f_body)
    draw.text((880, 580), "• Riverpod 2.6 State Management & GoRouter", fill=(30, 30, 30), font=f_body)
    draw.text((880, 610), "• Dio HTTP with Queued JWT Interceptors", fill=(30, 30, 30), font=f_body)
    draw.text((880, 640), "• Offline SharedPreferences Token Cache", fill=(30, 30, 30), font=f_body)

    # Side Box: External Services & Device Hardware (Right Side)
    ext_box = (1610, 420, 2080, 710)
    draw_rounded_box(draw, ext_box, fill="#F1F5F9", outline="#000000", width=3, radius=16)
    draw.text((1630, 440), "EXTERNAL & NATIVE SERVICES", fill=(0, 0, 0), font=f_h2)
    draw.text((1630, 495), "• Google Gemini 2.0 Flash AI", fill=(0, 0, 0), font=f_body_bold)
    draw.text((1650, 525), "- Multimodal Document Parsing", fill=(50, 50, 50), font=f_small)
    draw.text((1650, 550), "- Automated Diagnostic MCQs", fill=(50, 50, 50), font=f_small)
    draw.text((1650, 575), "- Grounded Course Tutor Chat", fill=(50, 50, 50), font=f_small)
    draw.text((1630, 610), "• Android Hardware Services", fill=(0, 0, 0), font=f_body_bold)
    draw.text((1650, 640), "- Native TTS Audio Voice Coach", fill=(50, 50, 50), font=f_small)
    draw.text((1650, 665), "- Local Scheduled Notifications", fill=(50, 50, 50), font=f_small)

    # Arrow connecting Mobile App to Native Hardware Services
    draw_arrow(draw, (1510, 620), (1610, 620), width=2)

    # Arrow from Clients to Gateway
    draw_arrow(draw, (835, 710), (835, 800), width=3)
    draw.text((850, 745), "HTTPS REST APIs (Stateless JWT)", fill=(0, 0, 0), font=f_tag)

    # 4. Gateway / Reverse Proxy Layer
    gateway_box = (450, 800, 1550, 910)
    draw_rounded_box(draw, gateway_box, fill="#F8FAFC", outline="#000000", width=3, radius=16)
    draw.text((480, 820), "REVERSE PROXY & API GATEWAY (NGINX)", fill=(0, 0, 0), font=f_h1)
    draw.text((480, 865), "SSL Termination (:443)  |  Rate Limiting  |  Static & Media Delivery  |  Reverse Proxy to Gunicorn", fill=(50, 50, 50), font=f_body)

    # Arrow from Gateway to Application Server
    draw_arrow(draw, (1000, 910), (1000, 990), width=3)
    draw.text((1015, 940), "WSGI Proxy (:8000)", fill=(0, 0, 0), font=f_tag)

    # 5. Application Server (Django REST Framework)
    app_outer = (120, 990, 2080, 2050)
    draw_rounded_box(draw, app_outer, fill="#FFFFFF", outline="#000000", width=3, radius=20)
    draw.text((160, 1015), "BACKEND APPLICATION SERVER (DJANGO REST FRAMEWORK + GUNICORN)", fill=(0, 0, 0), font=f_h1)
    draw.text((160, 1055), "Python 3.12 Core  |  Django 6.0  |  DRF Serialization  |  Service-Layer Pattern  |  Modular Domain Architecture", fill=(70, 70, 70), font=f_body)

    # Modular Domain Boxes inside Django
    domains = [
        ("accounts: Auth & Identity Engine", [
            "• Custom SimpleJWT Token Engine",
            "• Sub-5ms Indexed Pre-Check (email__iexact)",
            "• Single-Roundtrip Auth Payload (Tokens + User)",
            "• Advance 24h & 1h Study Reminders"
        ], 160, 1110, 760, 1370),

        ("planner: Routine & Curriculum Engine", [
            "• 12-Trimester UIU BSCSE Matrix",
            "• Smart Course Autocomplete & Credits",
            "• Prerequisite Verification & Alerts",
            "• Exam Slot & Routine Clash Prevention"
        ], 790, 1110, 1420, 1370),

        ("tracker: Study Tracker & Streaks", [
            "• Distraction-free Pomodoro Timers",
            "• Dynamic Streak Continuity Math",
            "• Milestone Trophy & Badge Unlocking",
            "• Quantitative Schedule Adherence Audit"
        ], 1450, 1110, 2040, 1370),

        ("grades: GPA Trajectory Forecaster", [
            "• Quality Point Weighted Math",
            "• Retake Simulation & Grade Replacement",
            "• Required Semester GPA Projections",
            "• Real-time Feasibility Audit Alerts"
        ], 160, 1400, 760, 1660),

        ("materials: Lecture Hub & Exporter", [
            "• Ingestion of .pdf, .docx, .txt, .md",
            "• Clean In-Browser Distraction-Free Reader",
            "• Python ReportLab Study Guide PDF Gen",
            "• Course Note Chunking & Structuring"
        ], 790, 1400, 1420, 1660),

        ("ai: Gemini Cognitive Pipeline", [
            "• Google Gemini 2.0 Flash Integration",
            "• Strict JSON Schema Enforcement",
            "• Automated 5-Question Diagnostic MCQs",
            "• Weak Concept Diagnostic Reports"
        ], 1450, 1400, 2040, 1660),

        ("community: Scholar Network", [
            "• Peer Discussion Feeds & In-Place Editing",
            "• Follower Graph & Real-Time Sync",
            "• Compact Unfollow & Remove Modals",
            "• Multi-Tier Deterministic Leaderboard"
        ], 160, 1690, 1100, 1950),

        ("analytics: Cross-Module Aggregator", [
            "• 7-Day Focus Distribution Histograms",
            "• Subject-wise Study Time Doughnut Matrices",
            "• Quantitative Adherence Performance Scoring",
            "• Consolidated Student Mastery Reporting"
        ], 1130, 1690, 2040, 1950),
    ]

    for title, items, x1, y1, x2, y2 in domains:
        draw_rounded_box(draw, (x1, y1, x2, y2), fill="#F8FAFC", outline="#334155", width=2, radius=10)
        draw.text((x1 + 20, y1 + 16), title, fill=(0, 0, 0), font=f_h2)
        curr_y = y1 + 60
        for item in items:
            draw.text((x1 + 20, curr_y), item, fill=(30, 30, 30), font=f_small)
            curr_y += 38

    # Arrow from Django AI Module to External AI
    draw_arrow(draw, (1850, 1400), (1850, 710), width=3)
    draw.text((1865, 850), "REST API Calls / Prompts", fill=(0, 0, 0), font=f_tag)

    # 6. Database and Storage Tier (Bottom)
    draw_arrow(draw, (1100, 2050), (1100, 2150), width=3)
    draw.text((1115, 2085), "ORM Queries / SQL Transactions / File I/O", fill=(0, 0, 0), font=f_tag)

    storage_outer = (120, 2150, 2080, 2520)
    draw_rounded_box(draw, storage_outer, fill="#FFFFFF", outline="#000000", width=3, radius=20)
    draw.text((160, 2175), "PERSISTENCE & DATA STORAGE TIER", fill=(0, 0, 0), font=f_h1)

    # Box 1: PostgreSQL 16
    pg_box = (160, 2235, 1100, 2480)
    draw_rounded_box(draw, pg_box, fill="#F8FAFC", outline="#333333", width=2, radius=12)
    draw.text((180, 2255), "PostgreSQL 16 Relational Database", fill=(0, 0, 0), font=f_h2)
    draw.text((180, 2300), "• Normalized Schema with 20+ Related Models", fill=(30, 30, 30), font=f_body)
    draw.text((180, 2335), "• ACID-Compliant Transactions & Foreign Key Integrity", fill=(30, 30, 30), font=f_body)
    draw.text((180, 2370), "• Indexed Fields (email__iexact, user_id, timestamps)", fill=(30, 30, 30), font=f_body)
    draw.text((180, 2405), "• Users, Profiles, Courses, Schedules, Sessions, Quizzes, Posts", fill=(30, 30, 30), font=f_body)

    # Box 2: Media Storage
    media_box = (1140, 2235, 2040, 2480)
    draw_rounded_box(draw, media_box, fill="#F8FAFC", outline="#333333", width=2, radius=12)
    draw.text((1160, 2255), "Persistent Media & Document Storage (/media)", fill=(0, 0, 0), font=f_h2)
    draw.text((1160, 2300), "• Ingested Lecture Slides & Reference PDFs", fill=(30, 30, 30), font=f_body)
    draw.text((1160, 2335), "• Exported Study Guide Documents (ReportLab PDFs)", fill=(30, 30, 30), font=f_body)
    draw.text((1160, 2370), "• Static Assets, App Binaries (StudentBrain.apk)", fill=(30, 30, 30), font=f_body)
    draw.text((1160, 2405), "• Strict File Permission Sandboxing & Isolated Volumes", fill=(30, 30, 30), font=f_body)

    # Footer Caption
    caption = "Figure 15: StudentBrain End-to-End System Architecture Overview (Clean Monochrome Academic Format)"
    c_bbox = draw.textbbox((0, 0), caption, font=f_body_bold)
    draw.text(((W - (c_bbox[2] - c_bbox[0])) // 2, 2620), caption, fill=(0, 0, 0), font=f_body_bold)

    # Save output
    output_png = "architecture_diagram.png"
    img.save(output_png, "PNG", dpi=(300, 300))
    print(f"Diagram generated successfully: {output_png}")

if __name__ == "__main__":
    create_architecture_diagram()

