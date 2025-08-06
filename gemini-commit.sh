#!/bin/bash

# โหลด ENV จาก .env ถ้ามี
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

# ตรวจสอบว่า API KEY ถูกตั้งไว้หรือไม่
if [ -z "$GEMINI_API_KEY" ]; then
  echo "❌ ERROR: GEMINI_API_KEY is not set. Please add it to your .env file or export it."
  exit 1
fi

# อ่าน diff ที่ถูก staged
DIFF=$(git diff --cached --no-color --no-ext-diff)

# ถ้าไม่มี diff ให้ถามผู้ใช้ว่าจะ add หรือไม่
if [ -z "$DIFF" ]; then
  echo "✅ No changes staged for commit."
  read -p "Do you want to add all changes? [Y/n]: " CONFIRM
  CONFIRM=${CONFIRM:-Y}
  if [[ $CONFIRM =~ ^[Yy]$ ]]; then
    git add .
    echo "✅ Files added."
    DIFF=$(git diff --cached --no-color --no-ext-diff)
    if [ -z "$DIFF" ]; then
      echo "❌ Nothing to commit even after adding."
      exit 0
    fi
  else
    echo "❌ Add cancelled."
    exit 0
  fi
fi

# Escape DIFF ให้เหมาะสำหรับ JSON (ไม่ใช้ jq)
ESCAPED_DIFF=$(printf '%s\n' "$DIFF" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n')

# สร้าง JSON Payload
read -r -d '' JSON_PAYLOAD <<EOF
{
  "contents": [
    {
      "parts": [
        {
          "text": "Write a concise and clear Git commit message in Conventional Commits format for this diff:\\n\\n\`\`\`diff\\n$ESCAPED_DIFF\\n\`\`\`"
        }
      ]
    }
  ]
}
EOF

# เรียก Gemini API
RESPONSE=$(curl -sfSk -X POST \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}")

# ตรวจสอบว่า curl ทำงานสำเร็จหรือไม่
if [ $? -ne 0 ]; then
  echo -e "\n❌ ERROR: Failed to get a response from Gemini API."
  exit 1
fi

# แยกข้อความ commit message ออกโดยไม่ใช้ jq
MESSAGE=$(echo "$RESPONSE" | grep -oP '"text":\s*"\K(.*?)(?=")' | head -n 1)
MESSAGE=$(echo -e "$MESSAGE" | sed '/^```/d')

# ตรวจสอบว่าได้ข้อความกลับมาหรือไม่
if [ -z "$MESSAGE" ]; then
  echo -e "\n❌ ERROR: Could not parse commit message from API response."
  echo -e "\n📦 RAW RESPONSE:"
  echo "$RESPONSE"
  exit 1
fi

# แสดงข้อความ commit ที่แนะนำ
echo -e "\n📥 Suggested commit message:"
echo "----------------------------------------"
echo "$MESSAGE"
echo "----------------------------------------"

# ยืนยันการ commit
read -p "Do you want to commit with this message? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-Y}
if [[ $CONFIRM =~ ^[Yy]$ ]]; then
  git commit -m "$MESSAGE"
  echo "✅ Commit successful."
else
  echo "❌ Commit cancelled."
  exit 0
fi

# ยืนยันการ push
read -p "Do you want to push to remote? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-Y}
if [[ $CONFIRM =~ ^[Yy]$ ]]; then
  git push
  echo "✅ Push successful."
else
  echo "❌ Push cancelled."
fi
