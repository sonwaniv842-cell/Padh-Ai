<!DOCTYPE html>
<html lang="hi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Padh-Ai | आपका स्मार्ट एआई टीचर</title>
    
    <!-- Google Fonts for Modern Look -->
    <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700&family=Hind:wght@400;600&display=swap" rel="stylesheet">
    <!-- Font Awesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <style>
        :root {
            --cyan: #00E5FF;
            --navy: #0A0E21;
            --card-bg: rgba(29, 27, 46, 0.95);
            --glass: rgba(255, 255, 255, 0.05);
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Hind', sans-serif;
            -webkit-tap-highlight-color: transparent;
        }

        body {
            background-color: var(--navy);
            color: white;
            text-align: center;
            overflow-x: hidden;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
        }

        /* Animated Glowing Background */
        .glow-bg {
            position: fixed;
            width: 300px;
            height: 300px;
            background: var(--cyan);
            filter: blur(150px);
            opacity: 0.15;
            z-index: -1;
            border-radius: 50%;
            top: 20%;
            left: 50%;
            transform: translate(-50%, -50%);
        }

        /* Robot Logo Animation */
        .robot-logo {
            font-size: 100px;
            margin-top: 50px;
            animation: float 3s ease-in-out infinite;
            filter: drop-shadow(0 0 20px var(--cyan));
        }

        @keyframes float {
            0%, 100% { transform: translateY(0); }
            50% { transform: translateY(-20px); }
        }

        h1 {
            font-family: 'Orbitron', sans-serif;
            font-size: 3.5rem;
            color: var(--cyan);
            text-shadow: 0 0 20px var(--cyan);
            margin: 10px 0;
        }

        .tagline {
            font-size: 1.2rem;
            opacity: 0.8;
            max-width: 80%;
            margin: 0 auto 30px;
        }

        /* FIXED DOWNLOAD BUTTON: NO NEW TAB */
        .btn-download {
            background: linear-gradient(135deg, var(--cyan), #00B0FF);
            color: var(--navy);
            padding: 18px 45px;
            border-radius: 50px;
            font-size: 1.3rem;
            font-weight: 800;
            border: none;
            cursor: pointer;
            box-shadow: 0 0 30px rgba(0, 229, 255, 0.4);
            transition: 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 15px;
            margin-bottom: 20px;
        }

        .btn-download:active {
            transform: scale(0.95);
        }

        /* Auth Card */
        .auth-container {
            background: var(--card-bg);
            border: 1px solid var(--cyan);
            border-radius: 30px;
            width: 90%;
            max-width: 400px;
            padding: 35px;
            margin: 20px 0;
            box-shadow: 0 0 40px rgba(0, 0, 0, 0.5);
            backdrop-filter: blur(10px);
        }

        h3 { margin-bottom: 20px; color: var(--cyan); font-family: 'Orbitron', sans-serif; }

        input {
            width: 100%;
            padding: 14px;
            margin: 10px 0;
            background: var(--glass);
            border: 1px solid var(--cyan);
            color: white;
            border-radius: 12px;
            font-size: 1rem;
            outline: none;
        }

        .btn-submit {
            background: var(--cyan);
            width: 100%;
            padding: 14px;
            border: none;
            border-radius: 12px;
            font-weight: bold;
            cursor: pointer;
            margin-top: 10px;
            color: var(--navy);
            font-size: 1.1rem;
        }

        .footer {
            margin-top: auto;
            padding: 30px;
            opacity: 0.5;
            font-size: 0.8rem;
        }

        /* Hidden Frame for download */
        #download_frame { display: none; }
        
        /* Loading Overlay for feedback */
        #loading_msg {
            display: none;
            color: var(--cyan);
            font-weight: bold;
            margin-bottom: 10px;
        }
    </style>
</head>
<body>

    <div class="glow-bg"></div>

    <div class="robot-logo">🤖</div>
    <h1>Padh-Ai</h1>
    <p class="tagline">भारत का अपना सुरक्षित डिजिटल स्कूल</p>

    <!-- फीडबैक मैसेज -->
    <div id="loading_msg">डाउनलोड शुरू हो रहा है...</div>

    <!-- सुधरा हुआ डाउनलोड बटन -->
    <button onclick="startDownload()" class="btn-download">
        <i class="fa-solid fa-cloud-arrow-down"></i> मुफ़्त डाउनलोड करें
    </button>

    <!-- छुपा हुआ फ्रेम जो फाइल को खींचेगा -->
    <iframe id="download_frame"></iframe>

    <div class="auth-container">
        <h3>स्टूडेंट लॉगिन</h3>
        <input type="email" placeholder="ईमेल आईडी">
        <input type="password" placeholder="6-अंकों का पिन">
        <button class="btn-submit">प्रवेश करें</button>
        <p style="margin-top:15px; font-size: 0.8rem; color: var(--cyan); cursor: pointer;">नया रजिस्ट्रेशन यहाँ करें</p>
    </div>

    <div class="footer">
        Padh-Ai Robotics Education • Made in India
    </div>

    <script>
        function startDownload() {
            const downloadUrl = "https://github.com/sonwaniv842-cell/Padh-Ai/releases/latest/download/app-release.apk";
            const loadingMsg = document.getElementById('loading_msg');
            const dlFrame = document.getElementById('download_frame');

            // 1. फीडबैक दिखाएं
            loadingMsg.style.display = "block";
            
            // 2. फ्रेम में लिंक लोड करें (इससे नया टैब नहीं खुलेगा)
            dlFrame.src = downloadUrl;

            // 3. 5 सेकंड बाद मैसेज छुपाएं
            setTimeout(() => {
                loadingMsg.style.display = "none";
            }, 5000);
        }
    </script>

</body>
</html>
