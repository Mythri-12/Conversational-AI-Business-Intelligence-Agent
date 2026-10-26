package com.mru.bi;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.*;

/** Reads table/column/foreign-key metadata so the LLM is grounded in the real schema. */
@Component
public class SchemaProvider {
    private final JdbcTemplate jdbc;
    private volatile String cached;

    public SchemaProvider(JdbcTemplate jdbc) { this.jdbc = jdbc; }

    public String describe() {
        if (cached == null) {
            Map<String, List<String>> tables = new LinkedHashMap<>();
            jdbc.query("SELECT table_name, column_name, column_type FROM information_schema.columns "
                    + "WHERE table_schema = DATABASE() ORDER BY table_name, ordinal_position", rs -> {
                tables.computeIfAbsent(rs.getString(1), k -> new ArrayList<>())
                      .add(rs.getString(2) + " " + rs.getString(3));
            });
            StringBuilder sb = new StringBuilder();
            tables.forEach((t, cols) -> sb.append(t).append("(").append(String.join(", ", cols)).append(")\n"));
            jdbc.query("SELECT table_name, column_name, referenced_table_name, referenced_column_name "
                    + "FROM information_schema.key_column_usage "
                    + "WHERE table_schema = DATABASE() AND referenced_table_name IS NOT NULL", rs -> {
                sb.append("FK: ").append(rs.getString(1)).append(".").append(rs.getString(2))
                  .append(" -> ").append(rs.getString(3)).append(".").append(rs.getString(4)).append("\n");
            });
            cached = sb.toString();
        }
        return cached;
    }
}
