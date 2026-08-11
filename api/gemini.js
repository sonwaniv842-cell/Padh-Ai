import { GoogleGenerativeAI } from "@google/generative-ai";

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

    const cleanQuestion = String(question).trim();

    if (!cleanQuestion && !imageBase64) {
      return res.status(400).json({
        error: "सवाल या फोटो भेजिए।"
      });
    }

    const genAI = new GoogleGenerativeAI(API_KEY);
    const model = genAI.getGenerativeModel({ 
      model: "gemini-1.5-flash",
      systemInstruction: `तुम Padh-Ai के प्यारे और धैर्यवान AI Teacher हो।
बच्चों को आसान हिंदी में पढ़ाई समझाओ।
गणित में step-by-step समाधान दो।
जरूरत पर English शब्द का आसान अर्थ बताओ।
फोटो में दिए सवाल को ध्यान से पढ़ो।
बच्चे को डाँटो मत।
छोटे paragraphs और bullets इस्तेमाल करो।
उत्तर दोस्ताना और encouraging रखो।`
    });

    const parts = [];

    if (imageBase64) {
      parts.push({
        text: "यह बच्चे द्वारा भेजी गई पढ़ाई के सवाल की फोटो है। इसे आसान हिंदी में समझाओ।"
      });
      parts.push({
        inlineData: {
          mimeType: mimeType || "image/jpeg",
          data: imageBase64
        }
      });
    }

    if (cleanQuestion) {
      parts.push({
        text: `बच्चे का सवाल:\n${cleanQuestion}`
      });
    }

    let contents = [];

    if (Array.isArray(history) && history.length > 0) {
      for (const item of history.slice(-10)) {
        if (!item?.text) continue;
        contents.push({
          role: item.role === "assistant" || item.role === "model" ? "model" : "user",
          parts: [{ text: String(item.text) }]
        });
      }
    }

    contents.push({
      role: "user",
      parts: parts
    });

    const result = await model.generateContent({ contents });
    const response = await result.response;
    const text = response.text().trim();

    if (!text) {
      return res.status(502).json({
        error: "Gemini से कोई उत्तर नहीं मिला।"
      });
    }

    return res.status(200).json({ text });

  } catch (error) {
    console.error("Gemini Error:", error);
    return res.status(500).json({
      error: "Gemini AI Teacher से जवाब नहीं मिला: " + (error?.message || error)
    });
  }
}
