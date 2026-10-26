import {
  Bar, BarChart, CartesianGrid, Cell, Legend, Line, LineChart, Pie, PieChart,
  ResponsiveContainer, Tooltip, XAxis, YAxis,
} from "recharts";

const COLORS = ["#2f6157", "#c9822b", "#4f7cac", "#a24e6b", "#7a8f3c", "#6d5ba8"];
const fmt = (v) => (typeof v === "number" ? v.toLocaleString() : v);
const isNum = (rows, c) => rows.length > 0 && typeof rows[0][c] === "number";

/** Long format (x, group, value) -> wide format so each group becomes its own series. */
function shape(columns, rows) {
  if (columns.length === 3 && !isNum(rows, columns[1]) && isNum(rows, columns[2])) {
    const [x, g, v] = columns;
    const byX = new Map();
    const series = [];
    rows.forEach((r) => {
      if (!series.includes(r[g])) series.push(r[g]);
      byX.set(r[x], { ...(byX.get(r[x]) || { [x]: r[x] }), [r[g]]: r[v] });
    });
    return { xKey: x, series, data: [...byX.values()] };
  }
  return { xKey: columns[0], series: columns.slice(1).filter((c) => isNum(rows, c)), data: rows };
}

export default function Chart({ type, columns, rows }) {
  if (type === "table" || rows.length === 0) return null;

  if (type === "pie") {
    const [name, value] = columns;
    return (
      <ResponsiveContainer width="100%" height={320}>
        <PieChart>
          <Pie data={rows} dataKey={value} nameKey={name} outerRadius={120} label>
            {rows.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
          </Pie>
          <Tooltip formatter={fmt} />
          <Legend />
        </PieChart>
      </ResponsiveContainer>
    );
  }

  const { xKey, series, data } = shape(columns, rows);
  const Plot = type === "line" ? LineChart : BarChart;
  return (
    <ResponsiveContainer width="100%" height={320}>
      <Plot data={data} margin={{ top: 8, right: 16, left: 0, bottom: 4 }}>
        <CartesianGrid stroke="#e4e6df" vertical={false} />
        <XAxis dataKey={xKey} tick={{ fontSize: 12 }} />
        <YAxis tick={{ fontSize: 12 }} tickFormatter={fmt} />
        <Tooltip formatter={fmt} />
        {series.length > 1 && <Legend />}
        {series.map((s, i) =>
          type === "line"
            ? <Line key={s} type="monotone" dataKey={s} stroke={COLORS[i % COLORS.length]} strokeWidth={2} dot={false} />
            : <Bar key={s} dataKey={s} fill={COLORS[i % COLORS.length]} radius={[2, 2, 0, 0]} />
        )}
      </Plot>
    </ResponsiveContainer>
  );
}
