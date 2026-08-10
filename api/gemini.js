// /api/gemini.js
// Ye Vercel Serverless Function hai. Iska kaam: browser se photo lena,
// Gemini API ko bhejna (key yahin server par chhupi rehti hai), aur Hindi jawaab wapas dena.
// Gemini key IS FILE ME NAHI hai -- Vercel dashboard ke "Environment Variables" me
// GEMINI_API_KEY naam se save hogi. Isse browser/console me kabhi nahi dikhegi.

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Sirf POST request allowed hai' });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return res.status(500).json({
      error: 'Server par GEMINI_API_KEY set nahi hai. Vercel Project Settings > Environment Variables me add karein.'
    });
  }

  try {
    const { imageBase64, mimeType } = req.body || {};
    if (!imageBase64) {
      return res.status(400).json({ error: 'Photo nahi mili' });
    }

    const prompt =
      'Tum ek pyaare, dhairyavaan Hindi teacher ho jo chhote bachchon ko padhate ho. ' +
      'Is photo me jo bhi likha hai (kitaab ka panna, sawaal, ya diagram), use dhyan se padho. ' +
      'Phir bahut simple, saral Hindi mein, jaise ek bade bhaiya/didi bachche ko samjhaate hain, ' +
      'samjhao ki isme kya likha hai aur iska matlab kya hai. Chhote-chhote vaakya likho. ' +
      'Agar koi sawaal hai to uska jawaab bhi do. Emoji ka thoda use karke isse mazedaar banao.';

    const model = 'gemini-2.0-flash';
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const geminiRes = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: prompt },
              {
                inline_data: {
                  mime_type: mimeType || 'image/jpeg',
                  data: imageBase64
                }
              }
            ]
          }
        ]
      })
    });

    const data = await geminiRes.json();

    if (!geminiRes.ok) {
      console.error('Gemini API error:', data);
      return res.status(geminiRes.status).json({
        error: data?.error?.message || 'Gemini se jawaab nahi mila'
      });
    }

    const text =
      data?.candidates?.[0]?.content?.parts?.map((p) => p.text).join('\n') ||
      'Maaf karna, mujhe iska jawaab nahi mil paaya. Dobara try karo.';

    return res.status(200).json({ text });
  } catch (err) {
    console.error('Server error:', err);
    return res.status(500).json({ error: 'Kuch gadbad ho gayi, dobara try karein' });
  }
}
