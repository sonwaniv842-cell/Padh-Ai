export default async function handler(req, res) {

  /* =====================================================
     ONLY POST
  ===================================================== */

  if (req.method !== "POST") {

    return res.status(405).json({
      error:
        "सिर्फ POST request allowed है।"
    });

  }


  /* =====================================================
     GEMINI API KEY
  ===================================================== */

  const API_KEY =
    process.env.GEMINI_API_KEY;


  if (!API_KEY) {

    return res.status(500).json({

      error:
        "GEMINI_API_KEY सेट नहीं है। " +
        "Vercel → Settings → Environment Variables में इसे जोड़ें।"

    });

  }


  try {

    /* ===================================================
       REQUEST DATA
    =================================================== */

    const {

      question = "",

      imageBase64 = "",

      mimeType = "image/jpeg",

      history = []

    } = req.body || {};


    const cleanQuestion =
      String(question || "").trim();


    if (
      !cleanQuestion &&
      !imageBase64
    ) {

      return res.status(400).json({

        error:
          "सवाल या फोटो भेजिए।"

      });

    }


    /* ===================================================
       PADH-AI TEACHER SYSTEM INSTRUCTION
    =================================================== */

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

5. अगर बच्चा पहाड़ा पूछे तो साफ-साफ पूरा पहाड़ा दो।

6. अगर बच्चा गिनती पूछे तो उदाहरण देकर समझाओ।

7. अगर बच्चा हिंदी वर्णमाला पूछे तो बच्चों के स्तर पर समझाओ।

8. Science या सामान्य ज्ञान में गलत तथ्य मत बनाओ।

9. अगर प्रश्न की फोटो भेजी गई है तो फोटो को ध्यान से पढ़ो।

10. फोटो में किताब, worksheet, maths question,
    Hindi question, English question या diagram हो
    तो पहले उसे समझो और फिर आसान भाषा में उत्तर दो।

11. बच्चे को सिर्फ answer मत दो।
    जहाँ संभव हो वहाँ यह भी समझाओ कि answer कैसे आया।

12. बहुत बड़े paragraph मत लिखो।

13. छोटे sections और bullets इस्तेमाल करो।

14. जरूरत के अनुसार ये emoji इस्तेमाल कर सकते हो:
    😊 📚 ✏️ 🤖 ⭐ 🔢 🎯 🧠 🎉

15. यदि सवाल अस्पष्ट है तो बच्चे से छोटा clarification पूछो।

16. खतरनाक, अनुचित या बच्चों के लिए असुरक्षित चीजों में मदद मत करो।

17. तुम Padh-Ai के AI Teacher हो।
    अपने आपको Google Assistant या कोई दूसरा assistant मत बताओ।

18. उत्तर दोस्ताना और encouraging होना चाहिए।

19. यदि बच्चा गलती करे तो उसे डाँटो मत।
    प्यार से सही तरीका समझाओ।

20. अंत में जरूरत हो तो छोटा encouragement दो,
    जैसे:
    "बहुत बढ़िया! 🌟"
    या
    "चलो अब एक और सवाल करते हैं! 😊"

`;


    /* ===================================================
       CONTENTS
    =================================================== */

    const contents = [];


    /* ===================================================
       PREVIOUS CHAT HISTORY
    =================================================== */

    if (
      Array.isArray(history) &&
      history.length > 0
    ) {

      for (
        const item of history.slice(-12)
      ) {

        if (
          !item ||
          !item.role ||
          !item.text
        ) {
          continue;
        }


        const role =
          item.role === "assistant"
            ? "model"
            : "user";


        contents.push({

          role,

          parts:[
            {
              text:
                String(item.text)
            }
          ]

        });

      }

    }


    /* ===================================================
       CURRENT USER MESSAGE
    =================================================== */

    const currentParts = [];


    if (imageBase64) {

      currentParts.push({

        text:
          `
यह बच्चे द्वारा भेजी गई प्रश्न की फोटो है।

फोटो को ध्यान से पढ़ो।
अगर इसमें प्रश्न है तो प्रश्न समझाकर
step-by-step आसान उत्तर दो।
          `

      });


      currentParts.push({

        inline_data: {

          mime_type:
            mimeType || "image/jpeg",

          data:
            imageBase64

        }

      });

    }


    if (cleanQuestion) {

      currentParts.push({

        text:
          `बच्चे का सवाल:\n${cleanQuestion}`

      });

    }


    contents.push({

      role:"user",

      parts:
        currentParts

    });


    /* ===================================================
       GEMINI MODEL
    =================================================== */

    const model =
      "gemini-3.6-flash";


    const url =
      "https://generativelanguage.googleapis.com/v1beta/models/" +
      model +
      ":generateContent";


    /* ===================================================
       REQUEST
    =================================================== */

    const response =
      await fetch(

        url,

        {

          method:"POST",

          headers:{

            "Content-Type":
              "application/json",

            "x-goog-api-key":
              API_KEY

          },

          body:

            JSON.stringify({

              system_instruction:{

                parts:[

                  {
                    text:
                      teacherPrompt
                  }

                ]

              },

              contents,

              generationConfig:{

                maxOutputTokens:
                  1800

              }

            })

        }

      );


    /* ===================================================
       RESPONSE JSON
    =================================================== */

    const data =
      await response.json();


    if (!response.ok) {

      console.error(
        "Gemini API error:",
        data
      );


      return res.status(
        response.status
      ).json({

        error:
          data?.error?.message ||
          "AI Teacher से जवाब नहीं मिला।"

      });

    }


    /* ===================================================
       TEXT
    =================================================== */

    const text =

      data
        ?.candidates?.[0]
        ?.content?.parts
        ?.map(
          part =>
            part.text || ""
        )
        .join("\n")
        .trim();


    /* ===================================================
       FINAL RESPONSE
    =================================================== */

    return res.status(200).json({

      text:

        text ||

        "मुझे अभी इसका जवाब नहीं मिल पाया। 😊 एक बार फिर पूछो।"

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
