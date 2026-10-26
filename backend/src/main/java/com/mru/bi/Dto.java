package com.mru.bi;

import java.util.List;
import java.util.Map;

/** Request/response shapes shared by the REST API and the LLM. */
public class Dto {
    public record ChatRequest(String sessionId, String message) {}

    public record ChatResponse(String reply, String sql, String chartType,
                               List<String> columns, List<Map<String, Object>> rows, String error) {
        static ChatResponse failure(String message) {
            return new ChatResponse(null, null, "table", List.of(), List.of(), message);
        }
    }

    /** What the LLM must return: SQL, a one-line answer, and a chart suggestion. */
    public record SqlPlan(String sql, String reply, String chartHint) {}

    public record QueryResult(List<String> columns, List<Map<String, Object>> rows) {}
}
