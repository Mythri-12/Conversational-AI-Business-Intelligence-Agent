package com.mru.bi;

import org.springframework.stereotype.Component;

import java.util.regex.Pattern;

/** Rejects anything that is not a single, read-only SELECT before it reaches the database. */
@Component
public class SqlValidator {
    public static class UnsafeSqlException extends RuntimeException {
        public UnsafeSqlException(String message) { super(message); }
    }

    private static final Pattern START = Pattern.compile("^(select|with)\\b", Pattern.CASE_INSENSITIVE);
    private static final Pattern FORBIDDEN = Pattern.compile(
            "\\b(insert|update|delete|drop|alter|truncate|create|grant|revoke|rename|call|handler|load_file|sleep|benchmark)\\b"
            + "|into\\s+(outfile|dumpfile)|replace\\s+into|#",
            Pattern.CASE_INSENSITIVE);

    public String validate(String raw) {
        if (raw == null || raw.isBlank()) throw new UnsafeSqlException("No SQL was generated.");
        String sql = raw.strip()
                .replaceAll("(?is)^```(?:sql)?", "").replaceAll("(?s)```$", "")
                .replaceAll("(?s)/\\*.*?\\*/", "").replaceAll("(?m)--.*$", "").strip();
        while (sql.endsWith(";")) sql = sql.substring(0, sql.length() - 1).strip();
        if (sql.contains(";")) throw new UnsafeSqlException("Only one SQL statement is allowed.");
        if (!START.matcher(sql).find()) throw new UnsafeSqlException("Only SELECT queries are allowed.");
        if (FORBIDDEN.matcher(sql).find())
            throw new UnsafeSqlException("The generated query contained a blocked keyword and was not run.");
        return sql;
    }
}
