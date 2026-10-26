package com.mru.bi;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Set;
import java.util.regex.Pattern;

/** Picks bar / line / pie / table from the shape of the result (the LLM's hint is used only if it fits). */
@Component
public class VisualizationSelector {
    private static final Pattern DATE_LIKE = Pattern.compile("^\\d{4}(-\\d{2})?(-\\d{2})?$|^\\d{4}-Q[1-4]$");
    private static final Set<String> TIME_WORDS = Set.of("month", "date", "day", "week", "quarter", "year", "period");

    public String choose(Dto.QueryResult r, String hint) {
        if (r.rows().size() < 2 || r.columns().size() < 2 || !hasNumeric(r)) return "table";
        String first = r.columns().get(0).toLowerCase();
        Object sample = r.rows().get(0).get(r.columns().get(0));
        boolean temporal = TIME_WORDS.stream().anyMatch(first::contains)
                || (sample instanceof String s && DATE_LIKE.matcher(s).matches());
        boolean pieOk = r.columns().size() == 2 && r.rows().size() <= 8;

        String h = hint == null ? "" : hint.toLowerCase();
        if (h.equals("table")) return "table";
        if (h.equals("pie") && pieOk) return "pie";
        if (h.equals("line") && temporal) return "line";
        if (h.equals("bar")) return "bar";
        return temporal ? "line" : "bar";
    }

    private boolean hasNumeric(Dto.QueryResult r) {
        Map<String, Object> row = r.rows().get(0);
        return r.columns().stream().skip(1).anyMatch(c -> row.get(c) instanceof Number);
    }
}
