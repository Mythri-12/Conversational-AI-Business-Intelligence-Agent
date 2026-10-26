# Conversational AI Business Intelligence Agent
Batch 118 · Malla Reddy University · Guide: Mr. Srikanth Dasari

Ask business questions in plain English. The app converts them to SQL, runs them on a read-only MySQL
database, and shows the result as a chart and a table. Follow-ups ("now only for Q2") work in the same session.

```
React (Vite) --/api/chat--> Spring Boot + Spring AI --> LLM (SQL)
                                  |                         
                     SqlValidator (SELECT only) --> MySQL (SELECT-only user)
```

## Setup
Requirements: JDK 17+, Maven, Node 18+, MySQL 8+, a free Gemini API key (get one at https://aistudio.google.com).

1. **Database** — open `database/schema_and_seed.sql` in MySQL Workbench and run it. It creates `bi_demo`
   (regions, products, customers, sales), 900 sample sales, and the read-only user `bi_readonly`.
2. **Backend**
   ```
   cd backend
   set GEMINI_API_KEY=your-key        (Windows CMD)   |   $env:GEMINI_API_KEY="your-key"  (PowerShell)
   mvn spring-boot:run
   ```
   Runs on http://localhost:8080. DB credentials are in `src/main/resources/application.properties`.
3. **Frontend**
   ```
   cd frontend
   npm install
   npm run dev
   ```
   Open http://localhost:5173.

## Changing the LLM provider
The app uses Spring AI's OpenAI-compatible client, so the provider is set only in `application.properties`.
Gemini is the default; a commented Groq block is included as a backup (set `GROQ_API_KEY`). No Java changes needed.

## Where each project module lives
| Module (from your slides) | File |
|---|---|
| NL2SQL (Spring AI ChatClient) | `NlToSqlService.java` |
| Schema metadata for the LLM | `SchemaProvider.java` |
| Validation layer (SELECT-only) | `SqlValidator.java` |
| Query execution (Spring JDBC) | `QueryExecutor.java` |
| Context manager (follow-ups) | `ContextManager.java` |
| Visualization engine | `VisualizationSelector.java` + `frontend/src/Chart.jsx` |
| REST API | `ChatController.java` |

## Security layers
1. The DB account has `SELECT` privilege only.
2. `SqlValidator` allows one statement, starting with SELECT/WITH, and blocks INSERT/UPDATE/DELETE/DROP etc.
3. Row limit (500) and 10-second query timeout in `QueryExecutor`.
4. The API key is read from an environment variable, never stored in code.

## Try these
- Show the top 5 selling products
- Compare monthly sales by region
- Display last quarter's revenue → then: *now break it down by region*
- Show sales distribution by region
