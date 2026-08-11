import { GoogleGenAI } from "@google/genai";

export default async function handler(req, res) {

  // =====================================================
  // ONLY POST
  // =====================================================

  if (req.method !== "POST") {
    return res.status(405).json({
      error: "सिर्फ POST request allowed है।"
    });
  }

  // =====================================================
  // GEMINI API KEY
  // =====================================================

  const API_KEY = process.env.GEMINI_API_KEY;

  if (!API_KEY) {
    return res.status(500).json({
      error:
        "GEMINI_API_KEY Vercel Environment Variables में सेट नहीं है।"
    });
  }

  try {

    // ===================================================
    // REQUEST DATA
    // ===================================================

    const {
      question = "",
      imageBase64 = "",
      mimeType = "image/jpeg",
      history = []
    } = req.body || {};

    const cleanQuestion =
      String(question || "").trim();

    if (!cleanQuestion && !imageBase64) {
      return res.status(400).json({
        error: "सवाल या फोटो भेजिए।"
      });
    }

    // ===================================================
    // PADH-AI TEACHER
    // ===================================================

    const teacherPrompt = `
तुम "Padh-Ai" के प्यारे, धैर्यवान और बच्चों के लिए
बनाए गए AI Teacher हो।

तुम्हारा काम बच्चों को पढ़ाई समझाना है।

मुख्य नियम:

1. बच्चों से हमेशा प्यार और सम्मान से बात करो।

2. भाषा बहुत आसान हिंदी रखो।

3. जरूरत पड़ने पर English शब्द का आसान अर्थ भी बताओ।

4. गणित के सवाल में:
   - पहले सवाल समझाओ
   - फिर step-by-step हल करो
   - अंत में साफ final answer दो

5. अगर बच्चा पहाड़ा पूछे तो पूरा पहाड़ा दो।

6. अगर बच्चा गिनती पूछे तो उदाहरण देकर समझाओ।

7. अगर बच्चा हिंदी वर्णमाला पूछे तो बच्चों के स्तर पर समझाओ।

8. Science या सामान्य ज्ञान में गलत तथ्य मत बनाओ।

9. अगर प्रश्न की फोटो भेजी गई है तो फोटो को ध्यान से पढ़ो।

10. फोटो में किताब, worksheet, maths question,
    Hindi question, English question या diagram हो
    तो पहले उसे समझो और फिर आसान भाषा में उत्तर दो।

11. बच्चे को सिर्फ answer मत दो।
    जहाँ संभव हो यह भी समझाओ कि answer कैसे आया।

12. बहुत बड़े paragraph मत लिखो।

13. छोटे sections और bullets इस्तेमाल करो।

14. जरूरत के अनुसार emoji इस्तेमाल कर सकते हो:
    😊 📚 ✏️ 🤖 ⭐ 🔢 🎯 🧠 🎉

15. यदि सवाल अस्पष्ट है तो छोटा clarification पूछो।

16. खतरनाक या बच्चों के लिए असुरक्षित चीजों में मदद मत करो।

17. तुम Padh-Ai के AI Teacher हो।

18. उत्तर दोस्ताना और encouraging होना चाहिए।

19. यदि बच्चा गलती करे तो उसे डाँटो मत।
    प्यार से सही तरीका समझाओ।

20. जरूरत हो तो अंत में छोटा encouragement दो।
`;

    // ===================================================
    // GOOGLE GENAI CLIENT
    // ===================================================

    const ai = new GoogleGenAI({
      apiKey: API_KEY
    });

    // ===================================================
    // BUILD CONTENTS
    // ===================================================

    const contents = [];

    // ===================================================
    // PREVIOUS HISTORY
    // ===================================================

    if (Array.isArray(history)) {

      for (const item of history.slice(-12)) {

        if (
          !item ||
          !item.role ||
          !item.text
        ) {
          continue;
        }

        contents.push({
          role:
            item.role === "assistant"
              ? "model"
              : "user",

          parts: [
            {
              text: String(item.text)
            }
          ]
        });
      }
    }

    // ===================================================
    // CURRENT MESSAGE
    // ===================================================

    const currentParts = [];

    // IMAGE
    if (imageBase64) {

      currentParts.push({
        text:
          "यह बच्चे द्वारा भेजी गई प्रश्न की फोटो है। " +
          "फोटो को ध्यान से पढ़ो और प्रश्न को समझाकर " +
          "आसान भाषा में step-by-step उत्तर दो।"
      });

      currentParts.push({
        inlineData: {
          mimeType:
            mimeType || "image/jpeg",

          data:
            imageBase64
        }
      });
    }

    // TEXT
    if (cleanQuestion) {

      currentParts.push({
        text:
          `बच्चे का सवाल:\n${cleanQuestion}`
      });
    }

    contents.push({
      role: "user",
      parts: currentParts
    });

    // ===================================================
    // GEMINI
    // ===================================================

    const response =
      await ai.models.generateContent({

        model: "gemini-3.6-flash",

        contents: contents,

        config: {
          systemInstruction: teacherPrompt,

          maxOutputTokens: 1800
        }

      });

    // ===================================================
    // GET TEXT
    // ===================================================

    const text =
      response?.text
        ? String(response.text).trim()
        : "";

    // ===================================================
    // FINAL RESPONSE
    // ===================================================

    if (!text) {

      return res.status(502).json({
        error:
          "Gemini AI Teacher से जवाब नहीं मिला।"
      });

    }

    return res.status(200).json({
      text
    });

  } catch (error) {

    console.error(
      "Padh-Ai Gemini error:",
      error
    );

    // ===================================================
    // FRIENDLY ERROR
    // ===================================================

    const message =
      error?.message ||
      String(error);

    if (
      message.includes("401") ||
      message.includes("UNAUTHENTICATED") ||
      message.includes("authentication") ||
      message.includes("ACCESS_TOKEN")
    ) {

      return res.status(401).json({
        error:
          "Gemini Authentication में समस्या है। " +
          "Vercel में GEMINI_API_KEY को नई AQ. Authorization Key से अपडेट करें।"
      });
    }

    return res.status(500).json({
      error:
        "Gemini AI Teacher से जवाब नहीं मिला।"
    });
  }
}
