package com.mru.bi;

import org.springframework.ai.chat.client.ChatClient;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;

import java.time.LocalDate;

/** NL2SQL pipeline: question + schema + history -> LLM -> validate -> execute -> pick chart. */
@Service
public class NlToSqlService {
    private static final String SYSTEM = """
            You are a business-intelligence analyst that writes MySQL 8 queries.
            Today's date is {today}.

            Database schema:
            {schema}

            Rules:
            - Write exactly one read-only SELECT statement. Use only the tables and columns listed above.
            - Previous questions in this session are given. If the new question is a follow-up
              (for example "now only for Q2"), modify the previous SQL instead of starting over.
            - Give result columns short readable aliases (name, sales, revenue, region, month).
            - Group by month with DATE_FORMAT(sale_date, '%Y-%m') AS month and order it ascending.
            - Resolve relative periods (last quarter, this year) from today's date.
            - Return at most 100 rows unless the user asks for more.
            - sql: the query. reply: one friendly sentence describing the answer.
              chartHint: one of bar, line, pie, table.
            - If the question cannot be answered from this schema, leave sql empty and explain in reply.
            """;

    private final ChatClient chat;
    private final SchemaProvider schema;
    private final ContextManager context;
    private final SqlValidator validator;
    private final QueryExecutor executor;
    private final VisualizationSelector selector;

    public NlToSqlService(ChatClient.Builder builder, SchemaProvider schema, ContextManager context,
                          SqlValidator validator, QueryExecutor executor, VisualizationSelector selector) {
        this.chat = builder.build();
        this.schema = schema;
        this.context = context;
        this.validator = validator;
        this.executor = executor;
        this.selector = selector;
    }

    public Dto.ChatResponse answer(String sessionId, String question) {
        String history = context.render(sessionId);
        Dto.SqlPlan plan = ask(question, history, null, null);
        if (plan.sql() == null || plan.sql().isBlank())
            return new Dto.ChatResponse(plan.reply(), null, "table", java.util.List.of(), java.util.List.of(), null);

        for (int attempt = 0; attempt < 2; attempt++) {
            try {
                String sql = validator.validate(plan.sql());
                Dto.QueryResult result = executor.run(sql);
                context.add(sessionId, question, sql);
                return new Dto.ChatResponse(plan.reply(), sql, selector.choose(result, plan.chartHint()),
                        result.columns(), result.rows(), null);
            } catch (SqlValidator.UnsafeSqlException e) {
                return Dto.ChatResponse.failure(e.getMessage());
            } catch (DataAccessException e) {
                if (attempt == 1) return Dto.ChatResponse.failure("The query could not be run: " + e.getMostSpecificCause().getMessage());
                plan = ask(question, history, plan.sql(), e.getMostSpecificCause().getMessage()); // one self-repair attempt
            }
        }
        return Dto.ChatResponse.failure("Something went wrong. Please rephrase the question.");
    }

    private Dto.SqlPlan ask(String question, String history, String failedSql, String dbError) {
        String user = "Previous questions:\n" + history + "\nNew question: " + question
                + (failedSql == null ? "" : "\n\nYour previous SQL failed.\nSQL: " + failedSql + "\nMySQL error: " + dbError + "\nFix it.");
        return chat.prompt()
                .system(s -> s.text(SYSTEM).param("today", LocalDate.now().toString()).param("schema", schema.describe()))
                .user(u -> u.text("{input}").param("input", user))   // params are not parsed as templates
                .call()
                .entity(Dto.SqlPlan.class);
    }
}
