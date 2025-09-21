<%@ page import="java.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Moffat Bay Lodge – Contact Us</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>

<header role="banner">
    <div class="container nav">
        <a class="brand" href="index.html">
            <img src="images/bear_logo.png" alt="Moffat Bay bear logo">
            <span>Moffat Bay Lodge</span>
        </a>
        <nav>
            <ul>
                <li><a href="about.html">About</a></li>
                <li><a href="book.jsp">Reservations</a></li>
                <li><a href="contact.jsp">Contact</a></li>
            </ul>
        </nav>
    </div>
</header>

<section class="hero about-hero">
    <div class="hero-inner">
        <h1>Contact Us</h1>
        <p class="sub">We’d love to hear from you!</p>
    </div>
</section>

<section class="container" style="max-width:600px; padding:40px 0">
    <form method="post" action="contact.jsp">
        <label for="name">Full Name</label>
        <input type="text" id="name" name="name" required>

        <label for="email">Email</label>
        <input type="email" id="email" name="email" required>

        <label for="subject">Subject</label>
        <input type="text" id="subject" name="subject" required>

        <label for="message">Message</label>
        <textarea id="message" name="message" rows="5" required></textarea>

        <button class="btn btn-primary" type="submit">Send Message</button>
    </form>

    <%
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String subject = request.getParameter("subject");
        String message = request.getParameter("message");

        if (name != null && email != null && subject != null && message != null) {
            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                Connection conn = DriverManager.getConnection(
                        "jdbc:mysql://localhost:3306/moffatbay",
                        "moffatbay", "moffatbay"
                );
                String sql = "INSERT INTO contact_messages (name, email, subject, message) VALUES (?,?,?,?)";
                PreparedStatement ps = conn.prepareStatement(sql);
                ps.setString(1, name);
                ps.setString(2, email);
                ps.setString(3, subject);
                ps.setString(4, message);
                ps.executeUpdate();
                conn.close();
    %>
                <p style="color:green; font-weight:bold; margin-top:20px">✅ Thank you! Your message has been sent.</p>
    <%
            } catch (Exception e) {
    %>
                <p style="color:red; font-weight:bold; margin-top:20px">❌ Error saving your message.</p>
                <pre><%= e.getMessage() %></pre>
    <%
            }
        }
    %>
</section>

<footer>
    <div class="container">
        <p>&copy; 2025 Moffat Bay Lodge</p>
    </div>
</footer>

</body>
</html>
