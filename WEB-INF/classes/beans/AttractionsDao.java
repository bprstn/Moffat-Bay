package beans;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AttractionsDao {
    private static final String URL =
        "jdbc:mysql://127.0.0.1:3306/moffatbay?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&connectTimeout=5000&socketTimeout=5000";
    private static final String USER = "moffatbay";
    private static final String PASS = "moffatbay";

    private Connection getConnection() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(URL, USER, PASS);
    }

    /** Return all attractions ordered similar to your featured cards (by name). */
    public List<Attraction> listAll() throws Exception {
        String sql = "SELECT id, name, category, description, meta, cta_text, cta_anchor, phone, open_hours " +
                     "FROM attractions ORDER BY name";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            List<Attraction> out = new ArrayList<>();
            while (rs.next()) out.add(map(rs));
            return out;
        }
    }

    /** Optional: filter by category to group cards. */
    public List<Attraction> listByCategory(String category) throws Exception {
        String sql = "SELECT id, name, category, description, meta, cta_text, cta_anchor, phone, open_hours " +
                     "FROM attractions WHERE category = ? ORDER BY name";
        try (Connection c = getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, category);
            try (ResultSet rs = ps.executeQuery()) {
                List<Attraction> out = new ArrayList<>();
                while (rs.next()) out.add(map(rs));
                return out;
            }
        }
    }

    // --- helpers ---
    private static Attraction map(ResultSet rs) throws SQLException {
        Attraction a = new Attraction();
        a.setId(rs.getInt("id"));
        a.setName(rs.getString("name"));
        a.setCategory(rs.getString("category"));
        a.setDescription(rs.getString("description"));
        a.setMeta(rs.getString("meta"));
        a.setCtaText(rs.getString("cta_text"));
        a.setCtaAnchor(rs.getString("cta_anchor"));
        a.setPhone(rs.getString("phone"));
        a.setOpenHours(rs.getString("open_hours"));
        return a;
    }
}
