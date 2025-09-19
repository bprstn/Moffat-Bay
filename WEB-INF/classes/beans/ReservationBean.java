// File: WEB-INF/classes/beans/ReservationBean.java
package beans;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ReservationBean {

    // --- DB connection (same style as your other beans) ---
    public static Connection getConnection() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/moffatbay?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
            "moffatbay",
            "moffatbay"
        );
    }

    /**
     * Fetch reservations for a customer, joined to room_types for friendly fields.
     * reservations: id, customer_id, room_type_id, check_in, check_out, guests, status,
     *               rate_at_booking, total_price, created_at
     * room_types:   id, code, name, nightly_rate, capacity, inventory_count, description
     *
     * Aliases provided:
     *  - room_types.code  -> room_code
     *  - room_types.name  -> room_name
     *  - room_types.nightly_rate -> current_rate
     *  - room_types.capacity     -> room_capacity
     */
    public List<Map<String,Object>> findByCustomerId(long customerId) throws Exception {
        final String sql =
            "SELECT " +
            "  r.id, r.customer_id, r.room_type_id, r.check_in, r.check_out, r.guests, r.status, " +
            "  r.rate_at_booking, r.total_price, r.created_at, " +
            "  t.code AS room_code, t.name AS room_name, " +
            "  t.nightly_rate AS current_rate, t.capacity AS room_capacity " +
            "FROM reservations r " +
            "LEFT JOIN room_types t ON r.room_type_id = t.id " +
            "WHERE r.customer_id = ? " +
            "ORDER BY r.check_in DESC";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                return rowsFromResultSet(rs);
            }
        }
    }

    /** Hard delete a reservation that belongs to this customer. */
    public boolean deleteReservation(long customerId, long reservationId) throws Exception {
        final String sql = "DELETE FROM reservations WHERE id = ? AND customer_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, reservationId);
            ps.setLong(2, customerId);
            return ps.executeUpdate() > 0;
        }
    }

    /** Soft delete: set status to CANCELLED (only if it belongs to this customer). */
    public boolean cancelReservation(long customerId, long reservationId) throws Exception {
        final String sql = "UPDATE reservations SET status = 'CANCELLED' WHERE id = ? AND customer_id = ?";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, reservationId);
            ps.setLong(2, customerId);
            return ps.executeUpdate() > 0;
        }
    }

    // --- helper: turn a ResultSet into a list of maps (columnLabel -> value) ---
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
    
    /**
     * Added 9/19/25
     * Get data from customers, room_types, and reservation tables from a reservationID. 
     * reservations : id, total_price, check_in, guests
     * customers: email, first_name, last_name
     * room_types: name, description
     * @param reservationID
     * @return rs
     * @throws Exception
     */
    public List<Map<String,Object>> getReservationInfoFromID(long reservationID) throws Exception {
        final String sql =
        	"SELECT " + 
        	" r.id, r.total_price, r.check_in, r.check_out, r.guests, " +
        	" c.email, c.first_name, c.last_name, " +
        	" s.name, s.description " +
        	" FROM reservations AS r " +
        	" Left join room_types s ON r.room_type_id = s.id " +
        	" LEFT JOIN customers c ON c.id = r.customer_id " + 
        	" WHERE r.id = ?";
        
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, reservationID);
            try (ResultSet rs = ps.executeQuery()) {
                return rowsFromResultSet(rs);
            }
        }
    }
}
