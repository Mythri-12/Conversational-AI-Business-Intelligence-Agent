package com.mru.bi;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.sql.ResultSetMetaData;
import java.util.*;

/** Runs validated SQL over the read-only connection and converts the result to JSON-friendly maps. */
@Component
public class QueryExecutor {
    private final JdbcTemplate jdbc;

    public QueryExecutor(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
        this.jdbc.setMaxRows(500);
        this.jdbc.setQueryTimeout(10);
    }

    public Dto.QueryResult run(String sql) {
        return jdbc.query(sql, rs -> {
            ResultSetMetaData md = rs.getMetaData();
            List<String> columns = new ArrayList<>();
            for (int i = 1; i <= md.getColumnCount(); i++) columns.add(md.getColumnLabel(i));
            List<Map<String, Object>> rows = new ArrayList<>();
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                for (int i = 1; i <= columns.size(); i++) {
                    Object v = rs.getObject(i);
                    row.put(columns.get(i - 1),
                            (v == null || v instanceof Number || v instanceof Boolean || v instanceof String) ? v : v.toString());
                }
                rows.add(row);
            }
            return new Dto.QueryResult(columns, rows);
        });
    }
}
