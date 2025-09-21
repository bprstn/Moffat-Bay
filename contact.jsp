<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
  // --- Simple server-side handling ---
  request.setCharacterEncoding("UTF-8");

  boolean isPost = "POST".equalsIgnoreCase(request.getMethod());
  String name = isPost ? request.getParameter("name") : "";
  String email = isPost ? request.getParameter("email") : "";
  String message = isPost ? request.getParameter("message") : "";

  String errName = null, errEmail = null, errMessage = null;
  boolean showSuccess = false;

  if (isPost) {
    if (name == null || name.trim().isEmpty())    errName = "Name is required.";
    if (email == null || email.trim().isEmpty())  errEmail = "Email is required.";
    else if (!email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) errEmail = "Enter a valid email.";
    if (message == null || message.trim().isEmpty()) errMessage = "Message is required.";

    if (errName == null && errEmail == null && errMessage == null) {
      showSuccess = true;

      // (Optional) "backend" evidence in server logs
      System.out.println("[Contact] name=" + name + ", email=" + email + ", msg=" + message);
      // If you later want DB insert, this is where it would go.
    }
  }
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Contact Us – Moffat Bay Lodge</title>
  <link rel="stylesheet" href="style.css" />
  <style>
    /* Light inline helpers in case style.css doesn't have them */
    .container{max-width:960px;margin:0 auto;padding:2rem 1rem;}
    .h1{font-size:2rem;margin:0 0 1rem;}
    .field{margin:0 0 1rem;}
    .input, .textarea{width:100%;padding:0.9rem;border:1px solid #ddd;border-radius:10px;font-size:1rem;}
    .error{color:#b00020;font-size:0.9rem;margin-top:0.35rem;}
    .btn{display:block;width:100%;padding:1rem;border:none;border-radius:999px;font-weight:600;cursor:pointer;background:#E39A3B;color:#173728;}
    .banner{padding:1rem 1.2rem;border-radius:12px;margin:1rem 0;font-weight:600}
    .banner-success{background:#e9f7ef;color:#155724;border:1px solid #c7e5d3;}
  </style>
</head>
<body>
  <header class="container" style="padding-top:1rem;">
    <nav>
      <ul style="display:flex;gap:1rem;list-style:none;padding:0;margin:0 0 1.5rem 0;">
        <li><a href="index.html">Home</a></li>
        <li><a href="about.html">About</a></li>
        <li><a href="reservations.jsp">My Reservations</a></li>
        <li><a href="registration.jsp">Register</a></li>
        <li><a href="contact.jsp" style="font-weight:700;">Contact</a></li>
      </ul>
    </nav>
    <h1 class="h1">Contact Us</h1>
    <p>We’d love to hear from you. Please fill out the form below and our team will get back to you soon.</p>
  </header>

  <main class="container">
    <% if (showSuccess) { %>
      <div class="banner banner-success">Thank you! Your message has been sent.</div>
    <% } %>

    <form method="post" action="contact.jsp" novalidate>
      <div class="field">
        <input class="input" type="text" name="name" placeholder="Your Name" value="<%= (name==null?"":name) %>"/>
        <% if (errName != null) { %><div class="error"><%= errName %></div><% } %>
      </div>

      <div class="field">
        <input class="input" type="email" name="email" placeholder="Your Email" value="<%= (email==null?"":email) %>"/>
        <% if (errEmail != null) { %><div class="error"><%= errEmail %></div><% } %>
      </div>

      <div class="field">
        <textarea class="textarea" name="message" rows="7" placeholder="Your Message"><%= (message==null?"":message) %></textarea>
        <% if (errMessage != null) { %><div class="error"><%= errMessage %></div><% } %>
      </div>

      <button class="btn" type="submit">Send Message</button>
    </form>
  </main>
</body>
</html>
