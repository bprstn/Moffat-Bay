// File: WEB-INF/classes/beans/SigninBean.java
package beans;

import java.sql.*;
import java.util.Base64;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

public class SigninBean {

    // --- DB Connection (same as CustomerBean) ---
    public static Connection getConnection() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/moffatbay?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
            "moffatbay",
            "moffatbay"
        );
    }

    /**
     * Attempt to authenticate a user by email + password.
     * @return the customer id (>0) on success; 0 if invalid credentials.
     */
    public long authenticate(String email, String plainPassword) throws Exception {
        if (email == null || plainPassword == null) return 0L;
        String normalized = email.trim().toLowerCase();
        final String sql = "SELECT id, password_hash, first_name, last_name FROM customers WHERE email = ? LIMIT 1";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, normalized);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return 0L;
                long id = rs.getLong("id");
                String stored = rs.getString("password_hash");
                if (verifyPassword(plainPassword, stored)) {
                    return id;
                }
                return 0L;
            }
        }
    }

    // ---- Password verification (supports both formats we used in CustomerBean) ----

    public static boolean verifyPassword(String plain, String stored) {
        if (stored == null || plain == null) return false;
        String[] parts = stored.split("\\$");
        try {
            // New format: pbkdf2$<algo>$<iter>$<salt>$<hash>
            if (parts.length == 5 && "pbkdf2".equals(parts[0])) {
                String algo = parts[1];
                int iter = Integer.parseInt(parts[2]);
                byte[] salt = Base64.getDecoder().decode(parts[3]);
                byte[] expected = Base64.getDecoder().decode(parts[4]);
                byte[] actual = pbkdf2(plain.toCharArray(), salt, iter, expected.length, algo);
                return slowEquals(expected, actual);
            }
            // Legacy format: pbkdf2_sha256$<iter>$<salt>$<hash>
            if (parts.length == 4 && "pbkdf2_sha256".equals(parts[0])) {
                int iter = Integer.parseInt(parts[1]);
                byte[] salt = Base64.getDecoder().decode(parts[2]);
                byte[] expected = Base64.getDecoder().decode(parts[3]);
                byte[] actual = pbkdf2(plain.toCharArray(), salt, iter, expected.length, "PBKDF2WithHmacSHA256");
                return slowEquals(expected, actual);
            }
        } catch (Exception e) {
            return false;
        }
        return false;
    }

    private static byte[] pbkdf2(char[] password, byte[] salt, int iterations, int bytes, String algo) 
            throws NoSuchAlgorithmException, InvalidKeySpecException {
        PBEKeySpec spec = new PBEKeySpec(password, salt, iterations, bytes * 8);
        SecretKeyFactory skf = SecretKeyFactory.getInstance(algo);
        return skf.generateSecret(spec).getEncoded();
    }

    private static boolean slowEquals(byte[] a, byte[] b) {
        if (a == null || b == null || a.length != b.length) return false;
        int diff = 0;
        for (int i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
        return diff == 0;
    }
}
