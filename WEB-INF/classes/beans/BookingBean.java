package beans;

import java.sql.Connection;
import java.sql.Date;              // <-- use java.sql.Date explicitly
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.sql.Statement;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class BookingBean {

    // --- Same connection approach as your other beans ---
    public static Connection getConnection() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return java.sql.DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/moffatbay?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
            "moffatbay",
            "moffatbay"
        );
    }

    /** List room types for the booking form. */
    public List<Map<String,Object>> listRoomTypes() throws Exception {
        final String sql =
            "SELECT id, code, name, nightly_rate, capacity, inventory_count " +
            "FROM room_types ORDER BY nightly_rate ASC, name ASC";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rowsFromResultSet(rs);
        }
    }

    /** Quote total = nightly_rate * max(nights, 1). */
    public double quoteTotal(int roomTypeId, Date checkIn, Date checkOut) throws Exception {
        final String sql =
            "SELECT nightly_rate * GREATEST(DATEDIFF(?, ?), 1) AS total " +
            "FROM room_types WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, checkOut);
            ps.setDate(2, checkIn);
            ps.setInt(3, roomTypeId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getDouble("total");
            }
        }
        return 0.0;
    }

    /** Current nightly rate for a room type. */
    public double getNightlyRate(int roomTypeId) throws Exception {
        final String sql = "SELECT nightly_rate FROM room_types WHERE id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, roomTypeId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getDouble(1);
            }
        }
        return 0.0;
    }

    /** Capacity + inventory availability check for overlapping dates. */
    public boolean isAvailable(int roomTypeId, Date checkIn, Date checkOut, int guests) throws Exception {
        final String capSql = "SELECT capacity, inventory_count FROM room_types WHERE id = ?";
        int capacity = 0, inventory = 0;

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(capSql)) {

            ps.setInt(1, roomTypeId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return false;
                capacity = rs.getInt("capacity");
                inventory = rs.getInt("inventory_count");
            }

            if (guests < 1 || guests > capacity) return false;

            // Overlap if: new_start < existing_end AND new_end > existing_start
            final String overlapSql =
                "SELECT COUNT(*) AS active " +
                "FROM reservations r " +
                "WHERE r.room_type_id = ? " +
                "  AND r.status <> 'CANCELLED' " +
                "  AND ? < r.check_out " +
                "  AND ? > r.check_in";

            try (PreparedStatement ps2 = conn.prepareStatement(overlapSql)) {
                ps2.setInt(1, roomTypeId);
                ps2.setDate(2, checkIn);   // compare: checkIn < existing.check_out
                ps2.setDate(3, checkOut);  // compare: checkOut > existing.check_in
                try (ResultSet rs2 = ps2.executeQuery()) {
                    if (rs2.next()) {
                        int active = rs2.getInt("active");
                        return active < inventory;
                    }
                }
            }
        }
        return false;
    }

    /**
     * Create reservation; returns new reservation id (>0) or 0 on failure.
     * Sets status = 'CONFIRMED' if available.
     */
    public long createReservation(long customerId, int roomTypeId, Date checkIn, Date checkOut, int guests) throws Exception {
        if (customerId <= 0 || roomTypeId <= 0 || checkIn == null || checkOut == null || !checkIn.before(checkOut)) {
            return 0L;
        }
        if (!isAvailable(roomTypeId, checkIn, checkOut, guests)) {
            return 0L;
        }

        double rate = getNightlyRate(roomTypeId);
        double total = quoteTotal(roomTypeId, checkIn, checkOut);

        final String sql =
            "INSERT INTO reservations " +
            "(customer_id, room_type_id, check_in, check_out, guests, status, rate_at_booking, total_price) " +
            "VALUES (?, ?, ?, ?, ?, 'CONFIRMED', ?, ?)";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setLong(1, customerId);
            ps.setInt(2, roomTypeId);
            ps.setDate(3, checkIn);
            ps.setDate(4, checkOut);
            ps.setInt(5, guests);
            ps.setDouble(6, rate);
            ps.setDouble(7, total);

            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getLong(1);
            }
            return 0L;

        } catch (SQLException ex) {
            if ("23000".equals(ex.getSQLState())) return 0L; // integrity violation
            throw ex;
        }
    }

    // --- helpers ---
    private static List<Map<String,Object>> rowsFromResultSet(ResultSet rs) throws SQLException {
        List<Map<String,Object>> list = new ArrayList<>();
        ResultSetMetaData meta = rs.getMetaData();
        int cols = meta.getColumnCount();
        while (rs.next()) {
            Map<String,Object> row = new LinkedHashMap<>();
            for (int i = 1; i <= cols; i++) {
                String key = meta.getColumnLabel(i);
                if (key == null || key.isEmpty()) key = meta.getColumnName(i);
                row.put(key, rs.getObject(i));
            }
            list.add(row);
        }
        return list;
    }
}
