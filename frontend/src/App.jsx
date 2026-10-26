import { useEffect, useRef, useState } from "react";
import Chart from "./Chart.jsx";

const SUGGESTIONS = [
  "Show the top 5 selling products",
  "Compare monthly sales by region",
  "Display last quarter's revenue",
  "Show sales distribution by region",
];

export default function App() {
  const sessionId = useRef(crypto.randomUUID());
  const logRef = useRef(null);
  const [messages, setMessages] = useState([
    { from: "bot", text: 'Ask me a business question — try "Show the top 5 selling products".' },
  ]);
  const [input, setInput] = useState("");
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState(null);
  const [showSql, setShowSql] = useState(true);

  useEffect(() => {
    logRef.current?.scrollTo({ top: logRef.current.scrollHeight });
  }, [messages, busy]);

  async function send(text) {
    const question = text.trim();
    if (!question || busy) return;
    setInput("");
    setBusy(true);
    setMessages((m) => [...m, { from: "user", text: question }]);
    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ sessionId: sessionId.current, message: question }),
      });
      const data = await res.json();
      if (data.error) {
        setMessages((m) => [...m, { from: "bot", text: data.error, error: true }]);
      } else {
        setMessages((m) => [...m, { from: "bot", text: data.reply }]);
        if (data.sql) setResult(data);
      }
    } catch {
      setMessages((m) => [...m, { from: "bot", text: "Can't reach the server. Start the backend on port 8080 and try again.", error: true }]);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="app">
      <header>
        <strong>BI Assistant</strong> <span>conversational query layer</span>
      </header>

      <aside className="chat">
        <div className="log" ref={logRef} aria-live="polite">
          {messages.map((m, i) => (
            <p key={i} className={`bubble ${m.from} ${m.error ? "error" : ""}`}>{m.text}</p>
          ))}
          {busy && <p className="bubble bot">Working on it…</p>}
        </div>
        <form onSubmit={(e) => { e.preventDefault(); send(input); }}>
          <input value={input} onChange={(e) => setInput(e.target.value)} placeholder="Ask a business question…" aria-label="Business question" />
          <button disabled={busy || !input.trim()}>Send</button>
        </form>
        <div className="chips">
          {SUGGESTIONS.map((s) => (
            <button key={s} type="button" onClick={() => send(s)} disabled={busy}>{s}</button>
          ))}
        </div>
      </aside>

      <main className="dashboard">
        <h2>Dashboard</h2>
        {!result ? (
          <div className="empty">Ask a question in the chat to see a visualization here.</div>
        ) : (
          <>
            <section className="sql">
              <div className="sql-head">
                <span>generated_query.sql</span>
                <button type="button" onClick={() => setShowSql((s) => !s)}>{showSql ? "hide" : "show"}</button>
              </div>
              {showSql && <pre>{result.sql}</pre>}
            </section>
            <Chart type={result.chartType} columns={result.columns} rows={result.rows} />
            <div className="table-wrap">
              <table>
                <thead><tr>{result.columns.map((c) => <th key={c}>{c}</th>)}</tr></thead>
                <tbody>
                  {result.rows.map((r, i) => (
                    <tr key={i}>{result.columns.map((c) => <td key={c}>{typeof r[c] === "number" ? r[c].toLocaleString() : String(r[c] ?? "")}</td>)}</tr>
                  ))}
                </tbody>
              </table>
            </div>
          </>
        )}
      </main>
    </div>
  );
}
