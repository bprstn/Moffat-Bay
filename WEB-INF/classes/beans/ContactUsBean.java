package beans;

import java.io.File;
import java.io.FileWriter;
import java.io.Serializable;
import java.sql.*;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

public class ContactUsBean implements Serializable {
    private static final long serialVersionUID = 1L;

    // --- inputs ---
    private String name;
    private String email;
    private String message;

    // --- state/outputs ---
    private boolean hasError;
    private String dbStatus = "not saved";
    private String errorMessage;
    private Long newId;

    // --- db config  ---
    private String jdbcUrl  = "jdbc:mysql://localhost:3306/moffatbay?useSSL=false&serverTimezone=UTC";
    private String jdbcUser = "moffatbay";
    private String jdbcPass = "moffatbay";

    public ContactUsBean() {}

    // getters/setters
    public String getName() { return name; }
    public void setName(String name) { this.name = safeTrim(name); }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = safeTrim(email); }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = safeTrim(message); }

    public boolean isHasError() { return hasError; }
    public String getErrorMessage() { return errorMessage; }
    public Long getNewId() { return newId; }
    public String getDbStatus() { return dbStatus; }

    public void setJdbcUrl(String jdbcUrl) { this.jdbcUrl = jdbcUrl; }
    public void setJdbcUser(String jdbcUser) { this.jdbcUser = jdbcUser; }
    public void setJdbcPass(String jdbcPass) { this.jdbcPass = jdbcPass; }

    // main entry: validate → save → log (no servlet deps)
    public void process(String appRealPath) {
        validate();
        if (!hasError) saveToDb();
        logToFile(appRealPath);
    }

    private void validate() {
        hasError = false; errorMessage = null;
        if (isBlank(name)) { fail("Name is required."); return; }
        if (isBlank(email)) { fail("Email is required."); return; }
        if (isBlank(message)) { fail("Message is required."); return; }
        if (!email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) { fail("Please enter a valid email address."); }
    }

    private void saveToDb() {
        Connection conn = null; PreparedStatement ps = null; ResultSet rs = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn = DriverManager.getConnection(jdbcUrl, jdbcUser, jdbcPass);
            ps = conn.prepareStatement(
                "INSERT INTO contact_messages (name, email, message) VALUES (?, ?, ?)",
                Statement.RETURN_GENERATED_KEYS
            );
            ps.setString(1, name);
            ps.setString(2, email);
            ps.setString(3, message);
            ps.executeUpdate();
            rs = ps.getGeneratedKeys();
            if (rs.next()) newId = rs.getLong(1);
            dbStatus = "saved";
        } catch (Exception e) {
            dbStatus = "db error: " + e.getMessage();
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception ignore) {}
            try { if (ps != null) ps.close(); } catch (Exception ignore) {}
            try { if (conn != null) conn.close(); } catch (Exception ignore) {}
        }
    }

    private void logToFile(String appRealPath) {
        String ts = ZonedDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss z"));
        String idStr = (newId == null) ? "-" : newId.toString();
        String sanitizedMsg = (message == null) ? "" : message.replaceAll("\\s+"," ").trim();
        String line = String.format("%s | name=%s | email=%s | db=%s | id=%s | msg=%s%n",
                ts, nullToEmpty(name), nullToEmpty(email), dbStatus, idStr, sanitizedMsg);
        try {
            File logsDir = new File(appRealPath, "WEB-INF/logs");
            if (!logsDir.exists()) logsDir.mkdirs();
            try (FileWriter fw = new FileWriter(new File(logsDir, "contact.log"), true)) {
                fw.write(line);
            }
        } catch (Exception ignore) {}
    }

    // tiny HTML escaper for use in JSP
    public static String esc(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
                .replace("\"","&quot;").replace("'","&#x27;");
    }

    private static boolean isBlank(String s){ return s == null || s.trim().isEmpty(); }
    private static String safeTrim(String s){ return s == null ? null : s.trim(); }
    private static String nullToEmpty(String s){ return s == null ? "" : s; }
    private void fail(String msg){ hasError = true; errorMessage = msg; }
}
