# TestsPrep.in – AI‑powered test‑prep platform (public repo)

**Repo:** https://github.com/inbharatai/testsprep.in

**Key public features (from the README):**
- **Unlimited AI‑generated questions** – generate practice items for any exam.
- **Real‑time web‑enriched answers** – answers pull the latest info from the web.
- **3D interactive science labs** – hands‑on virtual labs for physics/chemistry.
- **Built‑in AI/Python IDE** – write, run, and get AI feedback on code.
- **Daily GK digest + exam deadlines** – stay updated on current affairs and upcoming test dates.
- **110‑question psychometric diagnostic** – career‑path guidance based on a comprehensive questionnaire.
- **School dashboard + parent alerts** – teachers can monitor progress; parents receive concise alerts.
- **Gamification (XP, streaks, badges)** – motivates consistent study.
- **DOCX report export** – export performance reports for students/parents.
- **WhatsApp AI tutor (UniBot)** – get on‑demand help via WhatsApp.

**Tech stack**
- Node.js 18+, PostgreSQL, OpenAI API, Serper API (for live web search).
- NextAuth v5 for secure authentication (JWT + session management).
- Prisma for DB schema and migrations.
- Deployable via Vercel or any Node‑compatible host.

**Installation (quick start)**
```bash
git clone https://github.com/inbharatai/testsprep.in.git
cd testsprep.in
npm install
cp .env.example .env   # fill in OpenAI & Serper keys
npm run dev   # → http://localhost:3000
```

**License** – MIT (free to use, modify, distribute).

**Public positioning** – marketed as a competitor to Khan Academy and generic AI‑question generators, but with deeper Indian‑exam coverage (JEE, NEET, UPSC, etc.) and integrated policy‑simulation style dashboards.
