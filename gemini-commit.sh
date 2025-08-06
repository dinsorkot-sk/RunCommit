#!/bin/bash

# โหลด ENV จาก .env (ถ้ามี)
if [ -f .env ]; then
  . ./.env
fi

# ตรวจสอบว่า API KEY ถูกตั้งหรือยัง
if [ -z "$GEMINI_API_KEY" ]; then
  echo "❌ ERROR: GEMINI_API_KEY is not set. Please add it to your .env file or export it."
  exit 1
fi

# อ่าน diff ที่ถูก staged
DIFF=$(git diff --cached --no-color --no-ext-diff)

# ตรวจสอบว่ามี diff หรือไม่
if [ -z "$DIFF" ]; then
  echo "✅ No changes staged for commit. Nothing to do."
  exit 0
fi

# ----- สร้าง JSON Payload โดยไม่ต้องใช้ jq -----
# 1. Escape backslashes (\) -> \\
# 2. Escape double quotes (") -> \"
# 3. แปลง newlines (การขึ้นบรรทัดใหม่) ให้กลายเป็นตัวอักษร \n
ESCAPED_DIFF=$(echo "$DIFF" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}')

# 2. สร้าง JSON Payload เป็น string
JSON_PAYLOAD=$(cat <<EOF
{
  "contents": [
    {
      "parts": [
        {
          "text": "Write a concise and clear Git commit message in Conventional Commits format for this diff:\n\n\`\`\`diff\n$ESCAPED_DIFF\n\`\`\`"
        }
      ]
    }
  ]
}
EOF
)

# ส่งคำขอไปยัง Gemini API
# เพิ่ม -k (--insecure) เพื่อแก้ปัญหา certificate บน Windows (CRYPT_E_NO_REVOCATION_CHECK)
RESPONSE=$(curl -sfSk -X POST \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}")

# ตรวจสอบว่า curl ทำงานสำเร็จหรือไม่
if [ $? -ne 0 ]; then
  echo -e "\n❌ ERROR: Failed to get a response from Gemini API."
  echo "Please check your API key, internet connection, and network/firewall settings."
  exit 1
fi


# ----- ดึงข้อความออกจาก JSON Response โดยไม่ต้องใช้ jq -----
MESSAGE=$(echo "$RESPONSE" | grep -oP '"text":\s*"\K(.*?)(?=")' | head -n 1)

# แปลง escape sequence เช่น \n ให้เป็นบรรทัดใหม่จริง ๆ
MESSAGE=$(echo -e "$MESSAGE")

# ลบ backticks และ code fences (```diff, ``` ฯลฯ)
MESSAGE=$(echo "$MESSAGE" | sed '/^```/d')

if [ -z "$MESSAGE" ]; then
    echo -e "\n❌ ERROR: Could not parse the commit message from the API response."
    echo -e "\n📦 RAW RESPONSE:"
    echo "$RESPONSE"
    exit 1
fi

# แสดง commit message ที่ได้
echo -e "\n📥 Suggested commit message:\n--------------------------"
echo -e "$MESSAGE"
echo "--------------------------"

# ถามผู้ใช้ก่อน commit
read -p "Do you want to commit with this message? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-Y}

if [[ $CONFIRM =~ ^[Yy]$ ]]; then
  git commit -m "$MESSAGE"
  echo "✅ Commit successful."
else
  echo "❌ Commit cancelled."
fi
