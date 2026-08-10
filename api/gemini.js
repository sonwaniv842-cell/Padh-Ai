export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({
      error: "सिर्फ POST request allowed है।"
    });
  }

  const API_KEY = process.env.GEMINI_API_KEY;

  if (!API_KEY) {
    return res.status(500).json({
      error:
        "GEMINI_API_KEY सेट नहीं है। Vercel → Settings → Environment Variables में इसे जोड़ें।"
    });
  }

  try {
    const {
      question = "",
      imageBase64 = "",
      mimeType = "image/jpeg"
    } = req.body || {};

    if (!question.trim() && !imageBase64) {
      return res.status(400).json({
        error: "सवाल या फोटो भेजिए।"
      });
    }

    const parts = [];

    const teacherPrompt = `
तुम Padh-Ai के प्यारे AI Teacher हो।

बच्चों को बहुत आसान और दोस्ताना हिंदी में पढ़ाओ।
छोटे वाक्य इस्तेमाल करो।
जरूरत के अनुसार emoji इस्तेमाल करो।
अगर गणित का सवाल है तो step-by-step समझाओ।
अगर फोटो में सवाल है तो पहले सवाल पढ़ो और फिर उत्तर समझाओ।
गलत जानकारी मत बनाओ।
बच्चे की उम्र के हिसाब से सरल भाषा रखो।
`;

    parts.push({ text: teacherPrompt });

    if (imageBase64) {
      parts.push({
        text: `
इस फोटो को ध्यान से पढ़ो।
फोटो में किताब, गणित का सवाल, हिंदी/English का प्रश्न या diagram हो
तो उसे सरल हिंदी में समझाओ और जहाँ जरूरी हो वहाँ सही उत्तर भी दो।
        `
      });

      parts.push({
        inline_data: {
          mime_type: mimeType,
          data: imageBase64
        }
      });
    }

    if (question.trim()) {
      parts.push({
        text: `बच्चे का सवाल:\n${question.trim()}`
      });
    }

    const model = "gemini-2.0-flash";

    const url =
      "https://generativelanguage.googleapis.com/v1beta/models/" +
      model +
      ":generateContent?key=" +
      encodeURIComponent(API_KEY);

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        contents: [
          {
            role: "user",
            parts
          }
        ],
        generationConfig: {
          temperature: 0.5,
          maxOutputTokens: 1200
        }
      })
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("Gemini error:", data);

      return res.status(response.status).json({
        error:
          data?.error?.message ||
          "AI Teacher से जवाब नहीं मिला।"
      });
    }

    const text =
      data?.candidates?.[0]?.content?.parts
        ?.map(p => p.text || "")
        .join("\n")
        .trim();

    return res.status(200).json({
      text:
        text ||
        "मुझे इसका जवाब नहीं मिल पाया। एक बार फिर कोशिश करो। 😊"
    });

  } catch (error) {
    console.error("Server error:", error);

    return res.status(500).json({
      error: "Server में समस्या हुई। थोड़ी देर बाद फिर कोशिश करें।"
    });
  }
}
