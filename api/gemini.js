export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "सिर्फ POST request allowed है।" });
  }

  const API_KEY = process.env.GEMINI_API_KEY;

  if (!API_KEY) {
    return res.status(500).json({ error: "GEMINI_API_KEY Vercel में सेट नहीं है।" });
  }

  try {
    const { question = "", imageBase64 = "", mimeType = "image/jpeg" } = req.body || {};

    const cleanQuestion = String(question).trim();

    if (!cleanQuestion && !imageBase64) {
      return res.status(400).json({ error: "सवाल या फोटो भेजिए।" });
    }

    // Direct HTTP Request Parts
    const contentsParts = [];

    if (imageBase64) {
      contentsParts.push({
        text: "यह पढ़ाई के सवाल की फोटो है। इसे आसान हिंदी में समझाओ।"
      });
      contentsParts.push({
        inlineData: {
          mimeType: mimeType || "image/jpeg",
          data: imageBase64
        }
      });
    }

    if (cleanQuestion) {
      contentsParts.push({
        text: `तुम Padh-Ai के प्यारे AI Teacher हो। आसान हिंदी में उत्तर दो:\n${cleanQuestion}`
      });
    }

    // Direct Google Rest API Endpoint using Key as Query Parameter
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${API_KEY}`;

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        contents: [
          {
            parts: contentsParts
          }
        ]
      })
    });

    const data = await response.json();

    if (!response.ok) {
      console.error("Google API Direct Error:", data);
      return res.status(response.status).json({
        error: data.error?.message || "Google API से कनेक्ट नहीं हो पाया।"
      });
    }

    const replyText = data.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!replyText) {
      return res.status(502).json({ error: "Gemini से खाली जवाब मिला।" });
    }

    return res.status(200).json({ text: replyText });

  } catch (error) {
    console.error("Server Error:", error);
    return res.status(500).json({
      error: "सर्वर एरर: " + (error?.message || error)
    });
  }
}
