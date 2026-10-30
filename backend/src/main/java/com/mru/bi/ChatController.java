package com.mru.bi;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api")
public class ChatController {
    private static final Logger log = LoggerFactory.getLogger(ChatController.class);
    private final NlToSqlService service;

    public ChatController(NlToSqlService service) { this.service = service; }

    @PostMapping("/chat")
    public Dto.ChatResponse chat(@RequestBody Dto.ChatRequest req) {
        if (req.message() == null || req.message().isBlank())
            return Dto.ChatResponse.failure("Type a business question first.");
        String session = req.sessionId() == null ? "default" : req.sessionId();
        try {
            return service.answer(session, req.message().strip());
        } catch (Exception e) {
            log.error("Chat request failed", e);
            return Dto.ChatResponse.failure("The AI service did not respond. Check GEMINI_API_KEY and the database connection, then try again. Cause: " + rootCause(e));
        }
    }

    /** Shortest useful description of what actually failed. */
    private static String rootCause(Throwable t) {
        while (t.getCause() != null && t.getCause() != t) t = t.getCause();
        String msg = t.getMessage() == null ? "" : t.getMessage().replaceAll("\\s+", " ");
        return t.getClass().getSimpleName() + (msg.isBlank() ? "" : ": " + (msg.length() > 300 ? msg.substring(0, 300) : msg));
    }

    @GetMapping("/health")
    public Map<String, String> health() { return Map.of("status", "ok"); }
}
