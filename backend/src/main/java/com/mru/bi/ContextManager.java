package com.mru.bi;

import org.springframework.stereotype.Component;

import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedDeque;

/** Session-based memory so follow-ups like "now only for Q2" work. Keeps the last 5 turns. */
@Component
public class ContextManager {
    public record Turn(String question, String sql) {}

    private static final int MAX_TURNS = 5;
    private final Map<String, Deque<Turn>> sessions = new ConcurrentHashMap<>();

    public void add(String sessionId, String question, String sql) {
        Deque<Turn> turns = sessions.computeIfAbsent(sessionId, k -> new ConcurrentLinkedDeque<>());
        turns.addLast(new Turn(question, sql));
        while (turns.size() > MAX_TURNS) turns.pollFirst();
    }

    public String render(String sessionId) {
        Deque<Turn> turns = sessions.get(sessionId);
        if (turns == null || turns.isEmpty()) return "(no previous questions)";
        StringBuilder sb = new StringBuilder();
        for (Turn t : turns) sb.append("Q: ").append(t.question()).append("\nSQL: ").append(t.sql()).append("\n");
        return sb.toString();
    }
}
