#!/bin/bash

# 🌌 ∞ Ω ∞ FOUNDER EMAIL SENDER ∞ Ω ∞ 🌌
# Sends deployment emails to Ove and Ryan

set -e

# Founder email addresses
OVE_EMAIL="oveshen.govender@gmail.com"
RYAN_EMAIL="quinesryan@gmail.com"
STUDIO_NAME="Omega Studio Founders"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}🌌 ∞ Ω ∞ WARP-SPEED FOUNDER EMAIL SYSTEM ∞ Ω ∞ 🌌${NC}"
echo -e "${CYAN}=================================================${NC}"
echo
echo -e "${CYAN}📧 Founder Emails:${NC}"
echo -e "  • Ove: ${GREEN}${OVE_EMAIL}${NC}"
echo -e "  • Ryan: ${GREEN}${RYAN_EMAIL}${NC}"
echo -e "  • Studio: ${YELLOW}${STUDIO_NAME}${NC}"
echo

# Generate the emails first
echo -e "${CYAN}Generating personalized emails...${NC}"
./generate-founder-emails.sh

# Check if email templates exist
if [ ! -f "emails/ove_terminal_access.html" ] || [ ! -f "emails/ryan_terminal_access.html" ]; then
    echo -e "${YELLOW}⚠️  Email templates not found. Generating...${NC}"
    ./generate-founder-emails.sh
fi

# Function to send email using various methods
send_email() {
    local TO="$1"
    local SUBJECT="$2"
    local HTML_FILE="$3"
    local NAME="$4"
    
    echo -e "${CYAN}Sending to ${NAME} (${TO})...${NC}"
    
    # Method 1: Using mail command with HTML
    if command -v mail &> /dev/null; then
        (
            echo "Content-Type: text/html"
            echo "Subject: $SUBJECT"
            echo "To: $TO"
            echo ""
            cat "$HTML_FILE"
        ) | mail -s "$SUBJECT" "$TO"
        echo -e "${GREEN}✅ Sent via mail command${NC}"
        return 0
    fi
    
    # Method 2: Using sendmail
    if command -v sendmail &> /dev/null; then
        (
            echo "To: $TO"
            echo "Subject: $SUBJECT"
            echo "Content-Type: text/html"
            echo "MIME-Version: 1.0"
            echo ""
            cat "$HTML_FILE"
        ) | sendmail "$TO"
        echo -e "${GREEN}✅ Sent via sendmail${NC}"
        return 0
    fi
    
    # Method 3: Using Python
    if command -v python3 &> /dev/null; then
        python3 << EOF
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

# Read HTML content
with open("$HTML_FILE", "r") as f:
    html_content = f.read()

# Create message
msg = MIMEMultipart("alternative")
msg["Subject"] = "$SUBJECT"
msg["From"] = "warp-speed@omega.studio"
msg["To"] = "$TO"

# Attach HTML
html_part = MIMEText(html_content, "html")
msg.attach(html_part)

# Save to file for manual sending
output_file = "${HTML_FILE}.eml"
with open(output_file, "w") as f:
    f.write(msg.as_string())
    
print(f"Email saved to {output_file}")
EOF
        echo -e "${GREEN}✅ Email file created for ${NAME}${NC}"
        return 0
    fi
    
    # Fallback: Just notify where the files are
    echo -e "${YELLOW}⚠️  No email client found. HTML files are ready at:${NC}"
    echo "  • $HTML_FILE"
    return 1
}

# Send to Ove
send_email \
    "$OVE_EMAIL" \
    "🌌 Warp-Speed Omega Terminal Access - Ove" \
    "emails/ove_terminal_access.html" \
    "Ove"

echo

# Send to Ryan  
send_email \
    "$RYAN_EMAIL" \
    "🌌 Warp-Speed Omega Terminal Access - Ryan" \
    "emails/ryan_terminal_access.html" \
    "Ryan"

echo
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📧 EMAIL PREPARATION COMPLETE${NC}"
echo -e "${MAGENTA}═══════════════════════════════════════════════════════════${NC}"
echo
echo -e "${CYAN}📋 Summary:${NC}"
echo -e "  • Ove (${OVE_EMAIL}): Terminal OVE_TERMINAL_1"
echo -e "  • Ryan (${RYAN_EMAIL}): Terminal RYAN_TERMINAL_2"
echo -e "  • Studio: ${STUDIO_NAME}"
echo
echo -e "${CYAN}📁 HTML Files Location:${NC}"
echo -e "  • emails/ove_terminal_access.html"
echo -e "  • emails/ryan_terminal_access.html"
echo
echo -e "${YELLOW}💡 Manual Sending Instructions:${NC}"
echo -e "  1. Open the HTML files in a browser"
echo -e "  2. Copy the content to your email client"
echo -e "  3. Send as HTML email to the founders"
echo
echo -e "${CYAN}🚀 Alternative Methods:${NC}"
echo -e "  • Gmail: Compose → ⋮ → 'Insert HTML'"
echo -e "  • Outlook: New Email → Insert → Attach as Text"
echo -e "  • Thunderbird: Insert → HTML"
echo
echo -e "${GREEN}💰 Revenue Targets:${NC}"
echo -e "  • Daily: \$40,000 combined"
echo -e "  • Annual: \$145.76B combined"
echo -e "  • Consciousness: OMEGA (35.0x)"
echo
echo -e "${MAGENTA}🌌 ∞ Ω ∞ Ready for Production! ∞ Ω ∞ 🌌${NC}"