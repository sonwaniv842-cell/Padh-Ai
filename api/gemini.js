export default async function handler(req, res) {

  if (req.method !== "POST") {
    return res.status(405).json({
      error: "सिर्फ POST request allowed है।"
    });
  }

  const API_KEY = process.env.GEMINI_API_KEY;

  if (!API_KEY) {
    return res.status(500).json({
      error: "GEMINI_API_KEY Vercel में सेट नहीं है।"
    });
  }

  try {

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

    const teacherPrompt = `
तुम "Padh-Ai" के प्यारे, धैर्यवान और बच्चों के लिए
बनाए गए AI Teacher हो।

बच्चों से हमेशा प्यार और सम्मान से बात करो।

मुख्य नियम:

1. आसान हिंदी में समझाओ।
2. जरूरत पर English शब्द का आसान अर्थ बताओ।
3. गणित में step-by-step समाधान दो।
4. अंत में साफ final answer दो।
5. पहाड़ा पूछने पर पूरा पहाड़ा दो।
6. गिनती पूछने पर उदाहरण देकर समझाओ।
7. हिंदी वर्णमाला बच्चों के स्तर पर समझाओ।
8. Science और सामान्य ज्ञान में तथ्य सही रखो।
9. फोटो भेजी गई हो तो उसे ध्यान से पढ़ो।
10. फोटो में maths, Hindi, English, worksheet या diagram हो
    तो पहले प्रश्न समझो और फिर उत्तर दो।
11. सिर्फ answer नहीं, जहाँ संभव हो तरीका भी समझाओ।
12. छोटे sections और bullets इस्तेमाल करो।
13. जरूरत पर 😊 📚 ✏️ ⭐ 🧠 🎉 जैसे emoji इस्तेमाल कर सकते हो।
14. अस्पष्ट सवाल हो तो छोटा clarification पूछो।
15. खतरनाक या असुरक्षित चीजों में मदद मत करो।
16. अपने आपको Google Assistant मत बताओ।
17. तुम Padh-Ai के AI Teacher हो।
18. बच्चे की गलती पर डाँटो मत, प्यार से सही तरीका समझाओ।
19. उत्तर दोस्ताना और encouraging रखो।
`;

    /* =========================================
       INPUT
    ========================================= */

    const input = [];

    /* Previous history */
    if (Array.isArray(history)) {

      for (const item of history.slice(-12)) {

        if (!item || !item.text) {
          continue;
        }

        input.push({
          type: "text",
          text:
            `${item.role === "assistant"
              ? "Teacher"
              : "Student"}: ${String(item.text)}`
        });

      }

    }

    /* Image */
    if (imageBase64) {

      input.push({
        type: "image",
        mime_type: mimeType || "image/jpeg",
        data: imageBase64
      });

    }

    /* Question */
    if (cleanQuestion) {

      input.push({
        type: "text",
        text:
          `बच्चे का सवाल:\n${cleanQuestion}`
      });

    } else if (imageBase64) {

      input.push({
        type: "text",
        text:
          "इस फोटो में दिए गए प्रश्न को पढ़कर आसान भाषा में step-by-step समझाओ और उत्तर दो।"
      });

    }

    /* =========================================
       GEMINI INTERACTIONS API
    ========================================= */

    const url =
      "https://generativelanguage.googleapis.com/v1beta/interactions";

    const response = await fetch(url, {

      method: "POST",

      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": API_KEY
      },

      body: JSON.stringify({

        model: "gemini-3.6-flash",

        input,

        system_instruction:
          teacherPrompt,

        generation_config: {
          max_output_tokens: 1800
        },

        store: false

      })

    });

    const data = await response.json();

    /* =========================================
       GEMINI ERROR
    ========================================= */

    if (!response.ok) {

      console.error(
        "Gemini API error:",
        data
      );

      return res.status(response.status).json({

        error:
          data?.error?.message ||
          "Gemini AI Teacher से जवाब नहीं मिला।",

        status:
          data?.error?.status || "UNKNOWN"

      });

    }

    /* =========================================
       FIND MODEL TEXT
    ========================================= */

    let text = "";

    if (Array.isArray(data?.steps)) {

      for (const step of data.steps) {

        if (
          step?.type === "model_output" &&
          Array.isArray(step.content)
        ) {

          for (const item of step.content) {

            if (
              item?.type === "text" &&
              item?.text
            ) {

              text +=
                String(item.text) + "\n";

            }

          }

        }

      }

    }

    text = text.trim();

    /* =========================================
       FALLBACK
    ========================================= */

    if (!text && data?.output_text) {

      text =
        String(data.output_text).trim();

    }

    if (!text) {

      return res.status(502).json({

        error:
          "AI Teacher ने कोई text response नहीं दिया।"

      });

    }

    /* =========================================
       SUCCESS
    ========================================= */

    return res.status(200).json({
      text
    });

  } catch (error) {

    console.error(
      "Padh-Ai server error:",
      error
    );

    return res.status(500).json({

      error:
        "AI Teacher server में समस्या हुई। थोड़ी देर बाद फिर कोशिश करें।"

    });

  }

}
