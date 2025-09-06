// File: WEB-INF/classes/beans/CustomerBean.java
package beans;

import java.sql.*;
import java.util.Base64;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.security.NoSuchAlgorithmException;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/**
 * CustomerBean - registration + duplicate-email check for Moffat Bay.
 * - No java.time import (works on older JREs)
 * - DB access via static getConnection()
 * - Password hashing via PBKDF2 with algorithm fallback (SHA256 → SHA512 → SHA1)
 * - Stored format: pbkdf2$<algo>$<iterations>$<base64(salt)>$<base64(hash)>
 */
public class CustomerBean {

    // --- DB Connection ---
    public static Connection getConnection() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        return DriverManager.getConnection(
            "jdbc:mysql://localhost:3306/moffatbay?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC",
            "moffatbay",
            "moffatbay"
        );
    }

    // ---- PBKDF2 settings ----
    private static final String[] PBKDF2_ALGOS = {
        "PBKDF2WithHmacSHA256",
        "PBKDF2WithHmacSHA512",
        "PBKDF2WithHmacSHA1"
    };
    private static final int SALT_BYTES = 16;
    private static final int HASH_BYTES = 32;  // 256-bit output target
    private static final int ITERATIONS = 120_000;

    /** True if an account with this email exists (case-insensitive). */
    public boolean emailExists(String email) throws Exception {
        String normalized = normalizeEmail(email);
        final String sql = "SELECT 1 FROM customers WHERE email = ? LIMIT 1";
        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, normalized);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Registers a new customer; returns new id (>0) on success, 0 on failure/duplicate.
     * Lets MySQL fill created_at via DEFAULT CURRENT_TIMESTAMP.
     */
    public long registerCustomer(String firstName,
                                 String lastName,
                                 String email,
                                 String phone,
                                 String plainPassword) throws Exception {
        String normalizedEmail = normalizeEmail(email);
        if (isEmpty(firstName) || isEmpty(lastName) || isEmpty(normalizedEmail) || isEmpty(plainPassword)) {
            return 0L;
        }

        String passwordHash = hashPassword(plainPassword);

        final String sql = "INSERT INTO customers (email, first_name, last_name, phone, password_hash) " +
                           "VALUES (?, ?, ?, ?, ?)";

        try (Connection conn = getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1, normalizedEmail);
            ps.setString(2, firstName.trim());
            ps.setString(3, lastName.trim());
            ps.setString(4, emptyToNull(phone));
            ps.setString(5, passwordHash);

            ps.executeUpdate();

            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) return keys.getLong(1);
            }
            return 0L;

        } catch (SQLException ex) {
            // 23000 = integrity constraint violation (e.g., duplicate email)
            if ("23000".equals(ex.getSQLState())) return 0L;
            throw ex;
        }
    }

    // ---- Utilities ----
    private static String normalizeEmail(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }
    private static boolean isEmpty(String s) { return s == null || s.trim().isEmpty(); }
    private static String emptyToNull(String s) {
        String t = (s == null ? null : s.trim());
        return (t == null || t.isEmpty()) ? null : t;
        }

    // ---- Hashing / Verification ----

    private static String hashPassword(String plain) {
        byte[] salt = new byte[SALT_BYTES];
        new SecureRandom().nextBytes(salt);

        DeriveResult dr = pbkdf2WithFallback(plain.toCharArray(), salt, ITERATIONS, HASH_BYTES);
        String saltB64 = Base64.getEncoder().encodeToString(salt);
        String hashB64 = Base64.getEncoder().encodeToString(dr.hash);

        // Store algo used so we can verify later
        return String.format("pbkdf2$%s$%d$%s$%s", dr.algo, ITERATIONS, saltB64, hashB64);
    }

    /** Optional: use in login JSP to verify a password against the stored hash. */
    public static boolean verifyPassword(String plain, String stored) {
        if (stored == null) return false;

        // New format: pbkdf2$<algo>$<iter>$<salt>$<hash>
        String[] parts = stored.split("\\$");
        if (parts.length == 5 && "pbkdf2".equals(parts[0])) {
            String algo = parts[1];
            int iter = Integer.parseInt(parts[2]);
            byte[] salt = Base64.getDecoder().decode(parts[3]);
            byte[] expected = Base64.getDecoder().decode(parts[4]);

            byte[] actual = pbkdf2(plain.toCharArray(), salt, iter, expected.length, algo);
            return slowEquals(expected, actual);
        }

        // Legacy format support: pbkdf2_sha256$<iter>$<salt>$<hash>
        if (parts.length == 4 && "pbkdf2_sha256".equals(parts[0])) {
            int iter = Integer.parseInt(parts[1]);
            byte[] salt = Base64.getDecoder().decode(parts[2]);
            byte[] expected = Base64.getDecoder().decode(parts[3]);
            byte[] actual = pbkdf2(plain.toCharArray(), salt, iter, expected.length, "PBKDF2WithHmacSHA256");
            return slowEquals(expected, actual);
        }

        return false;
    }

    private static final class DeriveResult {
        final String algo;
        final byte[] hash;
        DeriveResult(String algo, byte[] hash){ this.algo = algo; this.hash = hash; }
    }

    private static DeriveResult pbkdf2WithFallback(char[] password, byte[] salt, int iterations, int bytes) {
        for (String algo : PBKDF2_ALGOS) {
            try {
                byte[] hash = pbkdf2(password, salt, iterations, bytes, algo);
                return new DeriveResult(algo, hash);
            } catch (IllegalStateException ignore) {
                // try next algorithm
            }
        }
        throw new IllegalStateException("No supported PBKDF2 algorithm found (tried SHA256, SHA512, SHA1)");
    }

    private static byte[] pbkdf2(char[] password, byte[] salt, int iterations, int bytes, String algo) {
        try {
            PBEKeySpec spec = new PBEKeySpec(password, salt, iterations, bytes * 8);
            SecretKeyFactory skf = SecretKeyFactory.getInstance(algo);
            return skf.generateSecret(spec).getEncoded();
        } catch (NoSuchAlgorithmException | InvalidKeySpecException e) {
            throw new IllegalStateException("PBKDF2 failure (" + algo + ")", e);
        }
    }

    // Constant-time comparison
    private static boolean slowEquals(byte[] a, byte[] b) {
        if (a == null || b == null || a.length != b.length) return false;
        int diff = 0;
        for (int i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
        return diff == 0;
    }
}
